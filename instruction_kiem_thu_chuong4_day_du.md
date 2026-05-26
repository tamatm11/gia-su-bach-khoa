# Instruction kiem thu day du cho Chuong 4

Tai lieu nay la file huong dan tong hop duy nhat de anh thuc hien cac kiem thu tu muc `4.2` den `4.9` trong bao cao. Cac buoc duoc viet theo huong:

- Chuan bi du lieu
- Chay tung nhom kiem thu
- Ghi lai ket qua thuc te
- Chup man hinh minh chung dua vao bao cao

File nay di kem voi:

- [schema_gia_su_complete.sql](</C:/Web gia sư/schema_gia_su_complete.sql:1>)
- [kiem_thu_chuong4.sql](</C:/Web gia sư/kiem_thu_chuong4.sql:1>)
- [kiem_thu_chuong4_tung_buoc.md](</C:/Web gia sư/kiem_thu_chuong4_tung_buoc.md:1>)

Neu anh muon chay tung test rat cham, dung file `kiem_thu_chuong4_tung_buoc.md`. Neu anh muon co 1 file ly thuyet + thao tac day du de viet bao cao, dung file nay.

## 1. Chuan bi truoc khi kiem thu

### 1.1 Moi truong

- SQL Server Management Studio
- Co CSDL `GiaSuBachKhoa`
- Da chay file schema moi nhat

### 1.2 Fix tuong thich schema cu

Neu CSDL cua anh duoc tao tu ban schema cu, chay doan sau 1 lan:

```sql
USE GiaSuBachKhoa;
GO

IF COL_LENGTH('dbo.thong_bao', 'ma_thong_bao') IS NOT NULL
   AND COL_LENGTH('dbo.thong_bao', 'ma_thong_bao') < 40
BEGIN
    ALTER TABLE dbo.thong_bao ALTER COLUMN ma_thong_bao VARCHAR(40) NOT NULL;
END;
GO
```

### 1.3 Tao du lieu nen

Anh co 2 cach:

1. Chay toan bo [kiem_thu_chuong4.sql](</C:/Web gia sư/kiem_thu_chuong4.sql:1>) neu muon lay minh chung nhanh.
2. Chay tung block trong [kiem_thu_chuong4_tung_buoc.md](</C:/Web gia sư/kiem_thu_chuong4_tung_buoc.md:1>) neu muon kiem soat loi o tung buoc.

Khuyen nghi:
- Lan dau nen chay tung buoc.
- Khi da on dinh moi chay file tong.

## 2. Cach ghi vao bao cao

Moi muc `4.x.3` nen giu cung 1 mau:

1. Muc tieu kiem thu
2. Du lieu dau vao
3. Cach thuc hien
4. Ket qua mong doi
5. Ket qua thuc te
6. Anh minh chung

Mau ngan de viet:

> Nhom tien hanh kiem thu chuc nang ... bang cach thuc hien ... tren bo du lieu mau. Ket qua cho thay he thong ... dung voi nghiep vu dat ra.

## 3. 4.2 Index

### 3.1 Muc tieu

Kiem tra SQL Server co su dung index dung nhu thiet ke hay khong.

### 3.2 Cach thuc hien

Bat `Include Actual Execution Plan`, sau do chay:

```sql
SELECT ma_gia_su FROM gia_su WHERE email = 'gs1@test.local';
SELECT ma_hoc_vien FROM hoc_vien WHERE so_dien_thoai = '0900000001';
SELECT ma_yeu_cau, ngay_yeu_cau
FROM yeu_cau_lop
WHERE trang_thai = 'open'
ORDER BY ngay_yeu_cau DESC;
GO
```

### 3.3 Ket qua mong doi

- Truy van 1 dung `ux_gia_su_email`
- Truy van 2 dung `ux_hoc_vien_sdt`
- Truy van 3 dung `ix_yeu_cau_trang_thai`
- Trong execution plan xuat hien `Index Seek`

