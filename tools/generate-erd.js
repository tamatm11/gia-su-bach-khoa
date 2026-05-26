const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const schemaPath = path.join(root, "schema_gia_su_complete.sql");
const outSvg = path.join(root, "erd_schema_gia_su_complete.svg");
const outHtml = path.join(root, "erd_schema_gia_su_complete.html");
const outMmd = path.join(root, "erd_schema_gia_su_complete.mmd");

const sql = fs.readFileSync(schemaPath, "utf8");

function cleanName(name) {
  return name.replace(/[\[\]]/g, "").replace(/^dbo\./i, "").trim();
}

function splitTopLevel(text) {
  const parts = [];
  let current = "";
  let depth = 0;
  let quote = false;

  for (let i = 0; i < text.length; i += 1) {
    const ch = text[i];
    const next = text[i + 1];

    if (ch === "'" && quote && next === "'") {
      current += ch + next;
      i += 1;
      continue;
    }

    if (ch === "'") quote = !quote;
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

function splitColumns(raw) {
  return raw
    .split(",")
    .map((item) => cleanName(item))
    .filter(Boolean);
}

function parseColumn(definition) {
  const match = definition.match(/^(\[?[A-Za-z_][\w]*\]?)(?:\s+)([\s\S]+)$/);
  if (!match) return null;

  const name = cleanName(match[1]);
  const rest = match[2].replace(/\s+/g, " ").trim();
  const upper = rest.toUpperCase();
  const typeMatch = rest.match(/^(.+?)(?=\s+(?:CONSTRAINT|NOT\s+NULL|NULL|PRIMARY\s+KEY|UNIQUE|REFERENCES|DEFAULT|CHECK|IDENTITY|COLLATE)\b|$)/i);
  const type = (typeMatch ? typeMatch[1] : rest).trim();

  return {
    name,
    type,
    nullable: !upper.includes("NOT NULL") && !upper.includes("PRIMARY KEY"),
    primary: upper.includes("PRIMARY KEY"),
    unique: /\bUNIQUE\b/i.test(rest),
    references: parseReferences(rest),
  };
}

function parseReferences(definition) {
  const match = definition.match(/REFERENCES\s+([A-Za-z_][\w.]*)\s*\(([^)]+)\)/i);
  if (!match) return null;

  return {
    table: cleanName(match[1]),
    columns: splitColumns(match[2]),
  };
}

function parseConstraint(definition) {
  let text = definition.replace(/\s+/g, " ").trim();
  text = text.replace(/^CONSTRAINT\s+\[?[A-Za-z_][\w]*\]?\s+/i, "");

  const pk = text.match(/^PRIMARY\s+KEY\s*(?:CLUSTERED|NONCLUSTERED)?\s*\(([^)]+)\)/i);
  if (pk) return { type: "primary", columns: splitColumns(pk[1]) };

  const unique = text.match(/^UNIQUE\s*(?:CLUSTERED|NONCLUSTERED)?\s*\(([^)]+)\)/i);
  if (unique) return { type: "unique", columns: splitColumns(unique[1]) };

  const fk = text.match(/^FOREIGN\s+KEY\s*\(([^)]+)\)\s+REFERENCES\s+([A-Za-z_][\w.]*)\s*\(([^)]+)\)/i);
  if (fk) {
    return {
      type: "foreign",
      columns: splitColumns(fk[1]),
      refTable: cleanName(fk[2]),
      refColumns: splitColumns(fk[3]),
    };
  }

  return null;
}

function parseSchema(source) {
  const tables = new Map();
  const relationships = [];
  const tableRegex = /CREATE\s+TABLE\s+([A-Za-z_][\w.]*)\s*\(([\s\S]*?)\);/gi;
  let match;

  while ((match = tableRegex.exec(source))) {
    const tableName = cleanName(match[1]);
    const table = {
      name: tableName,
      columns: [],
      pk: [],
      uniques: [],
    };

    for (const item of splitTopLevel(match[2])) {
      if (/^(CONSTRAINT|PRIMARY\s+KEY|UNIQUE|FOREIGN\s+KEY|CHECK)\b/i.test(item)) {
        const constraint = parseConstraint(item);
        if (!constraint) continue;

        if (constraint.type === "primary") table.pk.push(...constraint.columns);
        if (constraint.type === "unique") table.uniques.push(constraint.columns);
        if (constraint.type === "foreign") {
          relationships.push({
            childTable: tableName,
            childColumns: constraint.columns,
            parentTable: constraint.refTable,
            parentColumns: constraint.refColumns,
          });
        }
        continue;
      }

      const column = parseColumn(item);
      if (!column) continue;

      table.columns.push(column);
      if (column.primary) table.pk.push(column.name);
      if (column.unique) table.uniques.push([column.name]);
      if (column.references) {
        relationships.push({
          childTable: tableName,
          childColumns: [column.name],
          parentTable: column.references.table,
          parentColumns: column.references.columns,
        });
      }
    }

    table.pk = [...new Set(table.pk)];
    tables.set(tableName, table);
  }

  const alterRegex = /ALTER\s+TABLE\s+([A-Za-z_][\w.]*)\s+ADD\s+(?:CONSTRAINT\s+\[?[A-Za-z_][\w]*\]?\s+)?FOREIGN\s+KEY\s*\(([^)]+)\)\s+REFERENCES\s+([A-Za-z_][\w.]*)\s*\(([^)]+)\)/gi;
  while ((match = alterRegex.exec(source))) {
    relationships.push({
      childTable: cleanName(match[1]),
      childColumns: splitColumns(match[2]),
      parentTable: cleanName(match[3]),
      parentColumns: splitColumns(match[4]),
    });
  }

  return { tables: [...tables.values()], relationships };
}

