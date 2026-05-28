# Giải Thích Toàn Bộ Code Dự Án Gia Sư

Tài liệu này giải thích theo đúng những gì đang có trong workspace `C:\Web gia sư`: database SQL, web-app Node/Express, view EJS, script seed, script vẽ diagram và tool phụ Drive -> Sheet.

## 1. Tổng Quan Kiến Trúc

Dự án có 4 nhóm chính:

1. `Nhom_12_QuanLyGiaSuHocVien.sql`: file schema chính. Đây là T-SQL kiểu SQL Server, có `use master`, `create database`, `go`, `create procedure`, trigger, view, function.
2. `demo_seed_10_lop_day_du.sql`: file seed demo 10 lớp, tạo dữ liệu mẫu đầy đủ từ học viên, gia sư, môn học, yêu cầu, ứng tuyển, lớp học, lịch học, buổi học, thanh toán, đánh giá.
3. `web-app/`: ứng dụng web Node.js dùng Express + EJS + Supabase client. Người dùng đăng ký, đăng nhập, đăng tin tìm gia sư, ứng tuyển, chọn gia sư, xem lớp, xem lịch, đánh giá, quản trị.
4. `tools/`: script sinh sơ đồ SQL và một tool riêng để đọc Google Drive của giáo viên rồi ghi danh sách bài học sang Google Sheet.

`temp_docx/` là thư mục bung nội dung của file Word, chủ yếu là artifact tài liệu, không phải code chạy chính.

## 2. Luồng Nghiệp Vụ Chính

Luồng chuẩn của hệ thống:

1. Học viên đăng ký tài khoản.
2. Học viên đăng yêu cầu tìm gia sư: tiêu đề, môn, học phí, địa chỉ, hình thức học, số buổi/tuần, khung giờ mong muốn.
3. Gia sư xem danh sách yêu cầu đang mở.
4. Gia sư ứng tuyển vào yêu cầu.
5. Học viên xem các ứng tuyển và chọn một gia sư.
6. Hệ thống cập nhật trạng thái ứng tuyển, gửi thông báo, tạo lớp học, tạo đăng ký, tạo lịch học.
7. Gia sư/học viên xem lớp học, lịch học, buổi học.
8. Sau khi học, hệ thống có điểm danh, thanh toán, đánh giá.
9. Admin xem dashboard, quản lý yêu cầu, lớp học, gia sư, học viên.

## 3. Database Chính: `Nhom_12_QuanLyGiaSuHocVien.sql`

File này tạo database `giasubachkhoa`. Nếu database đã tồn tại, script đưa DB về `single_user`, rollback kết nối hiện tại, drop DB rồi tạo lại. Sau đó bật `ansi_nulls` và `quoted_identifier`.

### 3.1. Nhóm Bảng Cốt Lõi

`hoc_vien`

Lưu hồ sơ học viên. Khóa chính là `ma_hoc_vien`. Các cột quan trọng gồm `ho_ten`, `ngay_sinh`, `gioi_tinh`, `so_dien_thoai`, `email`, `dia_chi`, `anh_dai_dien`, `khoi_hien_tai`, `auth_id`, `ngay_tao`, `ngay_cap_nhat`. `auth_id` dùng để nối hồ sơ học viên với tài khoản đăng nhập. Có check constraint cho `gioi_tinh`.

`gia_su`

Lưu hồ sơ gia sư. Khóa chính là `ma_gia_su`. Ngoài thông tin cá nhân giống học viên, gia sư có thêm `trinh_do`, `gioi_thieu`, `trong_lich`. `trong_lich = 1` nghĩa là gia sư đang nhận lớp/đang rảnh để ứng tuyển. Có `auth_id` để nối với tài khoản đăng nhập.

`mon_hoc`

Danh mục môn học. Khóa chính là `ma_mon`. Có `ten_mon`, `cap_hoc`, `mo_ta`. Bảng này là danh mục dùng lại cho yêu cầu lớp, lớp học và chuyên môn gia sư.

`gia_su_mon_hoc`

Bảng trung gian nhiều-nhiều giữa `gia_su` và `mon_hoc`. Một gia sư dạy được nhiều môn, một môn có nhiều gia sư. Khóa chính ghép là `(ma_gia_su, ma_mon)`. Có thêm `nam_kinh_nghiem`, `muc_do_thanh_thao`, `chung_chi`.

### 3.2. Nhóm Yêu Cầu Và Ứng Tuyển

`yeu_cau_lop`

Lưu tin/yêu cầu tìm gia sư do học viên đăng. Khóa chính là `ma_yeu_cau`. Nối tới học viên bằng `ma_hoc_vien`. Các dữ liệu chính: `tieu_de`, `mo_ta`, `tien_hoc_phi`, `dia_chi`, `hinh_thuc_hoc`, `so_buoi_tuan`, `thoi_gian_mong_muon`, `trang_thai`. Khi học viên chọn gia sư, bảng này lưu `ma_gia_su_duoc_chon` và `ngay_chon_gia_su`.

