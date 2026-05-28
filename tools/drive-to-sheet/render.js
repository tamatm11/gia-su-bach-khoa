// Stage 3: Render Google Sheet từ trees/<id>.json + schemas/<id>.json
//
// CLI:
//   node render.js --teacher <folderId>            # đọc cache tree+schema
//   node render.js --teacher <folderId> --dry-run  # không ghi
//   node render.js --teacher <folderId> --max-videos 12
//   node render.js --teacher <folderId> --all-files
//
// Yêu cầu: chạy crawl.js trước, và có schemas/<id>.json (em sinh bằng tay).

const fs = require('fs');
const path = require('path');
const { getClients } = require('./auth');
const { listChildren } = require('./drive');
const { shortenTabName, ensureTab, writeValues } = require('./sheet');
const { loadCachedTree } = require('./crawl');
const { loadCachedSchema } = require('./infer-schema');

const SHEET_MIME = 'application/vnd.google-apps.spreadsheet';
const FOLDER_MIME = 'application/vnd.google-apps.folder';
const DEFAULT_MAX_VIDEOS = 8;
const VIDEO_MIME_PREFIX = 'video/';

function parseArgs(argv) {
  const out = { dryRun: false, maxVideos: DEFAULT_MAX_VIDEOS, allFiles: false };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--teacher' || a === '-t') out.teacherFolder = argv[++i];
    else if (a === '--sheet' || a === '-s') out.spreadsheetId = argv[++i];
    else if (a === '--dry-run') out.dryRun = true;
    else if (a === '--max-videos') out.maxVideos = parseInt(argv[++i], 10);
    else if (a === '--all-files') out.allFiles = true;
    else if (a === '--prefix') out.prefix = argv[++i];
  }
  return out;
}

