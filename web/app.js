const $ = (sel) => document.querySelector(sel);
const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
const fmt = (n) => n.toLocaleString("es-GT");
const MAX_FILAS = 200;

let db;
let sqlServer = null; // results from SQL Server 2022, written by CI

/* ------------------------------------------------------------------ CSV */
function parseCsv(text) {
  const rows = [];
  let row = [], field = "", quoted = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quoted) {
      if (c === '"' && text[i + 1] === '"') { field += '"'; i++; }
      else if (c === '"') quoted = false;
      else field += c;
    } else if (c === '"') quoted = true;
    else if (c === ",") { row.push(field); field = ""; }
    else if (c === "\n") { row.push(field); rows.push(row); row = []; field = ""; }
    else if (c !== "\r") field += c;
  }
  if (field || row.length) { row.push(field); rows.push(row); }
  return rows;
}

/* --------------------------------------------------------------- results */
function valor(v) {
  if (typeof v === "number" && !Number.isInteger(v)) return Math.round(v * 1e4) / 1e4;
  if (typeof v === "string") return v.trim();
  return v;
}
// Same normalization as tests/verificar.py: rounded, trimmed, order-independent.
const firma = (filas) => filas.map((f) => JSON.stringify(f.map(valor))).sort().join("\n");

function ejecutar(sql) {
  const t0 = performance.now();
  const res = db.exec(sql);
  const ms = performance.now() - t0;
  const last = res[res.length - 1] || { columns: [], values: [] };
  return { columnas: last.columns, filas: last.values, ms };
}

function tabla(columnas, filas) {
  if (!columnas.length) return `<p class="empty">La consulta no devolvió columnas.</p>`;
  if (!filas.length) return `<p class="empty">Sin filas.</p>`;
  // Years and ids read better without thousands separators (2018, not 2,018).
  const sinSeparador = columnas.map((c) => /^(a[nñ]o|fecha|id)$|_id$/i.test(c));
  const celda = (v, i) => {
    if (v === null) return `<td class="n">NULL</td>`;
    if (typeof v === "number") {
      const txt = sinSeparador[i] ? String(v)
        : Number.isInteger(v) ? fmt(v) : v.toLocaleString("es-GT", { maximumFractionDigits: 2 });
      return `<td class="n">${txt}</td>`;
    }
    return `<td>${esc(v)}</td>`;
  };
  const cuerpo = filas.slice(0, MAX_FILAS).map((f) => `<tr>${f.map(celda).join("")}</tr>`).join("");
  return `<div class="tablewrap"><table><thead><tr>${columnas.map((c) => `<th>${esc(c)}</th>`).join("")}</tr></thead><tbody>${cuerpo}</tbody></table></div>`;
}

/* ----------------------------------------------------------------- setup */
async function texto(url) {
  const r = await fetch(url);
  if (!r.ok) throw new Error(`${url}: ${r.status}`);
  return r.text();
}

async function iniciar() {
  const [SQL, esquema, temporal, carga, vista, csv, consultas] = await Promise.all([
    initSqlJs({ locateFile: (f) => `https://cdnjs.cloudflare.com/ajax/libs/sql.js/1.14.2/${f}` }),
    texto("sql/esquema.sql"), texto("sql/temporal.sql"), texto("sql/carga.sql"), texto("sql/vista.sql"),
    texto("ICE-Fuente.csv"), fetch("consultas.json").then((r) => r.json()),
  ]);
  try { sqlServer = await fetch("resultados.json").then((r) => (r.ok ? r.json() : null)); } catch { sqlServer = null; }

  // 1. the flat sheet
  const filas = parseCsv(csv).filter((f) => f.length > 1);
  const [encabezado, ...datos] = filas;
  const paises = new Set(datos.map((f) => f[0])).size;
  const guate = datos.filter((f) => f[0] === "GUATEMALA").length;
  $("#hojaInfo").textContent =
    `${fmt(datos.length)} filas × ${encabezado.length} columnas. Solo hay ${paises} países, pero "GUATEMALA" ` +
    `aparece escrito ${fmt(guate)} veces, y lo mismo pasa con cada región, departamento y partido.`;
  $("#hojaTabla").innerHTML =
    `<thead><tr>${encabezado.map((c) => `<th>${esc(c)}</th>`).join("")}</tr></thead>` +
    `<tbody>${datos.slice(0, 12).map((f) => `<tr>${f.map((v) => `<td${/^\d+$/.test(v) ? ' class="n"' : ""}>${esc(v)}</td>`).join("")}</tr>`).join("")}</tbody>`;

  // 2. normalize, running the 2018 load script
  db = new SQL.Database();
  db.exec(esquema);
  db.exec(temporal);
  const t0 = performance.now();
  db.exec("BEGIN");
  const insert = db.prepare(`INSERT INTO [#TEMPORAL0] VALUES (${Array(15).fill("?").join(",")})`);
  for (const f of datos) insert.run(f);
  insert.free();
  db.exec("COMMIT");
  const t1 = performance.now();
  db.exec(carga);
  const t2 = performance.now();
  db.exec(vista);

  const tablas = ["pais", "region", "departamento", "municipio", "eleccion", "partido", "genero", "raza", "tipovotante", "voto"];
  $("#conteos").innerHTML = tablas
    .map((t) => `<dt>${t}</dt><dd>${fmt(db.exec(`SELECT COUNT(*) FROM ${t}`)[0].values[0][0])}</dd>`).join("");
  const version = db.exec("SELECT sqlite_version()")[0].values[0][0];
  $("#cargaInfo").textContent =
    `Hoja cargada en ${Math.round(t1 - t0)} ms y normalizada en ${Math.round(t2 - t1)} ms, con SQLite ${version} en tu navegador. ` +
    `Cada una de las ${fmt(datos.length)} filas se convirtió en 5 votos.`;
  $("#cargaSql").textContent = carga;

  // 3. queries
  $("#verificado").textContent = sqlServer
    ? `Cada resultado se compara con el que dio el T-SQL original en ${(sqlServer.motor.match(/Microsoft SQL Server \d+/) || [sqlServer.motor])[0]} ` +
      `al publicar esta página (${new Date(sqlServer.generado).toLocaleDateString("es-GT", { dateStyle: "long" })}).`
    : "";
  $("#lista").innerHTML = consultas.map(tarjeta).join("");
  for (const c of consultas) montar(c);

  // 4. console
  $("#libreRun").addEventListener("click", () => correr($("#libre"), $("#libreOut"), $("#libreMeta")));
  correr($("#libre"), $("#libreOut"), $("#libreMeta"));
}

