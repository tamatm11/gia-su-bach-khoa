-- ============================================================================
-- GIA SƯ BÁCH KHOA - COMPLETE POSTGRESQL SCHEMA FOR SUPABASE
-- Version: 2.0
-- Nghiệp vụ: 1 lớp = 1 gia sư + 1 học viên
-- Flow: Học viên tạo yêu cầu → Gia sư ứng tuyển → Học viên chọn → Tạo lớp
-- ============================================================================

-- ============================================================================
-- PHẦN 1: BẢNG CHÍNH
-- ============================================================================

-- 1.1 HỌC VIÊN
CREATE TABLE IF NOT EXISTS hoc_vien (
    ma_hoc_vien     VARCHAR(20)   PRIMARY KEY,
    ho_ten          NVARCHAR(100) NOT NULL,
    ngay_sinh       DATE          NULL,
    so_dien_thoai   VARCHAR(15)   NULL,
    email           VARCHAR(150)  NULL,
    khoi_hien_tai   VARCHAR(20)   NULL,
    auth_id         UUID          NULL UNIQUE, -- liên kết với auth.users
    ngay_tao        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    ngay_cap_nhat   TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- 1.2 GIA SƯ
CREATE TABLE IF NOT EXISTS gia_su (
    ma_gia_su       VARCHAR(20)   PRIMARY KEY,
    ho_ten          NVARCHAR(100) NOT NULL,
    ngay_sinh       DATE          NULL,
    trinh_do        NVARCHAR(200) NULL,
    gioi_thieu      TEXT          NULL,
    trong_lich      BOOLEAN       NOT NULL DEFAULT TRUE, -- toggle trạng thái rảnh/bận
    auth_id         UUID          NULL UNIQUE, -- liên kết với auth.users
    ngay_tao        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    ngay_cap_nhat   TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- 1.3 MÔN HỌC
CREATE TABLE IF NOT EXISTS mon_hoc (
    ma_mon          VARCHAR(20)   PRIMARY KEY,
    ten_mon         NVARCHAR(100) NOT NULL,
    cap_hoc         NVARCHAR(50)  NOT NULL,
    mo_ta           TEXT          NULL
);

-- 1.4 GIA SƯ - MÔN HỌC (N-N)
CREATE TABLE IF NOT EXISTS gia_su_mon_hoc (
    ma_gia_su           VARCHAR(20)   NOT NULL REFERENCES gia_su(ma_gia_su) ON DELETE CASCADE,
    ma_mon              VARCHAR(20)   NOT NULL REFERENCES mon_hoc(ma_mon) ON DELETE CASCADE,
    nam_kinh_nghiem     INT           NOT NULL DEFAULT 0 CHECK (nam_kinh_nghiem >= 0),
    muc_do_thanh_thao   VARCHAR(20)   NULL,
    chung_chi           TEXT          NULL,
    PRIMARY KEY (ma_gia_su, ma_mon)
);

-- ============================================================================
-- PHẦN 2: YÊU CẦU LỚP & ỨNG TUYỂN (FLOW CHÍNH)
-- ============================================================================

-- 2.1 YÊU CẦU LỚP (học viên tạo)
CREATE TABLE IF NOT EXISTS yeu_cau_lop (
    ma_yeu_cau              VARCHAR(20)   PRIMARY KEY,
    ma_hoc_vien             VARCHAR(20)   NOT NULL REFERENCES hoc_vien(ma_hoc_vien),
    tieu_de                 NVARCHAR(200) NOT NULL,
    mo_ta                   TEXT          NULL,
    tien_hoc_phi            DECIMAL(12,0) NOT NULL CHECK (tien_hoc_phi >= 0),
    dia_chi                 TEXT          NOT NULL,
    hinh_thuc_hoc           VARCHAR(20)   NOT NULL DEFAULT 'Offline', -- Offline | Online
    so_buoi_tuan            SMALLINT      NOT NULL CHECK (so_buoi_tuan BETWEEN 1 AND 7),
    thoi_gian_mong_muon     TEXT          NULL, -- mô tả thời gian mong muốn
    ngay_yeu_cau            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    trang_thai              VARCHAR(20)   NOT NULL DEFAULT 'open', -- open | closed | approved | cancelled
    ma_gia_su_duoc_chon     VARCHAR(20)   NULL REFERENCES gia_su(ma_gia_su), -- gia sư được chọn
    ngay_chon_gia_su        TIMESTAMPTZ   NULL, -- ngày học viên chọn gia sư
    ngay_cap_nhat           TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- 2.2 YÊU CẦU - MÔN HỌC
CREATE TABLE IF NOT EXISTS yeu_cau_mon (
    ma_yeu_cau      VARCHAR(20)   NOT NULL REFERENCES yeu_cau_lop(ma_yeu_cau) ON DELETE CASCADE,
    ma_mon          VARCHAR(20)   NOT NULL REFERENCES mon_hoc(ma_mon),
    vai_tro_mon     VARCHAR(20)   NOT NULL DEFAULT 'Chính', -- Chính | Phụ
    ghi_chu         TEXT          NULL,
    PRIMARY KEY (ma_yeu_cau, ma_mon)
);

-- 2.3 ỨNG TUYỂN (gia sư apply vào yêu cầu) - BẢNG MỚI CỐT LÕI
CREATE TABLE IF NOT EXISTS ung_tuyen (
    ma_ung_tuyen    VARCHAR(30)   PRIMARY KEY,
    ma_yeu_cau      VARCHAR(20)   NOT NULL REFERENCES yeu_cau_lop(ma_yeu_cau) ON DELETE CASCADE,
    ma_gia_su       VARCHAR(20)   NOT NULL REFERENCES gia_su(ma_gia_su),
    thu_nhap_mong_muon DECIMAL(12,0) NULL,
    loi_nhan        TEXT          NULL, -- lời nhắn của gia sư gửi học viên
    trang_thai      VARCHAR(20)   NOT NULL DEFAULT 'pending', -- pending | accepted | rejected | withdrawn
    ngay_ung_tuyen  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    ngay_xu_ly      TIMESTAMPTZ   NULL,
    UNIQUE (ma_yeu_cau, ma_gia_su) -- mỗi gia sư chỉ ứng tuyển 1 lần cho 1 yêu cầu
);

-- ============================================================================
-- PHẦN 3: LỚP HỌC & LỊCH HỌC
-- ============================================================================

-- 3.1 LỚP HỌC (1 gia sư + 1 học viên)
CREATE TABLE IF NOT EXISTS lop_hoc (
    ma_lop          VARCHAR(20)   PRIMARY KEY,
    ma_gia_su       VARCHAR(20)   NOT NULL REFERENCES gia_su(ma_gia_su),
    ma_hoc_vien     VARCHAR(20)   NOT NULL REFERENCES hoc_vien(ma_hoc_vien),
    ma_yeu_cau      VARCHAR(20)   NULL UNIQUE REFERENCES yeu_cau_lop(ma_yeu_cau),
    ma_ung_tuyen    VARCHAR(30)   NULL REFERENCES ung_tuyen(ma_ung_tuyen),
    hoc_phi         DECIMAL(12,0) NOT NULL CHECK (hoc_phi >= 0),
    dia_chi         TEXT          NOT NULL,
    hinh_thuc_day   VARCHAR(20)   NOT NULL DEFAULT 'Offline',
    ngay_bat_dau    DATE          NOT NULL,
    ngay_ket_thuc   DATE          NULL,
    trang_thai      VARCHAR(20)   NOT NULL DEFAULT 'SapMo', -- SapMo | Active | Completed | Cancelled
    so_hv_toi_da    SMALLINT      NOT NULL DEFAULT 1 CHECK (so_hv_toi_da = 1), -- luôn = 1
    tong_so_buoi    INT           NOT NULL CHECK (tong_so_buoi > 0),
    ngay_tao        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_lop_hoc_ngay CHECK (ngay_ket_thuc IS NULL OR ngay_ket_thuc >= ngay_bat_dau)
);

-- 3.2 LỚP HỌC - MÔN HỌC
CREATE TABLE IF NOT EXISTS lop_hoc_mon (
    ma_lop              VARCHAR(20)   NOT NULL REFERENCES lop_hoc(ma_lop) ON DELETE CASCADE,
    ma_mon              VARCHAR(20)   NOT NULL REFERENCES mon_hoc(ma_mon),
    vai_tro_mon         VARCHAR(20)   NOT NULL DEFAULT 'Chính',
    so_buoi_du_kien     INT           NULL CHECK (so_buoi_du_kien IS NULL OR so_buoi_du_kien >= 0),
    ghi_chu             TEXT          NULL,
    PRIMARY KEY (ma_lop, ma_mon)
);

-- 3.3 LỊCH HỌC (thời khóa biểu cố định)
CREATE TABLE IF NOT EXISTS lich_hoc (
    ma_lich             VARCHAR(20)   PRIMARY KEY,
    ma_lop              VARCHAR(20)   NOT NULL REFERENCES lop_hoc(ma_lop) ON DELETE CASCADE,
    thu_trong_tuan      SMALLINT      NOT NULL CHECK (thu_trong_tuan BETWEEN 1 AND 7),
    gio_bat_dau         TIME          NOT NULL,
    gio_ket_thuc        TIME          NOT NULL,
    CONSTRAINT ck_lich_hoc_gio CHECK (gio_ket_thuc > gio_bat_dau),
    UNIQUE (ma_lop, ma_lich)
);

-- 3.4 BUỔI HỌC (thực tế)
CREATE TABLE IF NOT EXISTS buoi_hoc (
    ma_buoi_hoc     VARCHAR(20)   PRIMARY KEY,
    ma_lop          VARCHAR(20)   NOT NULL REFERENCES lop_hoc(ma_lop) ON DELETE CASCADE,
    ma_lich         VARCHAR(20)   NULL,
    ngay_hoc        DATE          NOT NULL,
    gio_bat_dau     TIME          NOT NULL,
    gio_ket_thuc    TIME          NOT NULL,
    trang_thai      VARCHAR(20)   NOT NULL DEFAULT 'Scheduled', -- Scheduled | Done | Cancelled | Absent
    ghi_chu         TEXT          NULL,
    CONSTRAINT ck_buoi_hoc_gio CHECK (gio_ket_thuc > gio_bat_dau),
    FOREIGN KEY (ma_lich, ma_lop) REFERENCES lich_hoc(ma_lich, ma_lop) ON DELETE SET NULL
);

-- ============================================================================
-- PHẦN 4: ĐĂNG KÝ, THANH TOÁN, ĐÁNH GIÁ
-- ============================================================================

-- 4.1 ĐĂNG KÝ (học viên xác nhận vào lớp)
CREATE TABLE IF NOT EXISTS dang_ky (
    ma_dang_ky      VARCHAR(20)   PRIMARY KEY,
    ma_hoc_vien     VARCHAR(20)   NOT NULL REFERENCES hoc_vien(ma_hoc_vien),
    ma_lop          VARCHAR(20)   NOT NULL REFERENCES lop_hoc(ma_lop),
    ngay_dang_ky    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    trang_thai      VARCHAR(20)   NOT NULL DEFAULT 'Pending', -- Pending | Confirmed | Cancelled
    ghi_chu         TEXT          NULL,
    UNIQUE (ma_hoc_vien, ma_lop),
    UNIQUE (ma_lop) -- mỗi lớp chỉ 1 đăng ký
);

-- 4.2 TÀI KHOẢN HỌC VIÊN
CREATE TABLE IF NOT EXISTS tai_khoan_hv (
    ma_tk_hv            VARCHAR(20)   PRIMARY KEY,
    ma_hoc_vien         VARCHAR(20)   NOT NULL REFERENCES hoc_vien(ma_hoc_vien),
    so_tai_khoan        VARCHAR(30)   NOT NULL,
    nha_cung_cap        VARCHAR(100)  NOT NULL,
    loai_phuong_thuc    VARCHAR(30)   NOT NULL DEFAULT 'Bank',
    ten_chu_tk          VARCHAR(100)  NOT NULL,
    la_mac_dinh         BOOLEAN       NOT NULL DEFAULT FALSE,
    UNIQUE (ma_hoc_vien, so_tai_khoan, nha_cung_cap)
);

-- 4.3 TÀI KHOẢN GIA SƯ
CREATE TABLE IF NOT EXISTS tai_khoan_gs (
    ma_tk_gs            VARCHAR(20)   PRIMARY KEY,
    ma_gia_su           VARCHAR(20)   NOT NULL REFERENCES gia_su(ma_gia_su),
    so_tai_khoan        VARCHAR(30)   NOT NULL,
    nha_cung_cap        VARCHAR(100)  NOT NULL,
    loai_phuong_thuc    VARCHAR(30)   NOT NULL DEFAULT 'Bank',
    ten_chu_tk          VARCHAR(100)  NOT NULL,
    la_mac_dinh         BOOLEAN       NOT NULL DEFAULT FALSE,
    UNIQUE (ma_gia_su, so_tai_khoan, nha_cung_cap)
);

-- 4.4 GIAO DỊCH
CREATE TABLE IF NOT EXISTS giao_dich (
    ma_giao_dich            VARCHAR(30)   PRIMARY KEY,
    ma_dang_ky              VARCHAR(20)   NOT NULL REFERENCES dang_ky(ma_dang_ky),
    ma_tk_hv                VARCHAR(20)   NOT NULL REFERENCES tai_khoan_hv(ma_tk_hv),
    ma_tk_gs                VARCHAR(20)   NOT NULL REFERENCES tai_khoan_gs(ma_tk_gs),
    tong_tien_thu           DECIMAL(15,0) NOT NULL CHECK (tong_tien_thu > 0),
    ty_le_hoa_hong          DECIMAL(5,2)  NOT NULL CHECK (ty_le_hoa_hong BETWEEN 0 AND 100),
    phi_hoa_hong            DECIMAL(15,0) NOT NULL CHECK (phi_hoa_hong >= 0),
    so_tien_gia_su_nhan     DECIMAL(15,0) NOT NULL CHECK (so_tien_gia_su_nhan >= 0),
    ngay_thanh_toan         TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    ngay_doi_soat           TIMESTAMPTZ   NULL,
    trang_thai              VARCHAR(20)   NOT NULL DEFAULT 'Success',
    loai_giao_dich          VARCHAR(30)   NOT NULL DEFAULT 'ThanhToanThang',
    ma_tham_chieu           VARCHAR(100)  NULL UNIQUE,
    CONSTRAINT ck_giao_dich_toan_ven CHECK (
        phi_hoa_hong + so_tien_gia_su_nhan = tong_tien_thu
    ),
    CONSTRAINT ck_giao_dich_ngay CHECK (ngay_doi_soat IS NULL OR ngay_doi_soat >= ngay_thanh_toan)
);

-- 4.5 ĐÁNH GIÁ
CREATE TABLE IF NOT EXISTS danh_gia (
    ma_danh_gia     VARCHAR(20)   PRIMARY KEY,
    ma_dang_ky      VARCHAR(20)   NOT NULL UNIQUE REFERENCES dang_ky(ma_dang_ky),
    diem_sao        SMALLINT      NOT NULL CHECK (diem_sao BETWEEN 1 AND 5),
    nhan_xet        TEXT          NULL,
    ngay_danh_gia   TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- 4.6 ĐIỂM DANH
CREATE TABLE IF NOT EXISTS diem_danh (
    ma_buoi_hoc     VARCHAR(20)   NOT NULL REFERENCES buoi_hoc(ma_buoi_hoc) ON DELETE CASCADE,
    ma_dang_ky      VARCHAR(20)   NOT NULL REFERENCES dang_ky(ma_dang_ky),
    trang_thai      VARCHAR(20)   NOT NULL DEFAULT 'CoMat', -- CoMat | VangMat | DiTre | CoPhep
    so_phut_hoc     INT           NULL CHECK (so_phut_hoc IS NULL OR so_phut_hoc >= 0),
    ghi_chu         TEXT          NULL,
    PRIMARY KEY (ma_buoi_hoc, ma_dang_ky)
);

-- ============================================================================
-- PHẦN 5: THÔNG BÁO & AUDIT
-- ============================================================================

-- 5.1 THÔNG BÁO
CREATE TABLE IF NOT EXISTS thong_bao (
    ma_thong_bao    VARCHAR(30)   PRIMARY KEY,
    ma_hoc_vien     VARCHAR(20)   NULL REFERENCES hoc_vien(ma_hoc_vien) ON DELETE CASCADE,
    ma_gia_su       VARCHAR(20)   NULL REFERENCES gia_su(ma_gia_su) ON DELETE CASCADE,
    loai_thong_bao  VARCHAR(30)   NOT NULL,
    tieu_de         VARCHAR(200)  NOT NULL,
    noi_dung        TEXT          NOT NULL,
    da_doc          BOOLEAN       NOT NULL DEFAULT FALSE,
    ngay_tao        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    ma_yeu_cau      VARCHAR(20)   NULL,
    ma_lop          VARCHAR(20)   NULL,
    ma_giao_dich    VARCHAR(30)   NULL,
    ma_buoi_hoc     VARCHAR(20)   NULL,
    CONSTRAINT ck_thong_bao_nguoi_nhan CHECK (
        (CASE WHEN ma_hoc_vien IS NULL THEN 0 ELSE 1 END) +
        (CASE WHEN ma_gia_su IS NULL THEN 0 ELSE 1 END) = 1
    )
);

-- 5.2 AUDIT LOG (theo dõi thay đổi)
CREATE TABLE IF NOT EXISTS audit_log (
    id              BIGSERIAL     PRIMARY KEY,
    table_name      VARCHAR(50)   NOT NULL,
    record_id       VARCHAR(30)   NOT NULL,
    action          VARCHAR(10)   NOT NULL, -- INSERT | UPDATE | DELETE
    old_data        JSONB         NULL,
    new_data        JSONB         NULL,
    changed_by      VARCHAR(100)  NULL,
    changed_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- PHẦN 6: INDEXES
-- ============================================================================

-- Học viên
CREATE INDEX IF NOT EXISTS ix_hoc_vien_auth ON hoc_vien(auth_id);
CREATE UNIQUE INDEX IF NOT EXISTS ux_hoc_vien_sdt ON hoc_vien(so_dien_thoai) WHERE so_dien_thoai IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_hoc_vien_email ON hoc_vien(email) WHERE email IS NOT NULL;

-- Gia sư
CREATE INDEX IF NOT EXISTS ix_gia_su_auth ON gia_su(auth_id);
CREATE INDEX IF NOT EXISTS ix_gia_su_trong_lich ON gia_su(trong_lich) WHERE trong_lich = TRUE;

-- Môn học
CREATE INDEX IF NOT EXISTS ix_gia_su_mon_hoc_mon ON gia_su_mon_hoc(ma_mon);

-- Yêu cầu lớp
CREATE INDEX IF NOT EXISTS ix_yeu_cau_hoc_vien ON yeu_cau_lop(ma_hoc_vien, trang_thai);
CREATE INDEX IF NOT EXISTS ix_yeu_cau_trang_thai ON yeu_cau_lop(trang_thai, ngay_yeu_cau DESC);

-- Ứng tuyển
CREATE INDEX IF NOT EXISTS ix_ung_tuyen_yeu_cau ON ung_tuyen(ma_yeu_cau, trang_thai);
CREATE INDEX IF NOT EXISTS ix_ung_tuyen_gia_su ON ung_tuyen(ma_gia_su, trang_thai);

-- Lớp học
CREATE INDEX IF NOT EXISTS ix_lop_hoc_gia_su ON lop_hoc(ma_gia_su, trang_thai);
CREATE INDEX IF NOT EXISTS ix_lop_hoc_hoc_vien ON lop_hoc(ma_hoc_vien, trang_thai);

-- Lịch học
CREATE INDEX IF NOT EXISTS ix_lich_hoc_lop ON lich_hoc(ma_lop, thu_trong_tuan, gio_bat_dau);
CREATE UNIQUE INDEX IF NOT EXISTS ux_lich_hoc_lop_thu_gio ON lich_hoc(ma_lop, thu_trong_tuan, gio_bat_dau);

-- Buổi học
CREATE INDEX IF NOT EXISTS ix_buoi_hoc_lop_ngay ON buoi_hoc(ma_lop, ngay_hoc);

-- Đăng ký
CREATE INDEX IF NOT EXISTS ix_dang_ky_lop ON dang_ky(ma_lop, trang_thai);

-- Giao dịch
CREATE INDEX IF NOT EXISTS ix_giao_dich_dang_ky ON giao_dich(ma_dang_ky, ngay_thanh_toan DESC);

-- Thông báo
CREATE INDEX IF NOT EXISTS ix_thong_bao_hv ON thong_bao(ma_hoc_vien, da_doc, ngay_tao DESC) WHERE ma_hoc_vien IS NOT NULL;
CREATE INDEX IF NOT EXISTS ix_thong_bao_gs ON thong_bao(ma_gia_su, da_doc, ngay_tao DESC) WHERE ma_gia_su IS NOT NULL;

-- Điểm danh
CREATE INDEX IF NOT EXISTS ix_diem_danh_dang_ky ON diem_danh(ma_dang_ky, ma_buoi_hoc);

-- Tài khoản
CREATE UNIQUE INDEX IF NOT EXISTS ux_tk_hv_mac_dinh ON tai_khoan_hv(ma_hoc_vien) WHERE la_mac_dinh = TRUE;
CREATE UNIQUE INDEX IF NOT EXISTS ux_tk_gs_mac_dinh ON tai_khoan_gs(ma_gia_su) WHERE la_mac_dinh = TRUE;

-- ============================================================================
-- PHẦN 7: FUNCTIONS
-- ============================================================================

-- 7.1 Tính điểm trung bình gia sư
CREATE OR REPLACE FUNCTION fn_tinh_diem_tb_gia_su(p_ma_gia_su VARCHAR)
RETURNS DECIMAL(3,2) AS $$
DECLARE
    v_diem DECIMAL(3,2);
BEGIN
    SELECT AVG(dg.diem_sao)::DECIMAL(3,2)
    INTO v_diem
    FROM danh_gia dg
    JOIN dang_ky dk ON dg.ma_dang_ky = dk.ma_dang_ky
    JOIN lop_hoc lh ON dk.ma_lop = lh.ma_lop
    WHERE lh.ma_gia_su = p_ma_gia_su;

    RETURN COALESCE(v_diem, 0);
END;
$$ LANGUAGE plpgsql;

-- 7.2 Kiểm tra trùng lịch gia sư (QUAN TRỌNG)
CREATE OR REPLACE FUNCTION fn_kiem_tra_trung_lich(
    p_ma_gia_su VARCHAR,
    p_thu SMALLINT,
    p_gio_bat_dau TIME,
    p_gio_ket_thuc TIME,
    p_ma_lop_exclude VARCHAR DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_trung BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM lich_hoc lh
        JOIN lop_hoc l ON lh.ma_lop = l.ma_lop
        WHERE l.ma_gia_su = p_ma_gia_su
          AND lh.thu_trong_tuan = p_thu
          AND l.trang_thai IN ('SapMo', 'Active')
          AND (p_ma_lop_exclude IS NULL OR l.ma_lop != p_ma_lop_exclude)
          AND (p_gio_bat_dau < lh.gio_ket_thuc AND p_gio_ket_thuc > lh.gio_bat_dau)
    ) INTO v_trung;

    RETURN v_trung;
END;
$$ LANGUAGE plpgsql;

-- 7.3 Đếm số lớp đang dạy của gia sư
CREATE OR REPLACE FUNCTION fn_dem_lop_dang_day(p_ma_gia_su VARCHAR)
RETURNS INT AS $$
DECLARE
    v_so_lop INT;
BEGIN
    SELECT COUNT(*) INTO v_so_lop
    FROM lop_hoc
    WHERE ma_gia_su = p_ma_gia_su AND trang_thai IN ('SapMo', 'Active');

    RETURN v_so_lop;
END;
$$ LANGUAGE plpgsql;

-- 7.4 Tính tổng doanh thu gia sư theo tháng
CREATE OR REPLACE FUNCTION fn_doanh_thu_gia_su(
    p_ma_gia_su VARCHAR,
    p_thang INT,
    p_nam INT
)
RETURNS DECIMAL(15,0) AS $$
DECLARE
    v_tong DECIMAL(15,0);
BEGIN
    SELECT COALESCE(SUM(gd.so_tien_gia_su_nhan), 0)
    INTO v_tong
    FROM giao_dich gd
    JOIN tai_khoan_gs tk ON gd.ma_tk_gs = tk.ma_tk_gs
    WHERE tk.ma_gia_su = p_ma_gia_su
      AND EXTRACT(MONTH FROM gd.ngay_thanh_toan) = p_thang
      AND EXTRACT(YEAR FROM gd.ngay_thanh_toan) = p_nam
      AND gd.trang_thai = 'Success';

    RETURN v_tong;
END;
$$ LANGUAGE plpgsql;

-- 7.5 Kiểm tra học viên hợp lệ
CREATE OR REPLACE FUNCTION fn_hoc_vien_hop_le(p_ma_hoc_vien VARCHAR)
RETURNS BOOLEAN AS $$
DECLARE
    v_hop_le BOOLEAN := TRUE;
BEGIN
    -- Kiểm tra có giao dịch fail nào chưa xử lý không
    IF EXISTS (
        SELECT 1 FROM giao_dich gd
        JOIN dang_ky dk ON gd.ma_dang_ky = dk.ma_dang_ky
        WHERE dk.ma_hoc_vien = p_ma_hoc_vien AND gd.trang_thai = 'Failed'
    ) THEN
        v_hop_le := FALSE;
    END IF;

    RETURN v_hop_le;
END;
$$ LANGUAGE plpgsql;

-- 7.6 Format giờ học thành chuỗi
CREATE OR REPLACE FUNCTION fn_format_gio_hoc(p_gio_bd TIME, p_gio_kt TIME)
RETURNS VARCHAR(50) AS $$
BEGIN
    RETURN TO_CHAR(p_gio_bd, 'HH24:MI') || ' - ' || TO_CHAR(p_gio_kt, 'HH24:MI');
END;
$$ LANGUAGE plpgsql;

-- 7.7 Lấy danh sách khung giờ trống của gia sư trong tuần
CREATE OR REPLACE FUNCTION fn_khung_gio_trong(p_ma_gia_su VARCHAR, p_thu SMALLINT)
RETURNS TABLE (
    gio_bat_dau TIME,
    gio_ket_thuc TIME
) AS $$
BEGIN
    -- Trả về các khung giờ gia sư đang bận trong ngày p_thu
    RETURN QUERY
    SELECT lh.gio_bat_dau, lh.gio_ket_thuc
    FROM lich_hoc lh
    JOIN lop_hoc l ON lh.ma_lop = l.ma_lop
    WHERE l.ma_gia_su = p_ma_gia_su
      AND lh.thu_trong_tuan = p_thu
      AND l.trang_thai IN ('SapMo', 'Active')
    ORDER BY lh.gio_bat_dau;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PHẦN 8: TRIGGERS
-- ============================================================================

-- 8.1 Tự động cập nhật ngay_cap_nhat
CREATE OR REPLACE FUNCTION trg_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.ngay_cap_nhat = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_hoc_vien_updated_at
    BEFORE UPDATE ON hoc_vien
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER tr_gia_su_updated_at
    BEFORE UPDATE ON gia_su
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER tr_yeu_cau_lop_updated_at
    BEFORE UPDATE ON yeu_cau_lop
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- 8.2 Validate DIEM_DANH: buổi học và đăng ký phải cùng lớp
CREATE OR REPLACE FUNCTION trg_validate_diem_danh()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM buoi_hoc bh
        JOIN dang_ky dk ON NEW.ma_dang_ky = dk.ma_dang_ky
        WHERE bh.ma_buoi_hoc = NEW.ma_buoi_hoc
          AND bh.ma_lop != dk.ma_lop
    ) THEN
        RAISE EXCEPTION 'DIEM_DANH: Buổi học và Đăng ký không cùng lớp học.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_diem_danh_validate
    BEFORE INSERT OR UPDATE ON diem_danh
    FOR EACH ROW EXECUTE FUNCTION trg_validate_diem_danh();

-- 8.3 Validate GIAO_DICH: tài khoản phải khớp chủ sở hữu
CREATE OR REPLACE FUNCTION trg_validate_giao_dich()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM dang_ky dk
        JOIN lop_hoc lh ON dk.ma_lop = lh.ma_lop
        JOIN tai_khoan_hv tkhv ON NEW.ma_tk_hv = tkhv.ma_tk_hv
        JOIN tai_khoan_gs tkgs ON NEW.ma_tk_gs = tkgs.ma_tk_gs
        WHERE dk.ma_dang_ky = NEW.ma_dang_ky
          AND (tkhv.ma_hoc_vien != dk.ma_hoc_vien OR tkgs.ma_gia_su != lh.ma_gia_su)
    ) THEN
        RAISE EXCEPTION 'GIAO_DICH: Tài khoản không khớp với chủ đăng ký hoặc gia sư.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_giao_dich_validate
    BEFORE INSERT OR UPDATE ON giao_dich
    FOR EACH ROW EXECUTE FUNCTION trg_validate_giao_dich();

-- 8.4 Validate TRÙNG LỊCH khi thêm LỊCH HỌC (CỐT LÕI)
CREATE OR REPLACE FUNCTION trg_validate_lich_hoc_trung()
RETURNS TRIGGER AS $$
DECLARE
    v_ma_gia_su VARCHAR(20);
BEGIN
    SELECT ma_gia_su INTO v_ma_gia_su
    FROM lop_hoc WHERE ma_lop = NEW.ma_lop;

    IF fn_kiem_tra_trung_lich(v_ma_gia_su, NEW.thu_trong_tuan, NEW.gio_bat_dau, NEW.gio_ket_thuc, NEW.ma_lop) THEN
        RAISE EXCEPTION 'LICH_HOC: Gia sư % đã có lịch trùng vào thứ %, giờ % - %.',
            v_ma_gia_su, NEW.thu_trong_tuan, NEW.gio_bat_dau, NEW.gio_ket_thuc;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_lich_hoc_check_trung
    BEFORE INSERT OR UPDATE ON lich_hoc
    FOR EACH ROW EXECUTE FUNCTION trg_validate_lich_hoc_trung();

-- 8.5 Validate TRÙNG LỊCH khi thêm BUỔI HỌC
CREATE OR REPLACE FUNCTION trg_validate_buoi_hoc_trung()
RETURNS TRIGGER AS $$
DECLARE
    v_ma_gia_su VARCHAR(20);
    v_thu SMALLINT;
BEGIN
    SELECT ma_gia_su INTO v_ma_gia_su
    FROM lop_hoc WHERE ma_lop = NEW.ma_lop;

    -- Tính thứ trong tuần từ ngày học
    v_thu := EXTRACT(ISODOW FROM NEW.ngay_hoc)::SMALLINT;

    IF fn_kiem_tra_trung_lich(v_ma_gia_su, v_thu, NEW.gio_bat_dau, NEW.gio_ket_thuc, NEW.ma_lop) THEN
        RAISE EXCEPTION 'BUOI_HOC: Gia sư % đã có lịch trùng vào ngày % giờ % - %.',
            v_ma_gia_su, NEW.ngay_hoc, NEW.gio_bat_dau, NEW.gio_ket_thuc;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_buoi_hoc_check_trung
    BEFORE INSERT OR UPDATE ON buoi_hoc
    FOR EACH ROW EXECUTE FUNCTION trg_validate_buoi_hoc_trung();

-- 8.6 Tự động tạo THÔNG BÁO khi có ứng tuyển mới
CREATE OR REPLACE FUNCTION trg_notify_ung_tuyen()
RETURNS TRIGGER AS $$
DECLARE
    v_ma_hoc_vien VARCHAR(20);
    v_ten_gs VARCHAR(200);
    v_tieu_de VARCHAR(200);
BEGIN
    -- Lấy thông tin học viên từ yêu cầu
    SELECT yc.ma_hoc_vien INTO v_ma_hoc_vien
    FROM yeu_cau_lop yc WHERE yc.ma_yeu_cau = NEW.ma_yeu_cau;

    -- Lấy tên gia sư
    SELECT ho_ten INTO v_ten_gs FROM gia_su WHERE ma_gia_su = NEW.ma_gia_su;

    v_tieu_de := 'Gia sư ' || v_ten_gs || ' đã ứng tuyển vào yêu cầu ' || NEW.ma_yeu_cau;

    INSERT INTO thong_bao (ma_thong_bao, ma_hoc_vien, loai_thong_bao, tieu_de, noi_dung, ma_yeu_cau)
    VALUES (
        'TB_' || REPLACE(gen_random_uuid()::TEXT, '-', ''),
        v_ma_hoc_vien,
        'UngTuyen',
        v_tieu_de,
        'Gia sư ' || v_ten_gs || ' đã ứng tuyển. Xem chi tiết và phản hồi trong mục "Yêu cầu của tôi".',
        NEW.ma_yeu_cau
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_ung_tuyen_notify
    AFTER INSERT ON ung_tuyen
    FOR EACH ROW EXECUTE FUNCTION trg_notify_ung_tuyen();

-- 8.7 Tự động thông báo khi học viên chọn gia sư
CREATE OR REPLACE FUNCTION trg_notify_chon_gia_su()
RETURNS TRIGGER AS $$
DECLARE
    v_ten_hv VARCHAR(200);
    v_ten_gs VARCHAR(200);
BEGIN
    -- Chỉ kích hoạt khi cột ma_gia_su_duoc_chon thay đổi từ NULL sang có giá trị
    IF OLD.ma_gia_su_duoc_chon IS NULL AND NEW.ma_gia_su_duoc_chon IS NOT NULL THEN
        SELECT ho_ten INTO v_ten_hv FROM hoc_vien WHERE ma_hoc_vien = NEW.ma_hoc_vien;
        SELECT ho_ten INTO v_ten_gs FROM gia_su WHERE ma_gia_su = NEW.ma_gia_su_duoc_chon;

        -- Thông báo cho gia sư được chọn
        INSERT INTO thong_bao (ma_thong_bao, ma_gia_su, loai_thong_bao, tieu_de, noi_dung, ma_yeu_cau)
        VALUES (
            'TB_' || REPLACE(gen_random_uuid()::TEXT, '-', ''),
            NEW.ma_gia_su_duoc_chon,
            'DuocChon',
            'Bạn đã được chọn cho yêu cầu ' || NEW.ma_yeu_cau,
            'Học viên ' || v_ten_hv || ' đã chọn bạn. Lớp học sẽ sớm được tạo.',
            NEW.ma_yeu_cau
        );

        -- Thông báo cho các gia sư khác bị từ chối
        INSERT INTO thong_bao (ma_thong_bao, ma_gia_su, loai_thong_bao, tieu_de, noi_dung, ma_yeu_cau)
        SELECT
            'TB_' || REPLACE(gen_random_uuid()::TEXT, '-', ''),
            ut.ma_gia_su,
            'TuChoi',
            'Yêu cầu ' || NEW.ma_yeu_cau || ' đã có gia sư được chọn',
            'Học viên ' || v_ten_hv || ' đã chọn gia sư khác cho yêu cầu này.',
            NEW.ma_yeu_cau
        FROM ung_tuyen ut
        WHERE ut.ma_yeu_cau = NEW.ma_yeu_cau
          AND ut.ma_gia_su != NEW.ma_gia_su_duoc_chon
          AND ut.trang_thai = 'pending';

        -- Cập nhật trạng thái ứng tuyển
        UPDATE ung_tuyen SET trang_thai = 'rejected', ngay_xu_ly = NOW()
        WHERE ma_yeu_cau = NEW.ma_yeu_cau
          AND ma_gia_su != NEW.ma_gia_su_duoc_chon
          AND trang_thai = 'pending';

        UPDATE ung_tuyen SET trang_thai = 'accepted', ngay_xu_ly = NOW()
        WHERE ma_yeu_cau = NEW.ma_yeu_cau
          AND ma_gia_su = NEW.ma_gia_su_duoc_chon;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_yeu_cau_chon_gia_su
    AFTER UPDATE ON yeu_cau_lop
    FOR EACH ROW EXECUTE FUNCTION trg_notify_chon_gia_su();

-- 8.8 Kiểm tra sĩ số khi insert DANG_KY (luôn fail nếu so_hv_toi_da != actual count)
CREATE OR REPLACE FUNCTION trg_dang_ky_check_siso()
RETURNS TRIGGER AS $$
DECLARE
    v_max SMALLINT;
    v_current INT;
BEGIN
    SELECT so_hv_toi_da INTO v_max FROM lop_hoc WHERE ma_lop = NEW.ma_lop;

    SELECT COUNT(*) INTO v_current
    FROM dang_ky
    WHERE ma_lop = NEW.ma_lop AND trang_thai IN ('Pending', 'Confirmed');

    IF v_current >= v_max THEN
        RAISE EXCEPTION 'Lớp học đã đủ sĩ số tối đa (% học viên).', v_max;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_dang_ky_check_siso
    BEFORE INSERT ON dang_ky
    FOR EACH ROW EXECUTE FUNCTION trg_dang_ky_check_siso();

-- 8.9 Audit log cho các bảng quan trọng
CREATE OR REPLACE FUNCTION trg_audit_log()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, record_id, action, new_data, changed_at)
        VALUES (TG_TABLE_NAME, NEW.ma_lop::TEXT, 'INSERT', to_jsonb(NEW), NOW());
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_data, new_data, changed_at)
        VALUES (TG_TABLE_NAME, NEW.ma_lop::TEXT, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), NOW());
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_data, changed_at)
        VALUES (TG_TABLE_NAME, OLD.ma_lop::TEXT, 'DELETE', to_jsonb(OLD), NOW());
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_audit_lop_hoc
    AFTER INSERT OR UPDATE OR DELETE ON lop_hoc
    FOR EACH ROW EXECUTE FUNCTION trg_audit_log();