### 3.4 Cach viet bao cao

Anh co the viet:

> Nhom kiem thu hieu qua cua cac chi muc bang cach theo doi execution plan cua cac truy van tim kiem co tinh chon loc cao. Ket qua cho thay SQL Server su dung `Index Seek` tren cac chi muc `ux_gia_su_email`, `ux_hoc_vien_sdt` va `ix_yeu_cau_trang_thai`, giup toi uu truy van va giam quet toan bang.

### 3.5 Anh minh chung nen chup

- Execution Plan cua 3 truy van
- Phan text hien `Index Seek`

## 4. 4.3 View

### 4.1 Muc tieu

Kiem tra cac view tong hop du lieu dung voi cac bang goc.

### 4.2 Cach thuc hien

```sql
SELECT ma_yeu_cau, tieu_de, ten_hoc_vien, so_luong_ung_tuyen
FROM vw_yeu_cau_dang_mo
WHERE ma_yeu_cau = 'YC_T02';

SELECT ma_gia_su, ho_ten, diem_danh_gia_tb, so_lop_dang_day, so_lop_da_nhan
FROM vw_gia_su_tong_hop
WHERE ma_gia_su = 'GS_T01';

SELECT ma_lop, ten_gia_su, ten_hoc_vien, so_lich_hoc, so_buoi_da_hoc
FROM vw_lop_hoc_chi_tiet
WHERE ma_lop = 'L_T01';

SELECT ma_gia_su, ma_lop, khoang_thoi_gian
FROM vw_lich_trinh_gia_su
WHERE ma_gia_su = 'GS_T01';

SELECT *
FROM vw_thong_ke_doanh_thu
WHERE nam = YEAR(GETDATE()) AND thang = MONTH(GETDATE());
GO
```

### 4.3 Ket qua mong doi

- `vw_yeu_cau_dang_mo` chi hien yeu cau con mo
- `vw_gia_su_tong_hop` hien dung diem trung binh, so lop dang day
- `vw_lop_hoc_chi_tiet` join dung gia su, hoc vien, lop hoc
- `vw_lich_trinh_gia_su` hien dung khung gio
- `vw_thong_ke_doanh_thu` tong hop dung doanh thu va hoa hong

### 4.4 Cach viet bao cao

> Nhom kiem thu cac view bang cach doi chieu du lieu tra ve voi cac bang goc trong he thong. Ket qua cho thay cac view tong hop du lieu dung theo nghiep vu, dac biet o cac phep join, cot tinh toan va dieu kien loc du lieu.

## 5. 4.4 Store Procedure

### 5.1 Muc tieu

Kiem tra luong nghiep vu chinh:

- Tao yeu cau lop
- Gia su ung tuyen
- Hoc vien chon gia su
- Tao lop hoc
- Danh gia
- Diem danh
- Ghi nhan thanh toan

### 5.2 Thu tu kiem thu

Nen chay theo thu tu nay:

1. `sp_tao_yeu_cau_lop`
2. `sp_ung_tuyen`
3. `sp_chon_gia_su`
4. `sp_tao_lop_hoc`
5. `sp_danh_gia`
6. `sp_diem_danh`
7. `sp_ghi_nhan_thanh_toan`
8. `sp_toggle_trong_lich`

### 5.3 Cac test chinh

#### SP-01 Tao yeu cau lop

```sql
EXEC dbo.sp_tao_yeu_cau_lop
    @p_ma_yeu_cau = 'YC_T01',
    @p_ma_hoc_vien = 'HV_T01',
    @p_tieu_de = N'Can gia su Toan 11',
    @p_mo_ta = N'Can on tap Toan hoc ky 2',
    @p_tien_hoc_phi = 200000,
    @p_dia_chi = N'Quan 1, TP HCM',
    @p_hinh_thuc_hoc = 'Offline',
    @p_so_buoi_tuan = 2,
    @p_thoi_gian_mong_muon = N'Toi thu 2 va thu 4';

SELECT ma_yeu_cau, ma_hoc_vien, trang_thai
FROM yeu_cau_lop
WHERE ma_yeu_cau = 'YC_T01';
GO
```

