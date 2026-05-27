-- Chuyển sang master để thao tác với database
USE master;
GO

-- Xóa database cũ nếu tồn tại (đóng các kết nối đang mở trước khi xóa)
IF DB_ID('GiaSuBachKhoa') IS NOT NULL
BEGIN
    ALTER DATABASE GiaSuBachKhoa SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GiaSuBachKhoa;
END
GO

-- Tạo Database mới
CREATE DATABASE GiaSuBachKhoa;
GO

USE GiaSuBachKhoa;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE TABLE hoc_vien (
    ma_hoc_vien     VARCHAR(20)   PRIMARY KEY,
    ho_ten          NVARCHAR(100) NOT NULL,
    ngay_sinh       DATE          NULL,
    gioi_tinh       NVARCHAR(10)  NULL,
    so_dien_thoai   VARCHAR(15)   NULL,
    email           VARCHAR(150)  NULL,
    dia_chi         NVARCHAR(MAX) NULL,
    anh_dai_dien    NVARCHAR(MAX) NULL,
    khoi_hien_tai   NVARCHAR(20)  NULL,
    auth_id         UNIQUEIDENTIFIER NULL,
    ngay_tao        DATETIME      NOT NULL DEFAULT GETDATE(),
    ngay_cap_nhat   DATETIME      NOT NULL DEFAULT GETDATE()
);

CREATE TABLE gia_su (
    ma_gia_su       VARCHAR(20)   PRIMARY KEY,
    ho_ten          NVARCHAR(100) NOT NULL,
    ngay_sinh       DATE          NULL,
    gioi_tinh       NVARCHAR(10)  NULL,
    so_dien_thoai   VARCHAR(15)   NULL,
    email           VARCHAR(150)  NULL,
    dia_chi         NVARCHAR(MAX) NULL,
    anh_dai_dien    NVARCHAR(MAX) NULL,
    trinh_do        NVARCHAR(200) NULL,
    gioi_thieu      NVARCHAR(MAX) NULL,
    trong_lich      BIT           NOT NULL DEFAULT 1,
    auth_id         UNIQUEIDENTIFIER NULL,
    ngay_tao        DATETIME      NOT NULL DEFAULT GETDATE(),
    ngay_cap_nhat   DATETIME      NOT NULL DEFAULT GETDATE()
);

CREATE TABLE mon_hoc (
    ma_mon          VARCHAR(20)   PRIMARY KEY,
    ten_mon         NVARCHAR(100) NOT NULL,
    cap_hoc         NVARCHAR(50)  NOT NULL,
    mo_ta           NVARCHAR(MAX) NULL
);

CREATE TABLE gia_su_mon_hoc (
    ma_gia_su           VARCHAR(20)   NOT NULL REFERENCES gia_su(ma_gia_su) ON DELETE CASCADE,
    ma_mon              VARCHAR(20)   NOT NULL REFERENCES mon_hoc(ma_mon) ON DELETE CASCADE,
    nam_kinh_nghiem     INT           NOT NULL DEFAULT 0 CHECK (nam_kinh_nghiem >= 0),
    muc_do_thanh_thao   NVARCHAR(20)  NULL,
    chung_chi           NVARCHAR(MAX) NULL,
    PRIMARY KEY (ma_gia_su, ma_mon)
);

CREATE TABLE yeu_cau_lop (
    ma_yeu_cau              VARCHAR(20)   PRIMARY KEY,
    ma_hoc_vien             VARCHAR(20)   NOT NULL REFERENCES hoc_vien(ma_hoc_vien),
    tieu_de                 NVARCHAR(200) NOT NULL,
    mo_ta                   NVARCHAR(MAX) NULL,
    tien_hoc_phi            DECIMAL(12,0) NOT NULL CHECK (tien_hoc_phi >= 0),
    dia_chi                 NVARCHAR(MAX) NOT NULL,
    hinh_thuc_hoc           VARCHAR(20)   NOT NULL DEFAULT 'Offline',
    so_buoi_tuan            SMALLINT      NOT NULL CHECK (so_buoi_tuan BETWEEN 1 AND 7),
    thoi_gian_mong_muon     NVARCHAR(MAX) NULL,
    ngay_yeu_cau            DATETIME      NOT NULL DEFAULT GETDATE(),
    trang_thai              VARCHAR(20)   NOT NULL DEFAULT 'open',
    ma_gia_su_duoc_chon     VARCHAR(20)   NULL REFERENCES gia_su(ma_gia_su),
    ngay_chon_gia_su        DATETIME      NULL,
    ngay_cap_nhat           DATETIME      NOT NULL DEFAULT GETDATE()
);

CREATE TABLE yeu_cau_mon (
    ma_yeu_cau      VARCHAR(20)   NOT NULL REFERENCES yeu_cau_lop(ma_yeu_cau) ON DELETE CASCADE,
    ma_mon          VARCHAR(20)   NOT NULL REFERENCES mon_hoc(ma_mon),
    vai_tro_mon     NVARCHAR(20)  NOT NULL DEFAULT N'Chính',
    ghi_chu         NVARCHAR(MAX) NULL,
    PRIMARY KEY (ma_yeu_cau, ma_mon)
);

CREATE TABLE ung_tuyen (
    ma_ung_tuyen    VARCHAR(30)   PRIMARY KEY,
    ma_yeu_cau      VARCHAR(20)   NOT NULL REFERENCES yeu_cau_lop(ma_yeu_cau) ON DELETE CASCADE,
    ma_gia_su       VARCHAR(20)   NOT NULL REFERENCES gia_su(ma_gia_su),
    thu_nhap_mong_muon DECIMAL(12,0) NULL,
    loi_nhan        NVARCHAR(MAX) NULL,
    trang_thai      VARCHAR(20)   NOT NULL DEFAULT 'pending',
    ngay_ung_tuyen  DATETIME      NOT NULL DEFAULT GETDATE(),
    ngay_xu_ly      DATETIME      NULL,
    UNIQUE (ma_yeu_cau, ma_gia_su)
);