-- ============================================================================
-- PHẦN 9: VIEWS
-- ============================================================================

-- 9.1 Tổng hợp gia sư
CREATE OR REPLACE VIEW vw_gia_su_tong_hop AS
SELECT
    gs.ma_gia_su,
    gs.ho_ten,
    gs.trinh_do,
    gs.trong_lich,
    gs.gioi_thieu,
    COALESCE(fn_tinh_diem_tb_gia_su(gs.ma_gia_su), 0) AS diem_danh_gia_tb,
    COALESCE(fn_dem_lop_dang_day(gs.ma_gia_su), 0) AS so_lop_dang_day,
    COALESCE((
        SELECT COUNT(*) FROM ung_tuyen ut
        WHERE ut.ma_gia_su = gs.ma_gia_su AND ut.trang_thai = 'accepted'
    ), 0) AS so_lop_da_nhan
FROM gia_su gs;

-- 9.2 Chi tiết đánh giá
CREATE OR REPLACE VIEW vw_danh_gia_chi_tiet AS
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

-- 9.3 Chi tiết giao dịch
CREATE OR REPLACE VIEW vw_giao_dich_chi_tiet AS
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

-- 9.4 Chi tiết lớp học
CREATE OR REPLACE VIEW vw_lop_hoc_chi_tiet AS
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