Ket qua mong doi:
- Tao duoc `YC_T01`
- `trang_thai = open`

#### SP-02 Gia su ung tuyen

```sql
EXEC dbo.sp_ung_tuyen
    @p_ma_ung_tuyen = 'UT_T01',
    @p_ma_yeu_cau = 'YC_T01',
    @p_ma_gia_su = 'GS_T01',
    @p_thu_nhap_mong_muon = 180000,
    @p_loi_nhan = N'Toi co kinh nghiem day Toan 11';

SELECT ma_ung_tuyen, ma_yeu_cau, ma_gia_su, trang_thai
FROM ung_tuyen
WHERE ma_ung_tuyen = 'UT_T01';
GO
```

Ket qua mong doi:
- Tao duoc `UT_T01`
- `trang_thai = pending`

#### SP-03 Chon gia su

```sql
EXEC dbo.sp_chon_gia_su
    @p_ma_yeu_cau = 'YC_T01',
    @p_ma_gia_su = 'GS_T01';

SELECT ma_yeu_cau, ma_gia_su_duoc_chon, trang_thai
FROM yeu_cau_lop
WHERE ma_yeu_cau = 'YC_T01';
GO
```

Ket qua mong doi:
- `trang_thai = closed`
- `ma_gia_su_duoc_chon = GS_T01`

#### SP-04 Tao lop hoc

```sql
EXEC dbo.sp_tao_lop_hoc
    @p_ma_lop = 'L_T01',
    @p_ma_yeu_cau = 'YC_T01',
    @p_ngay_bat_dau = '2026-06-01',
    @p_tong_so_buoi = 24;

SELECT ma_lop, ma_gia_su, ma_hoc_vien, trang_thai
FROM lop_hoc
WHERE ma_lop = 'L_T01';

SELECT ma_dang_ky, ma_lop, ma_hoc_vien, trang_thai
FROM dang_ky
WHERE ma_dang_ky = 'DK_L_T01';
GO
```

Ket qua mong doi:
- Tao duoc `L_T01`
- Tao duoc `DK_L_T01`

#### SP-05 Danh gia

```sql
EXEC dbo.sp_danh_gia
    @p_ma_danh_gia = 'DG_T01',
    @p_ma_dang_ky = 'DK_L_T01',
    @p_diem_sao = 5,
    @p_nhan_xet = N'Gia su day de hieu';

SELECT * FROM danh_gia WHERE ma_danh_gia = 'DG_T01';
GO
```

#### SP-06 Diem danh

```sql
EXEC dbo.sp_diem_danh
    @p_ma_buoi_hoc = 'BH_T01',
    @p_ma_dang_ky = 'DK_L_T01',
    @p_trang_thai = 'CoMat',
    @p_so_phut_hoc = 120;

SELECT * FROM diem_danh WHERE ma_buoi_hoc = 'BH_T01';
GO
```

#### SP-07 Ghi nhan thanh toan

```sql
EXEC dbo.sp_ghi_nhan_thanh_toan
    @p_ma_giao_dich = 'GD_T01',
    @p_ma_dang_ky = 'DK_L_T01',
    @p_ma_tk_hv = 'TKHV_T01',
    @p_ma_tk_gs = 'TKGS_T01',
    @p_tong_tien = 200000,
    @p_ty_le = 15,
    @p_loai_giao_dich = 'ThanhToanThang';

SELECT ma_giao_dich, tong_tien_thu, phi_hoa_hong, so_tien_gia_su_nhan
FROM giao_dich
WHERE ma_giao_dich = 'GD_T01';
GO
```

Ket qua mong doi:
- `phi_hoa_hong = 30000`
- `so_tien_gia_su_nhan = 170000`

