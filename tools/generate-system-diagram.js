const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const defaultSql = path.join(root, "schema_gia_su_complete.sql");
const sqlPath = process.argv[2] ? path.resolve(process.argv[2]) : defaultSql;

const outBase = path.join(root, "so_do_diagram_gia_su");
const outSvg = `${outBase}.svg`;
const outHtml = `${outBase}.html`;
const outMmd = `${outBase}.mmd`;

const sql = fs.readFileSync(sqlPath, "utf8");

function cleanName(value) {
  return value.replace(/[\[\]"]/g, "").replace(/^(public|dbo)\./i, "").trim();
}

function splitTopLevel(text) {
  const parts = [];
  let current = "";
  let depth = 0;
  let quote = null;

  for (let index = 0; index < text.length; index += 1) {
    const ch = text[index];
    const next = text[index + 1];

    if (quote === "'" && ch === "'" && next === "'") {
      current += ch + next;
      index += 1;
      continue;
    }

    if ((ch === "'" || ch === '"') && !quote) quote = ch;
    else if (ch === quote) quote = null;

    if (!quote && ch === "(") depth += 1;
    if (!quote && ch === ")") depth -= 1;

    if (!quote && depth === 0 && ch === ",") {
      parts.push(current.trim());
      current = "";
    } else {
      current += ch;
    }
  }

  if (current.trim()) parts.push(current.trim());
  return parts;
}

function parseColumn(definition) {
  const text = definition.replace(/\s+/g, " ").trim();
  if (!text || /^(CONSTRAINT|PRIMARY\s+KEY|FOREIGN\s+KEY|UNIQUE|CHECK)\b/i.test(text)) {
    return null;
  }

  const match = text.match(/^(\[?[A-Za-z_][\w]*\]?|"[A-Za-z_][\w]*")\s+(.+)$/);
  if (!match) return null;

  const name = cleanName(match[1]);
  const rest = match[2].trim();
  const typeMatch = rest.match(/^(.+?)(?=\s+(?:COLLATE|CONSTRAINT|DEFAULT|GENERATED|IDENTITY|NOT\s+NULL|NULL|PRIMARY\s+KEY|REFERENCES|UNIQUE|CHECK)\b|$)/i);
  const type = (typeMatch ? typeMatch[1] : rest).trim();

  return {
    name,
    type,
    primary: /\bPRIMARY\s+KEY\b/i.test(rest),
    required: /\bNOT\s+NULL\b/i.test(rest) || /\bPRIMARY\s+KEY\b/i.test(rest),
  };
}

function parseTables(source) {
  const tables = [];
  const regex = /CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?((?:(?:public|dbo)\.)?(?:\[?[A-Za-z_][\w]*\]?|"[A-Za-z_][\w]*"))\s*\(([\s\S]*?)\);/gi;
  let match;

  while ((match = regex.exec(source))) {
    const table = {
      name: cleanName(match[1]),
      columns: splitTopLevel(match[2]).map(parseColumn).filter(Boolean),
    };
    tables.push(table);
  }

  return tables;
}

function xml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function shortType(type) {
  return type.replace(/\s+/g, " ");
}

function renderSvg(tables) {
  const cardWidth = 395;
  const headerHeight = 46;
  const rowHeight = 22;
  const gapX = 30;
  const gapY = 30;
  const columns = 4;
  const margin = 56;
  const titleHeight = 132;
  const sourceName = path.relative(root, sqlPath).replace(/\\/g, "/");

  const cardHeights = tables.map((table) => headerHeight + table.columns.length * rowHeight + 18);
  const rowHeights = [];
  for (let i = 0; i < cardHeights.length; i += columns) {
    rowHeights.push(Math.max(...cardHeights.slice(i, i + columns)));
  }

  const width = margin * 2 + columns * cardWidth + (columns - 1) * gapX;
  const height = titleHeight + rowHeights.reduce((sum, h) => sum + h, 0) + (rowHeights.length - 1) * gapY + margin;

  const cards = tables.map((table, index) => {
    const col = index % columns;
    const row = Math.floor(index / columns);
    const x = margin + col * (cardWidth + gapX);
    const y = titleHeight + rowHeights.slice(0, row).reduce((sum, h) => sum + h, 0) + row * gapY;
    const height = cardHeights[index];

    const rows = table.columns.map((column, columnIndex) => {
      const yText = y + headerHeight + 21 + columnIndex * rowHeight;
      const marker = column.primary ? "PK" : column.required ? "NN" : "";
      return `
        <text class="col-name" x="${x + 18}" y="${yText}">${xml(column.name)}</text>
        <text class="col-type" x="${x + 215}" y="${yText}">${xml(shortType(column.type))}</text>
        ${marker ? `<text class="col-marker" x="${x + 354}" y="${yText}">${marker}</text>` : ""}`;
    }).join("\n");

    return `
      <g class="table-card">
        <rect class="card" x="${x}" y="${y}" width="${cardWidth}" height="${height}" rx="8"/>
        <rect class="card-head" x="${x}" y="${y}" width="${cardWidth}" height="${headerHeight}" rx="8"/>
        <rect class="head-square" x="${x}" y="${y + 30}" width="${cardWidth}" height="${headerHeight - 30}"/>
        <text class="table-name" x="${x + 18}" y="${y + 30}">${xml(table.name)}</text>
        <text class="column-count" x="${x + cardWidth - 18}" y="${y + 30}">${table.columns.length} cot</text>
        ${rows}
      </g>`;
  }).join("\n");

  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-labelledby="title desc">
  <title id="title">So do table diagram tu SQL</title>
  <desc id="desc">Diagram chi gom cac table va cot doc tu ${xml(sourceName)}. Khong phai ERD, khong co quan he, khong them doi tuong ngoai table.</desc>
  <style>
    .bg { fill: #f8fafc; }
    .eyebrow { font: 700 12px "Segoe UI", Arial, sans-serif; fill: #2563eb; letter-spacing: .08em; }
    .title { font: 800 31px "Segoe UI", Arial, sans-serif; fill: #0f172a; letter-spacing: 0; }
    .subtitle { font: 500 15px "Segoe UI", Arial, sans-serif; fill: #475569; }
    .card { fill: #ffffff; stroke: #cbd5e1; stroke-width: 1.2; }
    .card-head, .head-square { fill: #1f2937; }
    .table-name { font: 800 16px Consolas, "Courier New", monospace; fill: #ffffff; }
    .column-count { font: 700 12px "Segoe UI", Arial, sans-serif; fill: #cbd5e1; text-anchor: end; }
    .col-name { font: 700 12px Consolas, "Courier New", monospace; fill: #111827; }
    .col-type { font: 500 12px Consolas, "Courier New", monospace; fill: #475569; }
    .col-marker { font: 800 10px "Segoe UI", Arial, sans-serif; fill: #2563eb; text-anchor: middle; }
  </style>
  <rect class="bg" x="0" y="0" width="${width}" height="${height}"/>
  <text class="eyebrow" x="${margin}" y="42">TABLE DIAGRAM TU SQL - KHONG PHAI ERD</text>
  <text class="title" x="${margin}" y="80">So do cac table trong schema</text>
  <text class="subtitle" x="${margin}" y="108">Nguon: ${xml(sourceName)} | ${tables.length} table | Chi hien thi table va cot dung theo CREATE TABLE.</text>
  ${cards}
</svg>`;
}

function renderHtml(svg) {
  return `<!doctype html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>So do table diagram tu SQL</title>
  <style>
    body { margin: 0; background: #e2e8f0; }
    .wrap { width: max-content; min-width: 100%; }
    svg { display: block; }
  </style>
</head>
<body>
  <div class="wrap">
${svg}
  </div>
</body>
</html>
`;
}

function renderMmd(tables) {
  const lines = [
    "flowchart TB",
    "  classDef table fill:#ffffff,stroke:#1f2937,stroke-width:1px,color:#111827;",
  ];

  for (const table of tables) {
    lines.push(`  ${table.name}["${table.name}"]:::table`);
  }

  return `${lines.join("\n")}\n`;
}

const tables = parseTables(sql);

if (!tables.length) {
  throw new Error(`No CREATE TABLE blocks found in ${sqlPath}`);
}

const svg = renderSvg(tables);
fs.writeFileSync(outSvg, svg, "utf8");
fs.writeFileSync(outHtml, renderHtml(svg), "utf8");
fs.writeFileSync(outMmd, renderMmd(tables), "utf8");

console.log(`Generated ${tables.length} tables from ${path.relative(root, sqlPath)}`);
console.log(outSvg);
console.log(outHtml);
console.log(outMmd);