-- 9.5 Lịch trình gia sư
CREATE OR REPLACE VIEW vw_lich_trinh_gia_su AS
SELECT
    gs.ma_gia_su,
    gs.ho_ten AS ten_gia_su,
    l.ma_lop,
    l.trang_thai AS trang_thai_lop,
    lh.thu_trong_tuan,
    lh.gio_bat_dau,
    lh.gio_ket_thuc,
    fn_format_gio_hoc(lh.gio_bat_dau, lh.gio_ket_thuc) AS khoang_thoi_gian
FROM lich_hoc lh
JOIN lop_hoc l ON lh.ma_lop = l.ma_lop
JOIN gia_su gs ON l.ma_gia_su = gs.ma_gia_su
WHERE l.trang_thai IN ('SapMo', 'Active');

-- 9.6 Thống kê doanh thu
CREATE OR REPLACE VIEW vw_thong_ke_doanh_thu AS
SELECT
    EXTRACT(YEAR FROM ngay_thanh_toan)::INT AS nam,
    EXTRACT(MONTH FROM ngay_thanh_toan)::INT AS thang,
    trang_thai,
    COUNT(*) AS so_luong_giao_dich,
    SUM(tong_tien_thu) AS tong_doanh_thu,
    SUM(phi_hoa_hong) AS tong_loi_nhuan,
    SUM(so_tien_gia_su_nhan) AS tong_chi_tra_gia_su