#### SP-08 Toggle trong lich

```sql
EXEC dbo.sp_toggle_trong_lich
    @p_ma_gia_su = 'GS_T01',
    @p_trong_lich = 0;

SELECT ma_gia_su, trong_lich
FROM gia_su
WHERE ma_gia_su = 'GS_T01';
GO
```

### 5.4 Cach viet bao cao

> Nhom kiem thu cac stored procedure theo dung trinh tu nghiep vu cua he thong. Ket qua cho thay cac thu tuc tao moi, cap nhat va kiem tra du lieu deu hoat dong dung voi yeu cau bai toan, dong thoi dam bao tinh toan ven cua du lieu trong qua trinh xu ly.

## 6. 4.5 Function

### 6.1 Muc tieu

Kiem tra cac ham tinh toan va ham ho tro trong he thong.

### 6.2 Cach thuc hien

```sql
SELECT dbo.fn_tinh_diem_tb_gia_su('GS_T01') AS diem_tb_gia_su;
SELECT dbo.fn_dem_lop_dang_day('GS_T01') AS so_lop_dang_day;
SELECT dbo.fn_doanh_thu_gia_su('GS_T01', MONTH(GETDATE()), YEAR(GETDATE())) AS doanh_thu_gia_su;
SELECT dbo.fn_hoc_vien_hop_le('HV_T01') AS hoc_vien_hop_le;
SELECT dbo.fn_format_gio_hoc('18:00', '20:00') AS khung_gio;
SELECT dbo.fn_kiem_tra_trung_lich('GS_T01', 1, '18:30', '19:30', NULL) AS trung_lich;
SELECT * FROM dbo.fn_khung_gio_trong('GS_T01', 1);
GO
```

### 6.3 Ket qua mong doi

- Diem trung binh tra ve dung
- So lop dang day dung
- Doanh thu dung
- `fn_kiem_tra_trung_lich` tra `1` neu trung
- `fn_format_gio_hoc` tra chuoi `18:00 - 20:00`

### 6.4 Cach viet bao cao

> Nhom kiem thu function bang cach goi truc tiep ham voi bo du lieu mau va doi chieu ket qua voi tinh toan thu cong. Ket qua cho thay cac function tra ve gia tri dung va ho tro tot cho cac nghiep vu tong hop, kiem tra va hien thi du lieu.

## 7. 4.6 Trigger

### 7.1 Muc tieu

Kiem tra trigger tu dong cap nhat va trigger rang buoc nghiep vu.

### 7.2 Trigger cap nhat thoi gian

```sql
WAITFOR DELAY '00:00:01';
UPDATE hoc_vien
SET dia_chi = N'Quan 10, TP HCM'
WHERE ma_hoc_vien = 'HV_T01';

SELECT ma_hoc_vien, ngay_cap_nhat
FROM hoc_vien
WHERE ma_hoc_vien = 'HV_T01';
GO
```

Ket qua mong doi:
- `ngay_cap_nhat` thay doi

### 7.3 Trigger tao thong bao

```sql
SELECT loai_thong_bao, COUNT(*) AS so_luong
FROM thong_bao
WHERE ma_yeu_cau = 'YC_T01'
GROUP BY loai_thong_bao
ORDER BY loai_thong_bao;
GO
```

Ket qua mong doi:
- Co `UngTuyen`
- Co `DuocChon`
- Co `TuChoi`

### 7.4 Trigger chan loi nghiep vu

#### Sai lop khi diem danh

```sql
BEGIN TRY
    INSERT INTO diem_danh (ma_buoi_hoc, ma_dang_ky, trang_thai, so_phut_hoc)
    VALUES ('BH_T01', 'DK_L_T02', 'CoMat', 120);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS error_message;
END CATCH;
GO
```

#### Sai tai khoan khi giao dich

