# Bases de Datos 1 — Instituto Centroamericano Electoral

[![Verify on SQL Server](https://github.com/andreanicte02/ice-elecciones-sql/actions/workflows/verificar-y-publicar.yml/badge.svg)](https://github.com/andreanicte02/ice-elecciones-sql/actions/workflows/verificar-y-publicar.yml)
[![Live demo](https://img.shields.io/badge/demo-live-256abf)](https://andreanicte02.github.io/ice-elecciones-sql/)

*[English summary below](#english)*

Proyecto final de Bases de Datos 1 (USAC, 2018): normalizar una hoja de Excel con resultados
electorales de Centroamérica en un modelo relacional de 10 tablas, cargarla con SQL y responder
14 reportes con consultas.

**▶ Pruébalo en el navegador: <https://andreanicte02.github.io/ice-elecciones-sql/>**:
la carga y las 14 consultas corren ahí mismo con SQLite (WebAssembly), editables, y cada resultado
se compara con el que dio el T-SQL original en SQL Server 2022.

> **Datos sintéticos.** El Excel del curso (`ICE-Fuente.xls`) ya no existe y su enlace murió, así
> que [`data/generar_datos.py`](data/generar_datos.py) genera una hoja con la misma estructura:
> lugares reales de Centroamérica (una muestra de municipios por departamento), pero partidos y
> votos inventados. No representan ninguna elección real.

## Qué hay aquí

| Archivo | |
|---|---|
| [`creacionbd.sql`](creacionbd.sql), [`bd.ddl`](bd.ddl) | Esquema de 2018 (SQL Server): 10 tablas, llaves y foráneas |
| [`cargaabd.sql`](cargaabd.sql) | Carga de 2018: Excel → tabla temporal `#TEMPORAL0` → modelo normalizado |
| [`consultas.sql`](consultas.sql) | Las consultas de 2018 |
| [`er.png`](er.png), PDFs | Diagrama entidad-relación, documentación, manuales y enunciado |
| [`data/`](data) | Generador y la hoja sintética `ICE-Fuente.csv` |
| [`sql/sqlserver/carga-csv.sql`](sql/sqlserver/carga-csv.sql) | Reemplaza la importación de Excel (`OPENROWSET`) por `BULK INSERT` del CSV |
| [`sql/sqlite/`](sql/sqlite) | Port a SQLite del esquema, la carga y las consultas, con cambios mínimos |
| [`sql/modernas/`](sql/modernas) | Las 14 consultas reescritas en 2026 (CTEs, funciones de ventana, vista `voto_detalle`) |
| [`tests/verificar.py`](tests/verificar.py) | Ejecuta todo en SQL Server y SQLite y compara resultados |

## El modelo

Cada fila de la hoja repite país, región, departamento, municipio, partido y elección, y cuenta a
los votantes en cinco columnas: analfabetas, alfabetas y, de los alfabetas, primaria, nivel medio y
universitario. La carga lo separa en `pais → region → departamento → municipio`, catálogos
(`partido`, `eleccion`, `genero`, `raza`, `tipovotante`) y `voto`, donde **cada fila de la hoja se
convierte en cinco votos**, uno por tipo de votante. Por eso las consultas usan
`tipovotante_id >= 4` (analfabetas + alfabetas) para contar a cada votante una sola vez.

![Diagrama entidad-relación](er.png)

## Verificado contra SQL Server

En cada push, GitHub Actions levanta **SQL Server 2022**, ejecuta `creacionbd.sql`,
`cargaabd.sql` y `consultas.sql` tal como se escribieron en 2018 (solo la importación de Excel se
cambia por el CSV) y comprueba que:

1. cada consulta de 2018 da lo mismo en SQL Server que su port a SQLite;
2. cada consulta de 2026 da lo mismo en ambos motores;
3. cada consulta de 2026 da lo mismo que la de 2018;
4. la carga no pierde votantes y respeta todas las llaves foráneas.

Los resultados de SQL Server se publican con la página, que los compara en vivo.

## Lo que se encontró al revisarlo en 2026

- **La consulta 4 tiene un bug.** Usa `SELECT TOP 1` sin `ORDER BY`, así que devuelve una fila
  cualquiera en vez del país con más analfabetas. Con los mismos datos, SQL Server devuelve
  Guatemala (24.5 %, la respuesta correcta, por suerte) y SQLite devuelve Costa Rica (4 %, el menor).
  La versión 2026 ordena antes de elegir.
- **La consulta 5 nunca se escribió** (partidos con más alcaldías ganadas por país). Se agregó en 2026.
- **La carga casi no necesitó cambios para SQLite**: SQLite acepta los corchetes de SQL Server
  (`[nivel medio]`, `[#TEMPORAL0]`), así que solo hubo que terminar las sentencias con `;`.
- Las demás consultas son correctas: la reescritura con CTEs da exactamente los mismos resultados.

## Ejecutarlo localmente

```sh
python3 tests/verificar.py                 # carga y consultas en SQLite, sin instalar nada

# con SQL Server 2022 en Docker (requiere: pip install pymssql)
mkdir -p build
docker run -d --name mssql -e ACCEPT_EULA=Y -e "MSSQL_SA_PASSWORD=Bases-2018!" \
  -p 1433:1433 -v "$PWD/build:/data:ro" mcr.microsoft.com/mssql/server:2022-latest
python3 tests/verificar.py --sqlserver localhost

# el sitio
python3 scripts/build_site.py site && python3 -m http.server --directory site
```

## English

Final project for Databases 1 (USAC, 2018): normalizing a denormalized Central American election
spreadsheet into a 10-table relational model with a T-SQL load script, plus 14 report queries.
In 2026 it was revived with a synthetic dataset (the original file is gone), a CI job that runs
the original T-SQL on SQL Server 2022 and checks it against a SQLite port and modern CTE/window
function rewrites, and a [browser playground](https://andreanicte02.github.io/ice-elecciones-sql/)
where the load and every query run live. Reviewing it found one real bug (query 4: `TOP 1` without
`ORDER BY`) and one query that was never written (query 5), both fixed in the 2026 versions.

## Créditos

Por [Andrea Nicte Vicente Campos](https://github.com/andreanicte02) — Bases de Datos 1, sección B,
USAC, primer semestre 2018.