Trạng thái hợp lệ trong SQL: `open`, `closed`, `approved`, `cancelled`.

`yeu_cau_mon`

Các môn thuộc một yêu cầu lớp. Khóa chính ghép `(ma_yeu_cau, ma_mon)`. Nếu một yêu cầu cần nhiều môn, bảng này chứa từng môn. `vai_tro_mon` phân biệt môn chính/phụ.

`ung_tuyen`

Lưu việc gia sư ứng tuyển vào yêu cầu. Khóa chính là `ma_ung_tuyen`. Có `ma_yeu_cau`, `ma_gia_su`, `thu_nhap_mong_muon`, `loi_nhan`, `trang_thai`, `ngay_ung_tuyen`, `ngay_xu_ly`. Có unique `(ma_yeu_cau, ma_gia_su)` để một gia sư không ứng tuyển trùng vào cùng một yêu cầu.

Trạng thái hợp lệ: `pending`, `accepted`, `rejected`, `withdrawn`.

### 3.3. Nhóm Lớp Học Và Lịch Học

`lop_hoc`

Lưu lớp học chính thức sau khi học viên chọn gia sư. Khóa chính là `ma_lop`. Nối tới `gia_su`, `hoc_vien`, có thể nối tới `yeu_cau_lop` và `ung_tuyen`. Các cột chính: `hoc_phi`, `dia_chi`, `hinh_thuc_day`, `ngay_bat_dau`, `ngay_ket_thuc`, `trang_thai`, `tong_so_buoi`, `ngay_tao`.

Trạng thái hợp lệ trong SQL: `sapmo`, `dang_hoc`, `hoan_thanh`, `huy`.

`lop_hoc_mon`

Danh sách môn học được dạy trong một lớp. Khóa chính ghép `(ma_lop, ma_mon)`. Đây là bản sao từ `yeu_cau_mon` sang lớp học khi lớp chính thức được tạo.

`lich_hoc`

Lịch định kỳ theo tuần của lớp. Ví dụ lớp học Thứ 2 và Thứ 4 từ 18:00 đến 20:00 thì mỗi khung là một dòng. Khóa chính là `ma_lich`. Có `ma_lop`, `thu_trong_tuan`, `gio_bat_dau`, `gio_ket_thuc`. Constraint yêu cầu giờ kết thúc lớn hơn giờ bắt đầu.

`buoi_hoc`

Từng buổi học cụ thể theo ngày. Khóa chính là `ma_buoi_hoc`. Có `ma_lop`, `ma_lich`, `ngay_hoc`, `gio_bat_dau`, `gio_ket_thuc`, `trang_thai`, `ghi_chu`. `ma_lich` FK tới `lich_hoc`, `on delete set null`, nghĩa là xóa lịch định kỳ thì lịch sử buổi học cụ thể vẫn còn.

Trạng thái buổi học: `scheduled`, `completed`, `cancelled`, `rescheduled`.

### 3.4. Nhóm Đăng Ký, Điểm Danh, Thanh Toán, Đánh Giá

`dang_ky`

Lưu trạng thái đăng ký của học viên trong một lớp. Vì mô hình lớp 1-1 nên `ma_lop` là unique. Có `ma_dang_ky`, `ma_hoc_vien`, `ma_lop`, `ngay_dang_ky`, `trang_thai`, `ghi_chu`.

`tai_khoan_hv`

Tài khoản/phương thức thanh toán của học viên. Có `so_tai_khoan`, `nha_cung_cap`, `loai_phuong_thuc`, `ten_chu_tk`, `la_mac_dinh`. Unique `(ma_hoc_vien, so_tai_khoan, nha_cung_cap)`.

`tai_khoan_gs`

Tài khoản nhận tiền của gia sư. Cấu trúc tương tự `tai_khoan_hv`, nhưng nối tới `ma_gia_su`.

`giao_dich`

Lịch sử giao dịch tiền học và hoa hồng. Có `tong_tien_thu`, `ty_le_hoa_hong`, `phi_hoa_hong`, `so_tien_gia_su_nhan`, `ngay_thanh_toan`, `ngay_doi_soat`, `trang_thai`, `loai_giao_dich`, `ma_tham_chieu`. Constraint quan trọng: `phi_hoa_hong + so_tien_gia_su_nhan = tong_tien_thu`.

`danh_gia`

Đánh giá của học viên cho gia sư thông qua `ma_dang_ky`. `ma_dang_ky` unique, nghĩa là mỗi đăng ký/lớp chỉ có một đánh giá. `diem_sao` từ 1 đến 5.

`diem_danh`

