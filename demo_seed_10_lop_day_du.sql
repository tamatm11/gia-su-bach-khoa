USE GiaSuBachKhoa;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'dbo.lich_hoc', N'U') IS NULL
   OR OBJECT_ID(N'dbo.buoi_hoc', N'U') IS NULL
   OR OBJECT_ID(N'dbo.dang_ky', N'U') IS NULL
   OR OBJECT_ID(N'dbo.giao_dich', N'U') IS NULL
   OR OBJECT_ID(N'dbo.danh_gia', N'U') IS NULL
   OR OBJECT_ID(N'dbo.diem_danh', N'U') IS NULL
   OR OBJECT_ID(N'dbo.lich_su_day_hoc', N'U') IS NULL
   OR OBJECT_ID(N'dbo.lich_su_thue_gia_su', N'U') IS NULL
BEGIN
    RAISERROR(
        'Schema hien tai chua day du bang lich/day/hoc. Hay chay file Nhom_12_QuanLyGiaSuHocVien.sql tren DB demo truoc, roi chay file seed nay.',
        16,
        1
    );
    RETURN;
END;
GO

/* ============================================================
   Demo seed: 10 lop hoc co day du hoc vien, gia su, mon hoc,
   yeu cau, ung tuyen, lich hoc, buoi hoc, diem danh,
   thanh toan, danh gia va lich su.

   Co the chay lai nhieu lan. Phan cleanup se xoa du lieu
   co prefix *_D* truoc khi insert lai.
   ============================================================ */

