
-- 1.1 HỌC VIÊN
CREATE TABLE hoc_vien (
    ma_hoc_vien     VARCHAR(20)   PRIMARY KEY,
    ho_ten          NVARCHAR(100) NOT NULL,
    ngay_sinh       DATE          NULL,
    so_dien_thoai   VARCHAR(15)   NULL,
    email           VARCHAR(150)  NULL,
    khoi_hien_tai   NVARCHAR(20)  NULL,
    auth_id         UNIQUEIDENTIFIER NULL, -- liên kết với auth provider
    ngay_tao        DATETIME      NOT NULL DEFAULT GETDATE(),
    ngay_cap_nhat   DATETIME      NOT NULL DEFAULT GETDATE()
);

-- 1.2 GIA SƯ
CREATE TABLE gia_su (
    ma_gia_su       VARCHAR(20)   PRIMARY KEY,
    ho_ten          NVARCHAR(100) NOT NULL,
    ngay_sinh       DATE          NULL,
    trinh_do        NVARCHAR(200) NULL,
    gioi_thieu      NVARCHAR(MAX) NULL,
    trong_lich      BIT           NOT NULL DEFAULT 1, -- 1: rảnh, 0: bận
    auth_id         UNIQUEIDENTIFIER NULL,
    ngay_tao        DATETIME      NOT NULL DEFAULT GETDATE(),
    ngay_cap_nhat   DATETIME      NOT NULL DEFAULT GETDATE()
);

-- 1.3 MÔN HỌC
CREATE TABLE mon_hoc (
    ma_mon          VARCHAR(20)   PRIMARY KEY,
    ten_mon         NVARCHAR(100) NOT NULL,
    cap_hoc         NVARCHAR(50)  NOT NULL,
    mo_ta           NVARCHAR(MAX) NULL
);

-- 1.4 GIA SƯ - MÔN HỌC (N-N)
CREATE TABLE gia_su_mon_hoc (
    ma_gia_su           VARCHAR(20)   NOT NULL REFERENCES gia_su(ma_gia_su) ON DELETE CASCADE,
    ma_mon              VARCHAR(20)   NOT NULL REFERENCES mon_hoc(ma_mon) ON DELETE CASCADE,
    nam_kinh_nghiem     INT           NOT NULL DEFAULT 0 CHECK (nam_kinh_nghiem >= 0),
    muc_do_thanh_thao   NVARCHAR(20)  NULL,
    chung_chi           NVARCHAR(MAX) NULL,
    PRIMARY KEY (ma_gia_su, ma_mon)
);

-- ============================================================================
-- PHẦN 2: YÊU CẦU LỚP & ỨNG TUYỂN
-- ============================================================================

-- 2.1 YÊU CẦU LỚP
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

-- 2.2 YÊU CẦU - MÔN HỌC
CREATE TABLE yeu_cau_mon (
    ma_yeu_cau      VARCHAR(20)   NOT NULL REFERENCES yeu_cau_lop(ma_yeu_cau) ON DELETE CASCADE,
    ma_mon          VARCHAR(20)   NOT NULL REFERENCES mon_hoc(ma_mon),
    vai_tro_mon     NVARCHAR(20)  NOT NULL DEFAULT N'Chính',
    ghi_chu         NVARCHAR(MAX) NULL,
    PRIMARY KEY (ma_yeu_cau, ma_mon)
);

-- 2.3 ỨNG TUYỂN
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

-- ============================================================================
-- PHẦN 3: LỚP HỌC & LỊCH HỌC
-- ============================================================================

-- 3.1 LỚP HỌC
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

-- 3.2 LỚP HỌC - MÔN HỌC
CREATE TABLE lop_hoc_mon (
    ma_lop              VARCHAR(20)   NOT NULL REFERENCES lop_hoc(ma_lop) ON DELETE CASCADE,
    ma_mon              VARCHAR(20)   NOT NULL REFERENCES mon_hoc(ma_mon),
    vai_tro_mon         NVARCHAR(20)  NOT NULL DEFAULT N'Chính',
    so_buoi_du_kien     INT           NULL CHECK (so_buoi_du_kien IS NULL OR so_buoi_du_kien >= 0),
    ghi_chu             NVARCHAR(MAX) NULL,
    PRIMARY KEY (ma_lop, ma_mon)
);

-- 3.3 LỊCH HỌC
CREATE TABLE lich_hoc (
    ma_lich             VARCHAR(20)   PRIMARY KEY,
    ma_lop              VARCHAR(20)   NOT NULL REFERENCES lop_hoc(ma_lop) ON DELETE CASCADE,
    thu_trong_tuan      SMALLINT      NOT NULL CHECK (thu_trong_tuan BETWEEN 1 AND 7),
    gio_bat_dau         TIME          NOT NULL,
    gio_ket_thuc        TIME          NOT NULL,
    CONSTRAINT ck_lich_hoc_gio CHECK (gio_ket_thuc > gio_bat_dau),
    UNIQUE (ma_lop, ma_lich)
);

-- 3.4 BUỔI HỌC
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

-- ============================================================================
-- PHẦN 4: ĐĂNG KÝ, THANH TOÁN, ĐÁNH GIÁ
-- ============================================================================

-- 4.1 ĐĂNG KÝ
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

-- 4.2 TÀI KHOẢN HỌC VIÊN
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

-- 4.3 TÀI KHOẢN GIA SƯ
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

-- 4.4 GIAO DỊCH
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

-- 4.5 ĐÁNH GIÁ
CREATE TABLE danh_gia (
    ma_danh_gia     VARCHAR(20)   PRIMARY KEY,
    ma_dang_ky      VARCHAR(20)   NOT NULL UNIQUE REFERENCES dang_ky(ma_dang_ky),
    diem_sao        SMALLINT      NOT NULL CHECK (diem_sao BETWEEN 1 AND 5),
    nhan_xet        NVARCHAR(MAX) NULL,
    ngay_danh_gia   DATETIME      NOT NULL DEFAULT GETDATE()
);

-- 4.6 ĐIỂM DANH
CREATE TABLE diem_danh (
    ma_buoi_hoc     VARCHAR(20)   NOT NULL REFERENCES buoi_hoc(ma_buoi_hoc) ON DELETE CASCADE,
    ma_dang_ky      VARCHAR(20)   NOT NULL REFERENCES dang_ky(ma_dang_ky),
    trang_thai      VARCHAR(20)   NOT NULL DEFAULT 'CoMat',
    so_phut_hoc     INT           NULL CHECK (so_phut_hoc IS NULL OR so_phut_hoc >= 0),
    ghi_chu         NVARCHAR(MAX) NULL,
    PRIMARY KEY (ma_buoi_hoc, ma_dang_ky)
);