Điểm danh từng buổi học cho từng đăng ký. Khóa chính ghép `(ma_buoi_hoc, ma_dang_ky)`. Có `trang_thai`, `so_phut_hoc`, `ghi_chu`. Trạng thái: `comat`, `vangmat`, `tre`, `phep`.

### 3.5. Nhóm Thông Báo Và Theo Dõi

`thong_bao`

Lưu thông báo cho đúng một người nhận: hoặc học viên, hoặc gia sư. Constraint `ck_thong_bao_nguoi_nhan` bắt buộc đúng một trong hai cột `ma_hoc_vien`, `ma_gia_su` khác null. Có các cột ngữ cảnh như `ma_yeu_cau`, `ma_lop`, `ma_giao_dich`, `ma_buoi_hoc`.

`audit_log`

Ghi lịch sử thay đổi dữ liệu quan trọng. Có `table_name`, `record_id`, `action`, `old_data`, `new_data`, `changed_by`, `changed_at`. Trigger hiện dùng bảng này để ghi khi đổi trạng thái yêu cầu/lớp.

`lich_su_day_hoc`

Bảng archive lịch sử đi dạy của gia sư. Cố tình denormalized: `ma_lop` không có FK, `ten_hoc_vien` là snapshot. Như vậy nếu lớp bị xóa thì lịch sử vẫn còn.

`lich_su_thue_gia_su`

Bảng archive lịch sử thuê gia sư của học viên. Cũng cố tình không FK với `ma_lop`, `ma_yeu_cau`, `ma_gia_su` để giữ được lịch sử độc lập.

## 4. Indexes

Các index chính:

- Unique index cho `hoc_vien.auth_id`, `hoc_vien.so_dien_thoai`, `hoc_vien.email` khi không null.
- Unique index tương tự cho `gia_su`.
- `ix_gia_su_trong_lich`: lọc nhanh gia sư đang rảnh.
- `ix_gia_su_mon_hoc_mon`: tìm gia sư theo môn.
- `ix_yeu_cau_hoc_vien`, `ix_yeu_cau_trang_thai`: lọc yêu cầu theo học viên/trạng thái/ngày.
- `ix_ung_tuyen_yeu_cau`, `ix_ung_tuyen_gia_su`: xem ứng tuyển theo yêu cầu hoặc gia sư.
- `ix_lop_hoc_gia_su`, `ix_lop_hoc_hoc_vien`: xem lớp theo vai trò.
- `ux_lich_hoc_lop_thu_gio`: tránh một lớp có hai lịch cùng thứ và cùng giờ bắt đầu.
- `ix_buoi_hoc_lop_ngay`, `ix_buoi_hoc_ma_lich`, `ix_buoi_hoc_ngay_hoc`: phục vụ tra cứu buổi học và trigger chống trùng lịch.
- `ix_giao_dich_dang_ky`: xem giao dịch của đăng ký theo thời gian.
- `ix_thong_bao_hv`, `ix_thong_bao_gs`: lấy thông báo theo người nhận, trạng thái đã đọc, ngày tạo.
- `ux_tk_hv_mac_dinh`, `ux_tk_gs_mac_dinh`: mỗi học viên/gia sư chỉ có một tài khoản mặc định.
- `ux_lop_hoc_ung_tuyen`: một ứng tuyển chỉ tạo được một lớp.
- `ix_audit_log_table_record`: xem lịch sử audit theo bảng và record.

## 5. Functions Trong SQL

`fn_tinh_diem_tb_gia_su(@p_ma_gia_su)`

Tính điểm sao trung bình của gia sư bằng cách join `danh_gia -> dang_ky -> lop_hoc`. Nếu chưa có đánh giá thì trả `0`.

`fn_kiem_tra_trung_lich_lichhoc(...)`

Kiểm tra gia sư có bị trùng lịch định kỳ không. So sánh cùng thứ trong tuần, cùng gia sư, lớp đang `sapmo` hoặc `dang_hoc`, và hai khoảng giờ có giao nhau.

`fn_kiem_tra_trung_buoihoc(...)`

Kiểm tra trùng buổi học cụ thể theo ngày. Dùng cho bảng `buoi_hoc`, bỏ qua buổi đã `cancelled`.

`fn_dem_lop_dang_day(@p_ma_gia_su)`

Đếm số lớp hiện tại của gia sư, tính các lớp `sapmo` và `dang_hoc`.

`fn_doanh_thu_gia_su(@p_ma_gia_su, @p_thang, @p_nam)`

Tính tổng tiền gia sư nhận trong một tháng/năm, chỉ tính giao dịch `success`.

`fn_hoc_vien_hop_le(@p_ma_hoc_vien)`

Kiểm tra học viên có giao dịch thất bại chưa được giải quyết trong 30 ngày gần nhất không. Nếu có `failed` nhưng sau đó đã có `success` cho cùng đăng ký thì coi là đã xử lý.