BEGIN TRY
    BEGIN TRANSACTION;

    DELETE FROM diem_danh
    WHERE ma_buoi_hoc LIKE 'BH_D%' OR ma_dang_ky LIKE 'DK_D%';

    DELETE FROM danh_gia
    WHERE ma_danh_gia LIKE 'DG_D%' OR ma_dang_ky LIKE 'DK_D%';

    DELETE FROM giao_dich
    WHERE ma_giao_dich LIKE 'GD_D%' OR ma_dang_ky LIKE 'DK_D%';

    DELETE FROM buoi_hoc
    WHERE ma_buoi_hoc LIKE 'BH_D%' OR ma_lop LIKE 'LOP_D%' OR ma_lich LIKE 'LICH_D%';

    DELETE FROM lich_hoc
    WHERE ma_lich LIKE 'LICH_D%' OR ma_lop LIKE 'LOP_D%';

    DELETE FROM lop_hoc_mon
    WHERE ma_lop LIKE 'LOP_D%';

    DELETE FROM dang_ky
    WHERE ma_dang_ky LIKE 'DK_D%' OR ma_lop LIKE 'LOP_D%';

    DELETE FROM lich_su_day_hoc
    WHERE ma_lich_su_day LIKE 'LSD_D%' OR ma_lop LIKE 'LOP_D%';

    DELETE FROM lich_su_thue_gia_su
    WHERE ma_lich_su_thue LIKE 'LST_D%' OR ma_lop LIKE 'LOP_D%' OR ma_yeu_cau LIKE 'YC_D%';

    DELETE FROM thong_bao
    WHERE ma_yeu_cau LIKE 'YC_D%' OR ma_lop LIKE 'LOP_D%' OR ma_gia_su LIKE 'GS_D%' OR ma_hoc_vien LIKE 'HV_D%';

    DELETE FROM audit_log
    WHERE record_id LIKE 'YC_D%' OR record_id LIKE 'LOP_D%';

    DELETE FROM lop_hoc
    WHERE ma_lop LIKE 'LOP_D%';

    DELETE FROM ung_tuyen
    WHERE ma_ung_tuyen LIKE 'UT_D%' OR ma_yeu_cau LIKE 'YC_D%';

    DELETE FROM yeu_cau_mon
    WHERE ma_yeu_cau LIKE 'YC_D%';

    DELETE FROM yeu_cau_lop
    WHERE ma_yeu_cau LIKE 'YC_D%';

    DELETE FROM tai_khoan_hv
    WHERE ma_tk_hv LIKE 'TKHV_D%';

    DELETE FROM tai_khoan_gs
    WHERE ma_tk_gs LIKE 'TKGS_D%';

    DELETE FROM gia_su_mon_hoc
    WHERE ma_gia_su LIKE 'GS_D%' OR ma_mon LIKE 'MON_D%';

    DELETE FROM gia_su
    WHERE ma_gia_su LIKE 'GS_D%';

    DELETE FROM hoc_vien
    WHERE ma_hoc_vien LIKE 'HV_D%';

    DELETE FROM mon_hoc
    WHERE ma_mon LIKE 'MON_D%';

    /* 1. Danh muc mon hoc */
    INSERT INTO mon_hoc (ma_mon, ten_mon, cap_hoc, mo_ta)
    VALUES
    ('MON_D01', N'Toan',       N'THPT', N'Toan lop 10-12'),
    ('MON_D02', N'Tieng Anh',  N'THPT', N'Tieng Anh giao tiep va luyen thi'),
    ('MON_D03', N'Vat Ly',     N'THPT', N'Vat ly co ban va nang cao'),
    ('MON_D04', N'Hoa Hoc',    N'THPT', N'Hoa hoc lop 10-12'),
    ('MON_D05', N'Ngu Van',    N'THPT', N'Ngu van va viet bai nghi luan'),
    ('MON_D06', N'Sinh Hoc',   N'THPT', N'Sinh hoc lop 10-12');

    /* 2. Hoc vien demo */
    INSERT INTO hoc_vien (
        ma_hoc_vien, ho_ten, ngay_sinh, gioi_tinh,
        so_dien_thoai, email, dia_chi, khoi_hien_tai
    )
    VALUES
    ('HV_D01', N'Nguyen An Minh',    '2008-01-12', N'Nam', '0988000001', 'hv.demo01@test.local', N'Quan 1, TP HCM',      N'Lop 12'),
    ('HV_D02', N'Tran Bao Ngoc',     '2009-02-14', N'Nu',  '0988000002', 'hv.demo02@test.local', N'Quan 3, TP HCM',      N'Lop 11'),
    ('HV_D03', N'Le Gia Huy',        '2008-04-20', N'Nam', '0988000003', 'hv.demo03@test.local', N'Binh Thanh, TP HCM',  N'Lop 12'),
    ('HV_D04', N'Pham Khanh Linh',   '2010-06-01', N'Nu',  '0988000004', 'hv.demo04@test.local', N'Go Vap, TP HCM',      N'Lop 10'),
    ('HV_D05', N'Vo Thanh Dat',      '2009-07-09', N'Nam', '0988000005', 'hv.demo05@test.local', N'Quan 7, TP HCM',      N'Lop 11'),
    ('HV_D06', N'Dang My Anh',       '2008-09-11', N'Nu',  '0988000006', 'hv.demo06@test.local', N'Thu Duc, TP HCM',     N'Lop 12'),
    ('HV_D07', N'Hoang Nhat Khang',  '2011-10-16', N'Nam', '0988000007', 'hv.demo07@test.local', N'Quan 10, TP HCM',     N'Lop 9'),
    ('HV_D08', N'Bui Minh Chau',     '2009-12-05', N'Nu',  '0988000008', 'hv.demo08@test.local', N'Quan 5, TP HCM',      N'Lop 11'),
    ('HV_D09', N'Do Quoc Bao',       '2008-03-19', N'Nam', '0988000009', 'hv.demo09@test.local', N'Phu Nhuan, TP HCM',   N'Lop 12'),
    ('HV_D10', N'Trinh Ha Vy',       '2010-05-25', N'Nu',  '0988000010', 'hv.demo10@test.local', N'Tan Binh, TP HCM',    N'Lop 10');

    /* 3. Gia su demo */
    INSERT INTO gia_su (
        ma_gia_su, ho_ten, ngay_sinh, gioi_tinh,
        so_dien_thoai, email, dia_chi, trinh_do, gioi_thieu, trong_lich
    )
    VALUES
    ('GS_D01', N'Tran Minh Khoa',  '1998-03-02', N'Nam', '0977000001', 'gs.demo01@test.local', N'Quan 7, TP HCM',     N'Cu nhan Su pham Toan',       N'Chuyen Toan va Vat Ly THPT.', 1),
    ('GS_D02', N'Nguyen Ha Linh',  '1997-08-18', N'Nu',  '0977000002', 'gs.demo02@test.local', N'Quan 3, TP HCM',     N'Cu nhan Ngon ngu Anh',       N'Luyen thi tieng Anh va ngu van.', 1),
    ('GS_D03', N'Pham Quang Huy',  '1996-11-09', N'Nam', '0977000003', 'gs.demo03@test.local', N'Thu Duc, TP HCM',    N'Thac si Hoa Sinh',           N'Day Hoa va Sinh theo lo trinh.', 1),
    ('GS_D04', N'Le Thu Trang',    '1999-01-21', N'Nu',  '0977000004', 'gs.demo04@test.local', N'Binh Thanh, TP HCM', N'Sinh vien nam cuoi Bach Khoa', N'Manh Toan ung dung va giao tiep Anh.', 1),
    ('GS_D05', N'Vo Duc Anh',      '1995-05-30', N'Nam', '0977000005', 'gs.demo05@test.local', N'Go Vap, TP HCM',     N'Giao vien tu do',            N'Co kinh nghiem day Vat Ly, Hoa Hoc.', 1);

    /* 4. Mon ma gia su co the day */
    INSERT INTO gia_su_mon_hoc (ma_gia_su, ma_mon, nam_kinh_nghiem, muc_do_thanh_thao, chung_chi)
    VALUES
    ('GS_D01', 'MON_D01', 5, N'Gioi', N'Chung chi boi duong hoc sinh gioi Toan'),
    ('GS_D01', 'MON_D03', 4, N'Gioi', N'Kinh nghiem luyen thi Vat Ly THPT'),
    ('GS_D02', 'MON_D02', 6, N'Gioi', N'IELTS 7.5'),
    ('GS_D02', 'MON_D05', 3, N'Kha',  N'Kinh nghiem on thi van vao 10'),
    ('GS_D03', 'MON_D04', 5, N'Gioi', N'Thac si Hoa Sinh'),
    ('GS_D03', 'MON_D06', 4, N'Gioi', N'Thac si Hoa Sinh'),
    ('GS_D04', 'MON_D01', 3, N'Kha',  N'GPA Toan cao cap 3.7'),
    ('GS_D04', 'MON_D02', 3, N'Kha',  N'TOEIC 850'),
    ('GS_D05', 'MON_D03', 7, N'Gioi', N'Giao vien Vat Ly tu do'),
    ('GS_D05', 'MON_D04', 5, N'Kha',  N'Luyen thi Hoa co ban');

    /* 5. Tai khoan thanh toan */
    INSERT INTO tai_khoan_hv (ma_tk_hv, ma_hoc_vien, so_tai_khoan, nha_cung_cap, loai_phuong_thuc, ten_chu_tk, la_mac_dinh)
    VALUES
    ('TKHV_D01', 'HV_D01', '310000001', N'VCB',    'bank', N'NGUYEN AN MINH',   1),
    ('TKHV_D02', 'HV_D02', '310000002', N'ACB',    'bank', N'TRAN BAO NGOC',    1),
    ('TKHV_D03', 'HV_D03', '310000003', N'MBBank', 'bank', N'LE GIA HUY',       1),
    ('TKHV_D04', 'HV_D04', '310000004', N'TPB',    'bank', N'PHAM KHANH LINH',  1),
    ('TKHV_D05', 'HV_D05', '310000005', N'VCB',    'bank', N'VO THANH DAT',     1),
    ('TKHV_D06', 'HV_D06', '310000006', N'ACB',    'bank', N'DANG MY ANH',      1),
    ('TKHV_D07', 'HV_D07', '310000007', N'MBBank', 'bank', N'HOANG NHAT KHANG', 1),
    ('TKHV_D08', 'HV_D08', '310000008', N'TPB',    'bank', N'BUI MINH CHAU',    1),
    ('TKHV_D09', 'HV_D09', '310000009', N'VCB',    'bank', N'DO QUOC BAO',      1),
    ('TKHV_D10', 'HV_D10', '310000010', N'ACB',    'bank', N'TRINH HA VY',      1);

    INSERT INTO tai_khoan_gs (ma_tk_gs, ma_gia_su, so_tai_khoan, nha_cung_cap, loai_phuong_thuc, ten_chu_tk, la_mac_dinh)
    VALUES
    ('TKGS_D01', 'GS_D01', '410000001', N'MBBank', 'bank', N'TRAN MINH KHOA', 1),
    ('TKGS_D02', 'GS_D02', '410000002', N'TPB',    'bank', N'NGUYEN HA LINH', 1),
    ('TKGS_D03', 'GS_D03', '410000003', N'VCB',    'bank', N'PHAM QUANG HUY', 1),
    ('TKGS_D04', 'GS_D04', '410000004', N'ACB',    'bank', N'LE THU TRANG',   1),
    ('TKGS_D05', 'GS_D05', '410000005', N'MBBank', 'bank', N'VO DUC ANH',     1);

    /* 6. Yeu cau tim gia su */
    INSERT INTO yeu_cau_lop (
        ma_yeu_cau, ma_hoc_vien, tieu_de, mo_ta, tien_hoc_phi,
        dia_chi, hinh_thuc_hoc, so_buoi_tuan, thoi_gian_mong_muon,
        ngay_yeu_cau, trang_thai, ma_gia_su_duoc_chon, ngay_chon_gia_su
    )
    VALUES
    ('YC_D01', 'HV_D01', N'Can gia su Toan lop 12',       N'On thi tot nghiep THPT.',      600000, N'Quan 1, TP HCM',      'offline', 2, N'Thu 2 va thu 4, 18:00-19:30', '2026-05-15 08:00:00', 'approved', 'GS_D01', '2026-05-16 09:00:00'),
    ('YC_D02', 'HV_D02', N'Can gia su Tieng Anh lop 11',  N'Luyen ngu phap va giao tiep.', 550000, N'Quan 3, TP HCM',      'online',  2, N'Thu 3 va thu 5, 18:00-19:30', '2026-05-15 08:10:00', 'approved', 'GS_D02', '2026-05-16 09:10:00'),
    ('YC_D03', 'HV_D03', N'Can gia su Hoa hoc lop 12',    N'On thi dai hoc mon Hoa.',      650000, N'Binh Thanh, TP HCM',  'offline', 2, N'Thu 2 va thu 6, 20:00-21:30', '2026-05-15 08:20:00', 'approved', 'GS_D03', '2026-05-16 09:20:00'),
    ('YC_D04', 'HV_D04', N'Can gia su Toan lop 10',       N'Cung co kien thuc nen.',       700000, N'Go Vap, TP HCM',      'hybrid',  2, N'Thu 4 toi va thu 7 chieu',    '2026-05-15 08:30:00', 'approved', 'GS_D04', '2026-05-16 09:30:00'),
    ('YC_D05', 'HV_D05', N'Can gia su Vat Ly lop 11',     N'Hoc theo chuong trinh tren lop.', 620000, N'Quan 7, TP HCM',   'offline', 2, N'Thu 5 toi va thu 7 sang',      '2026-05-15 08:40:00', 'approved', 'GS_D05', '2026-05-16 09:40:00'),
    ('YC_D06', 'HV_D06', N'Lich su thue Toan da hoan thanh', N'Lop da hoc xong.',          680000, N'Thu Duc, TP HCM',     'offline', 2, N'Thu 3 va thu 6, 17:00-18:30', '2026-01-10 08:00:00', 'approved', 'GS_D01', '2026-01-11 09:00:00'),
    ('YC_D07', 'HV_D07', N'Lich su thue Tieng Anh da xong',  N'Lop da hoc xong.',          500000, N'Quan 10, TP HCM',     'online',  2, N'Cuoi tuan buoi sang',          '2026-01-12 08:00:00', 'approved', 'GS_D02', '2026-01-13 09:00:00'),
    ('YC_D08', 'HV_D08', N'Lich su thue Sinh hoc da xong',   N'Lop da hoc xong.',          580000, N'Quan 5, TP HCM',      'offline', 2, N'Thu 4 va thu 7 buoi sang',    '2026-02-10 08:00:00', 'approved', 'GS_D03', '2026-02-11 09:00:00'),
    ('YC_D09', 'HV_D09', N'Lop sap mo Toan nang cao',        N'Can hoc truoc ky thi.',     750000, N'Phu Nhuan, TP HCM',   'hybrid',  2, N'Thu 3 va thu 5, 20:00-21:30', '2026-05-20 08:00:00', 'approved', 'GS_D04', '2026-05-21 09:00:00'),
    ('YC_D10', 'HV_D10', N'Lop Hoa hoc bi huy',              N'Hoc vien doi lich nen huy.', 640000, N'Tan Binh, TP HCM',  'offline', 2, N'Thu 2 va thu 4, 08:00-09:30', '2026-03-15 08:00:00', 'cancelled', 'GS_D05', '2026-03-16 09:00:00');

    INSERT INTO yeu_cau_mon (ma_yeu_cau, ma_mon, vai_tro_mon, ghi_chu)
    VALUES
    ('YC_D01', 'MON_D01', N'Chinh', N'On thi tot nghiep'),
    ('YC_D02', 'MON_D02', N'Chinh', N'Luyen giao tiep'),
    ('YC_D03', 'MON_D04', N'Chinh', N'Luyen thi dai hoc'),
    ('YC_D04', 'MON_D01', N'Chinh', N'Cung co nen tang'),
    ('YC_D05', 'MON_D03', N'Chinh', N'Ly thuyet va bai tap'),
    ('YC_D06', 'MON_D01', N'Chinh', N'Lop da hoan thanh'),
    ('YC_D07', 'MON_D02', N'Chinh', N'Lop da hoan thanh'),
    ('YC_D08', 'MON_D06', N'Chinh', N'Lop da hoan thanh'),
    ('YC_D09', 'MON_D01', N'Chinh', N'Lop sap mo'),
    ('YC_D09', 'MON_D02', N'Phu',   N'Bo tro tieng Anh hoc thuat'),
    ('YC_D10', 'MON_D04', N'Chinh', N'Lop da huy');

    /* 7. Ung tuyen da duoc chap nhan
       Tam tat trigger thong bao vi trigger hien tai sinh ma_thong_bao dai hon varchar(30). */
    IF OBJECT_ID(N'dbo.tr_ung_tuyen_notify', N'TR') IS NOT NULL
        DISABLE TRIGGER dbo.tr_ung_tuyen_notify ON dbo.ung_tuyen;

    INSERT INTO ung_tuyen (
        ma_ung_tuyen, ma_yeu_cau, ma_gia_su,
        thu_nhap_mong_muon, loi_nhan, trang_thai, ngay_ung_tuyen, ngay_xu_ly
    )
    VALUES
    ('UT_D01', 'YC_D01', 'GS_D01', 500000, N'Em co the day dung khung gio yeu cau.', 'accepted', '2026-05-15 10:00:00', '2026-05-16 09:00:00'),
    ('UT_D02', 'YC_D02', 'GS_D02', 450000, N'Co giao trinh rieng cho lop 11.',       'accepted', '2026-05-15 10:10:00', '2026-05-16 09:10:00'),
    ('UT_D03', 'YC_D03', 'GS_D03', 520000, N'Co kinh nghiem on thi Hoa.',            'accepted', '2026-05-15 10:20:00', '2026-05-16 09:20:00'),
    ('UT_D04', 'YC_D04', 'GS_D04', 560000, N'Co the day hybrid.',                    'accepted', '2026-05-15 10:30:00', '2026-05-16 09:30:00'),
    ('UT_D05', 'YC_D05', 'GS_D05', 500000, N'Day Ly theo dang bai tap.',             'accepted', '2026-05-15 10:40:00', '2026-05-16 09:40:00'),
    ('UT_D06', 'YC_D06', 'GS_D01', 520000, N'Lop da hoan thanh.',                    'accepted', '2026-01-10 10:00:00', '2026-01-11 09:00:00'),
    ('UT_D07', 'YC_D07', 'GS_D02', 400000, N'Lop da hoan thanh.',                    'accepted', '2026-01-12 10:00:00', '2026-01-13 09:00:00'),
    ('UT_D08', 'YC_D08', 'GS_D03', 460000, N'Lop da hoan thanh.',                    'accepted', '2026-02-10 10:00:00', '2026-02-11 09:00:00'),
    ('UT_D09', 'YC_D09', 'GS_D04', 600000, N'Co the bat dau tu dau thang 6.',        'accepted', '2026-05-20 10:00:00', '2026-05-21 09:00:00'),
    ('UT_D10', 'YC_D10', 'GS_D05', 500000, N'Lop bi huy do hoc vien doi lich.',      'accepted', '2026-03-15 10:00:00', '2026-03-16 09:00:00');

    IF OBJECT_ID(N'dbo.tr_ung_tuyen_notify', N'TR') IS NOT NULL
        ENABLE TRIGGER dbo.tr_ung_tuyen_notify ON dbo.ung_tuyen;

    /* 8. Lop hoc */
    INSERT INTO lop_hoc (
        ma_lop, ma_gia_su, ma_hoc_vien, ma_yeu_cau, ma_ung_tuyen,
        hoc_phi, dia_chi, hinh_thuc_day, ngay_bat_dau, ngay_ket_thuc,
        trang_thai, tong_so_buoi
    )
    VALUES
    ('LOP_D01', 'GS_D01', 'HV_D01', 'YC_D01', 'UT_D01', 600000, N'Quan 1, TP HCM',      'offline', '2026-06-01', NULL,         'dang_hoc',   24),
    ('LOP_D02', 'GS_D02', 'HV_D02', 'YC_D02', 'UT_D02', 550000, N'Online qua Google Meet', 'online', '2026-06-02', NULL,      'dang_hoc',   24),
    ('LOP_D03', 'GS_D03', 'HV_D03', 'YC_D03', 'UT_D03', 650000, N'Binh Thanh, TP HCM',  'offline', '2026-06-01', NULL,         'dang_hoc',   24),
    ('LOP_D04', 'GS_D04', 'HV_D04', 'YC_D04', 'UT_D04', 700000, N'Go Vap, TP HCM',      'hybrid',  '2026-06-03', NULL,         'dang_hoc',   20),
    ('LOP_D05', 'GS_D05', 'HV_D05', 'YC_D05', 'UT_D05', 620000, N'Quan 7, TP HCM',      'offline', '2026-06-04', NULL,         'dang_hoc',   20),
    ('LOP_D06', 'GS_D01', 'HV_D06', 'YC_D06', 'UT_D06', 680000, N'Thu Duc, TP HCM',     'offline', '2026-02-03', '2026-03-20', 'hoan_thanh', 16),
    ('LOP_D07', 'GS_D02', 'HV_D07', 'YC_D07', 'UT_D07', 500000, N'Online qua Zoom',     'online',  '2026-02-07', '2026-03-14', 'hoan_thanh', 12),
    ('LOP_D08', 'GS_D03', 'HV_D08', 'YC_D08', 'UT_D08', 580000, N'Quan 5, TP HCM',      'offline', '2026-03-04', '2026-04-18', 'hoan_thanh', 14),
    ('LOP_D09', 'GS_D04', 'HV_D09', 'YC_D09', 'UT_D09', 750000, N'Phu Nhuan, TP HCM',   'hybrid',  '2026-06-02', NULL,         'sapmo',      24),
    ('LOP_D10', 'GS_D05', 'HV_D10', 'YC_D10', 'UT_D10', 640000, N'Tan Binh, TP HCM',    'offline', '2026-04-06', '2026-04-08', 'huy',         2);

    INSERT INTO lop_hoc_mon (ma_lop, ma_mon, vai_tro_mon, so_buoi_du_kien, ghi_chu)
    VALUES
    ('LOP_D01', 'MON_D01', N'Chinh', 24, N'Toan lop 12'),
    ('LOP_D02', 'MON_D02', N'Chinh', 24, N'Tieng Anh lop 11'),
    ('LOP_D03', 'MON_D04', N'Chinh', 24, N'Hoa lop 12'),
    ('LOP_D04', 'MON_D01', N'Chinh', 20, N'Toan lop 10'),
    ('LOP_D05', 'MON_D03', N'Chinh', 20, N'Vat Ly lop 11'),
    ('LOP_D06', 'MON_D01', N'Chinh', 16, N'Toan da hoan thanh'),
    ('LOP_D07', 'MON_D02', N'Chinh', 12, N'Tieng Anh da hoan thanh'),
    ('LOP_D08', 'MON_D06', N'Chinh', 14, N'Sinh hoc da hoan thanh'),
    ('LOP_D09', 'MON_D01', N'Chinh', 18, N'Toan nang cao'),
    ('LOP_D09', 'MON_D02', N'Phu',    6, N'Bo tro thuat ngu tieng Anh'),
    ('LOP_D10', 'MON_D04', N'Chinh',  2, N'Hoa hoc bi huy');

    /* 9. Lich hoc dinh ky. Quy uoc demo: 1..7 la cac ngay trong tuan. */
    INSERT INTO lich_hoc (ma_lich, ma_lop, thu_trong_tuan, gio_bat_dau, gio_ket_thuc)
    VALUES
    ('LICH_D01A', 'LOP_D01', 2, '18:00', '19:30'),
    ('LICH_D01B', 'LOP_D01', 4, '18:00', '19:30'),
    ('LICH_D02A', 'LOP_D02', 3, '18:00', '19:30'),
    ('LICH_D02B', 'LOP_D02', 5, '18:00', '19:30'),
    ('LICH_D03A', 'LOP_D03', 2, '20:00', '21:30'),
    ('LICH_D03B', 'LOP_D03', 6, '20:00', '21:30'),
    ('LICH_D04A', 'LOP_D04', 4, '19:45', '21:15'),
    ('LICH_D04B', 'LOP_D04', 7, '15:00', '16:30'),
    ('LICH_D05A', 'LOP_D05', 5, '20:00', '21:30'),
    ('LICH_D05B', 'LOP_D05', 7, '09:00', '10:30'),
    ('LICH_D06A', 'LOP_D06', 3, '17:00', '18:30'),
    ('LICH_D06B', 'LOP_D06', 6, '17:00', '18:30'),
    ('LICH_D07A', 'LOP_D07', 7, '08:00', '09:30'),
    ('LICH_D07B', 'LOP_D07', 1, '08:00', '09:30'),
    ('LICH_D08A', 'LOP_D08', 4, '08:00', '09:30'),
    ('LICH_D08B', 'LOP_D08', 7, '10:00', '11:30'),
    ('LICH_D09A', 'LOP_D09', 3, '20:00', '21:30'),
    ('LICH_D09B', 'LOP_D09', 5, '20:00', '21:30'),
    ('LICH_D10A', 'LOP_D10', 2, '08:00', '09:30'),
    ('LICH_D10B', 'LOP_D10', 4, '08:00', '09:30');

    /* 10. Buoi hoc cu the */
    INSERT INTO buoi_hoc (ma_buoi_hoc, ma_lop, ma_lich, ngay_hoc, gio_bat_dau, gio_ket_thuc, trang_thai, ghi_chu)
    VALUES
    ('BH_D01_01', 'LOP_D01', 'LICH_D01A', '2026-06-01', '18:00', '19:30', 'completed', N'Buoi 1 da hoc'),
    ('BH_D01_02', 'LOP_D01', 'LICH_D01B', '2026-06-03', '18:00', '19:30', 'scheduled', N'Buoi 2 sap hoc'),
    ('BH_D02_01', 'LOP_D02', 'LICH_D02A', '2026-06-02', '18:00', '19:30', 'completed', N'Buoi 1 online'),
    ('BH_D02_02', 'LOP_D02', 'LICH_D02B', '2026-06-04', '18:00', '19:30', 'scheduled', N'Buoi 2 online'),
    ('BH_D03_01', 'LOP_D03', 'LICH_D03A', '2026-06-01', '20:00', '21:30', 'completed', N'Buoi 1 hoa hoc'),
    ('BH_D03_02', 'LOP_D03', 'LICH_D03B', '2026-06-05', '20:00', '21:30', 'scheduled', N'Buoi 2 hoa hoc'),
    ('BH_D04_01', 'LOP_D04', 'LICH_D04A', '2026-06-03', '19:45', '21:15', 'scheduled', N'Buoi 1 sap hoc'),
    ('BH_D04_02', 'LOP_D04', 'LICH_D04B', '2026-06-06', '15:00', '16:30', 'scheduled', N'Buoi 2 sap hoc'),
    ('BH_D05_01', 'LOP_D05', 'LICH_D05A', '2026-06-04', '20:00', '21:30', 'completed', N'Buoi 1 vat ly'),
    ('BH_D05_02', 'LOP_D05', 'LICH_D05B', '2026-06-06', '09:00', '10:30', 'scheduled', N'Buoi 2 vat ly'),
    ('BH_D06_01', 'LOP_D06', 'LICH_D06A', '2026-02-03', '17:00', '18:30', 'completed', N'Lop da hoan thanh'),
    ('BH_D06_02', 'LOP_D06', 'LICH_D06B', '2026-02-06', '17:00', '18:30', 'completed', N'Lop da hoan thanh'),
    ('BH_D07_01', 'LOP_D07', 'LICH_D07A', '2026-02-07', '08:00', '09:30', 'completed', N'Lop da hoan thanh'),
    ('BH_D07_02', 'LOP_D07', 'LICH_D07B', '2026-02-08', '08:00', '09:30', 'completed', N'Lop da hoan thanh'),
    ('BH_D08_01', 'LOP_D08', 'LICH_D08A', '2026-03-04', '08:00', '09:30', 'completed', N'Lop da hoan thanh'),
    ('BH_D08_02', 'LOP_D08', 'LICH_D08B', '2026-03-07', '10:00', '11:30', 'completed', N'Lop da hoan thanh'),
    ('BH_D09_01', 'LOP_D09', 'LICH_D09A', '2026-06-02', '20:00', '21:30', 'scheduled', N'Lop sap mo'),
    ('BH_D09_02', 'LOP_D09', 'LICH_D09B', '2026-06-04', '20:00', '21:30', 'scheduled', N'Lop sap mo'),
    ('BH_D10_01', 'LOP_D10', 'LICH_D10A', '2026-04-06', '08:00', '09:30', 'cancelled', N'Lop bi huy'),
    ('BH_D10_02', 'LOP_D10', 'LICH_D10B', '2026-04-08', '08:00', '09:30', 'cancelled', N'Lop bi huy');

    /* 11. Dang ky lop */
    INSERT INTO dang_ky (ma_dang_ky, ma_hoc_vien, ma_lop, ngay_dang_ky, trang_thai, ghi_chu)
    VALUES
    ('DK_D01', 'HV_D01', 'LOP_D01', '2026-05-16 10:00:00', 'confirmed', N'Dang hoc'),
    ('DK_D02', 'HV_D02', 'LOP_D02', '2026-05-16 10:10:00', 'confirmed', N'Dang hoc'),
    ('DK_D03', 'HV_D03', 'LOP_D03', '2026-05-16 10:20:00', 'confirmed', N'Dang hoc'),
    ('DK_D04', 'HV_D04', 'LOP_D04', '2026-05-16 10:30:00', 'confirmed', N'Dang hoc'),
    ('DK_D05', 'HV_D05', 'LOP_D05', '2026-05-16 10:40:00', 'confirmed', N'Dang hoc'),
    ('DK_D06', 'HV_D06', 'LOP_D06', '2026-01-11 10:00:00', 'completed', N'Da hoan thanh'),
    ('DK_D07', 'HV_D07', 'LOP_D07', '2026-01-13 10:00:00', 'completed', N'Da hoan thanh'),
    ('DK_D08', 'HV_D08', 'LOP_D08', '2026-02-11 10:00:00', 'completed', N'Da hoan thanh'),
    ('DK_D09', 'HV_D09', 'LOP_D09', '2026-05-21 10:00:00', 'confirmed', N'Lop sap mo'),
    ('DK_D10', 'HV_D10', 'LOP_D10', '2026-03-16 10:00:00', 'cancelled', N'Hoc vien huy lich');

    /* 12. Diem danh cho cac buoi da hoc */
    INSERT INTO diem_danh (ma_buoi_hoc, ma_dang_ky, trang_thai, so_phut_hoc, ghi_chu)
    VALUES
    ('BH_D01_01', 'DK_D01', 'comat', 90, N'Hoc tot'),
    ('BH_D02_01', 'DK_D02', 'tre',   80, N'Vao lop tre 10 phut'),
    ('BH_D03_01', 'DK_D03', 'comat', 90, N'Hoan thanh bai tap'),
    ('BH_D05_01', 'DK_D05', 'comat', 90, N'Hoc tot'),
    ('BH_D06_01', 'DK_D06', 'comat', 90, N'Lop cu'),
    ('BH_D06_02', 'DK_D06', 'comat', 90, N'Lop cu'),
    ('BH_D07_01', 'DK_D07', 'comat', 90, N'Lop cu'),
    ('BH_D07_02', 'DK_D07', 'phep',  0,  N'Xin phep co bu'),
    ('BH_D08_01', 'DK_D08', 'comat', 90, N'Lop cu'),
    ('BH_D08_02', 'DK_D08', 'comat', 90, N'Lop cu');

    /* 13. Giao dich thanh toan */
    INSERT INTO giao_dich (
        ma_giao_dich, ma_dang_ky, ma_tk_hv, ma_tk_gs,
        tong_tien_thu, ty_le_hoa_hong, phi_hoa_hong, so_tien_gia_su_nhan,
        ngay_thanh_toan, ngay_doi_soat, trang_thai, loai_giao_dich, ma_tham_chieu
    )
    VALUES
    ('GD_D01', 'DK_D01', 'TKHV_D01', 'TKGS_D01', 2400000, 15.00, 360000, 2040000, '2026-06-01 21:00:00', NULL,                  'success',  'thanhtoanthang', 'REF_DEMO_D01'),
    ('GD_D02', 'DK_D02', 'TKHV_D02', 'TKGS_D02', 2200000, 15.00, 330000, 1870000, '2026-06-02 21:00:00', NULL,                  'success',  'thanhtoanthang', 'REF_DEMO_D02'),
    ('GD_D03', 'DK_D03', 'TKHV_D03', 'TKGS_D03', 2600000, 15.00, 390000, 2210000, '2026-06-01 22:00:00', NULL,                  'success',  'thanhtoanthang', 'REF_DEMO_D03'),
    ('GD_D04', 'DK_D04', 'TKHV_D04', 'TKGS_D04', 2800000, 15.00, 420000, 2380000, '2026-06-03 22:00:00', NULL,                  'pending',  'thanhtoanthang', 'REF_DEMO_D04'),
    ('GD_D05', 'DK_D05', 'TKHV_D05', 'TKGS_D05', 2480000, 15.00, 372000, 2108000, '2026-06-04 22:00:00', NULL,                  'success',  'thanhtoanthang', 'REF_DEMO_D05'),
    ('GD_D06', 'DK_D06', 'TKHV_D06', 'TKGS_D01', 2720000, 15.00, 408000, 2312000, '2026-03-20 20:00:00', '2026-03-21 09:00:00', 'success',  'thanhtoanthang', 'REF_DEMO_D06'),
    ('GD_D07', 'DK_D07', 'TKHV_D07', 'TKGS_D02', 2000000, 15.00, 300000, 1700000, '2026-03-14 20:00:00', '2026-03-15 09:00:00', 'success',  'thanhtoanthang', 'REF_DEMO_D07'),
    ('GD_D08', 'DK_D08', 'TKHV_D08', 'TKGS_D03', 2320000, 15.00, 348000, 1972000, '2026-04-18 20:00:00', '2026-04-19 09:00:00', 'success',  'thanhtoanthang', 'REF_DEMO_D08'),
    ('GD_D09', 'DK_D09', 'TKHV_D09', 'TKGS_D04', 3000000, 15.00, 450000, 2550000, '2026-05-21 20:00:00', NULL,                  'pending',  'thanhtoanthang', 'REF_DEMO_D09'),
    ('GD_D10', 'DK_D10', 'TKHV_D10', 'TKGS_D05', 1280000, 15.00, 192000, 1088000, '2026-04-06 20:00:00', '2026-04-08 09:00:00', 'refunded', 'hoantra',        'REF_DEMO_D10');

    /* 14. Danh gia cho cac lop da hoan thanh */
    INSERT INTO danh_gia (ma_danh_gia, ma_dang_ky, diem_sao, nhan_xet, ngay_danh_gia)
    VALUES
    ('DG_D06', 'DK_D06', 5, N'Gia su day de hieu, dung gio.',          '2026-03-21 10:00:00'),
    ('DG_D07', 'DK_D07', 4, N'Giao tiep tot, can them bai tap ve nha.', '2026-03-15 10:00:00'),
    ('DG_D08', 'DK_D08', 5, N'Lo trinh ro rang, hoc vien tien bo.',    '2026-04-19 10:00:00');

    /* 15. Lich su day hoc cua gia su */
    INSERT INTO lich_su_day_hoc (
        ma_lich_su_day, ma_gia_su, ma_lop, ten_hoc_vien, ten_mon_hoc,
        ngay_bat_dau, ngay_ket_thuc, tong_so_buoi, tong_thu_nhap,
        danh_gia_tb, trang_thai_lop, ngay_ghi_nhan
    )
    VALUES
    ('LSD_D06', 'GS_D01', 'LOP_D06', N'Dang My Anh',      N'Toan',      '2026-02-03', '2026-03-20', 16, 2312000, 5.00, 'hoan_thanh', '2026-03-21 09:00:00'),
    ('LSD_D07', 'GS_D02', 'LOP_D07', N'Hoang Nhat Khang', N'Tieng Anh', '2026-02-07', '2026-03-14', 12, 1700000, 4.00, 'hoan_thanh', '2026-03-15 09:00:00'),
    ('LSD_D08', 'GS_D03', 'LOP_D08', N'Bui Minh Chau',    N'Sinh Hoc',  '2026-03-04', '2026-04-18', 14, 1972000, 5.00, 'hoan_thanh', '2026-04-19 09:00:00'),
    ('LSD_D10', 'GS_D05', 'LOP_D10', N'Trinh Ha Vy',      N'Hoa Hoc',   '2026-04-06', '2026-04-08',  0,       0, NULL, 'huy',        '2026-04-08 09:00:00');

    /* 16. Lich su thue gia su cua hoc vien */
    INSERT INTO lich_su_thue_gia_su (
        ma_lich_su_thue, ma_hoc_vien, ma_gia_su, ten_gia_su,
        ma_yeu_cau, ma_lop, ten_mon_hoc, ngay_bat_dau, ngay_ket_thuc,
        tong_chi_phi, trang_thai, ngay_ghi_nhan
    )
    VALUES
    ('LST_D01', 'HV_D01', 'GS_D01', N'Tran Minh Khoa', 'YC_D01', 'LOP_D01', N'Toan',       '2026-06-01', NULL,         2400000, 'dang_hoc',   '2026-06-01 21:00:00'),
    ('LST_D02', 'HV_D02', 'GS_D02', N'Nguyen Ha Linh', 'YC_D02', 'LOP_D02', N'Tieng Anh',  '2026-06-02', NULL,         2200000, 'dang_hoc',   '2026-06-02 21:00:00'),
    ('LST_D03', 'HV_D03', 'GS_D03', N'Pham Quang Huy', 'YC_D03', 'LOP_D03', N'Hoa Hoc',    '2026-06-01', NULL,         2600000, 'dang_hoc',   '2026-06-01 22:00:00'),
    ('LST_D04', 'HV_D04', 'GS_D04', N'Le Thu Trang',   'YC_D04', 'LOP_D04', N'Toan',       '2026-06-03', NULL,         2800000, 'dang_hoc',   '2026-06-03 22:00:00'),
    ('LST_D05', 'HV_D05', 'GS_D05', N'Vo Duc Anh',     'YC_D05', 'LOP_D05', N'Vat Ly',     '2026-06-04', NULL,         2480000, 'dang_hoc',   '2026-06-04 22:00:00'),
    ('LST_D06', 'HV_D06', 'GS_D01', N'Tran Minh Khoa', 'YC_D06', 'LOP_D06', N'Toan',       '2026-02-03', '2026-03-20', 2720000, 'hoan_thanh', '2026-03-21 09:00:00'),
    ('LST_D07', 'HV_D07', 'GS_D02', N'Nguyen Ha Linh', 'YC_D07', 'LOP_D07', N'Tieng Anh',  '2026-02-07', '2026-03-14', 2000000, 'hoan_thanh', '2026-03-15 09:00:00'),
    ('LST_D08', 'HV_D08', 'GS_D03', N'Pham Quang Huy', 'YC_D08', 'LOP_D08', N'Sinh Hoc',   '2026-03-04', '2026-04-18', 2320000, 'hoan_thanh', '2026-04-19 09:00:00'),
    ('LST_D09', 'HV_D09', 'GS_D04', N'Le Thu Trang',   'YC_D09', 'LOP_D09', N'Toan, Tieng Anh', '2026-06-02', NULL,    3000000, 'sapmo',      '2026-05-21 20:00:00'),
    ('LST_D10', 'HV_D10', 'GS_D05', N'Vo Duc Anh',     'YC_D10', 'LOP_D10', N'Hoa Hoc',    '2026-04-06', '2026-04-08', 1280000, 'huy',        '2026-04-08 09:00:00');
    select * from lich_su_thue_gia_su
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF OBJECT_ID(N'dbo.tr_ung_tuyen_notify', N'TR') IS NOT NULL
        ENABLE TRIGGER dbo.tr_ung_tuyen_notify ON dbo.ung_tuyen;
    THROW;
