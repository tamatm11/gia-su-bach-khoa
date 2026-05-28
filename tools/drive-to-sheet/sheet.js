function shortenTabName(raw, maxLen = 90) {
  let s = String(raw || '').replace(/\s+/g, ' ').trim();
  s = s.replace(/^\d+\.\s*/, '');
  s = s.replace(/[\\/?*\[\]]/g, '-');
  if (s.length > maxLen) s = s.slice(0, maxLen - 1) + '…';
  return s || 'TAB';
}

async function getSpreadsheet(sheets, spreadsheetId) {
  const res = await sheets.spreadsheets.get({ spreadsheetId, includeGridData: false });
  return res.data;
}

async function ensureTab(sheets, spreadsheetId, title) {
  const meta = await getSpreadsheet(sheets, spreadsheetId);
  const existing = (meta.sheets || []).find((s) => s.properties.title === title);
  if (existing) {
    const otherTabs = (meta.sheets || []).filter((s) => s.properties.title !== title);
    if (otherTabs.length === 0) {
      await sheets.spreadsheets.batchUpdate({
        spreadsheetId,
        requestBody: {
          requests: [
            { addSheet: { properties: { title: '__tmp_keep__' } } },
            { deleteSheet: { sheetId: existing.properties.sheetId } },
          ],
        },
      });
    } else {
      await sheets.spreadsheets.batchUpdate({
        spreadsheetId,
        requestBody: { requests: [{ deleteSheet: { sheetId: existing.properties.sheetId } }] },
      });
    }
  }
  const addRes = await sheets.spreadsheets.batchUpdate({
    spreadsheetId,
    requestBody: { requests: [{ addSheet: { properties: { title } } }] },
  });
  const newSheetId = addRes.data.replies[0].addSheet.properties.sheetId;
  const meta2 = await getSpreadsheet(sheets, spreadsheetId);
  const tmp = (meta2.sheets || []).find((s) => s.properties.title === '__tmp_keep__');
  if (tmp) {
    await sheets.spreadsheets.batchUpdate({
      spreadsheetId,
      requestBody: { requests: [{ deleteSheet: { sheetId: tmp.properties.sheetId } }] },
    });
  }
  return newSheetId;
}

async function writeValues(sheets, spreadsheetId, title, values) {
  await sheets.spreadsheets.values.update({
    spreadsheetId,
    range: `'${title}'!A1`,
    valueInputOption: 'USER_ENTERED',
    requestBody: { values },
  });
}

async function applyHeaderFormat(sheets, spreadsheetId, sheetId, headerColCount) {
  await sheets.spreadsheets.batchUpdate({
    spreadsheetId,
    requestBody: {
      requests: [
        {
          repeatCell: {
            range: { sheetId, startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: headerColCount },
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
        },
        {
          updateSheetProperties: {
            properties: { sheetId, gridProperties: { frozenRowCount: 1 } },
            fields: 'gridProperties.frozenRowCount',
          },
        },
        {
          autoResizeDimensions: {
            dimensions: { sheetId, dimension: 'COLUMNS', startIndex: 0, endIndex: headerColCount },
          },
        },
      ],
    },
  });
}

module.exports = { shortenTabName, getSpreadsheet, ensureTab, writeValues, applyHeaderFormat };