`fn_format_gio_hoc(@p_gio_bd, @p_gio_kt)`

Định dạng giờ thành chuỗi như `07:00 - 09:00`.

`fn_khung_gio_dang_co(@p_ma_gia_su, @p_thu)`

Trả về bảng các khung giờ gia sư đã có lịch trong một thứ cụ thể.

## 6. Triggers Trong SQL

`tr_hoc_vien_updated_at`

Sau khi update `hoc_vien`, tự cập nhật `ngay_cap_nhat`. Có guard `trigger_nestlevel` để tránh đệ quy.

`tr_gia_su_updated_at`

Tương tự cho bảng `gia_su`.

`tr_yeu_cau_lop_updated_at`

Tương tự cho bảng `yeu_cau_lop`.

`tr_diem_danh_validate`

Đảm bảo `ma_buoi_hoc` và `ma_dang_ky` trong điểm danh thuộc cùng một lớp. Nếu lệch lớp thì throw lỗi.

`tr_giao_dich_validate`

Đảm bảo tài khoản học viên trong giao dịch thuộc đúng học viên của đăng ký, và tài khoản gia sư thuộc đúng gia sư của lớp.

`tr_lich_hoc_check_trung`

Ngăn thêm/sửa lịch định kỳ bị trùng giờ với lịch khác của cùng gia sư.

`tr_buoi_hoc_check_trung`

Ngăn thêm/sửa buổi học cụ thể bị trùng giờ với buổi khác của cùng gia sư trong cùng ngày.

`tr_ung_tuyen_notify`

Khi gia sư ứng tuyển, tự insert thông báo cho học viên.

`tr_yeu_cau_chon_gia_su`

Khi học viên chọn gia sư, trigger gửi thông báo cho gia sư được chọn, gửi thông báo từ chối cho các gia sư còn lại, cập nhật `ung_tuyen` được chọn thành `accepted` và các ứng tuyển còn lại thành `rejected`.

`tr_yeu_cau_lop_audit`

Ghi `audit_log` khi trạng thái của `yeu_cau_lop` đổi.

`tr_lop_hoc_audit`

Ghi `audit_log` khi trạng thái của `lop_hoc` đổi.

## 7. Views Trong SQL

`vw_gia_su_tong_hop`

Tổng hợp thông tin gia sư, điểm đánh giá trung bình, số lớp đang dạy, số lớp đã nhận.

`vw_danh_gia_chi_tiet`

Chi tiết đánh giá kèm tên học viên, tên gia sư, lớp, đăng ký.

`vw_giao_dich_chi_tiet`

Chi tiết giao dịch kèm học viên, gia sư, lớp.

`vw_lop_hoc_chi_tiet`

Thông tin lớp học kèm tên gia sư, tên học viên, số lịch học, số buổi đã học.

`vw_lich_trinh_gia_su`

Lịch dạy định kỳ của gia sư, có thêm chuỗi giờ học đã format.

`vw_thong_ke_doanh_thu`

Thống kê theo năm, tháng, trạng thái giao dịch: số giao dịch, tổng doanh thu, tổng lợi nhuận, tổng chi trả gia sư.

`vw_yeu_cau_dang_mo`

Danh sách yêu cầu đang `open`, có tên học viên, khối hiện tại, số lượng ứng tuyển, danh sách môn học.

## 8. Stored Procedures Trong SQL

`sp_tao_yeu_cau_lop`

Tạo một yêu cầu lớp mới ở trạng thái `open`.

`sp_ung_tuyen`

Gia sư ứng tuyển vào yêu cầu. Trước khi insert, kiểm tra yêu cầu còn `open` và gia sư `trong_lich = 1`.

`sp_chon_gia_su`

Học viên chọn gia sư cho yêu cầu. Procedure validate gia sư phải có ứng tuyển `pending`, yêu cầu phải `open`, rồi update `yeu_cau_lop` trong transaction. Trigger `tr_yeu_cau_chon_gia_su` sẽ xử lý thông báo và trạng thái ứng tuyển.

`sp_tao_lop_hoc`

Tạo lớp học từ yêu cầu đã chọn gia sư. Procedure lấy thông tin từ `yeu_cau_lop`, insert `lop_hoc`, đổi yêu cầu thành `approved`, tạo `dang_ky`, copy môn từ `yeu_cau_mon` sang `lop_hoc_mon`.

`sp_danh_gia`

Insert đánh giá mới vào `danh_gia`.

`sp_diem_danh`

Insert điểm danh vào `diem_danh`.

`sp_toggle_trong_lich`

Bật/tắt trạng thái `trong_lich` của gia sư.

`sp_ghi_nhan_thanh_toan`

Ghi giao dịch thanh toán. Tự tính `phi_hoa_hong = floor(tong_tien * ty_le / 100)` và `so_tien_gia_su_nhan = tong_tien - phi`. Insert giao dịch trong transaction rồi cập nhật đăng ký thành `confirmed`.