FROM giao_dich
GROUP BY nam, thang, trang_thai
ORDER BY nam DESC, thang DESC;

-- 9.7 Danh sách yêu cầu đang mở (có thể ứng tuyển)
CREATE OR REPLACE VIEW vw_yeu_cau_dang_mo AS
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
    (SELECT STRING_AGG(ten_mon, ', ') FROM yeu_cau_mon ycm JOIN mon_hoc mh ON ycm.ma_mon = mh.ma_mon WHERE ycm.ma_yeu_cau = yc.ma_yeu_cau) AS cac_mon_hoc
FROM yeu_cau_lop yc
JOIN hoc_vien hv ON yc.ma_hoc_vien = hv.ma_hoc_vien
WHERE yc.trang_thai IN ('open', 'approved');

-- ============================================================================
-- PHẦN 10: STORED PROCEDURES
-- ============================================================================

-- 10.1 Tạo yêu cầu lớp
CREATE OR REPLACE PROCEDURE sp_tao_yeu_cau_lop(
    p_ma_yeu_cau VARCHAR,
    p_ma_hoc_vien VARCHAR,
    p_tieu_de VARCHAR,
    p_mo_ta TEXT,
    p_tien_hoc_phi DECIMAL,
    p_dia_chi TEXT,
    p_hinh_thuc_hoc VARCHAR,
    p_so_buoi_tuan SMALLINT,
    p_thoi_gian_mong_muon TEXT
) AS $$
BEGIN
    INSERT INTO yeu_cau_lop (ma_yeu_cau, ma_hoc_vien, tieu_de, mo_ta, tien_hoc_phi, dia_chi, hinh_thuc_hoc, so_buoi_tuan, thoi_gian_mong_muon, trang_thai)
    VALUES (p_ma_yeu_cau, p_ma_hoc_vien, p_tieu_de, p_mo_ta, p_tien_hoc_phi, p_dia_chi, p_hinh_thuc_hoc, p_so_buoi_tuan, p_thoi_gian_mong_muon, 'open');