const parsed = parseSchema(sql);
const tableByName = new Map(parsed.tables.map((table) => [table.name, table]));

for (const relationship of parsed.relationships) {
  const table = tableByName.get(relationship.childTable);
  if (!table) continue;

  for (const columnName of relationship.childColumns) {
    const column = table.columns.find((candidate) => candidate.name === columnName);
    if (column) column.foreign = true;
  }
}

function sameColumns(a, b) {
  return a.length === b.length && a.every((item, index) => item === b[index]);
}

function fkIsUnique(relationship) {
  const table = tableByName.get(relationship.childTable);
  if (!table) return false;

  return sameColumns(table.pk, relationship.childColumns)
    || table.uniques.some((columns) => sameColumns(columns, relationship.childColumns));
}

function fkIsRequired(relationship) {
  const table = tableByName.get(relationship.childTable);
  if (!table) return false;

  return relationship.childColumns.every((columnName) => {
    const column = table.columns.find((candidate) => candidate.name === columnName);
    return column && !column.nullable;
  });
}

function childCardinality(relationship) {
  if (fkIsUnique(relationship)) return "0..1";
  return "0..N";
}

function parentCardinality(relationship) {
  return fkIsRequired(relationship) ? "1" : "0..1";
}

const boxWidth = 370;
const rowHeight = 24;
const headerHeight = 48;
const padding = 14;

const positionByTable = {
  hoc_vien: [70, 120],
  gia_su: [70, 575],
  mon_hoc: [70, 1010],
  yeu_cau_lop: [530, 80],
  ung_tuyen: [990, 125],
  lop_hoc: [1450, 80],
  dang_ky: [1910, 145],
  gia_su_mon_hoc: [530, 690],
  yeu_cau_mon: [990, 600],
  lop_hoc_mon: [1450, 630],
  lich_hoc: [1910, 560],
  buoi_hoc: [1910, 920],
  tai_khoan_hv: [530, 1085],
  tai_khoan_gs: [990, 1085],
  diem_danh: [1450, 1055],
  giao_dich: [530, 1470],
  danh_gia: [990, 1470],
  thong_bao: [1450, 1430],
  audit_log: [1910, 1325],
};

let fallbackIndex = 0;
for (const table of parsed.tables) {
  if (positionByTable[table.name]) continue;

  const col = fallbackIndex % 5;
  const row = Math.floor(fallbackIndex / 5);
  positionByTable[table.name] = [70 + col * 460, 120 + row * 420];
  fallbackIndex += 1;
}

function boxHeight(table) {
  return headerHeight + padding + table.columns.length * rowHeight + padding;
}

function escapeXml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function getBounds(tableName) {
  const table = tableByName.get(tableName);
  const [x, y] = positionByTable[tableName];
  return { x, y, w: boxWidth, h: boxHeight(table) };
}

function sidePoint(fromName, toName) {
  const from = getBounds(fromName);
  const to = getBounds(toName);
  const fromCenter = { x: from.x + from.w / 2, y: from.y + from.h / 2 };
  const toCenter = { x: to.x + to.w / 2, y: to.y + to.h / 2 };
  const dx = toCenter.x - fromCenter.x;
  const dy = toCenter.y - fromCenter.y;

  if (Math.abs(dx) > Math.abs(dy)) {
    return {
      x: dx > 0 ? from.x + from.w : from.x,
      y: fromCenter.y,
      side: dx > 0 ? "right" : "left",
    };
  }

  return {
    x: fromCenter.x,
    y: dy > 0 ? from.y + from.h : from.y,
    side: dy > 0 ? "bottom" : "top",
  };
}