## 9. File Seed Demo

`demo_seed_10_lop_day_du.sql` tạo dữ liệu demo gồm:

- 6 môn học.
- 10 học viên.
- 5 gia sư.
- Chuyên môn gia sư.
- Tài khoản thanh toán học viên/gia sư.
- 10 yêu cầu tìm gia sư.
- 10 ứng tuyển accepted.
- 10 lớp học với trạng thái đang học, sắp mở, hoàn thành hoặc hủy.
- Lịch học, buổi học, đăng ký, điểm danh, giao dịch, đánh giá.
- Lịch sử dạy học và lịch sử thuê gia sư.

File này có cleanup theo prefix `_D%`, nên có thể chạy lại nhiều lần tương đối an toàn trong database demo.

## 10. Web App: `web-app/`

### 10.1. Công Nghệ

`package.json` dùng:

- `express`: server web.
- `ejs`: template HTML.
- `express-session`: session đăng nhập.
- `@supabase/supabase-js`: kết nối Supabase.
- `dotenv`: đọc biến môi trường.
- `connect-pg-simple` và `bcryptjs` đang có dependency nhưng code hiện tại không dùng trực tiếp.

Script chạy:

- `npm start`: chạy `node server.js`.
- `npm run dev`: chạy `node --watch server.js`.

### 10.2. `lib/supabase.js`

Tạo 2 client:

- `supabase`: dùng `SUPABASE_ANON_KEY`, phù hợp query bình thường theo RLS.
- `supabaseAdmin`: dùng `SUPABASE_SERVICE_ROLE_KEY`, bypass RLS, chỉ nên dùng server-side.

### 10.3. `lib/supabaseStore.js`

Custom session store cho Express. Thay vì lưu session trong memory, class `SupabaseStore` lưu vào bảng `sessions`:

- `get(sid, cb)`: lấy session theo `sid`.
- `set(sid, sess, cb)`: upsert session, tính `expire` theo cookie.
- `destroy(sid, cb)`: xóa session khi logout.

### 10.4. `server.js`

Đây là file entrypoint chính.

Phần setup:

- Load `.env`.
- Tạo Express app.
- Set view engine là EJS.
- Serve static từ `web-app/public`.
- Parse form URL-encoded và JSON.
- Cấu hình session dùng `SupabaseStore`.

Middleware global:

- Đưa `user`, `role`, `isAdmin`, `error`, `success` vào `res.locals` để mọi view dùng được.
- Nếu đã đăng nhập, lấy 5 thông báo mới nhất từ `thong_bao`.
- Đếm số thông báo chưa đọc.
- Sau khi đưa flash message vào view thì xóa khỏi session.

Các route chính trong `server.js`:

- `GET /`: trang chủ, lấy 6 yêu cầu đang mở và 4 gia sư đang trống lịch.
- `GET /yeu-cau`: danh sách yêu cầu đang mở cho gia sư xem, có đếm ứng tuyển và lịch mong muốn.
- `GET /dang-tin`: form học viên đăng yêu cầu.
- `POST /dang-tin`: tạo yêu cầu, tạo môn mới nếu chọn "OTHER", gọi RPC `sp_tao_yeu_cau_lop`, insert `yeu_cau_mon`, insert lịch mong muốn.
- `GET /yeu-cau-cua-toi`: học viên xem yêu cầu của mình, các ứng tuyển, lịch yêu cầu, lịch sử thuê.
- `POST /chon-gia-su`: học viên chọn gia sư, gọi RPC `sp_chon_gia_su_va_tao_lop_va_lich`.
- `POST /ung-tuyen`: gia sư ứng tuyển, gọi RPC `sp_ung_tuyen`.
- `GET /lop-da-ung-tuyen`: gia sư xem các yêu cầu mình đã ứng tuyển.
- `GET /lich-day`: gia sư xem lịch dạy từ `vw_lich_trinh_gia_su` và lịch sử lớp.
- `POST /toggle-trong-lich`: bật/tắt trạng thái rảnh của gia sư bằng RPC `sp_toggle_trong_lich`.
- `POST /danh-gia`: học viên gửi đánh giá bằng RPC `sp_danh_gia`.
- `GET /ho-so-gia-su/:ma_gia_su`: xem hồ sơ công khai gia sư, môn dạy, lớp đang dạy, lớp đã dạy, đánh giá.
- `GET /api/gia-su-tim-kiem`: API JSON tìm gia sư theo môn/trạng thái rảnh.
- `GET /api/ung-tuyen-count/:ma_yeu_cau`: API JSON đếm ứng tuyển của một yêu cầu.
- `GET /thong-bao/read/:id`: đánh dấu một thông báo đã đọc rồi redirect theo ngữ cảnh.
- `POST /thong-bao/read-all`: đánh dấu tất cả thông báo của user hiện tại là đã đọc.