END;
$$ LANGUAGE plpgsql;

-- 10.2 Gia sư ứng tuyển
CREATE OR REPLACE PROCEDURE sp_ung_tuyen(
    p_ma_ung_tuyen VARCHAR,
    p_ma_yeu_cau VARCHAR,
    p_ma_gia_su VARCHAR,
    p_thu_nhap_mong_muon DECIMAL DEFAULT NULL,
    p_loi_nhan TEXT DEFAULT NULL
) AS $$
BEGIN
    -- Kiểm tra yêu cầu còn mở không
    IF NOT EXISTS (SELECT 1 FROM yeu_cau_lop WHERE ma_yeu_cau = p_ma_yeu_cau AND trang_thai = 'open') THEN
        RAISE EXCEPTION 'Yêu cầu này không còn mở để ứng tuyển.';
    END IF;

    -- Kiểm tra gia sư có đang trống lịch không
    IF NOT EXISTS (SELECT 1 FROM gia_su WHERE ma_gia_su = p_ma_gia_su AND trong_lich = TRUE) THEN
        RAISE EXCEPTION 'Gia sư đang bận, không thể ứng tuyển.';
    END IF;

    INSERT INTO ung_tuyen (ma_ung_tuyen, ma_yeu_cau, ma_gia_su, thu_nhap_mong_muon, loi_nhan)
    VALUES (p_ma_ung_tuyen, p_ma_yeu_cau, p_ma_gia_su, p_thu_nhap_mong_muon, p_loi_nhan);