END CATCH;
GO

/* ============================================================
   Query demo nhanh sau khi seed
   ============================================================ */

PRINT N'1) Tong hop so dong demo vua tao';
SELECT 'hoc_vien' AS bang, COUNT(*) AS so_dong FROM hoc_vien WHERE ma_hoc_vien LIKE 'HV_D%'
UNION ALL SELECT 'gia_su', COUNT(*) FROM gia_su WHERE ma_gia_su LIKE 'GS_D%'
UNION ALL SELECT 'mon_hoc', COUNT(*) FROM mon_hoc WHERE ma_mon LIKE 'MON_D%'
UNION ALL SELECT 'lop_hoc', COUNT(*) FROM lop_hoc WHERE ma_lop LIKE 'LOP_D%'
UNION ALL SELECT 'lich_hoc', COUNT(*) FROM lich_hoc WHERE ma_lop LIKE 'LOP_D%'
UNION ALL SELECT 'buoi_hoc', COUNT(*) FROM buoi_hoc WHERE ma_lop LIKE 'LOP_D%'
UNION ALL SELECT 'lich_su_thue_gia_su', COUNT(*) FROM lich_su_thue_gia_su WHERE ma_lich_su_thue LIKE 'LST_D%';
GO

PRINT N'2) Demo check lich su mot hoc vien thue gia su: HV_D06';
SELECT
    ma_lich_su_thue,
    ma_hoc_vien,
    ten_gia_su,
    ma_lop,
    ten_mon_hoc,
    ngay_bat_dau,
    ngay_ket_thuc,
    tong_chi_phi,
    trang_thai
