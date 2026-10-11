"""Assembles the GitHub Pages site into site/ (or the directory given).

    python3 scripts/build_site.py [site] [--resultados build/resultados.json]

Copies the page, the CSV, the SQL scripts the browser runs, the 2018 ER diagram,
and writes consultas.json with each query's question, 2018 SQL and 2026 SQL.
"""

import argparse
import json
import re
import shutil
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RAIZ / "tests"))
import verificar  # noqa: E402  (reuses the query splitting)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("salida", nargs="?", default="site")
    ap.add_argument("--resultados", help="SQL Server results written by tests/verificar.py --json")
    args = ap.parse_args()

    out = Path(args.salida)
    shutil.rmtree(out, ignore_errors=True)
    (out / "sql").mkdir(parents=True)

    for f in ("index.html", "app.js", "style.css"):
        shutil.copy(RAIZ / "web" / f, out / f)
    shutil.copy(RAIZ / "data" / "ICE-Fuente.csv", out / "ICE-Fuente.csv")
    shutil.copy(RAIZ / "er.png", out / "er.png")
    for f in ("sqlite/esquema.sql", "sqlite/temporal.sql", "sqlite/carga.sql", "modernas/vista.sql"):
        shutil.copy(RAIZ / "sql" / f, out / "sql" / Path(f).name)

    viejas = verificar.consultas_2018(verificar.leer(RAIZ / "sql/sqlite/consultas.sql"))
    nuevas = verificar.consultas_2026()
    consultas = []
    for n in sorted(nuevas):
        sql2026 = nuevas[n]
        # The question is the first comment line of the 2026 file; extra comment lines are notes.
        comentarios = re.findall(r"^-- ?(.*)$", sql2026, flags=re.M)
        pregunta = re.sub(r"^\d+\.\s*", "", comentarios[0])
        consultas.append({
            "n": n,
            "pregunta": pregunta,
            "nota": " ".join(comentarios[1:]),
            "sql2018": viejas.get(n),
            "sql2026": "\n".join(l for l in sql2026.splitlines() if not l.startswith("--")).strip(),
        })
    (out / "consultas.json").write_text(json.dumps(consultas, ensure_ascii=False, indent=1))

    if args.resultados:
        shutil.copy(args.resultados, out / "resultados.json")
    print(f"site written to {out}/ ({len(consultas)} queries)")


if __name__ == "__main__":
    main()
