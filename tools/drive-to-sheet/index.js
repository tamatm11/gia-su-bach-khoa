const { getClients } = require('./auth');
const { listChildren, walk, FOLDER_MIME, isVideo } = require('./drive');
const { shortenTabName, ensureTab, writeValues } = require('./sheet');

const SHEET_MIME = 'application/vnd.google-apps.spreadsheet';
const TAB_PREFIX = process.env.TAB_PREFIX || '';
const DEFAULT_MAX_VIDEOS = 8;

function parseArgs(argv) {
  const out = { dryRun: false, maxVideos: DEFAULT_MAX_VIDEOS };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--teacher' || a === '-t') out.teacherFolder = argv[++i];
    else if (a === '--sheet' || a === '-s') out.spreadsheetId = argv[++i];
    else if (a === '--dry-run') out.dryRun = true;
    else if (a === '--prefix') out.prefix = argv[++i];
    else if (a === '--max-videos') out.maxVideos = parseInt(argv[++i], 10);
    else if (a === '--all-files') out.allFiles = true;
  }
  return out;
}

function urlFolder(id) { return `https://drive.google.com/drive/folders/${id}`; }
function urlFile(id) { return `https://drive.google.com/file/d/${id}/view`; }
function hyperlink(url, label) {
  const safeLabel = String(label || '').replace(/"/g, '""');
  return `=HYPERLINK("${url}","${safeLabel}")`;
}

async function findTeacherSpreadsheet(drive, teacherFolderId) {
  const kids = await listChildren(drive, teacherFolderId);
  const sheets = kids.filter((k) => k.mimeType === SHEET_MIME);
  if (sheets.length === 0) return null;
  sheets.sort((a, b) => (b.modifiedTime || '').localeCompare(a.modifiedTime || ''));
  return sheets[0];
}

async function discoverCourses(drive, teacherFolderId) {
  const kids = await listChildren(drive, teacherFolderId);
  return kids.filter((k) => k.mimeType === FOLDER_MIME);
}

function pickMediaFiles(files, allFiles) {
  if (allFiles) return files.slice().sort((a, b) => a.name.localeCompare(b.name, 'vi'));
  const vids = files.filter(isVideo);
  return vids.sort((a, b) => a.name.localeCompare(b.name, 'vi'));
}

function buildCourseTab(course, root, opts) {
  const { maxVideos, allFiles } = opts;

  const header = ['STT', 'Tên', 'Cập nhật', 'Link'];
  const NCOL = header.length;

  const rows = [header];
  const styles = { courseRow: -1, levelRows: {}, videoRows: [], moreRows: [] };

  styles.courseRow = rows.length;
  rows.push(['', `📚 ${course.name}`, '', hyperlink(urlFolder(course.id), 'Mở folder khóa')]);
  rows.push(new Array(NCOL).fill(''));

  const LEVEL_ICONS = ['📖', '📂', '📁', '📄'];
  const counters = {};
  let totalLeaves = 0;
  let totalVideos = 0;

  function emit(node, depth) {
    const isLeaf = node.children.length === 0;
    const icon = LEVEL_ICONS[Math.min(depth, LEVEL_ICONS.length - 1)];
    const indent = '   '.repeat(depth);
    counters[depth] = (counters[depth] || 0) + 1;

    const stt = depth === 0 ? counters[0] : '';
    const label = `${indent}${icon} ${node.name}`;
    const updated = `'${(node.modifiedTime || '').slice(0, 10)}`;
    const link = hyperlink(node.webViewLink || urlFolder(node.id), 'Mở folder');

    (styles.levelRows[depth] = styles.levelRows[depth] || []).push(rows.length);
    rows.push([stt, label, updated, link]);

    if (isLeaf) {
      totalLeaves++;
      const media = pickMediaFiles(node.files, allFiles);
      totalVideos += media.length;
      const videoIndent = '   '.repeat(depth + 1);
      const shown = media.slice(0, maxVideos);
      shown.forEach((f, idx) => {
        styles.videoRows.push(rows.length);
        rows.push([
          '',
          `${videoIndent}▸ ${idx + 1}.  ${f.name}`,
          `'${(f.modifiedTime || '').slice(0, 10)}`,
          hyperlink(f.webViewLink || urlFile(f.id), '▶ Xem'),
        ]);
      });
      if (media.length > maxVideos) {
        const remain = media.length - maxVideos;
        styles.moreRows.push(rows.length);
        rows.push([
          '',
          `${videoIndent}…  còn ${remain} ${allFiles ? 'tệp' : 'video'} nữa — mở folder để xem hết`,
          '',
          hyperlink(node.webViewLink || urlFolder(node.id), 'Mở folder'),
        ]);
      }
      if (media.length === 0 && node.files.length > 0) {
        styles.moreRows.push(rows.length);
        rows.push([
          '',
          `${videoIndent}⚠  (folder có ${node.files.length} tệp nhưng không phải video)`,
          '',
          '',
        ]);
      }
    } else {
      counters[depth + 1] = 0;
      for (const child of node.children) emit(child, depth + 1);
    }

    if (depth === 0) rows.push(new Array(NCOL).fill(''));
  }

  for (const top of root.children) emit(top, 0);

  if (root.children.length === 0) {
    rows.push(['', '(Trống — chưa có bài học bên trong)', '', '']);
  }

  return { header, rows, leafCount: totalLeaves, totalVideos, NCOL, styles };
}

function padRow(arr, n) {
  const out = arr.slice(0, n);
  while (out.length < n) out.push('');
  return out;
}

async function applyTabFormatting(sheets, spreadsheetId, sheetId, built) {
  const reqs = [];
  const { styles, NCOL, rows } = built;

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

  if (styles.courseRow >= 0) {
    reqs.push({
      repeatCell: {
        range: { sheetId, startRowIndex: styles.courseRow, endRowIndex: styles.courseRow + 1, startColumnIndex: 0, endColumnIndex: NCOL },
        cell: {
          userEnteredFormat: {
            backgroundColor: { red: 0.83, green: 0.90, blue: 0.97 },
            textFormat: { bold: true, fontSize: 12 },
          },
        },
        fields: 'userEnteredFormat(backgroundColor,textFormat)',
      },
    });
  }

  const LEVEL_BG = {
    0: { red: 0.99, green: 0.90, blue: 0.71 },
    1: { red: 0.99, green: 0.95, blue: 0.83 },
    2: { red: 0.95, green: 0.98, blue: 0.92 },
    3: { red: 0.97, green: 0.97, blue: 0.97 },
  };
  const LEVEL_BOLD = { 0: true, 1: true, 2: false, 3: false };
  for (const [depthStr, idxs] of Object.entries(styles.levelRows || {})) {
    const depth = Number(depthStr);
    const bg = LEVEL_BG[depth] || LEVEL_BG[3];
    const bold = !!LEVEL_BOLD[depth];
    for (const idx of idxs) {
      reqs.push({
        repeatCell: {
          range: { sheetId, startRowIndex: idx, endRowIndex: idx + 1, startColumnIndex: 0, endColumnIndex: NCOL },
          cell: {
            userEnteredFormat: {
              backgroundColor: bg,
              textFormat: { bold },
            },
          },
          fields: 'userEnteredFormat(backgroundColor,textFormat)',
        },
      });
    }
  }

  reqs.push({
    repeatCell: {
      range: { sheetId, startRowIndex: 1, endRowIndex: rows.length, startColumnIndex: 1, endColumnIndex: 2 },
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
      properties: { pixelSize: 720 },
      fields: 'pixelSize',
    },
  });
  reqs.push({
    updateDimensionProperties: {
      range: { sheetId, dimension: 'COLUMNS', startIndex: 2, endIndex: 4 },
      properties: { pixelSize: 110 },
      fields: 'pixelSize',
    },
  });
  reqs.push({
    repeatCell: {
      range: { sheetId, startRowIndex: 1, endRowIndex: rows.length, startColumnIndex: 2, endColumnIndex: 3 },
      cell: { userEnteredFormat: { numberFormat: { type: 'DATE', pattern: 'yyyy-mm-dd' }, horizontalAlignment: 'CENTER' } },
      fields: 'userEnteredFormat(numberFormat,horizontalAlignment)',
    },
  });

  await sheets.spreadsheets.batchUpdate({ spreadsheetId, requestBody: { requests: reqs } });
}

function buildIndexRows(courseSummaries, teacherName, teacherFolderId) {
  const header = ['STT', 'Khóa học (folder cấp 3)', 'Tab', 'Số bài', 'Số video', 'Link folder'];
  const rows = [
    [`TỔNG HỢP DANH SÁCH BÀI HỌC – ${teacherName}`, '', '', '', '', ''],
    [`Folder gốc giáo viên:`, hyperlink(urlFolder(teacherFolderId), 'Mở folder gốc'), '', '', '', ''],
    [`Cập nhật:`, new Date().toISOString().slice(0, 19).replace('T', ' '), '', '', '', ''],
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
  const prefix = (args.prefix !== undefined ? args.prefix : TAB_PREFIX);
  const { drive, sheets } = getClients();

  console.log('1. Đọc folder giáo viên...');
  const teacherMeta = await drive.files.get({ fileId: args.teacherFolder, fields: 'id, name' });
  const teacherName = teacherMeta.data.name;
  console.log(`   → ${teacherName}`);

  let spreadsheetId = args.spreadsheetId;
  if (!spreadsheetId) {
    const ss = await findTeacherSpreadsheet(drive, args.teacherFolder);
    if (!ss) throw new Error('Không tìm thấy spreadsheet trong folder giáo viên. Truyền --sheet <id>.');
    spreadsheetId = ss.id;
    console.log(`2. Spreadsheet đích: ${ss.name}`);
    console.log(`   https://docs.google.com/spreadsheets/d/${ss.id}/edit`);
  }

  const courses = await discoverCourses(drive, args.teacherFolder);
  console.log(`3. Phát hiện ${courses.length} folder cấp 3 (mỗi folder = 1 tab)`);

  const oldPrefixes = ['BÀI HỌC - '];
  if (!args.dryRun) {
    const meta = await sheets.spreadsheets.get({ spreadsheetId });
    const toDelete = (meta.data.sheets || [])
      .filter((s) => oldPrefixes.some((p) => s.properties.title.startsWith(p)))
      .map((s) => s.properties.sheetId);
    if (toDelete.length) {
      console.log(`   Dọn ${toDelete.length} tab cũ với prefix "BÀI HỌC - "`);
      await sheets.spreadsheets.batchUpdate({
        spreadsheetId,
        requestBody: { requests: toDelete.map((id) => ({ deleteSheet: { sheetId: id } })) },
      });
    }
  }

  const summaries = [];
  for (let i = 0; i < courses.length; i++) {
    const c = courses[i];
    const tabName = shortenTabName(prefix + c.name, 99);
    console.log(`\n  [${i + 1}/${courses.length}] ${c.name}`);
    console.log(`    Tab: '${tabName}'`);

    let root;
    try {
      root = await walk(drive, c.id, {
        onProgress: ({ folderCount }) => {
          if (folderCount % 25 === 0) process.stdout.write(`    ...crawled ${folderCount} folders\r`);
        },
      });
      root.name = c.name;
    } catch (e) {
      console.error(`    Lỗi crawl: ${e.message}`);
      continue;
    }

    const built = buildCourseTab(c, root, { maxVideos: args.maxVideos, allFiles: !!args.allFiles });
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
  console.log(`\n4. Cập nhật tab tổng hợp: '${indexTab}'`);
  if (!args.dryRun) {
    const idxId = await ensureTab(sheets, spreadsheetId, indexTab);
    const idxRows = buildIndexRows(summaries, teacherName, args.teacherFolder);
    await writeValues(sheets, spreadsheetId, indexTab, idxRows);
    await sheets.spreadsheets.batchUpdate({
      spreadsheetId,
      requestBody: {
        requests: [
          {
            repeatCell: {
              range: { sheetId: idxId, startRowIndex: 4, endRowIndex: 5, startColumnIndex: 0, endColumnIndex: 6 },
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

main().catch((e) => {
  console.error('LỖI:', e.message);
  if (e.response && e.response.data) console.error(JSON.stringify(e.response.data, null, 2));
  process.exit(1);
});
