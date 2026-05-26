# Huong dan lam phan kiem thu cho Chuong 4

Tai lieu nay duoc viet theo dung khung trong mau bao cao: `4.2.3`, `4.3.3`, `4.4.3`, `4.5.3`, `4.6.3`, `4.7.3`, `4.8.3`.

## Cach lam chung trong SSMS

1. Chay file [schema_gia_su_complete.sql](</C:/Web gia sư/schema_gia_su_complete.sql:1>) de tao CSDL `GiaSuBachKhoa`.
2. Chay file [kiem_thu_chuong4.sql](</C:/Web gia sư/kiem_thu_chuong4.sql:1>) de tao du lieu mau va thuc hien cac ca kiem thu.
3. Khi viet bao cao, moi muc `4.x.3` nen co:
   - Muc tieu kiem thu
   - Cach thuc hien
   - Ket qua mong doi
   - Ket qua thuc te
4. Minh chung nen chup 2 loai anh:
   - Anh cau lenh SQL va ket qua tra ve
   - Anh `Execution Plan` doi voi phan `Index`

## 4.2.3 Kiem thu Index

**Doan van co the dua vao bao cao**

Nhom kiem thu hieu qua cua cac chi muc bang cach su dung `Include Actual Execution Plan` va `SET SHOWPLAN_TEXT ON` trong SQL Server Management Studio. Cac truy van duoc chon la nhung truy van co tinh chon loc cao, bao gom tim gia su theo email, tim hoc vien theo so dien thoai va loc yeu cau dang mo theo trang thai. Ket qua kiem thu cho thay SQL Server su dung `Index Seek` tren cac chi muc `ux_gia_su_email`, `ux_hoc_vien_sdt` va `ix_yeu_cau_trang_thai`, qua do giam chi phi quet toan bang va cai thien toc do truy van.

**Cach viet bang test**

| Ma TC | Noi dung | Cau lenh kiem thu | Ket qua mong doi |
| --- | --- | --- | --- |
| IDX-01 | Kiem tra tim gia su theo email | `SELECT ma_gia_su FROM gia_su WHERE email = 'gs1@test.local';` | Execution Plan su dung `ux_gia_su_email` |
| IDX-02 | Kiem tra tim hoc vien theo so dien thoai | `SELECT ma_hoc_vien FROM hoc_vien WHERE so_dien_thoai = '0900000001';` | Execution Plan su dung `ux_hoc_vien_sdt` |
| IDX-03 | Kiem tra loc yeu cau dang mo | `SELECT ma_yeu_cau, ngay_yeu_cau FROM yeu_cau_lop WHERE trang_thai = 'open' ORDER BY ngay_yeu_cau DESC;` | Execution Plan su dung `ix_yeu_cau_trang_thai` |

**Cach chup minh chung**

- Bat `Include Actual Execution Plan`.
- Chay tung truy van.
- Chup man hinh phan plan neu thay `Index Seek`.

## 4.3.3 Kiem thu View

**Doan van co the dua vao bao cao**

Nhom kiem thu cac `View` bang cach doi chieu ket qua tra ve voi du lieu goc trong cac bang lien quan. Viec kiem thu tap trung vao tinh dung dan cua phep `JOIN`, cot tinh toan va dieu kien loc du lieu. Ket qua cho thay cac view `vw_yeu_cau_dang_mo`, `vw_gia_su_tong_hop`, `vw_lop_hoc_chi_tiet`, `vw_lich_trinh_gia_su` va `vw_thong_ke_doanh_thu` deu tra ve thong tin tong hop dung voi nghiep vu thuc te cua he thong.

**Cach viet bang test**

| Ma TC | View | Noi dung kiem thu | Ket qua mong doi |
| --- | --- | --- | --- |
| VIEW-01 | `vw_yeu_cau_dang_mo` | Kiem tra danh sach yeu cau con mo | Chi hien yeu cau co trang thai `open` hoac `approved` |
| VIEW-02 | `vw_gia_su_tong_hop` | Kiem tra diem danh gia TB va so lop dang day | Cac cot tong hop khop voi bang `danh_gia`, `lop_hoc`, `ung_tuyen` |
| VIEW-03 | `vw_lop_hoc_chi_tiet` | Kiem tra thong tin lop, gia su, hoc vien | Du lieu join dung theo `ma_lop` |
| VIEW-04 | `vw_lich_trinh_gia_su` | Kiem tra khung gio hoc cua gia su | Hien dung thu trong tuan va khung gio da format |
| VIEW-05 | `vw_thong_ke_doanh_thu` | Kiem tra tong thu, hoa hong, so tien gia su nhan | So lieu tong hop dung voi bang `giao_dich` |

## 4.4.3 Kiem thu Store Procedure

**Doan van co the dua vao bao cao**