END;
$$ LANGUAGE plpgsql;

-- 10.3 Học viên chọn gia sư
CREATE OR REPLACE PROCEDURE sp_chon_gia_su(
    p_ma_yeu_cau VARCHAR,
    p_ma_gia_su VARCHAR
) AS $$
BEGIN
    -- Kiểm tra gia sư có ứng tuyển không
    IF NOT EXISTS (
        SELECT 1 FROM ung_tuyen
        WHERE ma_yeu_cau = p_ma_yeu_cau AND ma_gia_su = p_ma_gia_su AND trang_thai = 'pending'
    ) THEN
        RAISE EXCEPTION 'Gia sư chưa ứng tuyển hoặc đã được xử lý.';
    END IF;

    -- Cập nhật yêu cầu
    UPDATE yeu_cau_lop
    SET ma_gia_su_duoc_chon = p_ma_gia_su,
        ngay_chon_gia_su = NOW(),
        trang_thai = 'closed'
    WHERE ma_yeu_cau = p_ma_yeu_cau;
END;
$$ LANGUAGE plpgsql;

-- 10.4 Tạo lớp học từ yêu cầu đã chọn
CREATE OR REPLACE PROCEDURE sp_tao_lop_hoc(
    p_ma_lop VARCHAR,
    p_ma_yeu_cau VARCHAR,
    p_ngay_bat_dau DATE,
    p_tong_so_buoi INT
) AS $$
DECLARE
    v_ma_hoc_vien VARCHAR(20);
    v_ma_gia_su VARCHAR(20);
    v_hoc_phi DECIMAL;
    v_dia_chi TEXT;
    v_hinh_thuc VARCHAR(20);