function makePath(parentTable, childTable, index) {
  const start = sidePoint(parentTable, childTable);
  const end = sidePoint(childTable, parentTable);
  const offset = ((index % 5) - 2) * 10;
  const horizontal = start.side === "left" || start.side === "right";

  let d;
  if (horizontal) {
    const midX = (start.x + end.x) / 2 + offset;
    d = `M ${start.x} ${start.y} L ${midX} ${start.y} L ${midX} ${end.y} L ${end.x} ${end.y}`;
  } else {
    const midY = (start.y + end.y) / 2 + offset;
    d = `M ${start.x} ${start.y} L ${start.x} ${midY} L ${end.x} ${midY} L ${end.x} ${end.y}`;
  }

  return { d, start, end };
}

function badge(text, x, y, fill, stroke) {
  return `
    <rect x="${x}" y="${y - 13}" width="${Math.max(28, text.length * 7 + 12)}" height="17" rx="4" fill="${fill}" stroke="${stroke}" />
    <text x="${x + 6}" y="${y}" class="badge">${escapeXml(text)}</text>`;
}

function renderTable(table) {
  const [x, y] = positionByTable[table.name];
  const height = boxHeight(table);
  const rows = [];

  rows.push(`
    <g class="entity" id="entity-${table.name}">
      <rect class="entity-box" x="${x}" y="${y}" width="${boxWidth}" height="${height}" rx="8"/>
      <rect class="entity-head" x="${x}" y="${y}" width="${boxWidth}" height="${headerHeight}" rx="8"/>
      <path class="entity-head-fix" d="M ${x} ${y + headerHeight - 8} H ${x + boxWidth} V ${y + headerHeight} H ${x} Z"/>
      <text class="entity-title" x="${x + 16}" y="${y + 31}">${escapeXml(table.name)}</text>`);

  table.columns.forEach((column, index) => {
    const rowY = y + headerHeight + padding + index * rowHeight + 16;
    const badges = [];
    let badgeX = x + 14;
    if (table.pk.includes(column.name)) {
      badges.push(badge("PK", badgeX, rowY, "#fef3c7", "#d97706"));
      badgeX += 34;
    }
    if (column.foreign) {
      badges.push(badge("FK", badgeX, rowY, "#dbeafe", "#2563eb"));
      badgeX += 34;
    }
    if (column.unique || table.uniques.some((columns) => columns.length === 1 && columns[0] === column.name)) {
      badges.push(badge("UQ", badgeX, rowY, "#dcfce7", "#16a34a"));
      badgeX += 34;
    }

    const nameX = badgeX + 2;
    rows.push(`
      <g class="column-row">
        ${badges.join("")}
        <text class="column-name" x="${nameX}" y="${rowY}">${escapeXml(column.name)}</text>
        <text class="column-type" x="${x + boxWidth - 14}" y="${rowY}">${escapeXml(column.type)}</text>
      </g>`);
  });

  rows.push("</g>");
  return rows.join("");
}

function renderRelationships() {
  return parsed.relationships.map((relationship, index) => {
    if (!tableByName.has(relationship.parentTable) || !tableByName.has(relationship.childTable)) {
      return "";
    }

    const { d, start, end } = makePath(relationship.parentTable, relationship.childTable, index);
    const labelX = (start.x + end.x) / 2;
    const labelY = (start.y + end.y) / 2 - 8;
    const label = `${relationship.childColumns.join(", ")} -> ${relationship.parentColumns.join(", ")}`;

    return `
      <g class="relationship">
        <path d="${d}" />
        <text class="cardinality parent-card" x="${start.x}" y="${start.y - 8}">${parentCardinality(relationship)}</text>
        <text class="cardinality child-card" x="${end.x}" y="${end.y - 8}">${childCardinality(relationship)}</text>
        <text class="relationship-label" x="${labelX}" y="${labelY}">${escapeXml(label)}</text>
      </g>`;
  }).join("");
}