CREATE TABLE lop_hoc (
    ma_lop          VARCHAR(20)   PRIMARY KEY,
    ma_gia_su       VARCHAR(20)   NOT NULL REFERENCES gia_su(ma_gia_su),
    ma_hoc_vien     VARCHAR(20)   NOT NULL REFERENCES hoc_vien(ma_hoc_vien),
    ma_yeu_cau      VARCHAR(20)   NULL UNIQUE REFERENCES yeu_cau_lop(ma_yeu_cau),
    ma_ung_tuyen    VARCHAR(30)   NULL REFERENCES ung_tuyen(ma_ung_tuyen),
    hoc_phi         DECIMAL(12,0) NOT NULL CHECK (hoc_phi >= 0),
    dia_chi         NVARCHAR(MAX) NOT NULL,
    hinh_thuc_day   VARCHAR(20)   NOT NULL DEFAULT 'Offline',
    ngay_bat_dau    DATE          NOT NULL,
    ngay_ket_thuc   DATE          NULL,
    trang_thai      VARCHAR(20)   NOT NULL DEFAULT 'SapMo',
    so_hv_toi_da    SMALLINT      NOT NULL DEFAULT 1 CHECK (so_hv_toi_da = 1),
    tong_so_buoi    INT           NOT NULL CHECK (tong_so_buoi > 0),
    ngay_tao        DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT ck_lop_hoc_ngay CHECK (ngay_ket_thuc IS NULL OR ngay_ket_thuc >= ngay_bat_dau)
);

CREATE TABLE lop_hoc_mon (
    ma_lop              VARCHAR(20)   NOT NULL REFERENCES lop_hoc(ma_lop) ON DELETE CASCADE,
    ma_mon              VARCHAR(20)   NOT NULL REFERENCES mon_hoc(ma_mon),
    vai_tro_mon         NVARCHAR(20)  NOT NULL DEFAULT N'Chính',
    so_buoi_du_kien     INT           NULL CHECK (so_buoi_du_kien IS NULL OR so_buoi_du_kien >= 0),
    ghi_chu             NVARCHAR(MAX) NULL,
    PRIMARY KEY (ma_lop, ma_mon)
);

CREATE TABLE lich_hoc (
    ma_lich             VARCHAR(20)   PRIMARY KEY,
    ma_lop              VARCHAR(20)   NOT NULL REFERENCES lop_hoc(ma_lop) ON DELETE CASCADE,
    thu_trong_tuan      SMALLINT      NOT NULL CHECK (thu_trong_tuan BETWEEN 1 AND 7),
    gio_bat_dau         TIME          NOT NULL,
    gio_ket_thuc        TIME          NOT NULL,
    CONSTRAINT ck_lich_hoc_gio CHECK (gio_ket_thuc > gio_bat_dau),
    UNIQUE (ma_lop, ma_lich)
);

CREATE TABLE buoi_hoc (
    ma_buoi_hoc     VARCHAR(20)   PRIMARY KEY,
    ma_lop          VARCHAR(20)   NOT NULL REFERENCES lop_hoc(ma_lop) ON DELETE CASCADE,
    ma_lich         VARCHAR(20)   NULL,
    ngay_hoc        DATE          NOT NULL,
    gio_bat_dau     TIME          NOT NULL,
    gio_ket_thuc    TIME          NOT NULL,
    trang_thai      VARCHAR(20)   NOT NULL DEFAULT 'Scheduled',
    ghi_chu         NVARCHAR(MAX) NULL,
    CONSTRAINT ck_buoi_hoc_gio CHECK (gio_ket_thuc > gio_bat_dau)
);

ALTER TABLE buoi_hoc ADD CONSTRAINT FK_buoi_hoc_lich_hoc FOREIGN KEY (ma_lop, ma_lich) REFERENCES lich_hoc(ma_lop, ma_lich);

CREATE TABLE dang_ky (
    ma_dang_ky      VARCHAR(20)   PRIMARY KEY,
    ma_hoc_vien     VARCHAR(20)   NOT NULL REFERENCES hoc_vien(ma_hoc_vien),
    ma_lop          VARCHAR(20)   NOT NULL REFERENCES lop_hoc(ma_lop),
    ngay_dang_ky    DATETIME      NOT NULL DEFAULT GETDATE(),
    trang_thai      VARCHAR(20)   NOT NULL DEFAULT 'Pending',
    ghi_chu         NVARCHAR(MAX) NULL,
    UNIQUE (ma_hoc_vien, ma_lop),
    UNIQUE (ma_lop)
);

CREATE TABLE tai_khoan_hv (
    ma_tk_hv            VARCHAR(20)   PRIMARY KEY,
    ma_hoc_vien         VARCHAR(20)   NOT NULL REFERENCES hoc_vien(ma_hoc_vien),
    so_tai_khoan        VARCHAR(30)   NOT NULL,
    nha_cung_cap        NVARCHAR(100) NOT NULL,
    loai_phuong_thuc    VARCHAR(30)   NOT NULL DEFAULT 'Bank',
    ten_chu_tk          NVARCHAR(100) NOT NULL,
    la_mac_dinh         BIT           NOT NULL DEFAULT 0,
    UNIQUE (ma_hoc_vien, so_tai_khoan, nha_cung_cap)
);

CREATE TABLE tai_khoan_gs (
    ma_tk_gs            VARCHAR(20)   PRIMARY KEY,
    ma_gia_su           VARCHAR(20)   NOT NULL REFERENCES gia_su(ma_gia_su),
    so_tai_khoan        VARCHAR(30)   NOT NULL,
    nha_cung_cap        NVARCHAR(100) NOT NULL,
    loai_phuong_thuc    VARCHAR(30)   NOT NULL DEFAULT 'Bank',
    ten_chu_tk          NVARCHAR(100) NOT NULL,
    la_mac_dinh         BIT           NOT NULL DEFAULT 0,
    UNIQUE (ma_gia_su, so_tai_khoan, nha_cung_cap)
);

