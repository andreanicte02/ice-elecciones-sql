"""Runs the 2018 SQL and the 2026 rewrites, and checks they all agree.

    python3 tests/verificar.py                       # SQLite only
    python3 tests/verificar.py --sqlserver localhost # also SQL Server (needs pymssql)
    python3 tests/verificar.py --json web/resultados.json

Checks:
  1. The 2018 queries give the same results on SQLite (port) as on SQL Server (original).
  2. The 2026 queries give the same results on both engines.
  3. Each 2026 query gives the same result as its 2018 counterpart.
  4. Sanity checks on the normalized data (row counts, totals match the CSV).
"""

import argparse
import csv
import decimal
import json
import re
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
CSV = RAIZ / "data" / "ICE-Fuente.csv"
MODERNAS = RAIZ / "sql" / "modernas"
BUILD = RAIZ / "build"

# The 2018 query 4 uses TOP 1 without ORDER BY, so which country it returns is up
# to the engine. It is reported but not compared.
NO_DETERMINISTA_2018 = {4}


# ---------------------------------------------------------------- helpers

def leer(path, encoding="utf-8"):
    return Path(path).read_text(encoding=encoding).replace("\r\n", "\n")


def consultas_2018(texto):
    """Splits consultas.sql on its `----consulta N` markers -> {N: sql}."""
    partes = re.split(r"-{3,}\s*consulta\s+(\d+)\s*\n", texto)
    return {int(partes[i]): partes[i + 1].strip() for i in range(1, len(partes), 2)}


def consultas_2026():
    return {int(p.stem.split("-")[1]): leer(p) for p in sorted(MODERNAS.glob("consulta-*.sql"))}


def normalizar(filas):
    """Comparable, order-independent form of a result set."""
    def valor(v):
        if isinstance(v, (float, decimal.Decimal)):
            return round(float(v), 4)
        if isinstance(v, str):
            return v.strip()
        return v
    return sorted((tuple(valor(v) for v in fila) for fila in filas), key=repr)


def a_json(v):
    if isinstance(v, decimal.Decimal):
        return float(v)
    return v


# ---------------------------------------------------------------- SQLite

def cargar_sqlite():
    db = sqlite3.connect(":memory:")
    db.executescript(leer(RAIZ / "sql/sqlite/esquema.sql"))
    db.executescript(leer(RAIZ / "sql/sqlite/temporal.sql"))
    with open(CSV, encoding="utf-8", newline="") as f:
        filas = list(csv.reader(f))[1:]
    db.executemany(f"INSERT INTO [#TEMPORAL0] VALUES ({','.join('?' * 15)})", filas)
    db.executescript(leer(RAIZ / "sql/sqlite/carga.sql"))
    db.executescript(leer(MODERNAS / "vista.sql"))
    return db, filas


def ejecutar_sqlite(db, sql):
    cur = db.execute(sql.rstrip().rstrip(";"))
    return [d[0] for d in cur.description], cur.fetchall()


# ---------------------------------------------------------------- SQL Server

def lotes(texto):
    """Splits a T-SQL script into batches on GO lines, like sqlcmd does."""
    return [b.strip() for b in re.split(r"^\s*GO\s*$", texto, flags=re.M | re.I) if b.strip()]


def cargar_sqlserver(host, password):
    import pymssql  # only needed for this engine

    conn = pymssql.connect(server=host, user="sa", password=password, autocommit=True)
    cur = conn.cursor()
    cur.execute("IF DB_ID('pro3') IS NOT NULL DROP DATABASE pro3")
    # UTF-8 collation (SQL Server 2019+), so the UTF-8 CSV loads without a code page.
    cur.execute("CREATE DATABASE pro3 COLLATE Latin1_General_100_CI_AS_SC_UTF8")

    # creacionbd.sql starts by dropping tables that don't exist yet on a fresh
    # database; those errors are expected, exactly as when it ran in 2018.
    cur.execute("USE pro3")
    for lote in lotes(leer(RAIZ / "creacionbd.sql", "cp1252")):
        try:
            cur.execute(lote)
        except pymssql.Error as e:
            sin_use = re.sub(r"^\s*use\s+\w+\s*;?\s*", "", lote, flags=re.I)
            if not sin_use.upper().startswith(("ALTER TABLE", "DROP")):
                raise RuntimeError(f"creacionbd.sql failed:\n{lote[:200]}\n{e}") from e

    # BULK INSERT reads a UTF-16 copy of the CSV from build/, mounted in the container as /data.
    BUILD.mkdir(exist_ok=True)
    (BUILD / "ICE-Fuente-utf16.csv").write_text(leer(CSV), encoding="utf-16")

    # Same session for the temp table: CSV prelude, then cargaabd.sql after its Excel import.
    cur.execute("USE pro3")
    for lote in lotes(leer(RAIZ / "sql/sqlserver/carga-csv.sql")):
        cur.execute(lote)
    carga = leer(RAIZ / "cargaabd.sql", "cp1252")
    carga = carga[carga.index("use pro3\n---------------------------------"):]
    for lote in lotes(carga):
        cur.execute(lote)
    cur.execute(leer(MODERNAS / "vista.sql"))
    return conn