Nhom kiem thu cac `Stored Procedure` theo dung luong nghiep vu chinh cua he thong tim gia su, tu viec tao yeu cau lop, gia su ung tuyen, hoc vien chon gia su, tao lop hoc cho den ghi nhan thanh toan. Kiem thu duoc thuc hien theo ca hop le va ca khong hop le de dam bao thu tuc vua xu ly dung du lieu vua kiem soat loi nghiep vu. Ket qua cho thay cac procedure tao moi va cap nhat du lieu dung theo mong doi, dong thoi tra loi khi dieu kien nghiep vu khong thoa man.

**Cach viet bang test**

| Ma TC | Procedure | Noi dung kiem thu | Ket qua mong doi |
| --- | --- | --- | --- |
| SP-01 | `sp_tao_yeu_cau_lop` | Tao yeu cau hoc moi | Them 1 ban ghi vao `yeu_cau_lop`, trang thai mac dinh `open` |
| SP-02 | `sp_ung_tuyen` | Gia su ung tuyen vao yeu cau dang mo | Them ban ghi vao `ung_tuyen` |
| SP-03 | `sp_chon_gia_su` | Hoc vien chon 1 gia su trong danh sach ung tuyen | Yeu cau chuyen `closed`, 1 ung tuyen `accepted`, cac ung tuyen con lai `rejected` |
| SP-04 | `sp_tao_lop_hoc` | Tao lop hoc tu yeu cau da chon gia su | Tao `lop_hoc`, `dang_ky`, `lop_hoc_mon` |
| SP-05 | `sp_danh_gia` | Them danh gia cho lop hoc | Them ban ghi vao `danh_gia` |
| SP-06 | `sp_diem_danh` | Diem danh hoc vien trong buoi hoc | Them ban ghi vao `diem_danh` |
| SP-07 | `sp_toggle_trong_lich` | Doi trang thai ranh/bat cua gia su | Cot `trong_lich` thay doi dung |
| SP-08 | `sp_ghi_nhan_thanh_toan` | Ghi nhan thanh toan va tinh hoa hong | Phi hoa hong va so tien gia su nhan duoc tinh dung |

## 4.5.3 Kiem thu Function

**Doan van co the dua vao bao cao**

Nhom kiem thu cac `Function` bang cach goi truc tiep ham voi du lieu mau va doi chieu ket qua voi tinh toan thu cong. Cac ham duoc chon kiem thu gom ham tinh diem danh gia trung binh, dem so lop dang day, tinh doanh thu gia su, kiem tra trung lich, kiem tra hop le hoc vien va format khung gio hoc. Ket qua cho thay cac function tra ve gia tri phu hop voi du lieu phat sinh trong he thong.

**Cach viet bang test**

| Ma TC | Function | Noi dung kiem thu | Ket qua mong doi |
| --- | --- | --- | --- |
| FN-01 | `fn_tinh_diem_tb_gia_su` | Tinh diem trung binh cua gia su | Tra ve dung diem trung binh danh gia |
| FN-02 | `fn_dem_lop_dang_day` | Dem so lop dang hoat dong cua gia su | Tra ve dung so lop `SapMo` va `Active` |
| FN-03 | `fn_doanh_thu_gia_su` | Tinh thu nhap cua gia su theo thang | Tong tien khop voi bang `giao_dich` |
| FN-04 | `fn_kiem_tra_trung_lich` | Kiem tra lich hoc bi trung | Tra ve `1` neu trung, `0` neu khong trung |
| FN-05 | `fn_hoc_vien_hop_le` | Kiem tra hoc vien co giao dich that bai hay khong | Tra ve `1` neu hop le, `0` neu co giao dich `Failed` |
| FN-06 | `fn_format_gio_hoc` | Dinh dang gio hoc | Tra ve chuoi dang `HH:mm - HH:mm` |

## 4.6.3 Kiem thu Trigger

**Doan van co the dua vao bao cao**

Nhom kiem thu trigger theo hai huong: trigger cap nhat tu dong va trigger rang buoc nghiep vu. Ket qua kiem thu cho thay cac trigger `tr_hoc_vien_updated_at`, `tr_gia_su_updated_at`, `tr_yeu_cau_lop_updated_at` cap nhat dung thoi gian sua doi; cac trigger `tr_ung_tuyen_notify` va `tr_yeu_cau_chon_gia_su` tao thong bao tu dong dung doi tuong; trong khi cac trigger kiem tra du lieu nhu `tr_diem_danh_validate`, `tr_giao_dich_validate`, `tr_lich_hoc_check_trung` va `tr_buoi_hoc_check_trung` deu chan dung cac truong hop vi pham nghiep vu. Rieng truong hop vuot si so lop hoc hien tai duoc chan som boi rang buoc `UNIQUE(ma_lop)` tren bang `dang_ky`, dong thoi trigger `tr_dang_ky_check_siso` van dong vai tro mot lop bao ve bo sung.