CREATE TABLE giao_dich (
    ma_giao_dich            VARCHAR(30)   PRIMARY KEY,
    ma_dang_ky              VARCHAR(20)   NOT NULL REFERENCES dang_ky(ma_dang_ky),
    ma_tk_hv                VARCHAR(20)   NOT NULL REFERENCES tai_khoan_hv(ma_tk_hv),
    ma_tk_gs                VARCHAR(20)   NOT NULL REFERENCES tai_khoan_gs(ma_tk_gs),
    tong_tien_thu           DECIMAL(15,0) NOT NULL CHECK (tong_tien_thu > 0),
    ty_le_hoa_hong          DECIMAL(5,2)  NOT NULL CHECK (ty_le_hoa_hong BETWEEN 0 AND 100),
    phi_hoa_hong            DECIMAL(15,0) NOT NULL CHECK (phi_hoa_hong >= 0),
    so_tien_gia_su_nhan     DECIMAL(15,0) NOT NULL CHECK (so_tien_gia_su_nhan >= 0),
    ngay_thanh_toan         DATETIME      NOT NULL DEFAULT GETDATE(),
    ngay_doi_soat           DATETIME      NULL,
    trang_thai              VARCHAR(20)   NOT NULL DEFAULT 'Success',
    loai_giao_dich          VARCHAR(30)   NOT NULL DEFAULT 'ThanhToanThang',
    ma_tham_chieu           VARCHAR(100)  NULL UNIQUE,
    CONSTRAINT ck_giao_dich_toan_ven CHECK (phi_hoa_hong + so_tien_gia_su_nhan = tong_tien_thu),
    CONSTRAINT ck_giao_dich_ngay CHECK (ngay_doi_soat IS NULL OR ngay_doi_soat >= ngay_thanh_toan)
);

CREATE TABLE danh_gia (
    ma_danh_gia     VARCHAR(20)   PRIMARY KEY,
    ma_dang_ky      VARCHAR(20)   NOT NULL UNIQUE REFERENCES dang_ky(ma_dang_ky),
    diem_sao        SMALLINT      NOT NULL CHECK (diem_sao BETWEEN 1 AND 5),
    nhan_xet        NVARCHAR(MAX) NULL,
    ngay_danh_gia   DATETIME      NOT NULL DEFAULT GETDATE()
);

CREATE TABLE diem_danh (
    ma_buoi_hoc     VARCHAR(20)   NOT NULL REFERENCES buoi_hoc(ma_buoi_hoc) ON DELETE CASCADE,
    ma_dang_ky      VARCHAR(20)   NOT NULL REFERENCES dang_ky(ma_dang_ky),
    trang_thai      VARCHAR(20)   NOT NULL DEFAULT 'CoMat',
    so_phut_hoc     INT           NULL CHECK (so_phut_hoc IS NULL OR so_phut_hoc >= 0),
    ghi_chu         NVARCHAR(MAX) NULL,
    PRIMARY KEY (ma_buoi_hoc, ma_dang_ky)
);

CREATE TABLE thong_bao (
    ma_thong_bao    VARCHAR(30)   PRIMARY KEY,
    ma_hoc_vien     VARCHAR(20)   NULL REFERENCES hoc_vien(ma_hoc_vien) ON DELETE CASCADE,
    ma_gia_su       VARCHAR(20)   NULL REFERENCES gia_su(ma_gia_su) ON DELETE CASCADE,
    loai_thong_bao  VARCHAR(30)   NOT NULL,
    tieu_de         NVARCHAR(200) NOT NULL,
    noi_dung        NVARCHAR(MAX) NOT NULL,
    da_doc          BIT           NOT NULL DEFAULT 0,
    ngay_tao        DATETIME      NOT NULL DEFAULT GETDATE(),
    ma_yeu_cau      VARCHAR(20)   NULL,
    ma_lop          VARCHAR(20)   NULL,
    ma_giao_dich    VARCHAR(30)   NULL,
    ma_buoi_hoc     VARCHAR(20)   NULL,
    CONSTRAINT ck_thong_bao_nguoi_nhan CHECK (
        (CASE WHEN ma_hoc_vien IS NULL THEN 0 ELSE 1 END) +
        (CASE WHEN ma_gia_su IS NULL THEN 0 ELSE 1 END) = 1
    )
);

CREATE TABLE audit_log (
    id              BIGINT        IDENTITY(1,1) PRIMARY KEY,
    table_name      VARCHAR(50)   NOT NULL,
    record_id       VARCHAR(30)   NOT NULL,
    action          VARCHAR(10)   NOT NULL,
    old_data        NVARCHAR(MAX) NULL,
    new_data        NVARCHAR(MAX) NULL,
    changed_by      VARCHAR(100)  NULL,
    changed_at      DATETIME      NOT NULL DEFAULT GETDATE()
);

CREATE UNIQUE INDEX ux_hoc_vien_auth ON hoc_vien(auth_id) WHERE auth_id IS NOT NULL;
CREATE UNIQUE INDEX ux_hoc_vien_sdt ON hoc_vien(so_dien_thoai) WHERE so_dien_thoai IS NOT NULL;
CREATE UNIQUE INDEX ux_hoc_vien_email ON hoc_vien(email) WHERE email IS NOT NULL;

CREATE UNIQUE INDEX ux_gia_su_auth ON gia_su(auth_id) WHERE auth_id IS NOT NULL;
CREATE UNIQUE INDEX ux_gia_su_sdt ON gia_su(so_dien_thoai) WHERE so_dien_thoai IS NOT NULL;
CREATE UNIQUE INDEX ux_gia_su_email ON gia_su(email) WHERE email IS NOT NULL;
CREATE INDEX ix_gia_su_trong_lich ON gia_su(trong_lich) WHERE trong_lich = 1;

CREATE INDEX ix_gia_su_mon_hoc_mon ON gia_su_mon_hoc(ma_mon);

CREATE INDEX ix_yeu_cau_hoc_vien ON yeu_cau_lop(ma_hoc_vien, trang_thai);
CREATE INDEX ix_yeu_cau_trang_thai ON yeu_cau_lop(trang_thai, ngay_yeu_cau DESC);

CREATE INDEX ix_ung_tuyen_yeu_cau ON ung_tuyen(ma_yeu_cau, trang_thai);
CREATE INDEX ix_ung_tuyen_gia_su ON ung_tuyen(ma_gia_su, trang_thai);

