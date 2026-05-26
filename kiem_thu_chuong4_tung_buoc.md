# Kiem thu Chuong 4 tung buoc

Tai lieu nay dung de anh chay tung buoc trong SSMS. Khong chay het mot lan. Chay xong moi buoc, neu ket qua dung thi moi sang buoc tiep theo.

## Buoc 0: Sua tuong thich schema cu

Chay truoc 1 lan:

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

Ket qua mong doi:
- Khong bao loi.

## Buoc 1: Don du lieu test cu

```sql
USE GiaSuBachKhoa;
GO

SET NOCOUNT ON;
SET DATEFIRST 1;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

DELETE FROM diem_danh WHERE ma_buoi_hoc IN ('BH_T01', 'BH_OVER');
DELETE FROM buoi_hoc WHERE ma_buoi_hoc IN ('BH_T01', 'BH_OVER');
DELETE FROM lich_hoc WHERE ma_lich IN ('LH_T01', 'LH_OVER');
DELETE FROM giao_dich WHERE ma_giao_dich IN ('GD_T01', 'GD_BAD');
DELETE FROM danh_gia WHERE ma_danh_gia IN ('DG_T01');
DELETE FROM thong_bao WHERE ma_yeu_cau IN ('YC_T01', 'YC_T02');
DELETE FROM dang_ky WHERE ma_dang_ky IN ('DK_L_T01', 'DK_L_T02', 'DK_L_T03');
DELETE FROM lop_hoc_mon WHERE ma_lop IN ('L_T01', 'L_T02', 'L_T03');
DELETE FROM buoi_hoc WHERE ma_lop IN ('L_T01', 'L_T02', 'L_T03');
DELETE FROM lich_hoc WHERE ma_lop IN ('L_T01', 'L_T02', 'L_T03');
DELETE FROM lop_hoc WHERE ma_lop IN ('L_T01', 'L_T02', 'L_T03');
DELETE FROM ung_tuyen WHERE ma_ung_tuyen IN ('UT_T01', 'UT_T02');
DELETE FROM yeu_cau_mon WHERE ma_yeu_cau IN ('YC_T01', 'YC_T02');
DELETE FROM yeu_cau_lop WHERE ma_yeu_cau IN ('YC_T01', 'YC_T02');
DELETE FROM tai_khoan_hv WHERE ma_tk_hv IN ('TKHV_T01', 'TKHV_T02');
DELETE FROM tai_khoan_gs WHERE ma_tk_gs IN ('TKGS_T01', 'TKGS_T02');
DELETE FROM gia_su_mon_hoc WHERE ma_gia_su IN ('GS_T01', 'GS_T02') OR ma_mon IN ('MON_T01', 'MON_T02');
DELETE FROM mon_hoc WHERE ma_mon IN ('MON_T01', 'MON_T02');
DELETE FROM hoc_vien WHERE ma_hoc_vien IN ('HV_T01', 'HV_T02');
DELETE FROM gia_su WHERE ma_gia_su IN ('GS_T01', 'GS_T02');
GO
```

Ket qua mong doi:
- Khong bao loi.

## Buoc 2: Tao du lieu nen

```sql
INSERT INTO hoc_vien (ma_hoc_vien, ho_ten, ngay_sinh, gioi_tinh, so_dien_thoai, email, dia_chi, khoi_hien_tai)
VALUES
('HV_T01', N'Nguyen Van Test 1', '2008-01-15', N'Nam', '0900000001', 'hv1@test.local', N'Quan 1, TP HCM', N'Lop 11'),
('HV_T02', N'Tran Thi Test 2', '2009-03-20', N'Nu', '0900000002', 'hv2@test.local', N'Quan 3, TP HCM', N'Lop 10');

INSERT INTO gia_su (ma_gia_su, ho_ten, ngay_sinh, gioi_tinh, so_dien_thoai, email, dia_chi, trinh_do, gioi_thieu, trong_lich)
VALUES
('GS_T01', N'Le Gia Su 1', '1999-05-01', N'Nam', '0910000001', 'gs1@test.local', N'Quan 7, TP HCM', N'Dai hoc Su pham', N'Gia su Toan', 1),
('GS_T02', N'Pham Gia Su 2', '1998-08-10', N'Nu', '0910000002', 'gs2@test.local', N'Thu Duc, TP HCM', N'Dai hoc KHTN', N'Gia su Anh van', 1);

INSERT INTO mon_hoc (ma_mon, ten_mon, cap_hoc, mo_ta)
VALUES
('MON_T01', N'Toan', N'THPT', N'Mon Toan THPT'),
('MON_T02', N'Tieng Anh', N'THPT', N'Mon Tieng Anh THPT');

INSERT INTO gia_su_mon_hoc (ma_gia_su, ma_mon, nam_kinh_nghiem, muc_do_thanh_thao)
VALUES
('GS_T01', 'MON_T01', 3, N'Tot'),
('GS_T02', 'MON_T02', 2, N'Kha');

INSERT INTO tai_khoan_hv (ma_tk_hv, ma_hoc_vien, so_tai_khoan, nha_cung_cap, loai_phuong_thuc, ten_chu_tk, la_mac_dinh)
VALUES
('TKHV_T01', 'HV_T01', '100000001', N'VCB', 'Bank', N'NGUYEN VAN TEST 1', 1),
('TKHV_T02', 'HV_T02', '100000002', N'ACB', 'Bank', N'TRAN THI TEST 2', 1);

INSERT INTO tai_khoan_gs (ma_tk_gs, ma_gia_su, so_tai_khoan, nha_cung_cap, loai_phuong_thuc, ten_chu_tk, la_mac_dinh)
VALUES
('TKGS_T01', 'GS_T01', '200000001', N'MBBank', 'Bank', N'LE GIA SU 1', 1),
('TKGS_T02', 'GS_T02', '200000002', N'TPB', 'Bank', N'PHAM GIA SU 2', 1);
GO
```