`server.js` mount thêm router:

- `/auth` -> `routes/auth.js`
- `/` -> `routes/profile.js`
- `/lop-hoc` -> `routes/lop-hoc.js`
- `/admin` -> `routes/admin.js`

## 11. Routes Chi Tiết

### 11.1. `routes/auth.js`

`POST /auth/register`

Đăng ký tài khoản. Validate email, password, họ tên, vai trò. Dùng `supabaseAdmin.auth.admin.createUser` để tạo user Auth, sau đó insert hồ sơ vào `hoc_vien` hoặc `gia_su`. Nếu insert hồ sơ lỗi, code xóa lại Auth user để tránh tài khoản mồ côi.

`POST /auth/login`

Đăng nhập bằng `supabase.auth.signInWithPassword`. Sau đó tìm hồ sơ theo `auth_id` trong `quan_tri_vien`, `hoc_vien`, `gia_su`. Nếu là admin thì set `isAdmin = true`, nếu không thì set role học viên/gia sư.

`POST /auth/logout`

Destroy session rồi redirect về `/`.

`POST /auth/forgot-password`

Gửi email reset mật khẩu qua Supabase Auth.

`GET /auth/reset-password`

Render trang reset password, truyền `SUPABASE_URL` và `SUPABASE_ANON_KEY` xuống browser để gọi `supabase.auth.updateUser`.

### 11.2. `routes/profile.js`

`requireLogin`

Middleware bắt buộc đăng nhập. Nếu chưa đăng nhập thì redirect về `/`.

`GET /ho-so/chinh-sua`

Render form chỉnh sửa hồ sơ. Tự chọn bảng `gia_su` hoặc `hoc_vien` theo session role.

`POST /ho-so/chinh-sua`

Cập nhật hồ sơ. Gia sư cập nhật `trinh_do`, `gioi_thieu`, `so_dien_thoai`; học viên cập nhật `so_dien_thoai`, `khoi_hien_tai`. Sau update, session user được merge với dữ liệu mới.

`GET /ho-so-hoc-vien/:ma_hoc_vien`

Trang hồ sơ công khai học viên, kèm các yêu cầu đang mở của học viên đó.

### 11.3. `routes/lop-hoc.js`

`GET /lop-hoc`

Danh sách lớp của user hiện tại. Nếu là gia sư thì lọc `ma_gia_su`, nếu là học viên thì lọc `ma_hoc_vien`.

`GET /lop-hoc/:ma_lop`

Chi tiết lớp, gồm thông tin lớp, lịch định kỳ `lich_hoc`, và các buổi cụ thể `buoi_hoc`.

`POST /lop-hoc/:ma_lop/them-lich`

Thêm lịch định kỳ mới cho lớp. Trigger SQL sẽ chặn nếu trùng lịch gia sư.

`POST /lop-hoc/:ma_lop/xoa-lich/:ma_lich`

Xóa một lịch định kỳ.

### 11.4. `routes/admin.js`

`requireAdmin`

Chỉ cho phép user có `req.session.isAdmin`.

`GET /admin`

Dashboard admin, lấy thống kê từ `vw_admin_thong_ke`, yêu cầu mới nhất, lớp mới nhất.

`GET /admin/yeu-cau`

Quản lý yêu cầu. Có filter `trang_thai` và search theo tiêu đề/mã yêu cầu.

`GET /admin/lop-hoc`

Quản lý lớp học. Có filter trạng thái và search theo mã lớp.

`GET /admin/gia-su`

Danh sách gia sư, search theo họ tên/email/mã.

`GET /admin/hoc-vien`

Danh sách học viên, search theo họ tên/email/mã.

## 12. Views EJS

`views/partials/header.ejs`

Layout `<head>`, load Tailwind CDN, Material Symbols, Google Fonts, và khai báo theme/CSS dùng chung như button, card, badge, input, animation.

`views/partials/navbar.ejs`

Thanh điều hướng. Hiển thị menu khác nhau theo role:

- Gia sư: yêu cầu lớp, đã ứng tuyển, lớp của tôi, lịch dạy.
- Học viên: đăng tin, yêu cầu của tôi, lớp học.
- Admin: link quản trị.

Navbar cũng hiển thị chuông thông báo, dropdown thông báo, nút đánh dấu tất cả đã đọc, menu mobile.

`views/partials/footer.ejs`

Script global chống double submit: khi submit form thì disable button submit một lúc để tránh bấm nhiều lần.

`views/index.ejs`

Trang chủ. Có hero, danh sách yêu cầu nổi bật, danh sách gia sư nổi bật, modal đăng nhập/đăng ký/quên mật khẩu. Có JS điều khiển auth modal, chọn role đăng ký, loading state cho form quên mật khẩu, animation on scroll.

`views/yeu-cau.ejs`