function urlFolder(id) { return `https://drive.google.com/drive/folders/${id}`; }
function urlFile(id) { return `https://drive.google.com/file/d/${id}/view`; }
function hyperlink(url, label) {
  const safeLabel = String(label || '').replace(/"/g, '""');
  // Locale Vietnam dùng dấu `;` làm separator trong công thức Sheets
  return `=HYPERLINK("${url}";"${safeLabel}")`;
}

// Rút gọn tên khóa thành "Khóa <CODE>" để làm tên tab.
// Pattern: "X. KHO[ÁA] TDMXX 2027 ..." → "Khóa TDMXX"
// Fallback nếu không match: dùng shortenTabName tiêu chuẩn.
function shortCourseLabel(name) {
  const cleaned = String(name || '').replace(/\s+/g, ' ').trim();
  const m = /KHO[ÁA]\s+([A-Z]{2,6}\d?)/i.exec(cleaned);
  if (m) return `Khóa ${m[1].toUpperCase()}`;
  // Các khóa không phải KHOÁ (vd "INFO THÔNG TIN", "EBOOK") → lấy 2-3 từ đầu sau số thứ tự
  const noPrefix = cleaned.replace(/^[\dZ]+\.\s*/i, '');
  const words = noPrefix.split(' ').slice(0, 3).join(' ');
  return words;
}
function isVideo(file) {
  return file && file.mimeType && file.mimeType.startsWith(VIDEO_MIME_PREFIX);
}
function pickMediaFiles(files, allFiles) {
  if (allFiles) return files.slice().sort((a, b) => a.name.localeCompare(b.name, 'vi'));
  return files.filter(isVideo).sort((a, b) => a.name.localeCompare(b.name, 'vi'));
}

// Phân loại 1 file theo pattern tên (đặc thù sheet thầy Ái và tương tự):
//   BG (Bài giảng video): "Bg01.*.mp4"
//   CHUA (Chữa đề video): "Chữa ĐTL/đề ... .mp4", "Live_Chữa"
//   DE (Đề tự luyện PDF): "ĐỀ TDMXX...A.pdf" / "ĐỀ ... .pdf"
//   KEY (Đáp án PDF): "KEY ĐỀ ... .pdf"
//   BVT (BVT_LIVE PDF / bảng viết tay): "BVT_LIVE_*.pdf" / "BVT_*.pdf"
//   FCD/FGC (File chinh dung / Final guide cốt lõi): "*_FCD_*.pdf", "*_FGC_*.pdf"
// Trả về { kind, part } với part ∈ {A, B, ''} suy từ tên file/ folder cha.
function classifyFile(file, parentFolderName) {
  const name = file.name || '';
  const upper = name.toUpperCase();
  const partFromParent = /(?:PHẦN|ĐỀ)\s*([AB])/i.exec(parentFolderName || '');
  const partFromName = /PHẦN[\s_]*([AB])|[_\s]([AB])(?:[._\s]|$)/i.exec(upper.replace(/.PDF|.MP4/i, ''));
  const part = (partFromParent && partFromParent[1]) || (partFromName && (partFromName[1] || partFromName[2])) || '';

  if (isVideo(file)) {
    if (/CH[ỮU]A|LIVE.*CH[ỮU]A/i.test(name)) return { kind: 'CHUA', part };
    return { kind: 'BG', part };
  }
  if (/^KEY\s/i.test(name) || /^KEY\b/i.test(upper)) return { kind: 'KEY', part };
  if (/^BVT_LIVE/i.test(name) || /^BVT_/i.test(name)) return { kind: 'BVT', part };
  if (/^ĐỀ\s/i.test(name) || /^DE\s/i.test(name) || /^ĐỀ$/i.test(name)) return { kind: 'DE', part };
  if (/_FCD_|_FGC_/i.test(name)) return { kind: 'GUIDE', part: '' };
  return { kind: 'OTHER', part: '' };
}

// Thu thập tất cả file trong subtree (descendant của lessonNode), nhóm theo kind.
function collectLessonAssets(node) {
  const buckets = { BG: [], CHUA: [], DE: [], KEY: [], BVT: [], GUIDE: [], OTHER: [] };
  let latest = node.modifiedTime || '';
  function visit(n, parentName) {
    if ((n.modifiedTime || '') > latest) latest = n.modifiedTime;
    for (const f of n.files || []) {
      if ((f.modifiedTime || '') > latest) latest = f.modifiedTime;
      const cls = classifyFile(f, parentName);
      (buckets[cls.kind] || buckets.OTHER).push({ file: f, part: cls.part });
    }
    for (const c of n.children || []) visit(c, n.name);
  }
  visit(node, node.name);
  return { buckets, latest };
}

// Sinh badge text gọn: "🎬 2 • 📝 A,B • 🔑 A,B • ✏️ Chữa • 📘 Guide"
function makeBadgeText(buckets) {
  const parts = [];
  if (buckets.BG.length) parts.push(`🎬 ${buckets.BG.length}`);
  if (buckets.CHUA.length) {
    const tags = [...new Set(buckets.CHUA.map((x) => x.part).filter(Boolean))].sort();
    parts.push(`✏️ Chữa${tags.length ? ' ' + tags.join(',') : ''}`);
  }
  if (buckets.DE.length) {
    const tags = [...new Set(buckets.DE.map((x) => x.part).filter(Boolean))].sort();
    parts.push(`📝 Đề${tags.length ? ' ' + tags.join(',') : ''}`);
  }
  if (buckets.KEY.length) {
    const tags = [...new Set(buckets.KEY.map((x) => x.part).filter(Boolean))].sort();
    parts.push(`🔑 Key${tags.length ? ' ' + tags.join(',') : ''}`);
  }
  if (buckets.BVT.length) parts.push(`📋 BVT ${buckets.BVT.length}`);
  if (buckets.GUIDE.length) parts.push(`📘 Guide`);
  if (buckets.OTHER.length) parts.push(`📎 ${buckets.OTHER.length}`);
  return parts.join('  •  ');
}

function hexToRgb(hex) {
  const m = /^#?([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i.exec(hex || '');
  if (!m) return { red: 1, green: 1, blue: 1 };
  return {
    red: parseInt(m[1], 16) / 255,
    green: parseInt(m[2], 16) / 255,
    blue: parseInt(m[3], 16) / 255,
  };
}

async function findTeacherSpreadsheet(drive, teacherFolderId) {
  const kids = await listChildren(drive, teacherFolderId);
  const sheets = kids.filter((k) => k.mimeType === SHEET_MIME);
  if (sheets.length === 0) return null;
  sheets.sort((a, b) => (b.modifiedTime || '').localeCompare(a.modifiedTime || ''));
  return sheets[0];
}

// schema: { levels: [{ depth, label, icon, bold, bg }], leafFallback?, courseRow?, ... }
function buildCourseTab(course, schema, opts) {
  const { maxVideos, allFiles } = opts;

  const header = ['STT', 'Tên', 'Tài nguyên', 'Cập nhật', 'Link'];
  const NCOL = header.length;

  const rows = [header];
  const styles = { courseRow: -1, levelRows: {}, videoRows: [], moreRows: [] };

  const courseStyle = schema.courseRow || { icon: '📚', bold: true, fontSize: 12, bg: '#D4E5FA' };

  styles.courseRow = rows.length;
  rows.push(['', `${courseStyle.icon || '📚'} ${course.name}`, '', '', hyperlink(urlFolder(course.id), 'Mở folder khóa')]);
  rows.push(new Array(NCOL).fill(''));

  const counters = {};
  let totalLeaves = 0;
  let totalVideos = 0;

  function getLevelCfg(depth) {
    const levels = schema.levels || [];
    if (depth < levels.length) return levels[depth];
    // Quá sâu so với schema → fallback level cuối
    return levels[levels.length - 1] || { icon: '📁', bold: false, bg: '#F2F2F2' };
  }

  // Xác định 1 node có phải "lesson" (Bài học cấp 2) — depth 1 trong schema thầy Ái
  // Heuristic: tên match "TDMXX01_..." hoặc các pattern code bài học khác.
  function isLessonNode(node, depth) {
    if (depth !== 1) return false;
    return /^TDM[A-Z]{2}\d/i.test(node.name || '') || /^[A-Z]{3,6}\d/i.test(node.name || '');
  }

  function emit(node, depth) {
    const isLeaf = node.children.length === 0;
    const cfg = isLeaf && schema.leafFallback && depth < (schema.levels || []).length - 1
      ? schema.leafFallback
      : getLevelCfg(depth);
    const indent = '   '.repeat(depth);
    counters[depth] = (counters[depth] || 0) + 1;

    const stt = depth === 0 ? counters[0] : '';
    const label = `${indent}${cfg.icon || ''} ${node.name}`;

    // Với node Bài (depth=1) hoặc leaf bất kỳ, tính badge tài nguyên + ngày update mới nhất
    let badge = '';
    let updatedStr = `'${(node.modifiedTime || '').slice(0, 10)}`;
    let link = hyperlink(node.webViewLink || urlFolder(node.id), 'Mở folder');

    const isLesson = isLessonNode(node, depth) || (depth >= 1 && isLeaf);
    if (isLesson) {
      const { buckets, latest } = collectLessonAssets(node);
      badge = makeBadgeText(buckets);
      if (latest) updatedStr = `'${latest.slice(0, 10)}`;
      totalLeaves++;
      totalVideos += buckets.BG.length + buckets.CHUA.length;
    }

    (styles.levelRows[depth] = styles.levelRows[depth] || []).push({ row: rows.length, cfg });
    rows.push([stt, label, badge, updatedStr, link]);

    // Không recurse vào con của lesson node — badge đã tổng hợp xong.
    // Vẫn recurse với non-lesson container (depth=0 Chuyên đề).
    if (!isLeaf && !isLesson) {
      counters[depth + 1] = 0;
      for (const child of node.children) emit(child, depth + 1);
    }

    if (depth === 0) rows.push(new Array(NCOL).fill(''));
  }

  for (const top of course.children) emit(top, 0);

  if (course.children.length === 0) {
    rows.push(['', '(Trống — chưa có bài học bên trong)', '', '', '']);
  }

  return { header, rows, leafCount: totalLeaves, totalVideos, NCOL, styles, courseStyle };
}

async function applyTabFormatting(sheets, spreadsheetId, sheetId, built) {
  const reqs = [];
  const { styles, NCOL, rows, courseStyle } = built;

  // Header
  reqs.push({
    repeatCell: {
      range: { sheetId, startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: NCOL },
      cell: {
        userEnteredFormat: {
          backgroundColor: { red: 0.18, green: 0.46, blue: 0.71 },
          textFormat: { foregroundColor: { red: 1, green: 1, blue: 1 }, bold: true },
          horizontalAlignment: 'CENTER',
          verticalAlignment: 'MIDDLE',
        },
      },
      fields: 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment,verticalAlignment)',
    },
  });
  reqs.push({
    updateSheetProperties: {
      properties: { sheetId, gridProperties: { frozenRowCount: 1 } },
      fields: 'gridProperties.frozenRowCount',
    },
  });

  // Course row
  if (styles.courseRow >= 0) {
    reqs.push({
      repeatCell: {
        range: { sheetId, startRowIndex: styles.courseRow, endRowIndex: styles.courseRow + 1, startColumnIndex: 0, endColumnIndex: NCOL },
        cell: {
          userEnteredFormat: {
            backgroundColor: hexToRgb(courseStyle.bg || '#D4E5FA'),
            textFormat: { bold: !!courseStyle.bold, fontSize: courseStyle.fontSize || 12 },
          },
        },
        fields: 'userEnteredFormat(backgroundColor,textFormat)',
      },
    });
  }

  // Level rows — đọc từ schema config
  for (const [depthStr, items] of Object.entries(styles.levelRows || {})) {
    for (const { row, cfg } of items) {
      reqs.push({
        repeatCell: {
          range: { sheetId, startRowIndex: row, endRowIndex: row + 1, startColumnIndex: 0, endColumnIndex: NCOL },
          cell: {
            userEnteredFormat: {
              backgroundColor: hexToRgb(cfg.bg || '#FFFFFF'),
              textFormat: { bold: !!cfg.bold },
            },
          },
          fields: 'userEnteredFormat(backgroundColor,textFormat)',
        },
      });
    }
  }

  // Wrap + col widths + date column
  reqs.push({
    repeatCell: {
      range: { sheetId, startRowIndex: 1, endRowIndex: rows.length, startColumnIndex: 1, endColumnIndex: 3 },
      cell: { userEnteredFormat: { wrapStrategy: 'WRAP', verticalAlignment: 'MIDDLE' } },
      fields: 'userEnteredFormat(wrapStrategy,verticalAlignment)',
    },
  });
  reqs.push({
    updateDimensionProperties: {
      range: { sheetId, dimension: 'COLUMNS', startIndex: 0, endIndex: 1 },
      properties: { pixelSize: 50 },
      fields: 'pixelSize',
    },
  });
  reqs.push({
    updateDimensionProperties: {
      range: { sheetId, dimension: 'COLUMNS', startIndex: 1, endIndex: 2 },
      properties: { pixelSize: 520 },
      fields: 'pixelSize',
    },
  });
  reqs.push({
    updateDimensionProperties: {
      range: { sheetId, dimension: 'COLUMNS', startIndex: 2, endIndex: 3 },
      properties: { pixelSize: 280 },
      fields: 'pixelSize',
    },
  });
  reqs.push({
    updateDimensionProperties: {
      range: { sheetId, dimension: 'COLUMNS', startIndex: 3, endIndex: 5 },
      properties: { pixelSize: 110 },
      fields: 'pixelSize',
    },
  });
  reqs.push({
    repeatCell: {
      range: { sheetId, startRowIndex: 1, endRowIndex: rows.length, startColumnIndex: 3, endColumnIndex: 4 },
      cell: { userEnteredFormat: { numberFormat: { type: 'DATE', pattern: 'yyyy-mm-dd' }, horizontalAlignment: 'CENTER' } },
      fields: 'userEnteredFormat(numberFormat,horizontalAlignment)',
    },
  });

  // Batch theo cụm để tránh request quá to
  const CHUNK = 60;
  for (let i = 0; i < reqs.length; i += CHUNK) {
    await sheets.spreadsheets.batchUpdate({
      spreadsheetId,
      requestBody: { requests: reqs.slice(i, i + CHUNK) },
    });
  }
}