def ejecutar_sqlserver(conn, sql):
    cur = conn.cursor()
    cur.execute(sql)
    return [d[0] for d in cur.description], cur.fetchall()


# ---------------------------------------------------------------- main

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sqlserver", help="SQL Server host to also run the original T-SQL on")
    ap.add_argument("--password", default="Bases-2018!")
    ap.add_argument("--json", help="write the SQL Server (or SQLite) results here for the website")
    args = ap.parse_args()

    fallos = []

    def check(ok, mensaje):
        print(("  ok   " if ok else "  FAIL ") + mensaje)
        if not ok:
            fallos.append(mensaje)

    print("SQLite")
    db, filas_csv = cargar_sqlite()
    total_csv = sum(int(f[10]) + int(f[11]) for f in filas_csv)
    total_db = db.execute("SELECT SUM(cantidad) FROM voto WHERE tipovotante_id >= 4").fetchone()[0]
    check(total_db == total_csv, f"every voter loaded once ({total_db:,} = {total_csv:,})")
    check(db.execute("SELECT COUNT(*) FROM voto").fetchone()[0] == 5 * len(filas_csv),
          "each sheet row becomes 5 votes (one per tipovotante)")
    for tabla, esperado in [("pais", 6), ("genero", 2), ("raza", 3), ("tipovotante", 5)]:
        n = db.execute(f"SELECT COUNT(*) FROM {tabla}").fetchone()[0]
        check(n == esperado, f"{tabla}: {n} rows")
    check(db.execute("PRAGMA foreign_key_check").fetchall() == [], "no foreign key violations")

    viejas = consultas_2018(leer(RAIZ / "sql/sqlite/consultas.sql"))
    nuevas = consultas_2026()
    res = {"sqlite_2018": {n: ejecutar_sqlite(db, q) for n, q in viejas.items()},
           "sqlite_2026": {n: ejecutar_sqlite(db, q) for n, q in nuevas.items()}}

    if args.sqlserver:
        print("SQL Server")
        conn = cargar_sqlserver(args.sqlserver, args.password)
        originales = consultas_2018(leer(RAIZ / "consultas.sql", "cp1252"))
        res["sqlserver_2018"] = {n: ejecutar_sqlserver(conn, q) for n, q in originales.items()}
        res["sqlserver_2026"] = {n: ejecutar_sqlserver(conn, q) for n, q in nuevas.items()}
        version = ejecutar_sqlserver(conn, "SELECT @@VERSION")[1][0][0].splitlines()[0]
        check(set(res["sqlserver_2018"]) == set(viejas), f"same 2018 queries on both engines ({version})")
        for n in sorted(viejas):
            if n in NO_DETERMINISTA_2018:
                continue
            check(normalizar(res["sqlserver_2018"][n][1]) == normalizar(res["sqlite_2018"][n][1]),
                  f"2018 query {n:2}: SQL Server original == SQLite port")
        for n in sorted(nuevas):
            check(normalizar(res["sqlserver_2026"][n][1]) == normalizar(res["sqlite_2026"][n][1]),
                  f"2026 query {n:2}: SQL Server == SQLite")

    print("2018 vs 2026")
    for n in sorted(viejas):
        if n in NO_DETERMINISTA_2018:
            continue
        check(normalizar(res["sqlite_2018"][n][1]) == normalizar(res["sqlite_2026"][n][1]),
              f"query {n:2}: 2026 rewrite == 2018 original")
    check(len(res["sqlite_2018"][4][1]) == 1, "query  4: 2018 version returns one row (any country)")

    if args.json:
        motor = "sqlserver" if args.sqlserver else "sqlite"
        salida = {
            "generado": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            "motor": version if args.sqlserver else f"SQLite {sqlite3.sqlite_version}",
            **{
                version: {
                    str(n): {"columnas": cols, "filas": [[a_json(v) for v in f] for f in filas]}
                    for n, (cols, filas) in res[f"{motor}_{version}"].items()
                }
                for version in ("2018", "2026")
            },
        }
        Path(args.json).write_text(json.dumps(salida, ensure_ascii=False))
        print(f"wrote {args.json}")

    print(f"\n{len(fallos)} failure(s)")
    sys.exit(1 if fallos else 0)


if __name__ == "__main__":
    main()