BEGIN
    -- Lấy thông tin từ yêu cầu
    SELECT ma_hoc_vien, ma_gia_su_duoc_chon, tien_hoc_phi, dia_chi, hinh_thuc_hoc
    INTO v_ma_hoc_vien, v_ma_gia_su, v_hoc_phi, v_dia_chi, v_hinh_thuc
    FROM yeu_cau_lop
    WHERE ma_yeu_cau = p_ma_yeu_cau
      AND trang_thai = 'closed'
      AND ma_gia_su_duoc_chon IS NOT NULL;

    IF v_ma_hoc_vien IS NULL THEN
        RAISE EXCEPTION 'Yêu cầu chưa được chọn gia sư hoặc không tồn tại.';
    END IF;

    -- Tạo lớp học
    INSERT INTO lop_hoc (ma_lop, ma_gia_su, ma_hoc_vien, ma_yeu_cau, hoc_phi, dia_chi, hinh_thuc_day, ngay_bat_dau, tong_so_buoi, trang_thai)
    VALUES (p_ma_lop, v_ma_gia_su, v_ma_hoc_vien, p_ma_yeu_cau, v_hoc_phi, v_dia_chi, v_hinh_thuc, p_ngay_bat_dau, p_tong_so_buoi, 'SapMo');

    -- Cập nhật trạng thái yêu cầu
    UPDATE yeu_cau_lop SET trang_thai = 'approved' WHERE ma_yeu_cau = p_ma_yeu_cau;

    -- Tự động tạo đăng ký cho học viên
    INSERT INTO dang_ky (ma_dang_ky, ma_hoc_vien, ma_lop, trang_thai)
    VALUES ('DK_' || p_ma_lop, v_ma_hoc_vien, p_ma_lop, 'Confirmed');

    -- Copy môn học từ yêu cầu sang lớp
    INSERT INTO lop_hoc_mon (ma_lop, ma_mon, vai_tro_mon)
    SELECT p_ma_lop, ma_mon, vai_tro_mon
    FROM yeu_cau_mon
    WHERE ma_yeu_cau = p_ma_yeu_cau;
END;
$$ LANGUAGE plpgsql;

-- 10.5 Đánh giá gia sư
CREATE OR REPLACE PROCEDURE sp_danh_gia(
    p_ma_danh_gia VARCHAR,
    p_ma_dang_ky VARCHAR,
    p_diem_sao SMALLINT,
    p_nhan_xet TEXT DEFAULT NULL
) AS $$
BEGIN
    INSERT INTO danh_gia (ma_danh_gia, ma_dang_ky, diem_sao, nhan_xet)
    VALUES (p_ma_danh_gia, p_ma_dang_ky, p_diem_sao, p_nhan_xet);
END;
$$ LANGUAGE plpgsql;

-- 10.6 Điểm danh
CREATE OR REPLACE PROCEDURE sp_diem_danh(
    p_ma_buoi_hoc VARCHAR,
    p_ma_dang_ky VARCHAR,
    p_trang_thai VARCHAR,
    p_so_phut_hoc INT DEFAULT NULL
) AS $$
BEGIN
    INSERT INTO diem_danh (ma_buoi_hoc, ma_dang_ky, trang_thai, so_phut_hoc)
    VALUES (p_ma_buoi_hoc, p_ma_dang_ky, p_trang_thai, p_so_phut_hoc);
END;
$$ LANGUAGE plpgsql;

-- 10.7 Gia sư toggle trạng thái trống lịch
CREATE OR REPLACE PROCEDURE sp_toggle_trong_lich(
    p_ma_gia_su VARCHAR,
    p_trong_lich BOOLEAN
) AS $$
BEGIN
    UPDATE gia_su SET trong_lich = p_trong_lich WHERE ma_gia_su = p_ma_gia_su;
END;
$$ LANGUAGE plpgsql;

-- 10.8 Ghi nhận thanh toán
CREATE OR REPLACE PROCEDURE sp_ghi_nhan_thanh_toan(
    p_ma_giao_dich VARCHAR,
    p_ma_dang_ky VARCHAR,
    p_ma_tk_hv VARCHAR,
    p_ma_tk_gs VARCHAR,
    p_tong_tien DECIMAL,
    p_ty_le DECIMAL,
    p_loai_giao_dich VARCHAR DEFAULT 'ThanhToanThang'
) AS $$
DECLARE
    v_phi DECIMAL(15,0);
    v_tien_nhan DECIMAL(15,0);
BEGIN
    v_phi := p_tong_tien * p_ty_le / 100;
    v_tien_nhan := p_tong_tien - v_phi;

    INSERT INTO giao_dich (ma_giao_dich, ma_dang_ky, ma_tk_hv, ma_tk_gs, tong_tien_thu, ty_le_hoa_hong, phi_hoa_hong, so_tien_gia_su_nhan, loai_giao_dich)
    VALUES (p_ma_giao_dich, p_ma_dang_ky, p_ma_tk_hv, p_ma_tk_gs, p_tong_tien, p_ty_le, v_phi, v_tien_nhan, p_loai_giao_dich);

    UPDATE dang_ky SET trang_thai = 'Confirmed' WHERE ma_dang_ky = p_ma_dang_ky;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PHẦN 11: ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Bật RLS cho các bảng chính
ALTER TABLE hoc_vien ENABLE ROW LEVEL SECURITY;
ALTER TABLE gia_su ENABLE ROW LEVEL SECURITY;
ALTER TABLE yeu_cau_lop ENABLE ROW LEVEL SECURITY;
ALTER TABLE ung_tuyen ENABLE ROW LEVEL SECURITY;
ALTER TABLE lop_hoc ENABLE ROW LEVEL SECURITY;
ALTER TABLE lich_hoc ENABLE ROW LEVEL SECURITY;
ALTER TABLE buoi_hoc ENABLE ROW LEVEL SECURITY;
ALTER TABLE dang_ky ENABLE ROW LEVEL SECURITY;
ALTER TABLE giao_dich ENABLE ROW LEVEL SECURITY;
ALTER TABLE danh_gia ENABLE ROW LEVEL SECURITY;
ALTER TABLE thong_bao ENABLE ROW LEVEL SECURITY;

-- Policy: Học viên chỉ xem được dữ liệu của mình
CREATE POLICY hoc_vien_own ON hoc_vien
    FOR ALL USING (auth_id = auth.uid());

-- Policy: Gia sư chỉ xem được dữ liệu của mình
CREATE POLICY gia_su_own ON gia_su
    FOR ALL USING (auth_id = auth.uid());

-- Policy: Yêu cầu lớp - học viên xem của mình, gia sư xem tất cả đang mở
CREATE POLICY yeu_cau_owner ON yeu_cau_lop
    FOR ALL USING (ma_hoc_vien IN (SELECT ma_hoc_vien FROM hoc_vien WHERE auth_id = auth.uid()));

CREATE POLICY yeu_cau_public_read ON yeu_cau_lop
    FOR SELECT USING (trang_thai IN ('open', 'approved'));

-- Policy: Ứng tuyển - gia sư xem của mình, học viên xem ứng tuyển vào yêu cầu của mình
CREATE POLICY ung_tuyen_gs ON ung_tuyen
    FOR ALL USING (ma_gia_su IN (SELECT ma_gia_su FROM gia_su WHERE auth_id = auth.uid()));