function renderSvg() {
  const width = 2360;
  const height = 1870;
  const entityCount = parsed.tables.length;
  const relationCount = parsed.relationships.length;

  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-labelledby="title desc">
  <title id="title">ERD Gia Su Bach Khoa</title>
  <desc id="desc">Entity relationship diagram generated from schema_gia_su_complete.sql.</desc>
  <defs>
    <filter id="shadow" x="-10%" y="-10%" width="120%" height="125%">
      <feDropShadow dx="0" dy="10" stdDeviation="9" flood-color="#0f172a" flood-opacity="0.12"/>
    </filter>
  </defs>
  <style>
    .canvas { fill: #f8fafc; }
    .title { font: 800 32px "Segoe UI", Arial, sans-serif; fill: #111827; letter-spacing: 0; }
    .subtitle { font: 500 16px "Segoe UI", Arial, sans-serif; fill: #475569; }
    .legend-title { font: 700 14px "Segoe UI", Arial, sans-serif; fill: #334155; }
    .legend-text { font: 500 13px "Segoe UI", Arial, sans-serif; fill: #475569; }
    .entity-box { fill: #ffffff; stroke: #cbd5e1; stroke-width: 1.3; filter: url(#shadow); }
    .entity-head { fill: #1f2937; }
    .entity-head-fix { fill: #1f2937; }
    .entity-title { font: 800 18px "Segoe UI", Arial, sans-serif; fill: #ffffff; letter-spacing: 0; }
    .column-name { font: 600 13px Consolas, "Courier New", monospace; fill: #0f172a; }
    .column-type { font: 500 12px Consolas, "Courier New", monospace; fill: #64748b; text-anchor: end; }
    .badge { font: 700 10px "Segoe UI", Arial, sans-serif; fill: #111827; }
    .relationship path { fill: none; stroke: #64748b; stroke-width: 1.5; opacity: 0.74; }
    .relationship-label { font: 500 10px Consolas, "Courier New", monospace; fill: #334155; text-anchor: middle; paint-order: stroke; stroke: #f8fafc; stroke-width: 5px; stroke-linejoin: round; }
    .cardinality { font: 800 12px "Segoe UI", Arial, sans-serif; fill: #be123c; paint-order: stroke; stroke: #f8fafc; stroke-width: 5px; stroke-linejoin: round; }
  </style>
  <rect class="canvas" x="0" y="0" width="${width}" height="${height}" />
  <text class="title" x="70" y="52">ERD Gia Su Bach Khoa</text>
  <text class="subtitle" x="70" y="80">Generated from schema_gia_su_complete.sql - ${entityCount} entities, ${relationCount} foreign-key relationships. Views, functions, triggers and procedures are intentionally excluded.</text>
  <g transform="translate(1775, 30)">
    <rect x="0" y="0" width="515" height="66" rx="8" fill="#ffffff" stroke="#cbd5e1"/>
    <text class="legend-title" x="16" y="25">Legend</text>
    ${badge("PK", 78, 24, "#fef3c7", "#d97706")}
    <text class="legend-text" x="118" y="24">Primary key</text>
    ${badge("FK", 220, 24, "#dbeafe", "#2563eb")}
    <text class="legend-text" x="260" y="24">Foreign key</text>
    ${badge("UQ", 365, 24, "#dcfce7", "#16a34a")}
    <text class="legend-text" x="405" y="24">Unique</text>
    <text class="legend-text" x="16" y="50">Cardinality labels: parent side = 1, child side = 0..N or 0..1.</text>
  </g>
  <g class="relationships">
    ${renderRelationships()}
  </g>
  <g class="entities">
    ${parsed.tables.map(renderTable).join("")}
  </g>
</svg>
`;
}

function mermaidType(type) {
  return type
    .replace(/\s+/g, "_")
    .replace(/[(),]/g, "_")
    .replace(/_+/g, "_")
    .replace(/^_|_$/g, "")
    || "value";
}

function renderMermaid() {
  const lines = ["erDiagram"];
  for (const table of parsed.tables) {
    lines.push(`  ${table.name} {`);
    for (const column of table.columns) {
      const tags = [];
      if (table.pk.includes(column.name)) tags.push("PK");
      if (column.foreign) tags.push("FK");
      if (column.unique || table.uniques.some((columns) => columns.length === 1 && columns[0] === column.name)) tags.push("UQ");
      lines.push(`    ${mermaidType(column.type)} ${column.name}${tags.length ? ` "${tags.join(",")}"` : ""}`);
    }
    lines.push("  }");
  }

  for (const relationship of parsed.relationships) {
    const parentEnd = fkIsRequired(relationship) ? "||" : "o|";
    const childEnd = fkIsUnique(relationship) ? "o|" : "o{";
    lines.push(`  ${relationship.parentTable} ${parentEnd}--${childEnd} ${relationship.childTable} : "${relationship.childColumns.join("_")}"`);
  }

  return `${lines.join("\n")}\n`;
}

const svg = renderSvg();
const html = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>ERD Gia Su Bach Khoa</title>
  <style>
    body { margin: 0; background: #e2e8f0; }
    .wrap { min-width: 2360px; }
    svg { display: block; }
  </style>
</head>
<body>
  <div class="wrap">
${svg.replace(/^<\?xml[^>]+>\n/, "")}
  </div>
</body>
</html>
`;

fs.writeFileSync(outSvg, svg, "utf8");
fs.writeFileSync(outHtml, html, "utf8");
fs.writeFileSync(outMmd, renderMermaid(), "utf8");

console.log(`Wrote ${outSvg}`);
console.log(`Wrote ${outHtml}`);
console.log(`Wrote ${outMmd}`);