CREATE INDEX ix_lop_hoc_gia_su ON lop_hoc(ma_gia_su, trang_thai);
CREATE INDEX ix_lop_hoc_hoc_vien ON lop_hoc(ma_hoc_vien, trang_thai);

CREATE INDEX ix_lich_hoc_lop ON lich_hoc(ma_lop, thu_trong_tuan, gio_bat_dau);
CREATE UNIQUE INDEX ux_lich_hoc_lop_thu_gio ON lich_hoc(ma_lop, thu_trong_tuan, gio_bat_dau);

CREATE INDEX ix_buoi_hoc_lop_ngay ON buoi_hoc(ma_lop, ngay_hoc);

CREATE INDEX ix_dang_ky_lop ON dang_ky(ma_lop, trang_thai);
CREATE INDEX ix_giao_dich_dang_ky ON giao_dich(ma_dang_ky, ngay_thanh_toan DESC);

CREATE INDEX ix_thong_bao_hv ON thong_bao(ma_hoc_vien, da_doc, ngay_tao DESC) WHERE ma_hoc_vien IS NOT NULL;
CREATE INDEX ix_thong_bao_gs ON thong_bao(ma_gia_su, da_doc, ngay_tao DESC) WHERE ma_gia_su IS NOT NULL;

CREATE INDEX ix_diem_danh_dang_ky ON diem_danh(ma_dang_ky, ma_buoi_hoc);

CREATE UNIQUE INDEX ux_tk_hv_mac_dinh ON tai_khoan_hv(ma_hoc_vien) WHERE la_mac_dinh = 1;
CREATE UNIQUE INDEX ux_tk_gs_mac_dinh ON tai_khoan_gs(ma_gia_su) WHERE la_mac_dinh = 1;
GO

CREATE OR ALTER FUNCTION fn_tinh_diem_tb_gia_su(@p_ma_gia_su VARCHAR(20))
RETURNS DECIMAL(3,2) AS
BEGIN
    DECLARE @v_diem DECIMAL(3,2);
    SELECT @v_diem = CAST(AVG(CAST(dg.diem_sao AS DECIMAL(5,2))) AS DECIMAL(3,2))
    FROM danh_gia dg
    JOIN dang_ky dk ON dg.ma_dang_ky = dk.ma_dang_ky
    JOIN lop_hoc lh ON dk.ma_lop = lh.ma_lop
    WHERE lh.ma_gia_su = @p_ma_gia_su;

    RETURN ISNULL(@v_diem, 0);
END;
GO

CREATE OR ALTER FUNCTION fn_kiem_tra_trung_lich(
    @p_ma_gia_su VARCHAR(20),
    @p_thu SMALLINT,
    @p_gio_bat_dau TIME,
    @p_gio_ket_thuc TIME,
    @p_ma_lop_exclude VARCHAR(20) = NULL
)
RETURNS BIT AS
BEGIN
    DECLARE @v_trung BIT = 0;
    IF EXISTS (
        SELECT 1
        FROM lich_hoc lh
        JOIN lop_hoc l ON lh.ma_lop = l.ma_lop
        WHERE l.ma_gia_su = @p_ma_gia_su
          AND lh.thu_trong_tuan = @p_thu
          AND l.trang_thai IN ('SapMo', 'dang_hoc')
          AND (@p_ma_lop_exclude IS NULL OR l.ma_lop != @p_ma_lop_exclude)
          AND (@p_gio_bat_dau < lh.gio_ket_thuc AND @p_gio_ket_thuc > lh.gio_bat_dau)
    )
    BEGIN
        SET @v_trung = 1;
    END

    RETURN @v_trung;
END;
GO

CREATE OR ALTER FUNCTION fn_dem_lop_dang_day(@p_ma_gia_su VARCHAR(20))
RETURNS INT AS
BEGIN
    DECLARE @v_so_lop INT;
    SELECT @v_so_lop = COUNT(*)
    FROM lop_hoc
    WHERE ma_gia_su = @p_ma_gia_su AND trang_thai IN ('SapMo', 'dang_hoc');

    RETURN @v_so_lop;
END;
GO

CREATE OR ALTER FUNCTION fn_doanh_thu_gia_su(
    @p_ma_gia_su VARCHAR(20),
    @p_thang INT,
    @p_nam INT
)
RETURNS DECIMAL(15,0) AS
BEGIN
    DECLARE @v_tong DECIMAL(15,0);
    SELECT @v_tong = ISNULL(SUM(gd.so_tien_gia_su_nhan), 0)
    FROM giao_dich gd
    JOIN tai_khoan_gs tk ON gd.ma_tk_gs = tk.ma_tk_gs
    WHERE tk.ma_gia_su = @p_ma_gia_su
      AND MONTH(gd.ngay_thanh_toan) = @p_thang
      AND YEAR(gd.ngay_thanh_toan) = @p_nam
      AND gd.trang_thai = 'Success';

    RETURN @v_tong;
END;
GO

CREATE OR ALTER FUNCTION fn_hoc_vien_hop_le(@p_ma_hoc_vien VARCHAR(20))
RETURNS BIT AS
BEGIN
    DECLARE @v_hop_le BIT = 1;
    IF EXISTS (
        SELECT 1 FROM giao_dich gd
        JOIN dang_ky dk ON gd.ma_dang_ky = dk.ma_dang_ky
        WHERE dk.ma_hoc_vien = @p_ma_hoc_vien AND gd.trang_thai = 'Failed'
    )
    BEGIN
        SET @v_hop_le = 0;
    END

    RETURN @v_hop_le;
END;
GO

CREATE OR ALTER FUNCTION fn_format_gio_hoc(@p_gio_bd TIME, @p_gio_kt TIME)
RETURNS VARCHAR(50) AS
BEGIN
    RETURN CONVERT(VARCHAR(5), @p_gio_bd, 108) + ' - ' + CONVERT(VARCHAR(5), @p_gio_kt, 108);
END;
GO

CREATE OR ALTER FUNCTION fn_khung_gio_trong(@p_ma_gia_su VARCHAR(20), @p_thu SMALLINT)
RETURNS TABLE AS
RETURN (
    SELECT lh.gio_bat_dau, lh.gio_ket_thuc
    FROM lich_hoc lh
    JOIN lop_hoc l ON lh.ma_lop = l.ma_lop
    WHERE l.ma_gia_su = @p_ma_gia_su
      AND lh.thu_trong_tuan = @p_thu
      AND l.trang_thai IN ('SapMo', 'dang_hoc')
);
GO

