# Drive → Sheet (Danh sách bài học)

Script đọc đệ quy folder Drive của 1 giáo viên, tự phát hiện cấu trúc (Khóa → Chương → Bài → Tiết, độ sâu tùy giáo viên) và sinh các tab "BÀI HỌC - ..." trong chính spreadsheet của giáo viên đó.

## Yêu cầu

- Node.js ≥ 18 (đã test trên v25)
- File `credentials.json` (OAuth client) và `token.json` (đã có refresh_token, scope: drive + spreadsheets).
- Mặc định đọc từ `C:/Users/giaos/.claude/credentials.json` và `C:/Users/giaos/.claude/token.json` — đổi bằng biến môi trường `GDRIVE_CREDENTIALS`, `GDRIVE_TOKEN` nếu cần.

## Chạy

```
cd "C:/Web gia sư/tools/drive-to-sheet"
node index.js --teacher <FOLDER_ID_GIÁO_VIÊN>           # thật
node index.js --teacher <FOLDER_ID_GIÁO_VIÊN> --dry-run # thử, không ghi
node index.js --teacher <ID> --sheet <SPREADSHEET_ID>   # ép spreadsheet đích
node index.js --teacher <ID> --prefix "BÀI - "          # đổi tiền tố tab
```

## Hành vi

1. Lấy spreadsheet đích = spreadsheet được sửa gần nhất trong folder giáo viên (hoặc `--sheet`).
2. Liệt kê folder con cấp 1 của giáo viên = "các khóa học".
3. Với mỗi khóa: walk đệ quy → flatten đến folder "lá" (không còn folder con) = 1 bài/tiết.
4. Tạo (hoặc clear-rewrite) tab tên `BÀI HỌC - <Tên khóa rút gọn>`. Số cột "Cấp N" co giãn theo độ sâu thực tế của khóa đó.
5. Tạo tab `BÀI HỌC - INDEX` tổng hợp: số bài, độ sâu, link folder của từng khóa.
6. Không đụng tab gốc (`HOME`, `EBOOK`, `TKB`, ...).

## Schema mỗi tab khóa học

| STT | Cấp 1 | Cấp 2 | ... | Số mục bên trong | Cập nhật | Link Drive |

- `Số mục bên trong`: số file (PDF/video) trong folder lá.
- `Link Drive`: `=HYPERLINK(...)` mở folder lá.
- Hàng 1 cố định (freeze), header tô màu xanh.

## Ví dụ folder ID

- Root tổng: `1jzw1q9Chb9CQRdWXgu0qMP3jmMgmq8As`
- Thầy Chí (Toán): `1HgCgjlC0Y0UW7AK9DlYMI9DJIq8vxX7J`
- Cô Sương Mai (Văn): `1Nv_pXpXvHoZgVN8RhztDXZdxaECYgrRX`
- Cô Vũ Mai Phương (Anh): `1vz5GwySYJX7XYPH86EM8prQK3knoyTVn`

Chạy lại nhiều lần an toàn (idempotent — tab cùng tên sẽ bị clear rồi ghi lại).
