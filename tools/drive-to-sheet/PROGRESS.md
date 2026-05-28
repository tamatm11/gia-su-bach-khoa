# Tiến trình tool `drive-to-sheet`

## Pipeline đã chốt (3 stage)

1. **Stage 1 — `crawl.js`** (deterministic)
   - `node crawl.js --teacher <id>` → `trees/<id>.json`
   - `--force` để ép crawl lại, `--max-age 24h` để invalidate sau N giờ
2. **Stage 2 — Schema VIẾT TAY** (Claude session làm, không API)
   - Em đọc `trees/<id>.json` → phân tích pattern → Write `schemas/<id>.json`
   - File `infer-schema.js` có sẵn nhưng proxy freemodel chặn → giữ làm fallback
3. **Stage 3 — `render.js`**
   - `node render.js --teacher <id>` → đọc tree + schema → ghi spreadsheet TKB

## Đã DONE
- ✅ Thầy Chí (pipeline cũ hardcode) — sheet `1MYgFHes8oNTG8zNjpKaO-dlrU8IvTa_E6aFuc92Og4c`
- ✅ Thầy Ái TDM 2K9 — sheet `19W7flY2MrR-BDeqgpXRuCzL6HCV9nNQ126CvSqoKzbc`
  - 8 tab, 39 bài, 52 video
  - Schema 3 level: Chuyên đề (1.1, 1.2...) → Bài (TDMXX01_...) → Phần (Bài giảng/Phần A/B, Đề A/B)

## TODO
- 7 giáo viên Toán còn lại (Đức, Ngọc Huyền, Tiến, Mapstudy, Anh Giáo Kid, Shipper, Trịnh Đình Thành)
- Các môn khác (Văn, Anh, Lý, Hóa, Sinh, Sử, Địa, ĐGNL, Bonus)

## Cách thêm 1 giáo viên mới
```bash
cd "C:/Web gia sư/tools/drive-to-sheet"
node crawl.js --teacher <folderId>
# rồi nhờ Claude session: "infer schema cho thầy X"  → schemas/<id>.json
node render.js --teacher <folderId>
```

## Cập nhật khi Drive có khóa mới
```bash
node crawl.js --teacher <folderId> --force   # crawl lại
# (tùy chọn) nhờ Claude review schema cũ vs cấu trúc mới, sửa nếu cần
node render.js --teacher <folderId>          # ghi lại sheet
```

## File structure
- `auth.js` — OAuth Drive + Sheets
- `drive.js` — listChildren, walk, isVideo
- `sheet.js` — ensureTab, writeValues, shortenTabName
- `crawl.js` — Stage 1: crawl Drive → trees/<id>.json
- `infer-schema.js` — Stage 2 (không dùng): gọi Anthropic API qua proxy
- `render.js` — Stage 3: render sheet từ tree + schema
- `index.js` — pipeline cũ hardcode (giữ cho thầy Chí, deprecate dần)
- `trees/` — cache crawl (gitignored)
- `schemas/` — schema viết tay (gitignored)