CREATE OR ALTER TRIGGER tr_hoc_vien_updated_at ON hoc_vien AFTER UPDATE AS
BEGIN
    UPDATE hoc_vien SET ngay_cap_nhat = GETDATE() FROM hoc_vien INNER JOIN inserted ON hoc_vien.ma_hoc_vien = inserted.ma_hoc_vien;
END;
GO

CREATE OR ALTER TRIGGER tr_gia_su_updated_at ON gia_su AFTER UPDATE AS
BEGIN
    UPDATE gia_su SET ngay_cap_nhat = GETDATE() FROM gia_su INNER JOIN inserted ON gia_su.ma_gia_su = inserted.ma_gia_su;
END;
GO

CREATE OR ALTER TRIGGER tr_yeu_cau_lop_updated_at ON yeu_cau_lop AFTER UPDATE AS
BEGIN
    UPDATE yeu_cau_lop SET ngay_cap_nhat = GETDATE() FROM yeu_cau_lop INNER JOIN inserted ON yeu_cau_lop.ma_yeu_cau = inserted.ma_yeu_cau;
END;
GO

CREATE OR ALTER TRIGGER tr_diem_danh_validate ON diem_danh AFTER INSERT, UPDATE AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN buoi_hoc bh ON i.ma_buoi_hoc = bh.ma_buoi_hoc
        JOIN dang_ky dk ON i.ma_dang_ky = dk.ma_dang_ky
        WHERE bh.ma_lop != dk.ma_lop
    )
    BEGIN
        THROW 50000, 'DIEM_DANH: Buổi học và Đăng ký không cùng lớp học.', 1;
    END
END;
GO

CREATE OR ALTER TRIGGER tr_giao_dich_validate ON giao_dich AFTER INSERT, UPDATE AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dang_ky dk ON i.ma_dang_ky = dk.ma_dang_ky
        JOIN lop_hoc lh ON dk.ma_lop = lh.ma_lop
        JOIN tai_khoan_hv tkhv ON i.ma_tk_hv = tkhv.ma_tk_hv
        JOIN tai_khoan_gs tkgs ON i.ma_tk_gs = tkgs.ma_tk_gs
        WHERE tkhv.ma_hoc_vien != dk.ma_hoc_vien OR tkgs.ma_gia_su != lh.ma_gia_su
    )
    BEGIN
        THROW 50000, 'GIAO_DICH: Tài khoản không khớp với chủ đăng ký hoặc gia sư.', 1;
    END
END;
GO

CREATE OR ALTER TRIGGER tr_lich_hoc_check_trung ON lich_hoc AFTER INSERT, UPDATE AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN lop_hoc l ON i.ma_lop = l.ma_lop
        WHERE dbo.fn_kiem_tra_trung_lich(l.ma_gia_su, i.thu_trong_tuan, i.gio_bat_dau, i.gio_ket_thuc, i.ma_lop) = 1
    )
    BEGIN
        THROW 50000, 'LICH_HOC: Gia sư đã có lịch trùng.', 1;
    END
END;
GO

CREATE OR ALTER TRIGGER tr_buoi_hoc_check_trung ON buoi_hoc AFTER INSERT, UPDATE AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN lop_hoc l ON i.ma_lop = l.ma_lop
        WHERE dbo.fn_kiem_tra_trung_lich(
            l.ma_gia_su,
            ((DATEPART(dw, i.ngay_hoc) + @@DATEFIRST - 2) % 7 + 1),
            i.gio_bat_dau,
            i.gio_ket_thuc,
            i.ma_lop) = 1
    )
    BEGIN
        THROW 50000, 'BUOI_HOC: Gia sư đã có lịch trùng.', 1;
    END
END;
GO

CREATE OR ALTER TRIGGER tr_ung_tuyen_notify ON ung_tuyen AFTER INSERT AS
BEGIN
    INSERT INTO thong_bao (ma_thong_bao, ma_hoc_vien, loai_thong_bao, tieu_de, noi_dung, ma_yeu_cau)
    SELECT
        'TB_' + REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''),
        yc.ma_hoc_vien,
        'UngTuyen',
        N'Gia sư ' + gs.ho_ten + N' đã ứng tuyển vào yêu cầu ' + i.ma_yeu_cau,
        N'Gia sư ' + gs.ho_ten + N' đã ứng tuyển. Xem chi tiết và phản hồi trong mục "Yêu cầu của tôi".',
        i.ma_yeu_cau
    FROM inserted i
    JOIN yeu_cau_lop yc ON i.ma_yeu_cau = yc.ma_yeu_cau
    JOIN gia_su gs ON i.ma_gia_su = gs.ma_gia_su;
END;
GO