FROM lich_su_thue_gia_su
WHERE ma_hoc_vien = 'HV_D06'
ORDER BY ngay_ghi_nhan DESC;
GO

PRINT N'3) Demo xem lich day hien tai cua gia su GS_D01';
SELECT
    ma_gia_su,
    ten_gia_su,
    ma_lop,
    trang_thai_lop,
    thu_trong_tuan,
    khoang_thoi_gian
FROM vw_lich_trinh_gia_su
WHERE ma_gia_su = 'GS_D01'
ORDER BY thu_trong_tuan, gio_bat_dau;
GO

PRINT N'4) Demo check function trung lich: GS_D01, thu 2, 18:30-19:00';
SELECT
    CASE
        WHEN dbo.fn_kiem_tra_trung_lich_lichhoc('GS_D01', 2, '18:30', '19:00', NULL) = 1
            THEN N'TRUNG LICH'
        ELSE N'KHONG TRUNG'
    END AS ket_qua;
GO

PRINT N'5) Demo trigger bao loi khi insert lich trung';
BEGIN TRY
    INSERT INTO lich_hoc (ma_lich, ma_lop, thu_trong_tuan, gio_bat_dau, gio_ket_thuc)
    VALUES ('LICH_D_TEST_TRUNG', 'LOP_D01', 2, '18:30', '19:00');

    SELECT N'Khong bi trung - neu thay dong nay thi trigger can duoc kiem tra lai.' AS ket_qua;

    DELETE FROM lich_hoc WHERE ma_lich = 'LICH_D_TEST_TRUNG';
END TRY
BEGIN CATCH
    SELECT
        ERROR_NUMBER() AS ma_loi,
        ERROR_MESSAGE() AS thong_bao_loi;
END CATCH;
GO