function buildIndexRows(courseSummaries, teacherName, teacherFolderId, schema) {
  const header = ['STT', 'Khóa học (folder cấp 3)', 'Tab', 'Số bài', 'Số video', 'Link folder'];
  const rows = [
    [`TỔNG HỢP DANH SÁCH BÀI HỌC – ${teacherName}`, '', '', '', '', ''],
    [`Folder gốc giáo viên:`, hyperlink(urlFolder(teacherFolderId), 'Mở folder gốc'), '', '', '', ''],
    [`Cập nhật:`, new Date().toISOString().slice(0, 19).replace('T', ' '), '', '', '', ''],
    [`Schema:`, (schema && schema.notes) || '', '', '', '', ''],
    [],
    header,
  ];
  courseSummaries.forEach((c, i) => {
    rows.push([
      i + 1,
      c.courseName,
      c.tabName,
      c.leafCount,
      c.totalVideos,
      hyperlink(urlFolder(c.courseId), 'Mở folder khóa'),
    ]);
  });
  return rows;
}

async function main() {
  const args = parseArgs(process.argv);
  if (!args.teacherFolder) {
    console.error('Thiếu --teacher <folderId>');
    process.exit(1);
  }
  const prefix = args.prefix || '';

  const cachedTree = loadCachedTree(args.teacherFolder);
  if (!cachedTree) {
    console.error(`Chưa có tree cache. Chạy trước: node crawl.js --teacher ${args.teacherFolder}`);
    process.exit(1);
  }
  const schemaPayload = loadCachedSchema(args.teacherFolder);
  if (!schemaPayload) {
    console.error(`Chưa có schema. Nhờ Claude session sinh schemas/${args.teacherFolder}.json trước.`);
    process.exit(1);
  }
  const schema = schemaPayload.schema;

  const { drive, sheets } = getClients();
  const teacherName = cachedTree.teacher.name;
  console.log(`Giáo viên: ${teacherName}`);
  console.log(`Tree crawled: ${cachedTree.crawledAt}`);
  console.log(`Schema updated: ${schemaPayload.updatedAt}`);

  let spreadsheetId = args.spreadsheetId;
  if (!spreadsheetId) {
    const ss = await findTeacherSpreadsheet(drive, args.teacherFolder);
    if (!ss) throw new Error('Không tìm thấy spreadsheet trong folder giáo viên. Truyền --sheet <id>.');
    spreadsheetId = ss.id;
    console.log(`Sheet đích: ${ss.name}`);
    console.log(`  https://docs.google.com/spreadsheets/d/${ss.id}/edit`);
  }

  const courses = cachedTree.courses;
  console.log(`Phát hiện ${courses.length} khóa (mỗi khóa = 1 tab)`);

  // Dọn tab cũ với prefix BÀI HỌC
  const oldPrefixes = ['BÀI HỌC - '];
  if (!args.dryRun) {
    const meta = await sheets.spreadsheets.get({ spreadsheetId });
    const toDelete = (meta.data.sheets || [])
      .filter((s) => oldPrefixes.some((p) => s.properties.title.startsWith(p)))
      .map((s) => s.properties.sheetId);
    if (toDelete.length) {
      console.log(`  Dọn ${toDelete.length} tab cũ`);
      await sheets.spreadsheets.batchUpdate({
        spreadsheetId,
        requestBody: { requests: toDelete.map((id) => ({ deleteSheet: { sheetId: id } })) },
      });
    }
  }

  const summaries = [];
  for (let i = 0; i < courses.length; i++) {
    const c = courses[i];
    const tabName = shortenTabName(prefix + shortCourseLabel(c.name), 99);
    console.log(`\n  [${i + 1}/${courses.length}] ${c.name}`);
    console.log(`    Tab: '${tabName}'`);

    const built = buildCourseTab(c, schema, { maxVideos: args.maxVideos, allFiles: !!args.allFiles });
    console.log(`    ${built.leafCount} bài, ${built.totalVideos} video`);

    if (args.dryRun) {
      console.log('    [DRY-RUN] không ghi');
    } else {
      const sheetId = await ensureTab(sheets, spreadsheetId, tabName);
      await writeValues(sheets, spreadsheetId, tabName, built.rows);
      await applyTabFormatting(sheets, spreadsheetId, sheetId, built);
      console.log('    ✓ Đã ghi tab');
    }

    summaries.push({
      courseId: c.id,
      courseName: c.name,
      tabName,
      leafCount: built.leafCount,
      totalVideos: built.totalVideos,
    });
  }

  const indexTab = '📚 INDEX BÀI HỌC';
  console.log(`\nCập nhật tab tổng hợp: '${indexTab}'`);
  if (!args.dryRun) {
    const idxId = await ensureTab(sheets, spreadsheetId, indexTab);
    const idxRows = buildIndexRows(summaries, teacherName, args.teacherFolder, schema);
    await writeValues(sheets, spreadsheetId, indexTab, idxRows);
    await sheets.spreadsheets.batchUpdate({
      spreadsheetId,
      requestBody: {
        requests: [
          {
            repeatCell: {
              range: { sheetId: idxId, startRowIndex: 5, endRowIndex: 6, startColumnIndex: 0, endColumnIndex: 6 },
              cell: {
                userEnteredFormat: {
                  backgroundColor: { red: 0.18, green: 0.46, blue: 0.71 },
                  textFormat: { foregroundColor: { red: 1, green: 1, blue: 1 }, bold: true },
                  horizontalAlignment: 'CENTER',
                },
              },
              fields: 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)',
            },
          },
          { autoResizeDimensions: { dimensions: { sheetId: idxId, dimension: 'COLUMNS', startIndex: 0, endIndex: 6 } } },
        ],
      },
    });
  }

  console.log('\n✓ Hoàn tất.');
  console.log(`  Sheet: https://docs.google.com/spreadsheets/d/${spreadsheetId}/edit`);
  console.log(`  Tổng: ${summaries.reduce((s, c) => s + c.totalVideos, 0)} video / ${summaries.reduce((s, c) => s + c.leafCount, 0)} bài`);
}

if (require.main === module) {
  main().catch((e) => {
    console.error('LỖI:', e.message);
    if (e.response && e.response.data) console.error(JSON.stringify(e.response.data, null, 2));
    process.exit(1);
  });
}

module.exports = { buildCourseTab, applyTabFormatting };