CREATE OR ALTER TRIGGER tr_yeu_cau_chon_gia_su ON yeu_cau_lop AFTER UPDATE AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted i JOIN deleted d ON i.ma_yeu_cau = d.ma_yeu_cau
        WHERE d.ma_gia_su_duoc_chon IS NULL AND i.ma_gia_su_duoc_chon IS NOT NULL
    )
    BEGIN

        INSERT INTO thong_bao (ma_thong_bao, ma_gia_su, loai_thong_bao, tieu_de, noi_dung, ma_yeu_cau)
        SELECT
            'TB_' + REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''),
            i.ma_gia_su_duoc_chon,
            'DuocChon',
            N'Bạn đã được chọn cho yêu cầu ' + i.ma_yeu_cau,
            N'Học viên ' + hv.ho_ten + N' đã chọn bạn. Lớp học sẽ sớm được tạo.',
            i.ma_yeu_cau
        FROM inserted i
        JOIN deleted d ON i.ma_yeu_cau = d.ma_yeu_cau
        JOIN hoc_vien hv ON i.ma_hoc_vien = hv.ma_hoc_vien
        WHERE d.ma_gia_su_duoc_chon IS NULL AND i.ma_gia_su_duoc_chon IS NOT NULL;

        INSERT INTO thong_bao (ma_thong_bao, ma_gia_su, loai_thong_bao, tieu_de, noi_dung, ma_yeu_cau)
        SELECT
            'TB_' + REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''),
            ut.ma_gia_su,
            'TuChoi',
            N'Yêu cầu ' + i.ma_yeu_cau + N' đã có gia sư được chọn',
            N'Học viên ' + hv.ho_ten + N' đã chọn gia sư khác cho yêu cầu này.',
            i.ma_yeu_cau
        FROM inserted i
        JOIN deleted d ON i.ma_yeu_cau = d.ma_yeu_cau
        JOIN hoc_vien hv ON i.ma_hoc_vien = hv.ma_hoc_vien
        JOIN ung_tuyen ut ON ut.ma_yeu_cau = i.ma_yeu_cau
        WHERE d.ma_gia_su_duoc_chon IS NULL AND i.ma_gia_su_duoc_chon IS NOT NULL
          AND ut.ma_gia_su != i.ma_gia_su_duoc_chon
          AND ut.trang_thai = 'pending';

        UPDATE ung_tuyen SET trang_thai = 'rejected', ngay_xu_ly = GETDATE()
        FROM ung_tuyen ut
        JOIN inserted i ON ut.ma_yeu_cau = i.ma_yeu_cau
        JOIN deleted d ON i.ma_yeu_cau = d.ma_yeu_cau
        WHERE d.ma_gia_su_duoc_chon IS NULL AND i.ma_gia_su_duoc_chon IS NOT NULL
          AND ut.ma_gia_su != i.ma_gia_su_duoc_chon
          AND ut.trang_thai = 'pending';

        UPDATE ung_tuyen SET trang_thai = 'accepted', ngay_xu_ly = GETDATE()
        FROM ung_tuyen ut
        JOIN inserted i ON ut.ma_yeu_cau = i.ma_yeu_cau
        JOIN deleted d ON i.ma_yeu_cau = d.ma_yeu_cau
        WHERE d.ma_gia_su_duoc_chon IS NULL AND i.ma_gia_su_duoc_chon IS NOT NULL
          AND ut.ma_gia_su = i.ma_gia_su_duoc_chon;
    END
END;
GO

CREATE OR ALTER TRIGGER tr_dang_ky_check_siso ON dang_ky AFTER INSERT AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN lop_hoc l ON i.ma_lop = l.ma_lop
        WHERE (SELECT COUNT(*) FROM dang_ky WHERE ma_lop = i.ma_lop AND trang_thai IN ('Pending', 'Confirmed')) > l.so_hv_toi_da
    )
    BEGIN
        THROW 50000, 'Lớp học đã đủ sĩ số tối đa.', 1;
    END
END;
GO

CREATE OR ALTER VIEW vw_gia_su_tong_hop AS
SELECT
    gs.ma_gia_su,
    gs.ho_ten,
    gs.gioi_tinh,
    gs.anh_dai_dien,
    gs.trinh_do,
    gs.trong_lich,
    gs.gioi_thieu,
    ISNULL(dbo.fn_tinh_diem_tb_gia_su(gs.ma_gia_su), 0) AS diem_danh_gia_tb,
    ISNULL(dbo.fn_dem_lop_dang_day(gs.ma_gia_su), 0) AS so_lop_dang_day,
    ISNULL((
        SELECT COUNT(*) FROM ung_tuyen ut
        WHERE ut.ma_gia_su = gs.ma_gia_su AND ut.trang_thai = 'accepted'
    ), 0) AS so_lop_da_nhan
FROM gia_su gs;
GO

CREATE OR ALTER VIEW vw_danh_gia_chi_tiet AS
SELECT
    dg.ma_danh_gia,
    dg.diem_sao,
    dg.nhan_xet,
    dg.ngay_danh_gia,
    dk.ma_dang_ky,
    dk.ma_hoc_vien,
    hv.ho_ten AS ten_hoc_vien,
    dk.ma_lop,
    lh.ma_gia_su,
    gs.ho_ten AS ten_gia_su
FROM danh_gia dg
JOIN dang_ky dk ON dg.ma_dang_ky = dk.ma_dang_ky
JOIN hoc_vien hv ON dk.ma_hoc_vien = hv.ma_hoc_vien
JOIN lop_hoc lh ON dk.ma_lop = lh.ma_lop
JOIN gia_su gs ON lh.ma_gia_su = gs.ma_gia_su;
GO

CREATE OR ALTER VIEW vw_giao_dich_chi_tiet AS
SELECT
    gd.ma_giao_dich,
    gd.tong_tien_thu,
    gd.ty_le_hoa_hong,
    gd.phi_hoa_hong,
    gd.so_tien_gia_su_nhan,
    gd.ngay_thanh_toan,
    gd.trang_thai,
    gd.loai_giao_dich,
    dk.ma_hoc_vien,
    hv.ho_ten AS ten_hoc_vien,
    dk.ma_lop,
    lh.ma_gia_su,
    gs.ho_ten AS ten_gia_su
FROM giao_dich gd
JOIN dang_ky dk ON gd.ma_dang_ky = dk.ma_dang_ky
JOIN hoc_vien hv ON dk.ma_hoc_vien = hv.ma_hoc_vien
JOIN lop_hoc lh ON dk.ma_lop = lh.ma_lop
JOIN gia_su gs ON lh.ma_gia_su = gs.ma_gia_su;
GO

CREATE OR ALTER VIEW vw_lop_hoc_chi_tiet AS
SELECT
    l.ma_lop,
    l.hoc_phi,
    l.hinh_thuc_day,
    l.dia_chi,
    l.trang_thai,
    l.tong_so_buoi,
    l.ngay_bat_dau,
    l.ngay_ket_thuc,
    gs.ma_gia_su,
    gs.ho_ten AS ten_gia_su,
    hv.ma_hoc_vien,
    hv.ho_ten AS ten_hoc_vien,
    l.ma_yeu_cau,
    (SELECT COUNT(*) FROM lich_hoc lh WHERE lh.ma_lop = l.ma_lop) AS so_lich_hoc,
    (SELECT COUNT(*) FROM buoi_hoc bh WHERE bh.ma_lop = l.ma_lop) AS so_buoi_da_hoc