Danh sách yêu cầu đang mở. Gia sư có thể mở modal ứng tuyển. Nếu chưa login, view có modal login/register.

`views/dang-tin.ejs`

Form học viên đăng yêu cầu mới. Có chọn môn có sẵn hoặc tạo môn mới. JS `toggleNewMonInput` bật/tắt input môn mới. JS `updateDangTinLichHoc` sinh số dòng lịch học theo `so_buoi_tuan`.

`views/yeu-cau-cua-toi.ejs`

Học viên xem các yêu cầu mình đã đăng, các gia sư ứng tuyển, lịch mong muốn, và lịch sử thuê. Có modal duyệt gia sư, tự đổ lịch học theo lịch yêu cầu nếu có.

`views/ho-so-gia-su.ejs`

Hồ sơ công khai gia sư: thông tin, chuyên môn, lớp đang dạy, lớp đã dạy, đánh giá. Nếu đi từ yêu cầu cụ thể, học viên có thể chọn gia sư ngay tại trang này.

`views/ho-so-hoc-vien.ejs`

Hồ sơ công khai học viên và các yêu cầu đang mở của học viên.

`views/ho-so-chinh-sua.ejs`

Form chỉnh sửa hồ sơ cho cả học viên và gia sư. View dùng biến `isGiaSu` để hiện field phù hợp.

`views/lop-hoc.ejs`

Danh sách lớp của user hiện tại, mỗi lớp link sang chi tiết.

`views/lop-hoc-chi-tiet.ejs`

Chi tiết lớp, lịch học định kỳ, buổi học. Có form thêm lịch và form xóa lịch.

`views/lop-da-ung-tuyen.ejs`

Gia sư xem danh sách yêu cầu mình đã ứng tuyển cùng trạng thái.

`views/lich-day.ejs`

Gia sư xem lịch dạy theo thứ trong tuần, bật/tắt trạng thái trống lịch, và xem lịch sử lớp.

`views/reset-password.ejs`

Trang đặt lại mật khẩu. Dùng Supabase JS trên browser, có kiểm tra độ mạnh mật khẩu, confirm password, loading spinner, alert thành công/lỗi.

Các view admin:

- `views/admin/index.ejs`: dashboard thống kê.
- `views/admin/yeu-cau.ejs`: bảng quản lý yêu cầu.
- `views/admin/lop-hoc.ejs`: bảng quản lý lớp.
- `views/admin/gia-su.ejs`: bảng quản lý gia sư.
- `views/admin/hoc-vien.ejs`: bảng quản lý học viên.

## 13. Script Seed/Test Trong `web-app`

`seed_users.js`

Tạo user Supabase Auth mẫu: admin, 4 gia sư, 4 học viên. Sau khi tạo Auth user, insert profile tương ứng vào `quan_tri_vien`, `gia_su`, hoặc `hoc_vien`.

`test-query.js`

Script kiểm tra thông báo của một học viên hard-code `ma_hoc_vien`. Query `thong_bao`, in danh sách thông báo và unread count.

`vercel.json`

Cấu hình deploy Vercel: mọi route `/(.*)` đều đi vào `server.js` qua `@vercel/node`.

## 14. Tools Sinh Diagram

`tools/generate-system-diagram.js`

Đọc file SQL, parse `CREATE TABLE`, sinh diagram dạng SVG/HTML/Mermaid chỉ gồm bảng và cột. Mục đích là xem nhanh toàn bộ table, không thể hiện quan hệ FK chi tiết.

Các hàm chính:

- `cleanName`: chuẩn hóa tên bảng/cột.
- `splitTopLevel`: tách danh sách cột/constraint theo dấu phẩy nhưng không vỡ khi có ngoặc hoặc chuỗi.
- `parseColumn`: đọc tên cột, kiểu dữ liệu, primary/required.
- `parseTables`: tìm các block `CREATE TABLE`.
- `renderSvg`: vẽ SVG.
- `renderHtml`: bọc SVG vào HTML.
- `renderMmd`: xuất Mermaid đơn giản.

`tools/generate-erd.js`

Script tham vọng hơn: parse bảng, cột, primary key, unique, foreign key, sau đó vẽ ERD có quan hệ. Nó cũng sinh SVG/HTML/Mermaid.

Các hàm chính:

- `parseReferences`: đọc `REFERENCES table(column)`.
- `parseConstraint`: đọc PK, unique, FK ở dạng constraint.
- `parseSchema`: parse toàn bộ schema và quan hệ.
- `fkIsUnique`, `fkIsRequired`: suy luận cardinality.
- `childCardinality`, `parentCardinality`: biểu diễn 0..N, 0..1, 1.
- `renderTable`, `renderRelationships`, `renderSvg`, `renderMermaid`: vẽ output.