**Cach viet bang test**

| Ma TC | Trigger | Noi dung kiem thu | Ket qua mong doi |
| --- | --- | --- | --- |
| TRG-01 | `tr_hoc_vien_updated_at` | Sua thong tin hoc vien | `ngay_cap_nhat` thay doi |
| TRG-02 | `tr_ung_tuyen_notify` | Them 1 ung tuyen moi | Tao thong bao cho hoc vien |
| TRG-03 | `tr_yeu_cau_chon_gia_su` | Chon gia su cho yeu cau | Tao thong bao cho gia su duoc chon va gia su bi tu choi |
| TRG-04 | `tr_diem_danh_validate` | Diem danh sai lop hoc | Trigger bao loi va khong cho chen du lieu |
| TRG-05 | `tr_giao_dich_validate` | Dung sai tai khoan thanh toan | Trigger bao loi va huy thao tac |
| TRG-06 | `tr_lich_hoc_check_trung` | Tao lich hoc bi trung gio | Trigger bao loi trung lich |
| TRG-07 | `tr_buoi_hoc_check_trung` | Tao buoi hoc bi trung gio | Trigger bao loi trung lich |
| TRG-08 | Rang buoc si so lop hoc | Dang ky vuot 1 hoc vien/lop | He thong tu choi du lieu, thuc te co the bi chan boi `UNIQUE(ma_lop)` truoc khi trigger xu ly |

## 4.7.3 Kiem thu User

**Doan van co the dua vao bao cao**

Nhom kiem thu phan `User` bang cach tao cac tai khoan co muc quyen khac nhau va su dung `EXECUTE AS USER` de mo phong hanh vi truy cap. Qua trinh kiem thu tap trung vao hai nhom quyen chinh: nguoi dung chi duoc xem du lieu va nguoi dung duoc phep thuc thi nghiep vu. Ket qua cho thay user chi doc co the xem du lieu tong hop nhung khong duoc phep goi procedure cap nhat, trong khi user nghiep vu co the thuc thi cac thu tuc duoc cap quyen.

**Cach viet bang test**

| Ma TC | User | Noi dung kiem thu | Ket qua mong doi |
| --- | --- | --- | --- |
| USER-01 | `report_viewer` | Xem du lieu tu view | Truy van thanh cong |
| USER-02 | `report_viewer` | Goi `sp_toggle_trong_lich` | Bi tu choi do khong co quyen `EXECUTE` |
| USER-03 | `report_operator` | Goi `sp_toggle_trong_lich` | Thuc thi thanh cong |

## 4.8.3 Kiem thu tinh san sang cua ban sao luu

**Doan van co the dua vao bao cao**

Nhom kiem thu tinh san sang cua ban sao luu bang cach tao file backup tu CSDL hien tai, sau do phuc hoi sang mot CSDL moi de doi chieu so bang, so view va kha nang truy van du lieu. Phuong phap nay nham dam bao khi xay ra su co, he thong co the duoc khoi phuc ve trang thai hoat dong ma khong mat du lieu nghiep vu quan trong. Ket qua mong doi la file backup duoc tao thanh cong, CSDL phuc hoi co the mo va truy van binh thuong.

**Cach viet bang test**

| Ma TC | Noi dung kiem thu | Ket qua mong doi |
| --- | --- | --- |
| BK-01 | Tao file backup `.bak` | File backup duoc tao thanh cong |
| BK-02 | Restore sang CSDL moi | CSDL moi duoc khoi phuc thanh cong |
| BK-03 | Truy van doi chieu sau restore | So bang, so view va mot so du lieu mau khop voi ban goc |

## Goi y cach chup anh cho bao cao

- Phan `Index`: chup `Execution Plan` co dong `Index Seek`.
- Phan `View`: chup ket qua `SELECT TOP 5 * FROM vw_...`.
- Phan `Procedure`: chup lenh `EXEC` va bang du lieu sau khi chay.
- Phan `Function`: chup cau lenh `SELECT dbo.fn_...`.
- Phan `Trigger`: chup thong bao loi trong `Messages` hoac ket qua tao thong bao.
- Phan `User`: chup doan `EXECUTE AS USER` va loi phan quyen.
- Phan `Backup`: chup file `.bak` va lenh `RESTORE`.

## Ghi chu

File [kiem_thu_chuong4.sql](</C:/Web gia sư/kiem_thu_chuong4.sql:1>) da duoc soan san de anh chay va lay minh chung cho cac muc tu `4.2.3` den `4.7.3`. Rieng `4.8.3` em de kem mau lenh backup/restore de anh chay tren may theo duong dan phu hop voi SQL Server cua anh.