FROM lop_hoc l
JOIN gia_su gs ON l.ma_gia_su = gs.ma_gia_su
JOIN hoc_vien hv ON l.ma_hoc_vien = hv.ma_hoc_vien;
GO

CREATE OR ALTER VIEW vw_lich_trinh_gia_su AS
SELECT
    gs.ma_gia_su,
    gs.ho_ten AS ten_gia_su,
    l.ma_lop,
    l.trang_thai AS trang_thai_lop,
    lh.thu_trong_tuan,
    lh.gio_bat_dau,
    lh.gio_ket_thuc,
    dbo.fn_format_gio_hoc(lh.gio_bat_dau, lh.gio_ket_thuc) AS khoang_thoi_gian
FROM lich_hoc lh
JOIN lop_hoc l ON lh.ma_lop = l.ma_lop
JOIN gia_su gs ON l.ma_gia_su = gs.ma_gia_su
WHERE l.trang_thai IN ('SapMo', 'dang_hoc');
GO

CREATE OR ALTER VIEW vw_thong_ke_doanh_thu AS
SELECT
    YEAR(ngay_thanh_toan) AS nam,
    MONTH(ngay_thanh_toan) AS thang,
    trang_thai,
    COUNT(*) AS so_luong_giao_dich,
    SUM(tong_tien_thu) AS tong_doanh_thu,
    SUM(phi_hoa_hong) AS tong_loi_nhuan,
    SUM(so_tien_gia_su_nhan) AS tong_chi_tra_gia_su
FROM giao_dich
GROUP BY YEAR(ngay_thanh_toan), MONTH(ngay_thanh_toan), trang_thai;
GO

CREATE OR ALTER VIEW vw_yeu_cau_dang_mo AS
SELECT
    yc.ma_yeu_cau,
    yc.tieu_de,
    yc.mo_ta,
    yc.tien_hoc_phi,
    yc.dia_chi,
    yc.hinh_thuc_hoc,
    yc.so_buoi_tuan,
    yc.thoi_gian_mong_muon,
    yc.ngay_yeu_cau,
    yc.trang_thai,
    hv.ho_ten AS ten_hoc_vien,
    hv.khoi_hien_tai,
    (SELECT COUNT(*) FROM ung_tuyen ut WHERE ut.ma_yeu_cau = yc.ma_yeu_cau) AS so_luong_ung_tuyen,
    (SELECT STRING_AGG(mh.ten_mon, ', ') FROM yeu_cau_mon ycm JOIN mon_hoc mh ON ycm.ma_mon = mh.ma_mon WHERE ycm.ma_yeu_cau = yc.ma_yeu_cau) AS cac_mon_hoc
FROM yeu_cau_lop yc
JOIN hoc_vien hv ON yc.ma_hoc_vien = hv.ma_hoc_vien
WHERE yc.trang_thai = 'open';
GO