/* ------------------------------------------------------------- query cards */
function tarjeta(c) {
  const versiones = c.sql2018 ? ["2018", "2026"] : ["2026"];
  return `<article class="q" id="q${c.n}">
    <div class="qhead"><span class="qnum">${c.n}</span><h3>${esc(c.pregunta)}</h3></div>
    ${c.nota ? `<p class="qnote">${esc(c.nota)}</p>` : ""}
    <div class="tabs" role="tablist">${versiones.map((v, i) =>
      `<button type="button" role="tab" data-v="${v}" aria-selected="${i === 0}">${v}</button>`).join("")}</div>
    <div class="qbody">
      <textarea spellcheck="false" aria-label="SQL de la consulta ${c.n}"></textarea>
      <div class="runbar"><button type="button" class="run">Ejecutar</button><span class="meta"></span><span class="badge"></span></div>
      <div class="result"></div>
    </div>
  </article>`;
}

function montar(c) {
  const card = $(`#q${c.n}`);
  const area = card.querySelector("textarea");
  const editado = { 2018: c.sql2018, 2026: c.sql2026 };
  let actual = c.sql2018 ? "2018" : "2026";

  const mostrar = (v) => {
    editado[actual] = area.value;
    actual = v;
    area.value = editado[v];
    area.style.height = "auto";
    area.style.height = Math.min(area.scrollHeight + 4, 520) + "px";
    card.querySelectorAll(".tabs button").forEach((b) => b.setAttribute("aria-selected", String(b.dataset.v === v)));
    correr(area, card.querySelector(".result"), card.querySelector(".meta"), card.querySelector(".badge"), c.n, v);
  };
  card.querySelectorAll(".tabs button").forEach((b) => b.addEventListener("click", () => mostrar(b.dataset.v)));
  card.querySelector(".run").addEventListener("click", () =>
    correr(area, card.querySelector(".result"), card.querySelector(".meta"), card.querySelector(".badge"), c.n, actual));
  area.value = editado[actual];
  mostrar(actual);
}

function correr(area, out, meta, badge, n, version) {
  try {
    const r = ejecutar(area.value);
    out.innerHTML = tabla(r.columnas, r.filas);
    meta.textContent = `${fmt(r.filas.length)} fila${r.filas.length === 1 ? "" : "s"} · ${r.ms.toFixed(1)} ms` +
      (r.filas.length > MAX_FILAS ? ` · se muestran ${MAX_FILAS}` : "");
    if (badge) comparar(badge, n, version, r);
  } catch (e) {
    out.innerHTML = `<p class="error">${esc(e.message)}</p>`;
    meta.textContent = "";
    if (badge) { badge.className = "badge"; badge.textContent = ""; }
  }
}

function comparar(badge, n, version, r) {
  const ref = sqlServer && sqlServer[version] && sqlServer[version][n];
  badge.className = "badge";
  badge.textContent = "";
  if (!ref) return;
  if (firma(r.filas) === firma(ref.filas)) {
    badge.className = "badge ok";
    badge.textContent = "✓ mismo resultado que SQL Server 2022";
  } else if (n === 4 && version === "2018") {
    badge.className = "badge diff";
    badge.textContent = `✗ SQL Server devolvió ${ref.filas[0][0]}: sin ORDER BY, cada motor elige una fila distinta`;
  } else {
    badge.className = "badge diff";
    badge.textContent = "≠ distinto de SQL Server 2022 (¿editaste la consulta?)";
  }
}

iniciar().catch((e) => {
  $("#hojaInfo").textContent = "No se pudo cargar la base de datos: " + e.message;
});