```sql
BEGIN TRY
    INSERT INTO giao_dich (ma_giao_dich, ma_dang_ky, ma_tk_hv, ma_tk_gs, tong_tien_thu, ty_le_hoa_hong, phi_hoa_hong, so_tien_gia_su_nhan, loai_giao_dich)
    VALUES ('GD_BAD', 'DK_L_T01', 'TKHV_T02', 'TKGS_T01', 200000, 15, 30000, 170000, 'ThanhToanThang');
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS error_message;
END CATCH;
GO
```

#### Trung lich hoc

```sql
BEGIN TRY
    INSERT INTO lich_hoc (ma_lich, ma_lop, thu_trong_tuan, gio_bat_dau, gio_ket_thuc)
    VALUES ('LH_OVER', 'L_T03', 1, '19:00', '21:00');
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS error_message;
END CATCH;
GO
```

#### Trung buoi hoc

```sql
BEGIN TRY
    INSERT INTO buoi_hoc (ma_buoi_hoc, ma_lop, ngay_hoc, gio_bat_dau, gio_ket_thuc, trang_thai)
    VALUES ('BH_OVER', 'L_T03', '2026-06-01', '19:00', '20:30', 'Scheduled');
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS error_message;
END CATCH;
GO
```

### 7.5 Ket qua mong doi

- He thong bao loi dung nghiep vu
- Khong cho chen du lieu sai

### 7.6 Cach viet bao cao

> Nhom kiem thu trigger theo hai huong: trigger cap nhat tu dong va trigger rang buoc nghiep vu. Ket qua cho thay trigger hoat dong dung trong viec cap nhat thoi gian sua doi, tao thong bao tu dong va chan cac truong hop vi pham nghiep vu nhu trung lich, sai lop hoc va sai tai khoan thanh toan.

## 8. 4.7 User

### 8.1 Muc tieu

Kiem tra quyen truy cap cua user chi doc va user nghiep vu.

### 8.2 Cach thuc hien

```sql
IF USER_ID('report_viewer') IS NOT NULL DROP USER report_viewer;
IF USER_ID('report_operator') IS NOT NULL DROP USER report_operator;
GO

CREATE USER report_viewer WITHOUT LOGIN;
CREATE USER report_operator WITHOUT LOGIN;
GO

GRANT SELECT ON dbo.vw_gia_su_tong_hop TO report_viewer;
GRANT SELECT ON dbo.vw_yeu_cau_dang_mo TO report_viewer;
GRANT SELECT ON dbo.gia_su TO report_operator;
GRANT EXECUTE ON dbo.sp_toggle_trong_lich TO report_operator;
GO

EXECUTE AS USER = 'report_viewer';
SELECT TOP 1 ma_gia_su, ho_ten FROM dbo.vw_gia_su_tong_hop;
BEGIN TRY
    EXEC dbo.sp_toggle_trong_lich @p_ma_gia_su = 'GS_T01', @p_trong_lich = 0;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS error_message;
END CATCH;
REVERT;
GO

EXECUTE AS USER = 'report_operator';
EXEC dbo.sp_toggle_trong_lich @p_ma_gia_su = 'GS_T01', @p_trong_lich = 0;
REVERT;
GO
```

### 8.3 Ket qua mong doi

- `report_viewer` xem duoc view
- `report_viewer` khong duoc `EXECUTE`
- `report_operator` goi procedure thanh cong

### 8.4 Cach viet bao cao

> Nhom kiem thu phan quyen bang cach tao hai user co muc quyen khac nhau va dung `EXECUTE AS USER` de mo phong hanh vi truy cap. Ket qua cho thay user chi doc khong the thuc thi procedure cap nhat, trong khi user nghiep vu duoc cap quyen phu hop voi chuc nang he thong.

## 9. 4.8 Sao luu va phuc hoi du lieu

### 9.1 Muc tieu

Kiem tra kha nang backup va restore CSDL.

### 9.2 Lenh mau