IF OBJECT_ID(N'dbo.sp_tao_yeu_cau_lop', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_tao_yeu_cau_lop;
GO

CREATE PROCEDURE dbo.sp_tao_yeu_cau_lop
    @p_ma_yeu_cau VARCHAR(20),
    @p_ma_hoc_vien VARCHAR(20),
    @p_tieu_de NVARCHAR(200),
    @p_mo_ta NVARCHAR(MAX),
    @p_tien_hoc_phi DECIMAL(12,0),
    @p_dia_chi NVARCHAR(MAX),
    @p_hinh_thuc_hoc VARCHAR(20),
    @p_so_buoi_tuan SMALLINT,
    @p_thoi_gian_mong_muon NVARCHAR(MAX)
AS
BEGIN
    INSERT INTO yeu_cau_lop (ma_yeu_cau, ma_hoc_vien, tieu_de, mo_ta, tien_hoc_phi, dia_chi, hinh_thuc_hoc, so_buoi_tuan, thoi_gian_mong_muon, trang_thai)
    VALUES (@p_ma_yeu_cau, @p_ma_hoc_vien, @p_tieu_de, @p_mo_ta, @p_tien_hoc_phi, @p_dia_chi, @p_hinh_thuc_hoc, @p_so_buoi_tuan, @p_thoi_gian_mong_muon, 'open');
END;
GO

IF OBJECT_ID(N'dbo.sp_ung_tuyen', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ung_tuyen;
GO

CREATE PROCEDURE dbo.sp_ung_tuyen
    @p_ma_ung_tuyen VARCHAR(30),
    @p_ma_yeu_cau VARCHAR(20),
    @p_ma_gia_su VARCHAR(20),
    @p_thu_nhap_mong_muon DECIMAL(12,0) = NULL,
    @p_loi_nhan NVARCHAR(MAX) = NULL
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM yeu_cau_lop WHERE ma_yeu_cau = @p_ma_yeu_cau AND trang_thai = 'open')
    BEGIN
        THROW 50000, 'Yêu cầu này không còn mở để ứng tuyển.', 1;
    END

    IF NOT EXISTS (SELECT 1 FROM gia_su WHERE ma_gia_su = @p_ma_gia_su AND trong_lich = 1)
    BEGIN
        THROW 50000, 'Gia sư đang bận, không thể ứng tuyển.', 1;
    END

    INSERT INTO ung_tuyen (ma_ung_tuyen, ma_yeu_cau, ma_gia_su, thu_nhap_mong_muon, loi_nhan)
    VALUES (@p_ma_ung_tuyen, @p_ma_yeu_cau, @p_ma_gia_su, @p_thu_nhap_mong_muon, @p_loi_nhan);
END;
GO

IF OBJECT_ID(N'dbo.sp_chon_gia_su', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_chon_gia_su;
GO

CREATE PROCEDURE dbo.sp_chon_gia_su
    @p_ma_yeu_cau VARCHAR(20),
    @p_ma_gia_su VARCHAR(20)
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ung_tuyen
        WHERE ma_yeu_cau = @p_ma_yeu_cau AND ma_gia_su = @p_ma_gia_su AND trang_thai = 'pending'
    )
    BEGIN
        THROW 50000, 'Gia sư chưa ứng tuyển hoặc đã được xử lý.', 1;
    END

    UPDATE yeu_cau_lop
    SET ma_gia_su_duoc_chon = @p_ma_gia_su,
        ngay_chon_gia_su = GETDATE(),
        trang_thai = 'closed'
    WHERE ma_yeu_cau = @p_ma_yeu_cau;
END;
GO

IF OBJECT_ID(N'dbo.sp_tao_lop_hoc', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_tao_lop_hoc;
GO

CREATE PROCEDURE dbo.sp_tao_lop_hoc
    @p_ma_lop VARCHAR(20),
    @p_ma_yeu_cau VARCHAR(20),
    @p_ngay_bat_dau DATE,
    @p_tong_so_buoi INT
AS
BEGIN
    DECLARE @v_ma_hoc_vien VARCHAR(20);
    DECLARE @v_ma_gia_su VARCHAR(20);
    DECLARE @v_hoc_phi DECIMAL(12,0);
    DECLARE @v_dia_chi NVARCHAR(MAX);
    DECLARE @v_hinh_thuc VARCHAR(20);

    SELECT @v_ma_hoc_vien = ma_hoc_vien, @v_ma_gia_su = ma_gia_su_duoc_chon, @v_hoc_phi = tien_hoc_phi, @v_dia_chi = dia_chi, @v_hinh_thuc = hinh_thuc_hoc
    FROM yeu_cau_lop
    WHERE ma_yeu_cau = @p_ma_yeu_cau
      AND trang_thai = 'closed'
      AND ma_gia_su_duoc_chon IS NOT NULL;

    IF @v_ma_hoc_vien IS NULL
    BEGIN
        THROW 50000, 'Yêu cầu chưa được chọn gia sư hoặc không tồn tại.', 1;
    END

    INSERT INTO lop_hoc (ma_lop, ma_gia_su, ma_hoc_vien, ma_yeu_cau, hoc_phi, dia_chi, hinh_thuc_day, ngay_bat_dau, tong_so_buoi, trang_thai)
    VALUES (@p_ma_lop, @v_ma_gia_su, @v_ma_hoc_vien, @p_ma_yeu_cau, @v_hoc_phi, @v_dia_chi, @v_hinh_thuc, @p_ngay_bat_dau, @p_tong_so_buoi, 'SapMo');

    UPDATE yeu_cau_lop SET trang_thai = 'approved' WHERE ma_yeu_cau = @p_ma_yeu_cau;

    INSERT INTO dang_ky (ma_dang_ky, ma_hoc_vien, ma_lop, trang_thai)
    VALUES ('DK_' + @p_ma_lop, @v_ma_hoc_vien, @p_ma_lop, 'Confirmed');

    INSERT INTO lop_hoc_mon (ma_lop, ma_mon, vai_tro_mon)
    SELECT @p_ma_lop, ma_mon, vai_tro_mon
    FROM yeu_cau_mon
    WHERE ma_yeu_cau = @p_ma_yeu_cau;
END;
GO

IF OBJECT_ID(N'dbo.sp_danh_gia', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_danh_gia;
GO

CREATE PROCEDURE dbo.sp_danh_gia
    @p_ma_danh_gia VARCHAR(20),
    @p_ma_dang_ky VARCHAR(20),
    @p_diem_sao SMALLINT,
    @p_nhan_xet NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO danh_gia (ma_danh_gia, ma_dang_ky, diem_sao, nhan_xet)
    VALUES (@p_ma_danh_gia, @p_ma_dang_ky, @p_diem_sao, @p_nhan_xet);
END;
GO

IF OBJECT_ID(N'dbo.sp_diem_danh', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_diem_danh;
GO

CREATE PROCEDURE dbo.sp_diem_danh
    @p_ma_buoi_hoc VARCHAR(20),
    @p_ma_dang_ky VARCHAR(20),
    @p_trang_thai VARCHAR(20),
    @p_so_phut_hoc INT = NULL
AS
BEGIN
    INSERT INTO diem_danh (ma_buoi_hoc, ma_dang_ky, trang_thai, so_phut_hoc)
    VALUES (@p_ma_buoi_hoc, @p_ma_dang_ky, @p_trang_thai, @p_so_phut_hoc);
END;
GO

IF OBJECT_ID(N'dbo.sp_toggle_trong_lich', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_toggle_trong_lich;
GO

CREATE PROCEDURE dbo.sp_toggle_trong_lich
    @p_ma_gia_su VARCHAR(20),
    @p_trong_lich BIT
AS
BEGIN
    UPDATE gia_su SET trong_lich = @p_trong_lich WHERE ma_gia_su = @p_ma_gia_su;
END;
GO

IF OBJECT_ID(N'dbo.sp_ghi_nhan_thanh_toan', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ghi_nhan_thanh_toan;
GO

CREATE PROCEDURE dbo.sp_ghi_nhan_thanh_toan
    @p_ma_giao_dich VARCHAR(30),
    @p_ma_dang_ky VARCHAR(20),
    @p_ma_tk_hv VARCHAR(20),
    @p_ma_tk_gs VARCHAR(20),
    @p_tong_tien DECIMAL(15,0),
    @p_ty_le DECIMAL(5,2),
    @p_loai_giao_dich VARCHAR(30) = 'ThanhToanThang'
AS
BEGIN
    DECLARE @v_phi DECIMAL(15,0);
    DECLARE @v_tien_nhan DECIMAL(15,0);

    SET @v_phi = @p_tong_tien * @p_ty_le / 100;
    SET @v_tien_nhan = @p_tong_tien - @v_phi;

    INSERT INTO giao_dich (ma_giao_dich, ma_dang_ky, ma_tk_hv, ma_tk_gs, tong_tien_thu, ty_le_hoa_hong, phi_hoa_hong, so_tien_gia_su_nhan, loai_giao_dich)
    VALUES (@p_ma_giao_dich, @p_ma_dang_ky, @p_ma_tk_hv, @p_ma_tk_gs, @p_tong_tien, @p_ty_le, @v_phi, @v_tien_nhan, @p_loai_giao_dich);

    UPDATE dang_ky SET trang_thai = 'Confirmed' WHERE ma_dang_ky = @p_ma_dang_ky;
END;
GO

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