Check:

```sql
SELECT * FROM hoc_vien WHERE ma_hoc_vien IN ('HV_T01', 'HV_T02');
SELECT * FROM gia_su WHERE ma_gia_su IN ('GS_T01', 'GS_T02');
SELECT * FROM mon_hoc WHERE ma_mon IN ('MON_T01', 'MON_T02');
```

Ket qua mong doi:
- Moi bang co du 2 dong.

## Buoc 3: Test 4.4.1 tao yeu cau lop

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
- Co 1 dong `YC_T01`
- `ma_hoc_vien = HV_T01`
- `trang_thai = open`

Neu buoc nay loi thi dung lai, khong chay buoc 4.

## Buoc 4: Gan mon hoc cho yeu cau

```sql
INSERT INTO yeu_cau_mon (ma_yeu_cau, ma_mon, vai_tro_mon)
VALUES ('YC_T01', 'MON_T01', N'Chinh');

SELECT * FROM yeu_cau_mon WHERE ma_yeu_cau = 'YC_T01';
GO
```

Ket qua mong doi:
- Co 1 dong `YC_T01 - MON_T01`

## Buoc 5: Tao them yeu cau thu hai

```sql
EXEC dbo.sp_tao_yeu_cau_lop
    @p_ma_yeu_cau = 'YC_T02',
    @p_ma_hoc_vien = 'HV_T02',
    @p_tieu_de = N'Can gia su Tieng Anh 10',
    @p_mo_ta = N'Can luyen ngu phap va giao tiep',
    @p_tien_hoc_phi = 180000,
    @p_dia_chi = N'Quan 3, TP HCM',
    @p_hinh_thuc_hoc = 'Online',
    @p_so_buoi_tuan = 3,
    @p_thoi_gian_mong_muon = N'Toi thu 3, 5, 7';

INSERT INTO yeu_cau_mon (ma_yeu_cau, ma_mon, vai_tro_mon)
VALUES ('YC_T02', 'MON_T02', N'Chinh');

SELECT ma_yeu_cau, trang_thai FROM yeu_cau_lop WHERE ma_yeu_cau = 'YC_T02';
GO
```

## Buoc 6: Test 4.4.2 gia su ung tuyen

```sql
EXEC dbo.sp_ung_tuyen
    @p_ma_ung_tuyen = 'UT_T01',
    @p_ma_yeu_cau = 'YC_T01',
    @p_ma_gia_su = 'GS_T01',
    @p_thu_nhap_mong_muon = 180000,
    @p_loi_nhan = N'Toi co kinh nghiem day Toan 11';

EXEC dbo.sp_ung_tuyen
    @p_ma_ung_tuyen = 'UT_T02',
    @p_ma_yeu_cau = 'YC_T01',
    @p_ma_gia_su = 'GS_T02',
    @p_thu_nhap_mong_muon = 175000,
    @p_loi_nhan = N'Toi san sang day online';

SELECT ma_ung_tuyen, ma_yeu_cau, ma_gia_su, trang_thai
FROM ung_tuyen
WHERE ma_yeu_cau = 'YC_T01'
ORDER BY ma_ung_tuyen;
GO
```

Ket qua mong doi:
- Co 2 dong `UT_T01`, `UT_T02`
- `trang_thai = pending`

## Buoc 7: Test trigger thong bao ung tuyen

```sql
SELECT loai_thong_bao, ma_hoc_vien, ma_yeu_cau
FROM thong_bao
WHERE ma_yeu_cau = 'YC_T01'
ORDER BY ngay_tao;
GO
```

Ket qua mong doi:
- Co 2 thong bao `UngTuyen`

## Buoc 8: Test 4.4.3 chon gia su