CREATE POLICY ung_tuyen_hv_read ON ung_tuyen
    FOR SELECT USING (
        ma_yeu_cau IN (SELECT ma_yeu_cau FROM yeu_cau_lop WHERE ma_hoc_vien IN
            (SELECT ma_hoc_vien FROM hoc_vien WHERE auth_id = auth.uid()))
    );

-- Policy: Lớp học - cả gia sư và học viên đều xem được
CREATE POLICY lop_hoc_gs ON lop_hoc
    FOR ALL USING (ma_gia_su IN (SELECT ma_gia_su FROM gia_su WHERE auth_id = auth.uid()));

CREATE POLICY lop_hoc_hv ON lop_hoc
    FOR ALL USING (ma_hoc_vien IN (SELECT ma_hoc_vien FROM hoc_vien WHERE auth_id = auth.uid()));

-- Policy: Thông báo - chỉ người nhận mới xem được
CREATE POLICY thong_bao_hv ON thong_bao
    FOR ALL USING (ma_hoc_vien IN (SELECT ma_hoc_vien FROM hoc_vien WHERE auth_id = auth.uid()));

CREATE POLICY thong_bao_gs ON thong_bao
    FOR ALL USING (ma_gia_su IN (SELECT ma_gia_su FROM gia_su WHERE auth_id = auth.uid()));

-- ============================================================================
-- PHẦN 12: DỮ LIỆU MẪU
-- ============================================================================

INSERT INTO hoc_vien (ma_hoc_vien, ho_ten, ngay_sinh, so_dien_thoai, email, khoi_hien_tai) VALUES
('HV001', N'Nguyễn Văn An', '2005-01-15', '0901234567', 'an.nguyen@gmail.com', N'Lớp 12'),
('HV002', N'Trần Thị Bình', '2008-05-20', '0912345678', 'binh.tran@gmail.com', N'Lớp 9'),
('HV003', N'Lê Hoàng Cường', '2010-09-10', '0923456789', 'cuong.le@gmail.com', N'Lớp 7'),
('HV004', N'Phạm Mai Dung', '2006-11-25', '0934567890', 'dung.pham@gmail.com', N'Lớp 11'),
('HV005', N'Hoàng Tuấn Em', '2004-03-30', '0945678901', 'em.hoang@gmail.com', N'Lớp 12');

INSERT INTO gia_su (ma_gia_su, ho_ten, ngay_sinh, trinh_do, gioi_thieu, trong_lich) VALUES
('GS001', N'Nguyễn Thanh Tùng', '1998-02-14', N'Đại học Sư phạm Toán', N'Giáo viên Toán 5 năm kinh nghiệm', TRUE),
('GS002', N'Lê Thu Hà', '1995-07-22', N'Thạc sĩ Toán học', N'Chuyên luyện thi THPT Quốc gia môn Toán', TRUE),
('GS003', N'Trần Minh Khang', '2000-10-05', N'Sinh viên năm cuối ĐH Ngoại Thương', N'IELTS 7.5, kinh nghiệm dạy Tiếng Anh 2 năm', TRUE),
('GS004', N'Phạm Bích Ngọc', '1997-12-11', N'Giáo viên Ngữ Văn Cấp 2', N'6 năm dạy Văn, giáo viên giỏi cấp tỉnh', TRUE),
('GS005', N'Vũ Hải Đăng', '1996-08-09', N'Đại học Bách Khoa', N'Kỹ sư, dạy Lý-Hóa 4 năm', TRUE);

INSERT INTO mon_hoc (ma_mon, ten_mon, cap_hoc, mo_ta) VALUES
('MH001', N'Toán', N'Cấp 3', N'Toán THPT ôn thi đại học'),
('MH002', N'Vật Lý', N'Cấp 3', N'Vật lý chuyên sâu 10-11-12'),
('MH003', N'Hóa Học', N'Cấp 3', N'Hóa vô cơ và hữu cơ'),
('MH004', N'Tiếng Anh', N'Tất cả', N'Giao tiếp và luyện thi IELTS'),
('MH005', N'Ngữ Văn', N'Cấp 2', N'Luyện thi vào lớp 10');

INSERT INTO gia_su_mon_hoc (ma_gia_su, ma_mon, nam_kinh_nghiem, muc_do_thanh_thao, chung_chi) VALUES
('GS001', 'MH001', 3, N'Khá', N'Chứng chỉ sư phạm'),
('GS002', 'MH001', 5, N'Tốt', N'Bằng giỏi ĐH Sư Phạm'),
('GS003', 'MH004', 2, N'Khá', N'IELTS 7.5'),
('GS004', 'MH005', 6, N'Tốt', N'Giáo viên giỏi cấp tỉnh'),
('GS005', 'MH002', 4, N'Khá', NULL);

-- Một vài yêu cầu mẫu
INSERT INTO yeu_cau_lop (ma_yeu_cau, ma_hoc_vien, tieu_de, mo_ta, tien_hoc_phi, dia_chi, hinh_thuc_hoc, so_buoi_tuan, thoi_gian_mong_muon, trang_thai) VALUES
('YC001', 'HV001', N'Cần gia sư Toán 12 luyện thi ĐH', N'Học sinh cần củng cố kiến thức Toán 12', 200000, N'Quận 1, TP.HCM', 'Offline', 2, N'Tối thứ 2, 4 (18h-20h)', 'open'),
('YC002', 'HV002', N'Luyện Văn 9 thi vào 10', N'Cần gia sư Văn giúp em tự tin thi vào 10', 150000, N'Quận 3, TP.HCM', 'Offline', 2, N'Cuối tuần', 'open'),
('YC003', 'HV003', N'Học Tiếng Anh giao tiếp', N'Học sinh lớp 7 muốn cải thiện giao tiếp', 180000, N'Quận 10, TP.HCM', 'Online', 3, N'Tối 2-4-6', 'open'),
('YC004', 'HV004', N'Lý 11 nâng cao', N'Học sinh khá giỏi cần nâng cao Lý 11', 250000, N'Quận 5, TP.HCM', 'Offline', 1, N'Chủ nhật sáng', 'open'),
('YC005', 'HV005', N'Toán luyện thi THPT Quốc gia', N'Học sinh cần luyện đề và nâng cao', 300000, N'Quận 7, TP.HCM', 'Offline', 3, N'Tối 3-5-7', 'open');

INSERT INTO yeu_cau_mon (ma_yeu_cau, ma_mon, vai_tro_mon) VALUES
('YC001', 'MH001', N'Chính'),
('YC002', 'MH005', N'Chính'),
('YC003', 'MH004', N'Chính'),
('YC004', 'MH002', N'Chính'),
('YC005', 'MH001', N'Chính');

-- Một vài ứng tuyển mẫu
INSERT INTO ung_tuyen (ma_ung_tuyen, ma_yeu_cau, ma_gia_su, thu_nhap_mong_muon, loi_nhan) VALUES
('UT001', 'YC001', 'GS001', 180000, N'Tôi có 3 năm kinh nghiệm dạy Toán 12, đã giúp nhiều em đỗ đại học.'),
('UT002', 'YC001', 'GS002', 220000, N'Thạc sĩ Toán, chuyên luyện thi THPT Quốc gia. Cam kết học sinh đạt điểm cao.'),
('UT003', 'YC005', 'GS001', 280000, N'Kinh nghiệm dạy luyện thi, có giáo án đầy đủ.'),
('UT004', 'YC005', 'GS002', 320000, N'Nhận dạy online hoặc offline theo yêu cầu.');