Anh sua duong dan phu hop voi may anh roi chay:

```sql
BACKUP DATABASE GiaSuBachKhoa
TO DISK = 'C:\SQLBackup\GiaSuBachKhoa.bak'
WITH INIT;
GO

RESTORE DATABASE GiaSuBachKhoa_RestoreTest
FROM DISK = 'C:\SQLBackup\GiaSuBachKhoa.bak'
WITH REPLACE;
GO
```

### 9.3 Kiem tra sau restore

```sql
USE GiaSuBachKhoa_RestoreTest;
GO

SELECT COUNT(*) AS so_bang
FROM sys.tables;

SELECT COUNT(*) AS so_view
FROM sys.views;

SELECT TOP 5 * FROM hoc_vien;
GO
```

### 9.4 Ket qua mong doi

- Tao duoc file `.bak`
- Restore thanh cong
- CSDL restore truy van duoc

### 9.5 Cach viet bao cao

> Nhom tien hanh kiem thu tinh san sang cua ban sao luu bang cach backup CSDL hien tai va restore sang mot CSDL moi. Ket qua cho thay he thong co kha nang khoi phuc du lieu va tiep tuc truy van binh thuong sau khi phuc hoi.

## 10. 4.9 Quan ly bao mat va nguoi dung

Muc `4.9` trong mau bao cao nghieng nhieu hon ve app va van hanh. Neu anh muon viet theo huong CSDL + he thong, co the tach thanh 3 nhom kiem thu sau.

### 10.1 Kiem thu phan quyen truy cap

Su dung lai ket qua o muc `4.7`:

- User chi doc chi duoc xem
- User nghiep vu duoc thuc thi procedure
- Hanh vi bi tu choi duoc ghi nhan ro

### 10.2 Kiem thu bao mat du lieu dau vao

Noi dung viet:

> Cac du lieu dau vao duoc rang buoc bang khoa ngoai, khoa chinh, unique constraint, check constraint va trigger nghiep vu. Trong qua trinh kiem thu, cac thao tac chen du lieu sai quan he hoac sai nghiep vu deu bi tu choi boi he thong.

Minh chung:

- Loi FK khi chen `yeu_cau_mon` khong ton tai `ma_yeu_cau`
- Loi trigger khi diem danh sai lop
- Loi trigger khi trung lich

### 10.3 Kiem thu audit va thong bao

Noi dung viet:

> He thong tu dong tao thong bao khi phat sinh ung tuyen moi va khi hoc vien chon gia su. Viec nay giup tang tinh minh bach va kha nang theo doi luong nghiep vu.

Minh chung:

```sql
SELECT loai_thong_bao, ma_yeu_cau, ngay_tao
FROM thong_bao
WHERE ma_yeu_cau = 'YC_T01'
ORDER BY ngay_tao;
GO
```

## 11. Thu tu chup anh de lam bao cao nhanh

Neu anh muon lam nhanh, chup theo thu tu nay:

1. Buoc tao `YC_T01`
2. Buoc ung tuyen `UT_T01`, `UT_T02`
3. Buoc chon gia su
4. Buoc tao lop hoc `L_T01`
5. Buoc ghi nhan thanh toan `GD_T01`
6. Execution Plan cua index
7. Ket qua 1 view tong hop
8. Ket qua 1 function
9. 1 loi trigger
10. 1 loi phan quyen user
11. Lenh backup / restore

## 12. Ghi chu cuoi

- Neu muon chay tat ca mot lan: dung [kiem_thu_chuong4.sql](</C:/Web gia sư/kiem_thu_chuong4.sql:1>)
- Neu muon chay rat an toan, tung buoc: dung [kiem_thu_chuong4_tung_buoc.md](</C:/Web gia sư/kiem_thu_chuong4_tung_buoc.md:1>)
- Neu gap loi o 1 buoc, dung lai o buoc do, khong chay tiep de tranh loi day chuyen