```sql
EXEC dbo.sp_chon_gia_su
    @p_ma_yeu_cau = 'YC_T01',
    @p_ma_gia_su = 'GS_T01';

SELECT ma_yeu_cau, ma_gia_su_duoc_chon, trang_thai
FROM yeu_cau_lop
WHERE ma_yeu_cau = 'YC_T01';

SELECT ma_ung_tuyen, ma_gia_su, trang_thai
FROM ung_tuyen
WHERE ma_yeu_cau = 'YC_T01'
ORDER BY ma_ung_tuyen;
GO
```

Ket qua mong doi:
- `yeu_cau_lop.trang_thai = closed`
- `GS_T01 = accepted`
- `GS_T02 = rejected`

## Buoc 9: Test tao lop hoc

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

## Buoc 10: Tao lich hoc va buoi hoc

```sql
INSERT INTO lich_hoc (ma_lich, ma_lop, thu_trong_tuan, gio_bat_dau, gio_ket_thuc)
VALUES ('LH_T01', 'L_T01', 1, '18:00', '20:00');

INSERT INTO buoi_hoc (ma_buoi_hoc, ma_lop, ma_lich, ngay_hoc, gio_bat_dau, gio_ket_thuc, trang_thai)
VALUES ('BH_T01', 'L_T01', 'LH_T01', '2026-06-01', '18:00', '20:00', 'Scheduled');

SELECT * FROM lich_hoc WHERE ma_lich = 'LH_T01';
SELECT * FROM buoi_hoc WHERE ma_buoi_hoc = 'BH_T01';
GO
```

## Buoc 11: Test danh gia

```sql
EXEC dbo.sp_danh_gia
    @p_ma_danh_gia = 'DG_T01',
    @p_ma_dang_ky = 'DK_L_T01',
    @p_diem_sao = 5,
    @p_nhan_xet = N'Gia su day de hieu';

SELECT * FROM danh_gia WHERE ma_danh_gia = 'DG_T01';
GO
```

## Buoc 12: Test diem danh

```sql
EXEC dbo.sp_diem_danh
    @p_ma_buoi_hoc = 'BH_T01',
    @p_ma_dang_ky = 'DK_L_T01',
    @p_trang_thai = 'CoMat',
    @p_so_phut_hoc = 120;

SELECT * FROM diem_danh WHERE ma_buoi_hoc = 'BH_T01';
GO
```

## Buoc 13: Test thanh toan

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

## Buoc 14: Test function

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

## Buoc 15: Test view

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

## Buoc 16: Test index

Bat `Include Actual Execution Plan`, sau do chay:

```sql
SELECT ma_gia_su FROM gia_su WHERE email = 'gs1@test.local';
SELECT ma_hoc_vien FROM hoc_vien WHERE so_dien_thoai = '0900000001';
SELECT ma_yeu_cau, ngay_yeu_cau FROM yeu_cau_lop WHERE trang_thai = 'open' ORDER BY ngay_yeu_cau DESC;
GO
```

Ket qua mong doi:
- Plan hien `Index Seek`

## Buoc 17: Test trigger loi nghiep vu

```sql
INSERT INTO lop_hoc (ma_lop, ma_gia_su, ma_hoc_vien, ma_yeu_cau, hoc_phi, dia_chi, hinh_thuc_day, ngay_bat_dau, trang_thai, so_hv_toi_da, tong_so_buoi)
VALUES ('L_T02', 'GS_T02', 'HV_T02', 'YC_T02', 180000, N'Online', 'Online', '2026-06-02', 'Cancelled', 1, 12);

INSERT INTO dang_ky (ma_dang_ky, ma_hoc_vien, ma_lop, trang_thai)
VALUES ('DK_L_T02', 'HV_T02', 'L_T02', 'Confirmed');
GO
```

Test sai lop khi diem danh:

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

Test trung lich hoc:

```sql
INSERT INTO lop_hoc (ma_lop, ma_gia_su, ma_hoc_vien, hoc_phi, dia_chi, hinh_thuc_day, ngay_bat_dau, trang_thai, so_hv_toi_da, tong_so_buoi)
VALUES ('L_T03', 'GS_T01', 'HV_T02', 150000, N'Quan 5', 'Offline', '2026-06-01', 'Cancelled', 1, 10);
GO

BEGIN TRY
    INSERT INTO lich_hoc (ma_lich, ma_lop, thu_trong_tuan, gio_bat_dau, gio_ket_thuc)
    VALUES ('LH_OVER', 'L_T03', 1, '19:00', '21:00');
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS error_message;
END CATCH;
GO
```

## Buoc 18: Test user

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

## Cach lam voi em

Neu anh muon lam dung nghia "tung kiem thu 1", minh se di theo cach nay:

1. Anh chay `Buoc 0`, `Buoc 1`, `Buoc 2`.
2. Anh chay `Buoc 3`.
3. Gui cho em anh man hinh hoac text ket qua cua `Buoc 3`.
4. Em se check xong roi moi dua tiep `Buoc 4`.