Điểm cần chú ý: hai script này đang mặc định đọc `schema_gia_su_complete.sql`, nhưng trong workspace hiện có file `Nhom_12_QuanLyGiaSuHocVien.sql`. Muốn dùng cần truyền đúng path hoặc sửa default.

## 15. Tool Phụ `tools/drive-to-sheet`

Đây là một tool riêng để đọc folder Google Drive của giáo viên và render danh sách bài học vào Google Sheet.

`auth.js`

Đọc OAuth credentials/token, tạo Google OAuth client, trả về client Drive và Sheets.

`drive.js`

Các hàm làm việc với Drive:

- `listChildren`: list file/folder con.
- `walk`: DFS qua folder tree.
- `flattenLeaves`: lấy các folder lá.
- `isVideo`: kiểm tra MIME video.
- `formatSize`, `formatDuration`: format dung lượng/thời lượng.

`sheet.js`

Các hàm làm việc với Google Sheets:

- `shortenTabName`: rút gọn tên tab, bỏ ký tự cấm.
- `getSpreadsheet`: lấy metadata spreadsheet.
- `ensureTab`: xóa tab cũ cùng tên rồi tạo tab mới.
- `writeValues`: ghi values vào sheet.
- `applyHeaderFormat`: format header, freeze row, autoresize cột.

`crawl.js`

Stage 1. Crawl folder giáo viên, lưu cache vào `trees/<teacherFolderId>.json`. Có CLI `node crawl.js --teacher <id>`.

`infer-schema.js`

Stage 2. Dùng Anthropic API để suy ra schema hiển thị từ tree đã crawl. Lưu vào `schemas/<teacherFolderId>.json`.

`render.js`

Stage 3. Đọc tree + schema cache rồi render ra Google Sheet. Có logic phân loại file như bài giảng, đề, key, chữa đề, BVT/guide. Đây là bản render nâng cấp theo schema.

`index.js`

Phiên bản render cũ/đơn giản hơn: crawl trực tiếp Drive, tạo tab cho mỗi khóa, liệt kê folder và video.

## 16. Những Điểm Lệch Quan Trọng Cần Biết

Đây là phần rất đáng chú ý vì nó ảnh hưởng chạy thật.

1. SQL chính là T-SQL/SQL Server, còn web-app dùng Supabase/Postgres. Các cú pháp như `use master`, `go`, `create procedure`, `datetime2`, `nvarchar`, `bit`, `sysdatetime()` không chạy trực tiếp trên Supabase Postgres nếu chưa chuyển đổi.

2. Web-app đang gọi một số bảng/hàm/view/procedure không có trong `Nhom_12_QuanLyGiaSuHocVien.sql`:

- `sessions`: dùng bởi `SupabaseStore`.
- `quan_tri_vien`: dùng cho đăng nhập admin và `seed_users.js`.
- `yeu_cau_lich_hoc`: dùng khi đăng tin và chọn gia sư.
- `vw_admin_thong_ke`: dùng dashboard admin.
- `fn_kiem_tra_trung_lich_hoc_vien`: dùng khi học viên đăng lịch mong muốn.
- `sp_chon_gia_su_va_tao_lop_va_lich`: dùng khi chọn gia sư và tạo lớp/lịch cùng lúc.

3. Trạng thái lớp bị lệch giữa SQL và web-app:

- SQL cho `lop_hoc.trang_thai`: `sapmo`, `dang_hoc`, `hoan_thanh`, `huy`.
- Web-app/view lại dùng: `SapMo`, `da_hoan_thanh`, `da_huy`, `dang_hoc`.

4. `sp_tao_lop_hoc` trong SQL không set `ma_ung_tuyen`, dù bảng `lop_hoc` có `ma_ung_tuyen` và có unique index `ux_lop_hoc_ung_tuyen`.

5. Trigger `tr_ung_tuyen_notify` tạo `ma_thong_bao = 'TB_' + GUID bỏ dấu gạch`, dài hơn `varchar(30)`. File seed demo cũng ghi chú phải disable trigger vì mã thông báo hiện sinh dài hơn cột.

6. Web-app dùng `supabaseAdmin` khá nhiều. Điều này hợp lý ở server-side, nhưng phải đảm bảo route guard chặt, vì service role bypass RLS.

7. `web-app/server.js` serve static từ `web-app/public`, nhưng trong danh sách file hiện chưa thấy thư mục `public`.

## 17. Tóm Tắt Một Câu

Database thiết kế khá đầy đủ cho hệ thống quản lý gia sư - học viên; web-app Express/EJS đã dựng được các luồng chính như đăng nhập, đăng tin, ứng tuyển, chọn gia sư, lớp học, lịch dạy, thông báo và admin. Tuy nhiên để chạy trơn với Supabase, cần đồng bộ lại schema Postgres thật với những bảng/hàm mà web-app đang gọi, và thống nhất lại tên trạng thái lớp.
