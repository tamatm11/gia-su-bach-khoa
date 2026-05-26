-- ============================================================================
-- SCHEMA TỔNG HỢP: HỆ THỐNG GIA SƯ BÁCH KHOA
-- Ngày xuất: 2026-05-21 | PostgreSQL 17 (Supabase) | v7
-- File này chứa TOÀN BỘ schema, functions, triggers, views, policies, indexes và dữ liệu mẫu
-- Cấu trúc: SETTINGS -> SEQUENCES -> TABLES -> CONSTRAINTS -> INDEXES -> VIEWS -> FUNCTIONS -> TRIGGERS -> RLS -> SEED DATA
-- LƯU Ý: FK quan_tri_vien.auth_id -> auth.users(id) cần schema auth tồn tại trước
-- ============================================================================

-- ======================================================================
-- SECTION 1: SETTINGS (EXTENSIONS)
-- ======================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;

-- ======================================================================
-- SECTION 2: SEQUENCES
-- ======================================================================
CREATE SEQUENCE IF NOT EXISTS public.audit_log_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

-- ======================================================================
-- SECTION 3: TABLES (20 bảng)
-- ======================================================================

-- 3.1: hoc_vien
CREATE TABLE public.hoc_vien (
    ma_hoc_vien     varchar(20)    NOT NULL,
    ho_ten          varchar(200)   NOT NULL,
    ngay_sinh       date,
    so_dien_thoai   varchar(20),
    email           varchar(100),
    khoi_hien_tai   varchar(50),
    auth_id         uuid,
    ngay_tao        timestamptz    NOT NULL DEFAULT now(),
    ngay_cap_nhat   timestamptz    NOT NULL DEFAULT now()
);

-- 3.2: gia_su
CREATE TABLE public.gia_su (
    ma_gia_su       varchar(20)    NOT NULL,
    ho_ten          varchar(200)   NOT NULL,
    ngay_sinh       date,
    trinh_do        varchar(100),
    gioi_thieu      text,
    trong_lich      boolean        NOT NULL DEFAULT true,
    auth_id         uuid,
    ngay_tao        timestamptz    NOT NULL DEFAULT now(),
    ngay_cap_nhat   timestamptz    NOT NULL DEFAULT now()
);

-- 3.3: mon_hoc
CREATE TABLE public.mon_hoc (
    ma_mon          varchar(20)    NOT NULL,
    ten_mon         varchar(200)   NOT NULL,
    cap_hoc         varchar(50)    NOT NULL,
    mo_ta           text
);

-- 3.4: gia_su_mon_hoc
CREATE TABLE public.gia_su_mon_hoc (
    ma_gia_su          varchar(20)    NOT NULL,
    ma_mon             varchar(20)    NOT NULL,
    nam_kinh_nghiem    integer        NOT NULL DEFAULT 0,
    muc_do_thanh_thao  varchar(20),
    chung_chi          text
);

-- 3.5: yeu_cau_lop
CREATE TABLE public.yeu_cau_lop (
    ma_yeu_cau            varchar(20)    NOT NULL,
    ma_hoc_vien           varchar(20)    NOT NULL,
    tieu_de               varchar(200)   NOT NULL,
    mo_ta                 text,
    tien_hoc_phi          numeric(15,0)  NOT NULL,
    dia_chi               text           NOT NULL,
    hinh_thuc_hoc         varchar(20)    NOT NULL DEFAULT 'Offline',
    so_buoi_tuan          smallint       NOT NULL,
    thoi_gian_mong_muon   text,
    ngay_yeu_cau          timestamptz    NOT NULL DEFAULT now(),
    trang_thai            varchar(20)    NOT NULL DEFAULT 'open',
    ma_gia_su_duoc_chon   varchar(20),
    ngay_chon_gia_su      timestamptz,
    ngay_cap_nhat         timestamptz    NOT NULL DEFAULT now()
);

-- 3.6: yeu_cau_mon
CREATE TABLE public.yeu_cau_mon (
    ma_yeu_cau      varchar(20)    NOT NULL,
    ma_mon          varchar(20)    NOT NULL,
    vai_tro_mon     varchar(20)    NOT NULL DEFAULT 'Chính',
    ghi_chu         text
);

-- 3.7: ung_tuyen
CREATE TABLE public.ung_tuyen (
    ma_ung_tuyen          varchar(20)    NOT NULL,
    ma_yeu_cau            varchar(20)    NOT NULL,
    ma_gia_su             varchar(20)    NOT NULL,
    thu_nhap_mong_muon    numeric(15,0),
    loi_nhan              text,
    trang_thai            varchar(20)    NOT NULL DEFAULT 'pending',
    ngay_ung_tuyen        timestamptz    NOT NULL DEFAULT now(),
    ngay_xu_ly            timestamptz
);

-- 3.8: lop_hoc
CREATE TABLE public.lop_hoc (
    ma_lop           varchar(20)    NOT NULL,
    ma_gia_su        varchar(20)    NOT NULL,
    ma_hoc_vien      varchar(20)    NOT NULL,
    ma_yeu_cau       varchar(20),
    ma_ung_tuyen     varchar(20),
    hoc_phi          numeric(15,0)  NOT NULL,
    dia_chi          text           NOT NULL,
    hinh_thuc_day    varchar(20)    NOT NULL DEFAULT 'Offline',
    ngay_bat_dau     date           NOT NULL,
    ngay_ket_thuc    date,
    trang_thai       varchar(20)    NOT NULL DEFAULT 'SapMo',
    so_hv_toi_da     smallint       NOT NULL DEFAULT 1,
    tong_so_buoi     integer        NOT NULL,
    ngay_tao         timestamptz    NOT NULL DEFAULT now()
);

-- 3.9: lop_hoc_mon
CREATE TABLE public.lop_hoc_mon (
    ma_lop             varchar(20)    NOT NULL,
    ma_mon             varchar(20)    NOT NULL,
    vai_tro_mon        varchar(20)    NOT NULL DEFAULT 'Chính',
    so_buoi_du_kien    integer,
    ghi_chu            text
);

-- 3.10: lich_hoc
CREATE TABLE public.lich_hoc (
    ma_lich          varchar(20)    NOT NULL,
    ma_lop           varchar(20)    NOT NULL,
    thu_trong_tuan   smallint       NOT NULL,
    gio_bat_dau      time           NOT NULL,
    gio_ket_thuc     time           NOT NULL
);

-- 3.11: buoi_hoc
CREATE TABLE public.buoi_hoc (
    ma_buoi_hoc     varchar(20)    NOT NULL,
    ma_lop          varchar(20)    NOT NULL,
    ma_lich         varchar(20),
    ngay_hoc        date           NOT NULL,
    gio_bat_dau     time           NOT NULL,
    gio_ket_thuc    time           NOT NULL,
    trang_thai      varchar(20)    NOT NULL DEFAULT 'Scheduled',
    ghi_chu         text
);

-- 3.12: dang_ky
CREATE TABLE public.dang_ky (
    ma_dang_ky      varchar(20)    NOT NULL,
    ma_hoc_vien     varchar(20)    NOT NULL,
    ma_lop          varchar(20)    NOT NULL,
    ngay_dang_ky    timestamptz    NOT NULL DEFAULT now(),
    trang_thai      varchar(20)    NOT NULL DEFAULT 'Pending',
    ghi_chu         text
);

-- 3.13: tai_khoan_hv
CREATE TABLE public.tai_khoan_hv (
    ma_tk_hv         varchar(20)    NOT NULL,
    ma_hoc_vien      varchar(20)    NOT NULL,
    so_tai_khoan     varchar(50)    NOT NULL,
    nha_cung_cap     varchar(50)    NOT NULL,
    loai_phuong_thuc varchar(20)    NOT NULL DEFAULT 'Bank',
    ten_chu_tk       varchar(200)   NOT NULL,
    la_mac_dinh      boolean        NOT NULL DEFAULT false
);

-- 3.14: tai_khoan_gs
CREATE TABLE public.tai_khoan_gs (
    ma_tk_gs         varchar(20)    NOT NULL,
    ma_gia_su        varchar(20)    NOT NULL,
    so_tai_khoan     varchar(50)    NOT NULL,
    nha_cung_cap     varchar(50)    NOT NULL,
    loai_phuong_thuc varchar(20)    NOT NULL DEFAULT 'Bank',
    ten_chu_tk       varchar(200)   NOT NULL,
    la_mac_dinh      boolean        NOT NULL DEFAULT false
);

-- 3.15: giao_dich
CREATE TABLE public.giao_dich (
    ma_giao_dich          varchar(20)    NOT NULL,
    ma_dang_ky            varchar(20)    NOT NULL,
    ma_tk_hv              varchar(20)    NOT NULL,
    ma_tk_gs              varchar(20)    NOT NULL,
    tong_tien_thu         numeric(15,0)  NOT NULL,
    ty_le_hoa_hong        numeric(5,2)   NOT NULL,
    phi_hoa_hong          numeric(15,0)  NOT NULL,
    so_tien_gia_su_nhan   numeric(15,0)  NOT NULL,
    ngay_thanh_toan       timestamptz    NOT NULL DEFAULT now(),
    ngay_doi_soat         timestamptz,
    trang_thai            varchar(20)    NOT NULL DEFAULT 'Success',
    loai_giao_dich        varchar(30)    NOT NULL DEFAULT 'ThanhToanThang',
    ma_tham_chieu         varchar(100)
);

-- 3.16: danh_gia
CREATE TABLE public.danh_gia (
    ma_danh_gia     varchar(20)    NOT NULL,
    ma_dang_ky      varchar(20)    NOT NULL,
    diem_sao        smallint       NOT NULL,
    nhan_xet        text,
    ngay_danh_gia   timestamptz    NOT NULL DEFAULT now()
);

-- 3.17: diem_danh
CREATE TABLE public.diem_danh (
    ma_buoi_hoc     varchar(20)    NOT NULL,
    ma_dang_ky      varchar(20)    NOT NULL,
    trang_thai      varchar(20)    NOT NULL DEFAULT 'CoMat',
    so_phut_hoc     integer,
    ghi_chu         text
);

-- 3.18: thong_bao
CREATE TABLE public.thong_bao (
    ma_thong_bao    varchar(100)   NOT NULL,
    ma_hoc_vien     varchar(20),
    ma_gia_su       varchar(20),
    loai_thong_bao  varchar(30)    NOT NULL,
    tieu_de         varchar(200)   NOT NULL,
    noi_dung        text           NOT NULL,
    da_doc          boolean        NOT NULL DEFAULT false,
    ngay_tao        timestamptz    NOT NULL DEFAULT now(),
    ma_yeu_cau      varchar(20),
    ma_lop          varchar(20),
    ma_giao_dich    varchar(20),
    ma_buoi_hoc     varchar(20)
);

-- 3.19: audit_log
CREATE TABLE public.audit_log (
    id              bigint         NOT NULL DEFAULT nextval('public.audit_log_id_seq'::regclass),
    table_name      varchar(100)   NOT NULL,
    record_id       varchar(100)   NOT NULL,
    action          varchar(10)    NOT NULL,
    old_data        jsonb,
    new_data        jsonb,
    changed_by      varchar(100),
    changed_at      timestamptz    NOT NULL DEFAULT now()
);

-- 3.20: quan_tri_vien
CREATE TABLE public.quan_tri_vien (
    ma_qtv          varchar(20)    NOT NULL,
    ho_ten          varchar(200)   NOT NULL,
    email           varchar(100),
    auth_id         uuid,
    ngay_tao        timestamptz    NOT NULL DEFAULT now(),
    ngay_cap_nhat   timestamptz    NOT NULL DEFAULT now()
);

-- ======================================================================
-- SECTION 4: CONSTRAINTS (PRIMARY KEYS, FOREIGN KEYS, UNIQUE, CHECK)
-- ======================================================================

-- 4.1: PRIMARY KEYS
ALTER TABLE ONLY public.hoc_vien       ADD CONSTRAINT hoc_vien_pkey       PRIMARY KEY (ma_hoc_vien);
ALTER TABLE ONLY public.gia_su         ADD CONSTRAINT gia_su_pkey         PRIMARY KEY (ma_gia_su);
ALTER TABLE ONLY public.mon_hoc        ADD CONSTRAINT mon_hoc_pkey        PRIMARY KEY (ma_mon);
ALTER TABLE ONLY public.gia_su_mon_hoc ADD CONSTRAINT gia_su_mon_hoc_pkey PRIMARY KEY (ma_gia_su, ma_mon);
ALTER TABLE ONLY public.yeu_cau_lop    ADD CONSTRAINT yeu_cau_lop_pkey    PRIMARY KEY (ma_yeu_cau);
ALTER TABLE ONLY public.yeu_cau_mon    ADD CONSTRAINT yeu_cau_mon_pkey    PRIMARY KEY (ma_yeu_cau, ma_mon);
ALTER TABLE ONLY public.ung_tuyen      ADD CONSTRAINT ung_tuyen_pkey      PRIMARY KEY (ma_ung_tuyen);
ALTER TABLE ONLY public.lop_hoc        ADD CONSTRAINT lop_hoc_pkey        PRIMARY KEY (ma_lop);
ALTER TABLE ONLY public.lop_hoc_mon    ADD CONSTRAINT lop_hoc_mon_pkey    PRIMARY KEY (ma_lop, ma_mon);
ALTER TABLE ONLY public.lich_hoc       ADD CONSTRAINT lich_hoc_pkey       PRIMARY KEY (ma_lich);
ALTER TABLE ONLY public.buoi_hoc       ADD CONSTRAINT buoi_hoc_pkey       PRIMARY KEY (ma_buoi_hoc);
ALTER TABLE ONLY public.dang_ky        ADD CONSTRAINT dang_ky_pkey        PRIMARY KEY (ma_dang_ky);
ALTER TABLE ONLY public.tai_khoan_hv   ADD CONSTRAINT tai_khoan_hv_pkey   PRIMARY KEY (ma_tk_hv);
ALTER TABLE ONLY public.tai_khoan_gs   ADD CONSTRAINT tai_khoan_gs_pkey   PRIMARY KEY (ma_tk_gs);
ALTER TABLE ONLY public.giao_dich      ADD CONSTRAINT giao_dich_pkey      PRIMARY KEY (ma_giao_dich);
ALTER TABLE ONLY public.danh_gia       ADD CONSTRAINT danh_gia_pkey       PRIMARY KEY (ma_danh_gia);
ALTER TABLE ONLY public.diem_danh      ADD CONSTRAINT diem_danh_pkey      PRIMARY KEY (ma_buoi_hoc, ma_dang_ky);
ALTER TABLE ONLY public.thong_bao      ADD CONSTRAINT thong_bao_pkey      PRIMARY KEY (ma_thong_bao);
ALTER TABLE ONLY public.audit_log      ADD CONSTRAINT audit_log_pkey      PRIMARY KEY (id);
ALTER TABLE ONLY public.quan_tri_vien  ADD CONSTRAINT quan_tri_vien_pkey  PRIMARY KEY (ma_qtv);

-- 4.2: FOREIGN KEYS
ALTER TABLE ONLY public.gia_su_mon_hoc ADD CONSTRAINT gia_su_mon_hoc_ma_gia_su_fkey  FOREIGN KEY (ma_gia_su) REFERENCES public.gia_su(ma_gia_su) ON DELETE CASCADE;
ALTER TABLE ONLY public.gia_su_mon_hoc ADD CONSTRAINT gia_su_mon_hoc_ma_mon_fkey     FOREIGN KEY (ma_mon)    REFERENCES public.mon_hoc(ma_mon) ON DELETE CASCADE;

ALTER TABLE ONLY public.yeu_cau_lop    ADD CONSTRAINT yeu_cau_lop_ma_hoc_vien_fkey          FOREIGN KEY (ma_hoc_vien)          REFERENCES public.hoc_vien(ma_hoc_vien);
ALTER TABLE ONLY public.yeu_cau_lop    ADD CONSTRAINT yeu_cau_lop_ma_gia_su_duoc_chon_fkey  FOREIGN KEY (ma_gia_su_duoc_chon)  REFERENCES public.gia_su(ma_gia_su);

ALTER TABLE ONLY public.yeu_cau_mon    ADD CONSTRAINT yeu_cau_mon_ma_yeu_cau_fkey  FOREIGN KEY (ma_yeu_cau) REFERENCES public.yeu_cau_lop(ma_yeu_cau) ON DELETE CASCADE;
ALTER TABLE ONLY public.yeu_cau_mon    ADD CONSTRAINT yeu_cau_mon_ma_mon_fkey      FOREIGN KEY (ma_mon)     REFERENCES public.mon_hoc(ma_mon);

ALTER TABLE ONLY public.ung_tuyen      ADD CONSTRAINT ung_tuyen_ma_yeu_cau_fkey  FOREIGN KEY (ma_yeu_cau) REFERENCES public.yeu_cau_lop(ma_yeu_cau) ON DELETE CASCADE;
ALTER TABLE ONLY public.ung_tuyen      ADD CONSTRAINT ung_tuyen_ma_gia_su_fkey   FOREIGN KEY (ma_gia_su)  REFERENCES public.gia_su(ma_gia_su);

ALTER TABLE ONLY public.lop_hoc        ADD CONSTRAINT lop_hoc_ma_gia_su_fkey    FOREIGN KEY (ma_gia_su)    REFERENCES public.gia_su(ma_gia_su);
ALTER TABLE ONLY public.lop_hoc        ADD CONSTRAINT lop_hoc_ma_hoc_vien_fkey  FOREIGN KEY (ma_hoc_vien)  REFERENCES public.hoc_vien(ma_hoc_vien);
ALTER TABLE ONLY public.lop_hoc        ADD CONSTRAINT lop_hoc_ma_yeu_cau_fkey   FOREIGN KEY (ma_yeu_cau)   REFERENCES public.yeu_cau_lop(ma_yeu_cau);
ALTER TABLE ONLY public.lop_hoc        ADD CONSTRAINT lop_hoc_ma_ung_tuyen_fkey FOREIGN KEY (ma_ung_tuyen) REFERENCES public.ung_tuyen(ma_ung_tuyen);

ALTER TABLE ONLY public.lop_hoc_mon    ADD CONSTRAINT lop_hoc_mon_ma_lop_fkey  FOREIGN KEY (ma_lop) REFERENCES public.lop_hoc(ma_lop) ON DELETE CASCADE;
ALTER TABLE ONLY public.lop_hoc_mon    ADD CONSTRAINT lop_hoc_mon_ma_mon_fkey  FOREIGN KEY (ma_mon) REFERENCES public.mon_hoc(ma_mon);

ALTER TABLE ONLY public.lich_hoc       ADD CONSTRAINT lich_hoc_ma_lop_fkey  FOREIGN KEY (ma_lop) REFERENCES public.lop_hoc(ma_lop) ON DELETE CASCADE;

ALTER TABLE ONLY public.buoi_hoc       ADD CONSTRAINT buoi_hoc_ma_lop_fkey  FOREIGN KEY (ma_lop) REFERENCES public.lop_hoc(ma_lop) ON DELETE CASCADE;

ALTER TABLE ONLY public.dang_ky        ADD CONSTRAINT dang_ky_ma_hoc_vien_fkey  FOREIGN KEY (ma_hoc_vien) REFERENCES public.hoc_vien(ma_hoc_vien);
ALTER TABLE ONLY public.dang_ky        ADD CONSTRAINT dang_ky_ma_lop_fkey       FOREIGN KEY (ma_lop)      REFERENCES public.lop_hoc(ma_lop);

ALTER TABLE ONLY public.tai_khoan_hv   ADD CONSTRAINT tai_khoan_hv_ma_hoc_vien_fkey  FOREIGN KEY (ma_hoc_vien) REFERENCES public.hoc_vien(ma_hoc_vien);
ALTER TABLE ONLY public.tai_khoan_gs   ADD CONSTRAINT tai_khoan_gs_ma_gia_su_fkey    FOREIGN KEY (ma_gia_su)   REFERENCES public.gia_su(ma_gia_su);

ALTER TABLE ONLY public.giao_dich      ADD CONSTRAINT giao_dich_ma_dang_ky_fkey  FOREIGN KEY (ma_dang_ky) REFERENCES public.dang_ky(ma_dang_ky);
ALTER TABLE ONLY public.giao_dich      ADD CONSTRAINT giao_dich_ma_tk_hv_fkey    FOREIGN KEY (ma_tk_hv)   REFERENCES public.tai_khoan_hv(ma_tk_hv);
ALTER TABLE ONLY public.giao_dich      ADD CONSTRAINT giao_dich_ma_tk_gs_fkey    FOREIGN KEY (ma_tk_gs)   REFERENCES public.tai_khoan_gs(ma_tk_gs);

ALTER TABLE ONLY public.danh_gia       ADD CONSTRAINT danh_gia_ma_dang_ky_fkey  FOREIGN KEY (ma_dang_ky) REFERENCES public.dang_ky(ma_dang_ky);

ALTER TABLE ONLY public.diem_danh      ADD CONSTRAINT diem_danh_ma_buoi_hoc_fkey  FOREIGN KEY (ma_buoi_hoc) REFERENCES public.buoi_hoc(ma_buoi_hoc) ON DELETE CASCADE;
ALTER TABLE ONLY public.diem_danh      ADD CONSTRAINT diem_danh_ma_dang_ky_fkey   FOREIGN KEY (ma_dang_ky)  REFERENCES public.dang_ky(ma_dang_ky);

ALTER TABLE ONLY public.thong_bao      ADD CONSTRAINT thong_bao_ma_hoc_vien_fkey  FOREIGN KEY (ma_hoc_vien) REFERENCES public.hoc_vien(ma_hoc_vien) ON DELETE CASCADE;
ALTER TABLE ONLY public.thong_bao      ADD CONSTRAINT thong_bao_ma_gia_su_fkey    FOREIGN KEY (ma_gia_su)   REFERENCES public.gia_su(ma_gia_su) ON DELETE CASCADE;

ALTER TABLE ONLY public.quan_tri_vien  ADD CONSTRAINT quan_tri_vien_auth_id_fkey  FOREIGN KEY (auth_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- 4.3: UNIQUE CONSTRAINTS
ALTER TABLE ONLY public.hoc_vien       ADD CONSTRAINT hoc_vien_auth_id_key       UNIQUE (auth_id);
ALTER TABLE ONLY public.gia_su         ADD CONSTRAINT gia_su_auth_id_key         UNIQUE (auth_id);
ALTER TABLE ONLY public.yeu_cau_lop    ADD CONSTRAINT yeu_cau_lop_ma_yeu_cau_key UNIQUE (ma_yeu_cau);
ALTER TABLE ONLY public.ung_tuyen      ADD CONSTRAINT ung_tuyen_ma_yeu_cau_ma_gia_su_key UNIQUE (ma_yeu_cau, ma_gia_su);
ALTER TABLE ONLY public.lop_hoc        ADD CONSTRAINT lop_hoc_ma_yeu_cau_key     UNIQUE (ma_yeu_cau);
ALTER TABLE ONLY public.lich_hoc       ADD CONSTRAINT lich_hoc_ma_lop_ma_lich_key UNIQUE (ma_lop, ma_lich);
ALTER TABLE ONLY public.dang_ky        ADD CONSTRAINT dang_ky_ma_lop_key         UNIQUE (ma_lop);
ALTER TABLE ONLY public.dang_ky        ADD CONSTRAINT dang_ky_ma_hoc_vien_ma_lop_key UNIQUE (ma_hoc_vien, ma_lop);
ALTER TABLE ONLY public.tai_khoan_hv   ADD CONSTRAINT tai_khoan_hv_ma_hoc_vien_so_tai_khoan_nha_cung_cap_key UNIQUE (ma_hoc_vien, so_tai_khoan, nha_cung_cap);
ALTER TABLE ONLY public.tai_khoan_gs   ADD CONSTRAINT tai_khoan_gs_ma_gia_su_so_tai_khoan_nha_cung_cap_key  UNIQUE (ma_gia_su, so_tai_khoan, nha_cung_cap);
ALTER TABLE ONLY public.giao_dich      ADD CONSTRAINT giao_dich_ma_tham_chieu_key UNIQUE (ma_tham_chieu);
ALTER TABLE ONLY public.danh_gia       ADD CONSTRAINT danh_gia_ma_dang_ky_key    UNIQUE (ma_dang_ky);
ALTER TABLE ONLY public.quan_tri_vien  ADD CONSTRAINT quan_tri_vien_auth_id_key  UNIQUE (auth_id);

-- 4.4: CHECK CONSTRAINTS
ALTER TABLE ONLY public.gia_su_mon_hoc ADD CONSTRAINT gia_su_mon_hoc_nam_kinh_nghiem_check CHECK (nam_kinh_nghiem >= 0);
ALTER TABLE ONLY public.yeu_cau_lop    ADD CONSTRAINT yeu_cau_lop_tien_hoc_phi_check CHECK (tien_hoc_phi >= 0::numeric);
ALTER TABLE ONLY public.yeu_cau_lop    ADD CONSTRAINT yeu_cau_lop_so_buoi_tuan_check CHECK (so_buoi_tuan >= 1 AND so_buoi_tuan <= 7);
ALTER TABLE ONLY public.lich_hoc       ADD CONSTRAINT lich_hoc_thu_trong_tuan_check CHECK (thu_trong_tuan >= 1 AND thu_trong_tuan <= 7);
ALTER TABLE ONLY public.lich_hoc       ADD CONSTRAINT ck_lich_hoc_gio CHECK (gio_ket_thuc > gio_bat_dau);
ALTER TABLE ONLY public.buoi_hoc       ADD CONSTRAINT ck_buoi_hoc_gio CHECK (gio_ket_thuc > gio_bat_dau);
ALTER TABLE ONLY public.lop_hoc        ADD CONSTRAINT lop_hoc_hoc_phi_check CHECK (hoc_phi >= 0::numeric);
ALTER TABLE ONLY public.lop_hoc        ADD CONSTRAINT lop_hoc_so_hv_toi_da_check CHECK (so_hv_toi_da = 1);
ALTER TABLE ONLY public.lop_hoc        ADD CONSTRAINT lop_hoc_tong_so_buoi_check CHECK (tong_so_buoi > 0);
ALTER TABLE ONLY public.lop_hoc        ADD CONSTRAINT ck_lop_hoc_ngay CHECK (ngay_ket_thuc IS NULL OR ngay_ket_thuc >= ngay_bat_dau);
ALTER TABLE ONLY public.lop_hoc_mon    ADD CONSTRAINT lop_hoc_mon_so_buoi_du_kien_check CHECK (so_buoi_du_kien IS NULL OR so_buoi_du_kien >= 0);
ALTER TABLE ONLY public.giao_dich      ADD CONSTRAINT giao_dich_tong_tien_thu_check CHECK (tong_tien_thu > 0::numeric);
ALTER TABLE ONLY public.giao_dich      ADD CONSTRAINT giao_dich_ty_le_hoa_hong_check CHECK (ty_le_hoa_hong >= 0::numeric AND ty_le_hoa_hong <= 100::numeric);
ALTER TABLE ONLY public.giao_dich      ADD CONSTRAINT giao_dich_phi_hoa_hong_check CHECK (phi_hoa_hong >= 0::numeric);
ALTER TABLE ONLY public.giao_dich      ADD CONSTRAINT giao_dich_so_tien_gia_su_nhan_check CHECK (so_tien_gia_su_nhan >= 0::numeric);
ALTER TABLE ONLY public.giao_dich      ADD CONSTRAINT ck_giao_dich_toan_ven CHECK (phi_hoa_hong + so_tien_gia_su_nhan = tong_tien_thu);
ALTER TABLE ONLY public.giao_dich      ADD CONSTRAINT ck_giao_dich_ngay CHECK (ngay_doi_soat IS NULL OR ngay_doi_soat >= ngay_thanh_toan);
ALTER TABLE ONLY public.danh_gia       ADD CONSTRAINT danh_gia_diem_sao_check CHECK (diem_sao >= 1 AND diem_sao <= 5);
ALTER TABLE ONLY public.diem_danh      ADD CONSTRAINT diem_danh_so_phut_hoc_check CHECK (so_phut_hoc IS NULL OR so_phut_hoc >= 0);
ALTER TABLE ONLY public.thong_bao      ADD CONSTRAINT ck_thong_bao_nguoi_nhan CHECK (
    (CASE WHEN ma_hoc_vien IS NULL THEN 0 ELSE 1 END + CASE WHEN ma_gia_su IS NULL THEN 0 ELSE 1 END) = 1
);

-- ======================================================================
-- SECTION 5: INDEXES
-- ======================================================================

-- hoc_vien indexes
CREATE UNIQUE INDEX ux_hoc_vien_email ON public.hoc_vien USING btree (email) WHERE (email IS NOT NULL);
CREATE UNIQUE INDEX ux_hoc_vien_sdt   ON public.hoc_vien USING btree (so_dien_thoai) WHERE (so_dien_thoai IS NOT NULL);
CREATE INDEX ix_hoc_vien_auth ON public.hoc_vien USING btree (auth_id);

-- gia_su indexes
CREATE INDEX ix_gia_su_auth ON public.gia_su USING btree (auth_id);
CREATE INDEX ix_gia_su_trong_lich ON public.gia_su USING btree (trong_lich) WHERE (trong_lich = true);

-- gia_su_mon_hoc indexes
CREATE INDEX ix_gia_su_mon_hoc_mon ON public.gia_su_mon_hoc USING btree (ma_mon);

-- yeu_cau_lop indexes
CREATE INDEX ix_yeu_cau_hoc_vien  ON public.yeu_cau_lop USING btree (ma_hoc_vien, trang_thai);
CREATE INDEX ix_yeu_cau_trang_thai ON public.yeu_cau_lop USING btree (trang_thai, ngay_yeu_cau DESC);

-- ung_tuyen indexes
CREATE INDEX ix_ung_tuyen_gia_su  ON public.ung_tuyen USING btree (ma_gia_su, trang_thai);
CREATE INDEX ix_ung_tuyen_yeu_cau ON public.ung_tuyen USING btree (ma_yeu_cau, trang_thai);

-- lop_hoc indexes
CREATE INDEX ix_lop_hoc_gia_su   ON public.lop_hoc USING btree (ma_gia_su, trang_thai);
CREATE INDEX ix_lop_hoc_hoc_vien ON public.lop_hoc USING btree (ma_hoc_vien, trang_thai);

-- lich_hoc indexes
CREATE INDEX ix_lich_hoc_lop ON public.lich_hoc USING btree (ma_lop, thu_trong_tuan, gio_bat_dau);
CREATE UNIQUE INDEX ux_lich_hoc_lop_thu_gio ON public.lich_hoc USING btree (ma_lop, thu_trong_tuan, gio_bat_dau);

-- buoi_hoc indexes
CREATE INDEX ix_buoi_hoc_lop_ngay ON public.buoi_hoc USING btree (ma_lop, ngay_hoc);

-- dang_ky indexes
CREATE INDEX ix_dang_ky_lop ON public.dang_ky USING btree (ma_lop, trang_thai);

-- giao_dich indexes
CREATE INDEX ix_giao_dich_dang_ky ON public.giao_dich USING btree (ma_dang_ky, ngay_thanh_toan DESC);

-- diem_danh indexes
CREATE INDEX ix_diem_danh_dang_ky ON public.diem_danh USING btree (ma_dang_ky, ma_buoi_hoc);

-- tai_khoan_hv partial unique indexes
CREATE UNIQUE INDEX ux_tk_hv_mac_dinh ON public.tai_khoan_hv USING btree (ma_hoc_vien) WHERE (la_mac_dinh = true);

-- tai_khoan_gs partial unique indexes
CREATE UNIQUE INDEX ux_tk_gs_mac_dinh ON public.tai_khoan_gs USING btree (ma_gia_su) WHERE (la_mac_dinh = true);

-- thong_bao indexes
CREATE INDEX ix_thong_bao_hv ON public.thong_bao USING btree (ma_hoc_vien, da_doc, ngay_tao DESC) WHERE (ma_hoc_vien IS NOT NULL);
CREATE INDEX ix_thong_bao_gs ON public.thong_bao USING btree (ma_gia_su, da_doc, ngay_tao DESC)   WHERE (ma_gia_su IS NOT NULL);

-- quan_tri_vien indexes
CREATE INDEX ix_qtv_auth ON public.quan_tri_vien USING btree (auth_id);

-- ======================================================================
-- SECTION 6: VIEWS (8 views)
-- ======================================================================

-- 6.1: Thống kê admin
CREATE OR REPLACE VIEW public.vw_admin_thong_ke AS
SELECT
    (SELECT count(*) FROM public.hoc_vien) AS tong_hoc_vien,
    (SELECT count(*) FROM public.gia_su) AS tong_gia_su,
    (SELECT count(*) FROM public.yeu_cau_lop) AS tong_yeu_cau,
    (SELECT count(*) FROM public.yeu_cau_lop WHERE yeu_cau_lop.trang_thai::text = 'open'::text) AS yeu_cau_dang_mo,
    (SELECT count(*) FROM public.lop_hoc) AS tong_lop_hoc,
    (SELECT count(*) FROM public.lop_hoc WHERE lop_hoc.trang_thai::text = ANY (ARRAY['SapMo'::varchar, 'Active'::varchar]::text[])) AS lop_dang_hoc,
    (SELECT count(*) FROM public.lop_hoc WHERE lop_hoc.trang_thai::text = 'Completed'::text) AS lop_da_hoan_thanh,
    (SELECT COALESCE(sum(giao_dich.tong_tien_thu), 0::numeric) FROM public.giao_dich WHERE giao_dich.trang_thai::text = 'Success'::text) AS tong_doanh_thu;

-- 6.2: Đánh giá chi tiết
CREATE OR REPLACE VIEW public.vw_danh_gia_chi_tiet AS
SELECT
    dg.ma_danh_gia, dg.diem_sao, dg.nhan_xet, dg.ngay_danh_gia,
    dk.ma_dang_ky, dk.ma_hoc_vien, hv.ho_ten AS ten_hoc_vien,
    dk.ma_lop, lh.ma_gia_su, gs.ho_ten AS ten_gia_su
FROM public.danh_gia dg
JOIN public.dang_ky dk ON dg.ma_dang_ky::text = dk.ma_dang_ky::text
JOIN public.hoc_vien hv ON dk.ma_hoc_vien::text = hv.ma_hoc_vien::text
JOIN public.lop_hoc lh ON dk.ma_lop::text = lh.ma_lop::text
JOIN public.gia_su gs ON lh.ma_gia_su::text = gs.ma_gia_su::text;

-- 6.3: Gia sư tổng hợp
CREATE OR REPLACE VIEW public.vw_gia_su_tong_hop AS
SELECT
    ma_gia_su, ho_ten, trinh_do, trong_lich, gioi_thieu,
    COALESCE(public.fn_tinh_diem_tb_gia_su(ma_gia_su), 0::numeric) AS diem_danh_gia_tb,
    COALESCE(public.fn_dem_lop_dang_day(ma_gia_su), 0) AS so_lop_dang_day,
    COALESCE((SELECT count(*) FROM public.ung_tuyen ut WHERE ut.ma_gia_su::text = gs.ma_gia_su::text AND ut.trang_thai::text = 'accepted'::text), 0::bigint) AS so_lop_da_nhan
FROM public.gia_su gs;

-- 6.4: Giao dịch chi tiết
CREATE OR REPLACE VIEW public.vw_giao_dich_chi_tiet AS
SELECT
    gd.ma_giao_dich, gd.tong_tien_thu, gd.ty_le_hoa_hong, gd.phi_hoa_hong,
    gd.so_tien_gia_su_nhan, gd.ngay_thanh_toan, gd.trang_thai, gd.loai_giao_dich,
    dk.ma_hoc_vien, hv.ho_ten AS ten_hoc_vien,
    dk.ma_lop, lh.ma_gia_su, gs.ho_ten AS ten_gia_su
FROM public.giao_dich gd
JOIN public.dang_ky dk ON gd.ma_dang_ky::text = dk.ma_dang_ky::text
JOIN public.hoc_vien hv ON dk.ma_hoc_vien::text = hv.ma_hoc_vien::text
JOIN public.lop_hoc lh ON dk.ma_lop::text = lh.ma_lop::text
JOIN public.gia_su gs ON lh.ma_gia_su::text = gs.ma_gia_su::text;

-- 6.5: Lịch trình gia sư
CREATE OR REPLACE VIEW public.vw_lich_trinh_gia_su AS
SELECT
    gs.ma_gia_su, gs.ho_ten AS ten_gia_su,
    l.ma_lop, ('Lớp '::text || l.ma_lop::text) AS ten_lop, l.trang_thai AS trang_thai_lop,
    lh.thu_trong_tuan, lh.gio_bat_dau, lh.gio_ket_thuc,
    public.fn_format_gio_hoc(lh.gio_bat_dau, lh.gio_ket_thuc) AS khoang_thoi_gian,
    hv.ho_ten AS ho_ten_hoc_vien
FROM public.lich_hoc lh
JOIN public.lop_hoc l ON lh.ma_lop::text = l.ma_lop::text
JOIN public.gia_su gs ON l.ma_gia_su::text = gs.ma_gia_su::text
JOIN public.hoc_vien hv ON l.ma_hoc_vien::text = hv.ma_hoc_vien::text
WHERE l.trang_thai::text = ANY (ARRAY['SapMo'::varchar, 'Active'::varchar]::text[]);

-- 6.6: Lớp học chi tiết
CREATE OR REPLACE VIEW public.vw_lop_hoc_chi_tiet AS
SELECT
    l.ma_lop, l.hoc_phi, l.hinh_thuc_day, l.dia_chi, l.trang_thai,
    l.tong_so_buoi, l.ngay_bat_dau, l.ngay_ket_thuc,
    gs.ma_gia_su, gs.ho_ten AS ten_gia_su,
    hv.ma_hoc_vien, hv.ho_ten AS ten_hoc_vien,
    l.ma_yeu_cau,
    (SELECT count(*) FROM public.lich_hoc lh WHERE lh.ma_lop::text = l.ma_lop::text) AS so_lich_hoc,
    (SELECT count(*) FROM public.buoi_hoc bh WHERE bh.ma_lop::text = l.ma_lop::text) AS so_buoi_da_hoc
FROM public.lop_hoc l
JOIN public.gia_su gs ON l.ma_gia_su::text = gs.ma_gia_su::text
JOIN public.hoc_vien hv ON l.ma_hoc_vien::text = hv.ma_hoc_vien::text;

-- 6.7: Thống kê doanh thu
CREATE OR REPLACE VIEW public.vw_thong_ke_doanh_thu AS
SELECT
    EXTRACT(year FROM ngay_thanh_toan)::integer AS nam,
    EXTRACT(month FROM ngay_thanh_toan)::integer AS thang,
    trang_thai,
    count(*) AS so_luong_giao_dich,
    sum(tong_tien_thu) AS tong_doanh_thu,
    sum(phi_hoa_hong) AS tong_loi_nhuan,
    sum(so_tien_gia_su_nhan) AS tong_chi_tra_gia_su
FROM public.giao_dich
GROUP BY (EXTRACT(year FROM ngay_thanh_toan)::integer), (EXTRACT(month FROM ngay_thanh_toan)::integer), trang_thai
ORDER BY (EXTRACT(year FROM ngay_thanh_toan)::integer) DESC, (EXTRACT(month FROM ngay_thanh_toan)::integer) DESC;

-- 6.8: Yêu cầu đang mở
CREATE OR REPLACE VIEW public.vw_yeu_cau_dang_mo AS
SELECT
    yc.ma_yeu_cau, yc.tieu_de, yc.mo_ta, yc.tien_hoc_phi, yc.dia_chi,
    yc.hinh_thuc_hoc, yc.so_buoi_tuan, yc.thoi_gian_mong_muon, yc.ngay_yeu_cau, yc.trang_thai,
    hv.ho_ten AS ten_hoc_vien, hv.khoi_hien_tai,
    (SELECT count(*) FROM public.ung_tuyen ut WHERE ut.ma_yeu_cau::text = yc.ma_yeu_cau::text) AS so_luong_ung_tuyen,
    (SELECT string_agg(mh.ten_mon::text, ', '::text)
     FROM public.yeu_cau_mon ycm
     JOIN public.mon_hoc mh ON ycm.ma_mon::text = mh.ma_mon::text
     WHERE ycm.ma_yeu_cau::text = yc.ma_yeu_cau::text) AS cac_mon_hoc
FROM public.yeu_cau_lop yc
JOIN public.hoc_vien hv ON yc.ma_hoc_vien::text = hv.ma_hoc_vien::text
WHERE yc.trang_thai::text = ANY (ARRAY['open'::varchar, 'approved'::varchar]::text[]);

-- ======================================================================
-- SECTION 7: FUNCTIONS & PROCEDURES (7 functions + 8 procedures)
-- ======================================================================

-- 7.1: fn_dem_lop_dang_day
CREATE OR REPLACE FUNCTION public.fn_dem_lop_dang_day(p_ma_gia_su varchar)
RETURNS integer
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
DECLARE
    v_so_lop INT;
BEGIN
    SELECT COUNT(*) INTO v_so_lop
    FROM lop_hoc
    WHERE ma_gia_su = p_ma_gia_su AND trang_thai IN ('SapMo', 'Active');
    RETURN v_so_lop;
END;
$$;

-- 7.2: fn_doanh_thu_gia_su
CREATE OR REPLACE FUNCTION public.fn_doanh_thu_gia_su(p_ma_gia_su varchar, p_thang integer, p_nam integer)
RETURNS numeric
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
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
$$;

-- 7.3: fn_format_gio_hoc
CREATE OR REPLACE FUNCTION public.fn_format_gio_hoc(p_gio_bd time, p_gio_kt time)
RETURNS varchar
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
    RETURN TO_CHAR(p_gio_bd, 'HH24:MI') || ' - ' || TO_CHAR(p_gio_kt, 'HH24:MI');
END;
$$;

-- 7.4: fn_hoc_vien_hop_le
CREATE OR REPLACE FUNCTION public.fn_hoc_vien_hop_le(p_ma_hoc_vien varchar)
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
DECLARE
    v_hop_le BOOLEAN := TRUE;
BEGIN
    IF EXISTS (
        SELECT 1 FROM giao_dich gd
        JOIN dang_ky dk ON gd.ma_dang_ky = dk.ma_dang_ky
        WHERE dk.ma_hoc_vien = p_ma_hoc_vien AND gd.trang_thai = 'Failed'
    ) THEN
        v_hop_le := FALSE;
    END IF;
    RETURN v_hop_le;
END;
$$;

-- 7.5: fn_khung_gio_trong
CREATE OR REPLACE FUNCTION public.fn_khung_gio_trong(p_ma_gia_su varchar, p_thu smallint)
RETURNS TABLE(gio_bat_dau time, gio_ket_thuc time)
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
    RETURN QUERY
    SELECT lh.gio_bat_dau, lh.gio_ket_thuc
    FROM lich_hoc lh
    JOIN lop_hoc l ON lh.ma_lop = l.ma_lop
    WHERE l.ma_gia_su = p_ma_gia_su
      AND lh.thu_trong_tuan = p_thu
      AND l.trang_thai IN ('SapMo', 'Active')
    ORDER BY lh.gio_bat_dau;
END;
$$;

-- 7.6: fn_kiem_tra_trung_lich
CREATE OR REPLACE FUNCTION public.fn_kiem_tra_trung_lich(
    p_ma_gia_su varchar, p_thu smallint,
    p_gio_bat_dau time, p_gio_ket_thuc time,
    p_ma_lop_exclude varchar DEFAULT NULL::varchar
)
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
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
$$;

-- 7.7: fn_tinh_diem_tb_gia_su
CREATE OR REPLACE FUNCTION public.fn_tinh_diem_tb_gia_su(p_ma_gia_su varchar)
RETURNS numeric
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
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
$$;

-- 7.8: sp_chon_gia_su
CREATE OR REPLACE FUNCTION public.sp_chon_gia_su(IN p_ma_yeu_cau varchar, IN p_ma_gia_su varchar)
RETURNS void
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ung_tuyen WHERE ma_yeu_cau = p_ma_yeu_cau AND ma_gia_su = p_ma_gia_su AND trang_thai = 'pending') THEN
        RAISE EXCEPTION 'Gia sư chưa ứng tuyển hoặc đã được xử lý.';
    END IF;
    UPDATE yeu_cau_lop SET ma_gia_su_duoc_chon = p_ma_gia_su, ngay_chon_gia_su = NOW(), trang_thai = 'closed'
    WHERE ma_yeu_cau = p_ma_yeu_cau;
END;
$$;

-- 7.9: sp_danh_gia
CREATE OR REPLACE FUNCTION public.sp_danh_gia(IN p_ma_danh_gia varchar, IN p_ma_dang_ky varchar, IN p_diem_sao smallint, IN p_nhan_xet text DEFAULT NULL::text)
RETURNS void
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
    INSERT INTO danh_gia (ma_danh_gia, ma_dang_ky, diem_sao, nhan_xet)
    VALUES (p_ma_danh_gia, p_ma_dang_ky, p_diem_sao, p_nhan_xet);
END;
$$;

-- 7.10: sp_diem_danh
CREATE OR REPLACE FUNCTION public.sp_diem_danh(IN p_ma_buoi_hoc varchar, IN p_ma_dang_ky varchar, IN p_trang_thai varchar, IN p_so_phut_hoc integer DEFAULT NULL::integer)
RETURNS void
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
    INSERT INTO diem_danh (ma_buoi_hoc, ma_dang_ky, trang_thai, so_phut_hoc)
    VALUES (p_ma_buoi_hoc, p_ma_dang_ky, p_trang_thai, p_so_phut_hoc);
END;
$$;

-- 7.11: sp_ghi_nhan_thanh_toan
CREATE OR REPLACE FUNCTION public.sp_ghi_nhan_thanh_toan(
    IN p_ma_giao_dich varchar, IN p_ma_dang_ky varchar,
    IN p_ma_tk_hv varchar, IN p_ma_tk_gs varchar,
    IN p_tong_tien numeric, IN p_ty_le numeric,
    IN p_loai_giao_dich varchar DEFAULT 'ThanhToanThang'::varchar
)
RETURNS void
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
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
$$;

-- 7.12: sp_tao_lop_hoc
CREATE OR REPLACE FUNCTION public.sp_tao_lop_hoc(IN p_ma_lop varchar, IN p_ma_yeu_cau varchar, IN p_ngay_bat_dau date, IN p_tong_so_buoi integer)
RETURNS void
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
DECLARE
    v_ma_hoc_vien VARCHAR(20);
    v_ma_gia_su VARCHAR(20);
    v_hoc_phi DECIMAL;
    v_dia_chi TEXT;
    v_hinh_thuc VARCHAR(20);
BEGIN
    SELECT ma_hoc_vien, ma_gia_su_duoc_chon, tien_hoc_phi, dia_chi, hinh_thuc_hoc
    INTO v_ma_hoc_vien, v_ma_gia_su, v_hoc_phi, v_dia_chi, v_hinh_thuc
    FROM yeu_cau_lop WHERE ma_yeu_cau = p_ma_yeu_cau AND trang_thai = 'closed' AND ma_gia_su_duoc_chon IS NOT NULL;

    IF v_ma_hoc_vien IS NULL THEN
        RAISE EXCEPTION 'Yêu cầu chưa được chọn gia sư hoặc không tồn tại.';
    END IF;

    INSERT INTO lop_hoc (ma_lop, ma_gia_su, ma_hoc_vien, ma_yeu_cau, hoc_phi, dia_chi, hinh_thuc_day, ngay_bat_dau, tong_so_buoi, trang_thai)
    VALUES (p_ma_lop, v_ma_gia_su, v_ma_hoc_vien, p_ma_yeu_cau, v_hoc_phi, v_dia_chi, v_hinh_thuc, p_ngay_bat_dau, p_tong_so_buoi, 'SapMo');

    UPDATE yeu_cau_lop SET trang_thai = 'approved' WHERE ma_yeu_cau = p_ma_yeu_cau;

    INSERT INTO dang_ky (ma_dang_ky, ma_hoc_vien, ma_lop, trang_thai)
    VALUES ('DK_' || p_ma_lop, v_ma_hoc_vien, p_ma_lop, 'Confirmed');

    INSERT INTO lop_hoc_mon (ma_lop, ma_mon, vai_tro_mon)
    SELECT p_ma_lop, ma_mon, vai_tro_mon FROM yeu_cau_mon WHERE ma_yeu_cau = p_ma_yeu_cau;
END;
$$;

-- 7.13: sp_tao_yeu_cau_lop
CREATE OR REPLACE FUNCTION public.sp_tao_yeu_cau_lop(
    IN p_ma_yeu_cau varchar, IN p_ma_hoc_vien varchar, IN p_tieu_de varchar,
    IN p_mo_ta text, IN p_tien_hoc_phi numeric, IN p_dia_chi text,
    IN p_hinh_thuc_hoc varchar, IN p_so_buoi_tuan smallint, IN p_thoi_gian_mong_muon text
)
RETURNS void
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
    INSERT INTO yeu_cau_lop (ma_yeu_cau, ma_hoc_vien, tieu_de, mo_ta, tien_hoc_phi, dia_chi, hinh_thuc_hoc, so_buoi_tuan, thoi_gian_mong_muon, trang_thai)
    VALUES (p_ma_yeu_cau, p_ma_hoc_vien, p_tieu_de, p_mo_ta, p_tien_hoc_phi, p_dia_chi, p_hinh_thuc_hoc, p_so_buoi_tuan, p_thoi_gian_mong_muon, 'open');
END;
$$;

-- 7.14: sp_toggle_trong_lich
CREATE OR REPLACE FUNCTION public.sp_toggle_trong_lich(IN p_ma_gia_su varchar, IN p_trong_lich boolean)
RETURNS void
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
    UPDATE gia_su SET trong_lich = p_trong_lich WHERE ma_gia_su = p_ma_gia_su;
END;
$$;

-- 7.15: sp_ung_tuyen
CREATE OR REPLACE FUNCTION public.sp_ung_tuyen(
    IN p_ma_ung_tuyen varchar, IN p_ma_yeu_cau varchar, IN p_ma_gia_su varchar,
    IN p_thu_nhap_mong_muon numeric DEFAULT NULL::numeric, IN p_loi_nhan text DEFAULT NULL::text
)
RETURNS void
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM yeu_cau_lop WHERE ma_yeu_cau = p_ma_yeu_cau AND trang_thai = 'open') THEN
        RAISE EXCEPTION 'Yêu cầu này không còn mở để ứng tuyển.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM gia_su WHERE ma_gia_su = p_ma_gia_su AND trong_lich = TRUE) THEN
        RAISE EXCEPTION 'Gia sư đang bận, không thể ứng tuyển.';
    END IF;
    INSERT INTO ung_tuyen (ma_ung_tuyen, ma_yeu_cau, ma_gia_su, thu_nhap_mong_muon, loi_nhan)
    VALUES (p_ma_ung_tuyen, p_ma_yeu_cau, p_ma_gia_su, p_thu_nhap_mong_muon, p_loi_nhan);
END;
$$;

-- ======================================================================
-- SECTION 8: TRIGGERS (11 table triggers + 1 event trigger)
-- ======================================================================

-- 8.1: trg_set_updated_at (trigger function)
CREATE OR REPLACE FUNCTION public.trg_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
    NEW.ngay_cap_nhat = NOW();
    RETURN NEW;
END;
$$;

-- 8.2: trg_validate_lich_hoc_trung
CREATE OR REPLACE FUNCTION public.trg_validate_lich_hoc_trung()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
DECLARE
    v_ma_gia_su VARCHAR(20);
BEGIN
    SELECT ma_gia_su INTO v_ma_gia_su FROM lop_hoc WHERE ma_lop = NEW.ma_lop;
    IF fn_kiem_tra_trung_lich(v_ma_gia_su, NEW.thu_trong_tuan, NEW.gio_bat_dau, NEW.gio_ket_thuc, NEW.ma_lop) THEN
        RAISE EXCEPTION 'LICH_HOC: Gia sư % đã có lịch trùng vào thứ %, giờ % - %.', v_ma_gia_su, NEW.thu_trong_tuan, NEW.gio_bat_dau, NEW.gio_ket_thuc;
    END IF;
    RETURN NEW;
END;
$$;

-- 8.3: trg_validate_buoi_hoc_trung
CREATE OR REPLACE FUNCTION public.trg_validate_buoi_hoc_trung()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
DECLARE
    v_ma_gia_su VARCHAR(20);
    v_thu SMALLINT;
BEGIN
    SELECT ma_gia_su INTO v_ma_gia_su FROM lop_hoc WHERE ma_lop = NEW.ma_lop;
    v_thu := EXTRACT(ISODOW FROM NEW.ngay_hoc)::SMALLINT;
    IF fn_kiem_tra_trung_lich(v_ma_gia_su, v_thu, NEW.gio_bat_dau, NEW.gio_ket_thuc, NEW.ma_lop) THEN
        RAISE EXCEPTION 'BUOI_HOC: Gia sư % đã có lịch trùng vào ngày % giờ % - %.', v_ma_gia_su, NEW.ngay_hoc, NEW.gio_bat_dau, NEW.gio_ket_thuc;
    END IF;
    RETURN NEW;
END;
$$;

-- 8.4: trg_dang_ky_check_siso
CREATE OR REPLACE FUNCTION public.trg_dang_ky_check_siso()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
DECLARE
    v_max SMALLINT;
    v_current INT;
BEGIN
    SELECT so_hv_toi_da INTO v_max FROM lop_hoc WHERE ma_lop = NEW.ma_lop;
    SELECT COUNT(*) INTO v_current FROM dang_ky WHERE ma_lop = NEW.ma_lop AND trang_thai IN ('Pending', 'Confirmed');
    IF v_current >= v_max THEN
        RAISE EXCEPTION 'Lớp học đã đủ sĩ số tối đa (% học viên).', v_max;
    END IF;
    RETURN NEW;
END;
$$;

-- 8.5: trg_validate_diem_danh
CREATE OR REPLACE FUNCTION public.trg_validate_diem_danh()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM buoi_hoc bh
        JOIN dang_ky dk ON NEW.ma_dang_ky = dk.ma_dang_ky
        WHERE bh.ma_buoi_hoc = NEW.ma_buoi_hoc AND bh.ma_lop != dk.ma_lop
    ) THEN
        RAISE EXCEPTION 'DIEM_DANH: Buổi học và Đăng ký không cùng lớp học.';
    END IF;
    RETURN NEW;
END;
$$;

-- 8.6: trg_validate_giao_dich
CREATE OR REPLACE FUNCTION public.trg_validate_giao_dich()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM dang_ky dk
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
$$;

-- 8.7: trg_notify_ung_tuyen
CREATE OR REPLACE FUNCTION public.trg_notify_ung_tuyen()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
DECLARE
    v_ma_hoc_vien VARCHAR(20);
    v_ten_gs VARCHAR(200);
    v_tieu_de VARCHAR(200);
BEGIN
    SELECT yc.ma_hoc_vien INTO v_ma_hoc_vien FROM yeu_cau_lop yc WHERE yc.ma_yeu_cau = NEW.ma_yeu_cau;
    SELECT ho_ten INTO v_ten_gs FROM gia_su WHERE ma_gia_su = NEW.ma_gia_su;
    v_tieu_de := 'Gia sư ' || v_ten_gs || ' đã ứng tuyển vào yêu cầu ' || NEW.ma_yeu_cau;
    INSERT INTO thong_bao (ma_thong_bao, ma_hoc_vien, loai_thong_bao, tieu_de, noi_dung, ma_yeu_cau)
    VALUES ('TB_' || REPLACE(gen_random_uuid()::TEXT, '-', ''), v_ma_hoc_vien, 'UngTuyen', v_tieu_de,
            'Gia sư ' || v_ten_gs || ' đã ứng tuyển. Xem chi tiết trong mục "Yêu cầu của tôi".', NEW.ma_yeu_cau);
    RETURN NEW;
END;
$$;

-- 8.8: trg_notify_chon_gia_su
CREATE OR REPLACE FUNCTION public.trg_notify_chon_gia_su()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
DECLARE
    v_ten_hv VARCHAR(200);
    v_ten_gs VARCHAR(200);
BEGIN
    IF OLD.ma_gia_su_duoc_chon IS NULL AND NEW.ma_gia_su_duoc_chon IS NOT NULL THEN
        SELECT ho_ten INTO v_ten_hv FROM hoc_vien WHERE ma_hoc_vien = NEW.ma_hoc_vien;
        SELECT ho_ten INTO v_ten_gs FROM gia_su WHERE ma_gia_su = NEW.ma_gia_su_duoc_chon;

        INSERT INTO thong_bao (ma_thong_bao, ma_gia_su, loai_thong_bao, tieu_de, noi_dung, ma_yeu_cau)
        VALUES ('TB_' || REPLACE(gen_random_uuid()::TEXT, '-', ''), NEW.ma_gia_su_duoc_chon, 'DuocChon',
                'Bạn đã được chọn cho yêu cầu ' || NEW.ma_yeu_cau,
                'Học viên ' || v_ten_hv || ' đã chọn bạn. Lớp học sẽ sớm được tạo.', NEW.ma_yeu_cau);

        INSERT INTO thong_bao (ma_thong_bao, ma_gia_su, loai_thong_bao, tieu_de, noi_dung, ma_yeu_cau)
        SELECT 'TB_' || REPLACE(gen_random_uuid()::TEXT, '-', ''), ut.ma_gia_su, 'TuChoi',
               'Yêu cầu ' || NEW.ma_yeu_cau || ' đã có gia sư được chọn',
               'Học viên ' || v_ten_hv || ' đã chọn gia sư khác cho yêu cầu này.', NEW.ma_yeu_cau
        FROM ung_tuyen ut
        WHERE ut.ma_yeu_cau = NEW.ma_yeu_cau AND ut.ma_gia_su != NEW.ma_gia_su_duoc_chon AND ut.trang_thai = 'pending';

        UPDATE ung_tuyen SET trang_thai = 'rejected', ngay_xu_ly = NOW()
        WHERE ma_yeu_cau = NEW.ma_yeu_cau AND ma_gia_su != NEW.ma_gia_su_duoc_chon AND trang_thai = 'pending';

        UPDATE ung_tuyen SET trang_thai = 'accepted', ngay_xu_ly = NOW()
        WHERE ma_yeu_cau = NEW.ma_yeu_cau AND ma_gia_su = NEW.ma_gia_su_duoc_chon;
    END IF;
    RETURN NEW;
END;
$$;

-- 8.9: trg_audit_log
CREATE OR REPLACE FUNCTION public.trg_audit_log()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
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
$$;

-- 8.10: Event trigger function - rls_auto_enable
CREATE OR REPLACE FUNCTION public.rls_auto_enable()
RETURNS event_trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public')
        AND cmd.schema_name NOT IN ('pg_catalog','information_schema')
        AND cmd.schema_name NOT LIKE 'pg_toast%'
        AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;

-- ======================================================================
-- SECTION 8b: TABLE TRIGGERS
-- ======================================================================

-- hoc_vien: auto-set ngay_cap_nhat on UPDATE
CREATE TRIGGER tr_hoc_vien_updated_at
    BEFORE UPDATE ON public.hoc_vien
    FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();

-- gia_su: auto-set ngay_cap_nhat on UPDATE
CREATE TRIGGER tr_gia_su_updated_at
    BEFORE UPDATE ON public.gia_su
    FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();

-- yeu_cau_lop: auto-set ngay_cap_nhat on UPDATE + notify when gia su selected
CREATE TRIGGER tr_yeu_cau_lop_updated_at
    BEFORE UPDATE ON public.yeu_cau_lop
    FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();

CREATE TRIGGER tr_yeu_cau_chon_gia_su
    AFTER UPDATE ON public.yeu_cau_lop
    FOR EACH ROW EXECUTE FUNCTION public.trg_notify_chon_gia_su();

-- ung_tuyen: notify when insert
CREATE TRIGGER tr_ung_tuyen_notify
    AFTER INSERT ON public.ung_tuyen
    FOR EACH ROW EXECUTE FUNCTION public.trg_notify_ung_tuyen();

-- lich_hoc: validate no schedule overlap
CREATE TRIGGER tr_lich_hoc_check_trung
    BEFORE INSERT OR UPDATE ON public.lich_hoc
    FOR EACH ROW EXECUTE FUNCTION public.trg_validate_lich_hoc_trung();

-- buoi_hoc: validate no session overlap
CREATE TRIGGER tr_buoi_hoc_check_trung
    BEFORE INSERT OR UPDATE ON public.buoi_hoc
    FOR EACH ROW EXECUTE FUNCTION public.trg_validate_buoi_hoc_trung();

-- dang_ky: check capacity
CREATE TRIGGER tr_dang_ky_check_siso
    BEFORE INSERT ON public.dang_ky
    FOR EACH ROW EXECUTE FUNCTION public.trg_dang_ky_check_siso();

-- diem_danh: validate consistency
CREATE TRIGGER tr_diem_danh_validate
    BEFORE INSERT OR UPDATE ON public.diem_danh
    FOR EACH ROW EXECUTE FUNCTION public.trg_validate_diem_danh();

-- giao_dich: validate account ownership
CREATE TRIGGER tr_giao_dich_validate
    BEFORE INSERT OR UPDATE ON public.giao_dich
    FOR EACH ROW EXECUTE FUNCTION public.trg_validate_giao_dich();

-- lop_hoc: audit logging
CREATE TRIGGER tr_audit_lop_hoc
    AFTER INSERT OR UPDATE OR DELETE ON public.lop_hoc
    FOR EACH ROW EXECUTE FUNCTION public.trg_audit_log();

-- ======================================================================
-- SECTION 8c: EVENT TRIGGER
-- ======================================================================

CREATE EVENT TRIGGER ensure_rls
    ON ddl_command_end
    WHEN TAG IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
    EXECUTE FUNCTION public.rls_auto_enable();

-- ======================================================================
-- SECTION 9: ROW LEVEL SECURITY (RLS POLICIES)
-- ======================================================================

-- 9.1: Enable RLS on all 20 tables
ALTER TABLE public.hoc_vien        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gia_su          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mon_hoc         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gia_su_mon_hoc  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.yeu_cau_lop     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.yeu_cau_mon     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ung_tuyen       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lop_hoc         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lop_hoc_mon     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lich_hoc        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.buoi_hoc        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dang_ky         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tai_khoan_hv    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tai_khoan_gs    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.giao_dich       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.danh_gia        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.diem_danh       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.thong_bao       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quan_tri_vien   ENABLE ROW LEVEL SECURITY;

-- 9.2: hoc_vien policies (4 policies)
CREATE POLICY hoc_vien_select ON public.hoc_vien FOR SELECT TO public USING (true);
CREATE POLICY hoc_vien_insert ON public.hoc_vien FOR INSERT TO public WITH CHECK (auth_id = auth.uid());
CREATE POLICY hoc_vien_update ON public.hoc_vien FOR UPDATE TO public USING (auth_id = auth.uid()) WITH CHECK (auth_id = auth.uid());
CREATE POLICY hoc_vien_delete ON public.hoc_vien FOR DELETE TO public USING (auth_id = auth.uid());

-- 9.3: gia_su policies (4 policies)
CREATE POLICY gia_su_select ON public.gia_su FOR SELECT TO public USING (true);
CREATE POLICY gia_su_insert ON public.gia_su FOR INSERT TO public WITH CHECK (auth_id = auth.uid());
CREATE POLICY gia_su_update ON public.gia_su FOR UPDATE TO public USING (auth_id = auth.uid()) WITH CHECK (auth_id = auth.uid());
CREATE POLICY gia_su_delete ON public.gia_su FOR DELETE TO public USING (auth_id = auth.uid());

-- 9.4: mon_hoc policies (1 policy)
CREATE POLICY mon_hoc_select ON public.mon_hoc FOR SELECT TO public USING (true);

-- 9.5: gia_su_mon_hoc policies (4 policies)
CREATE POLICY gia_su_mon_hoc_select ON public.gia_su_mon_hoc FOR SELECT TO public USING (true);
CREATE POLICY gia_su_mon_hoc_insert ON public.gia_su_mon_hoc FOR INSERT TO public WITH CHECK (ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()));
CREATE POLICY gia_su_mon_hoc_update ON public.gia_su_mon_hoc FOR UPDATE TO public USING (ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()));
CREATE POLICY gia_su_mon_hoc_delete ON public.gia_su_mon_hoc FOR DELETE TO public USING (ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()));

-- 9.6: yeu_cau_lop policies (4 policies)
CREATE POLICY yeu_cau_select ON public.yeu_cau_lop FOR SELECT TO public USING (trang_thai::text = ANY (ARRAY['open'::varchar, 'approved'::varchar]::text[]) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()));
CREATE POLICY yeu_cau_insert ON public.yeu_cau_lop FOR INSERT TO public WITH CHECK (ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()));
CREATE POLICY yeu_cau_update ON public.yeu_cau_lop FOR UPDATE TO public USING (ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()));
CREATE POLICY yeu_cau_delete ON public.yeu_cau_lop FOR DELETE TO public USING (ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()));

-- 9.7: yeu_cau_mon policies (4 policies)
CREATE POLICY yeu_cau_mon_select ON public.yeu_cau_mon FOR SELECT TO public USING (true);
CREATE POLICY yeu_cau_mon_insert ON public.yeu_cau_mon FOR INSERT TO public WITH CHECK (ma_yeu_cau IN (SELECT ma_yeu_cau FROM public.yeu_cau_lop WHERE ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid())));
CREATE POLICY yeu_cau_mon_update ON public.yeu_cau_mon FOR UPDATE TO public USING (ma_yeu_cau IN (SELECT ma_yeu_cau FROM public.yeu_cau_lop WHERE ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid())));
CREATE POLICY yeu_cau_mon_delete ON public.yeu_cau_mon FOR DELETE TO public USING (ma_yeu_cau IN (SELECT ma_yeu_cau FROM public.yeu_cau_lop WHERE ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid())));

-- 9.8: ung_tuyen policies (5 policies)
CREATE POLICY ung_tuyen_gs_select ON public.ung_tuyen FOR SELECT TO public USING (ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()));
CREATE POLICY ung_tuyen_hv_select ON public.ung_tuyen FOR SELECT TO public USING (ma_yeu_cau IN (SELECT ma_yeu_cau FROM public.yeu_cau_lop WHERE ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid())));
CREATE POLICY ung_tuyen_insert ON public.ung_tuyen FOR INSERT TO public WITH CHECK (ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()));
CREATE POLICY ung_tuyen_update ON public.ung_tuyen FOR UPDATE TO public USING (ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()));
CREATE POLICY ung_tuyen_delete ON public.ung_tuyen FOR DELETE TO public USING (ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()));

-- 9.9: lop_hoc policies (4 policies)
CREATE POLICY lop_hoc_select ON public.lop_hoc FOR SELECT TO public USING (ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()));
CREATE POLICY lop_hoc_insert ON public.lop_hoc FOR INSERT TO public WITH CHECK (ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()));
CREATE POLICY lop_hoc_update ON public.lop_hoc FOR UPDATE TO public USING (ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()));
CREATE POLICY lop_hoc_delete ON public.lop_hoc FOR DELETE TO public USING (ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()));

-- 9.10: lop_hoc_mon policies (4 policies)
CREATE POLICY lop_hoc_mon_select ON public.lop_hoc_mon FOR SELECT TO public USING (ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid())));
CREATE POLICY lop_hoc_mon_insert ON public.lop_hoc_mon FOR INSERT TO public WITH CHECK (ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid())));
CREATE POLICY lop_hoc_mon_update ON public.lop_hoc_mon FOR UPDATE TO public USING (ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid())));
CREATE POLICY lop_hoc_mon_delete ON public.lop_hoc_mon FOR DELETE TO public USING (ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid())));

-- 9.11: lich_hoc policies (4 policies)
CREATE POLICY lich_hoc_select ON public.lich_hoc FOR SELECT TO public USING (ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid())));
CREATE POLICY lich_hoc_insert ON public.lich_hoc FOR INSERT TO public WITH CHECK (ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid())));
CREATE POLICY lich_hoc_update ON public.lich_hoc FOR UPDATE TO public USING (ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid())));
CREATE POLICY lich_hoc_delete ON public.lich_hoc FOR DELETE TO public USING (ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid())));

-- 9.12: buoi_hoc policies (4 policies)
CREATE POLICY buoi_hoc_select ON public.buoi_hoc FOR SELECT TO public USING (ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid())));
CREATE POLICY buoi_hoc_insert ON public.buoi_hoc FOR INSERT TO public WITH CHECK (ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid())));
CREATE POLICY buoi_hoc_update ON public.buoi_hoc FOR UPDATE TO public USING (ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid())));
CREATE POLICY buoi_hoc_delete ON public.buoi_hoc FOR DELETE TO public USING (ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid())));

-- 9.13: dang_ky policies (4 policies)
CREATE POLICY dang_ky_select ON public.dang_ky FOR SELECT TO public USING (ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()) OR ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid())));
CREATE POLICY dang_ky_insert ON public.dang_ky FOR INSERT TO public WITH CHECK (ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()) OR ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid())));
CREATE POLICY dang_ky_update ON public.dang_ky FOR UPDATE TO public USING (ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()) OR ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid())));
CREATE POLICY dang_ky_delete ON public.dang_ky FOR DELETE TO public USING (ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()) OR ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid())));

-- 9.14: tai_khoan_hv policies (4 policies)
CREATE POLICY tai_khoan_hv_select ON public.tai_khoan_hv FOR SELECT TO public USING (ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()));
CREATE POLICY tai_khoan_hv_insert ON public.tai_khoan_hv FOR INSERT TO public WITH CHECK (ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()));
CREATE POLICY tai_khoan_hv_update ON public.tai_khoan_hv FOR UPDATE TO public USING (ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()));
CREATE POLICY tai_khoan_hv_delete ON public.tai_khoan_hv FOR DELETE TO public USING (ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()));

-- 9.15: tai_khoan_gs policies (4 policies)
CREATE POLICY tai_khoan_gs_select ON public.tai_khoan_gs FOR SELECT TO public USING (ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()));
CREATE POLICY tai_khoan_gs_insert ON public.tai_khoan_gs FOR INSERT TO public WITH CHECK (ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()));
CREATE POLICY tai_khoan_gs_update ON public.tai_khoan_gs FOR UPDATE TO public USING (ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()));
CREATE POLICY tai_khoan_gs_delete ON public.tai_khoan_gs FOR DELETE TO public USING (ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()));

-- 9.16: giao_dich policies (2 policies)
CREATE POLICY giao_dich_select ON public.giao_dich FOR SELECT TO public USING (ma_tk_hv IN (SELECT ma_tk_hv FROM public.tai_khoan_hv WHERE ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid())) OR ma_tk_gs IN (SELECT ma_tk_gs FROM public.tai_khoan_gs WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid())));
CREATE POLICY giao_dich_insert ON public.giao_dich FOR INSERT TO public WITH CHECK (ma_tk_hv IN (SELECT ma_tk_hv FROM public.tai_khoan_hv WHERE ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid())) OR ma_tk_gs IN (SELECT ma_tk_gs FROM public.tai_khoan_gs WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid())));

-- 9.17: danh_gia policies (4 policies)
CREATE POLICY danh_gia_select ON public.danh_gia FOR SELECT TO public USING (true);
CREATE POLICY danh_gia_insert ON public.danh_gia FOR INSERT TO public WITH CHECK (ma_dang_ky IN (SELECT ma_dang_ky FROM public.dang_ky WHERE ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()) OR ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()))));
CREATE POLICY danh_gia_update ON public.danh_gia FOR UPDATE TO public USING (ma_dang_ky IN (SELECT ma_dang_ky FROM public.dang_ky WHERE ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()) OR ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()))));
CREATE POLICY danh_gia_delete ON public.danh_gia FOR DELETE TO public USING (ma_dang_ky IN (SELECT ma_dang_ky FROM public.dang_ky WHERE ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()) OR ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()))));

-- 9.18: diem_danh policies (4 policies)
CREATE POLICY diem_danh_select ON public.diem_danh FOR SELECT TO public USING (ma_buoi_hoc IN (SELECT ma_buoi_hoc FROM public.buoi_hoc WHERE ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()))));
CREATE POLICY diem_danh_insert ON public.diem_danh FOR INSERT TO public WITH CHECK (ma_buoi_hoc IN (SELECT ma_buoi_hoc FROM public.buoi_hoc WHERE ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()))));
CREATE POLICY diem_danh_update ON public.diem_danh FOR UPDATE TO public USING (ma_buoi_hoc IN (SELECT ma_buoi_hoc FROM public.buoi_hoc WHERE ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()))));
CREATE POLICY diem_danh_delete ON public.diem_danh FOR DELETE TO public USING (ma_buoi_hoc IN (SELECT ma_buoi_hoc FROM public.buoi_hoc WHERE ma_lop IN (SELECT ma_lop FROM public.lop_hoc WHERE ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()) OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()))));

-- 9.19: thong_bao policies (3 policies)
CREATE POLICY thong_bao_select ON public.thong_bao FOR SELECT TO public USING (ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()) OR ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()));
CREATE POLICY thong_bao_update ON public.thong_bao FOR UPDATE TO public USING (ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()) OR ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()));
CREATE POLICY thong_bao_delete ON public.thong_bao FOR DELETE TO public USING (ma_hoc_vien IN (SELECT ma_hoc_vien FROM public.hoc_vien WHERE auth_id = auth.uid()) OR ma_gia_su IN (SELECT ma_gia_su FROM public.gia_su WHERE auth_id = auth.uid()));

-- 9.20: audit_log policies (1 policy)
CREATE POLICY audit_log_deny_public ON public.audit_log FOR ALL TO public USING (false);

-- 9.21: quan_tri_vien policies (4 policies)
CREATE POLICY quan_tri_vien_select ON public.quan_tri_vien FOR SELECT TO public USING (auth_id = auth.uid());
CREATE POLICY quan_tri_vien_insert ON public.quan_tri_vien FOR INSERT TO public WITH CHECK (auth_id = auth.uid());
CREATE POLICY quan_tri_vien_update ON public.quan_tri_vien FOR UPDATE TO public USING (auth_id = auth.uid());
CREATE POLICY quan_tri_vien_delete ON public.quan_tri_vien FOR DELETE TO public USING (auth_id = auth.uid());

-- ======================================================================
-- SECTION 10: SEED DATA
-- ======================================================================

-- 10.1: quan_tri_vien
INSERT INTO public.quan_tri_vien (ma_qtv, ho_ten, email, auth_id, ngay_tao, ngay_cap_nhat)
VALUES ('ADM001', 'Quản trị viên', 'admin@giasubachkhoa.edu.vn', NULL, '2026-05-21 02:12:59.165133+00', '2026-05-21 02:12:59.165133+00');

-- 10.2: mon_hoc
INSERT INTO public.mon_hoc (ma_mon, ten_mon, cap_hoc, mo_ta) VALUES
('MH001', 'Toán',       'Cấp 3',    'Toán THPT ôn thi đại học'),
('MH002', 'Vật Lý',     'Cấp 3',    'Vật lý chuyên sâu 10-11-12'),
('MH003', 'Hóa Học',    'Cấp 3',    'Hóa vô cơ và hữu cơ'),
('MH004', 'Tiếng Anh',  'Tất cả',   'Giao tiếp và luyện thi IELTS'),
('MH005', 'Ngữ Văn',    'Cấp 2',    'Luyện thi vào lớp 10'),
('MH006', 'Sinh Học',   'Cấp 3',    'Sinh học các cấp, luyện thi THPT Quốc gia'),
('MH007', 'Lịch Sử',    'Cấp 3',    'Lịch sử Việt Nam và thế giới, luyện thi'),
('MH008', 'Địa Lý',     'Tất cả',   'Địa lý tự nhiên và xã hội, kỹ năng bản đồ');

-- 10.3: hoc_vien
INSERT INTO public.hoc_vien (ma_hoc_vien, ho_ten, ngay_sinh, so_dien_thoai, email, khoi_hien_tai, auth_id, ngay_tao, ngay_cap_nhat) VALUES
('HV001', 'Nguyễn Văn An',   '2005-01-15', '0901234567', 'an.nguyen@gmail.com',    'Lớp 12', NULL, '2026-05-21 01:03:14.56742+00', '2026-05-21 01:03:14.56742+00'),
('HV002', 'Trần Thị Bình',   '2008-05-20', '0912345678', 'binh.tran@gmail.com',   'Lớp 9',  NULL, '2026-05-21 01:03:14.56742+00', '2026-05-21 01:03:14.56742+00'),
('HV003', 'Lê Hoàng Cường',  '2010-09-10', '0923456789', 'cuong.le@gmail.com',    'Lớp 7',  NULL, '2026-05-21 01:03:14.56742+00', '2026-05-21 01:03:14.56742+00'),
('HV004', 'Phạm Mai Dung',   '2006-11-25', '0934567890', 'dung.pham@gmail.com',   'Lớp 11', NULL, '2026-05-21 01:03:14.56742+00', '2026-05-21 01:03:14.56742+00'),
('HV005', 'Hoàng Tuấn Em',   '2004-03-30', '0945678901', 'em.hoang@gmail.com',    'Lớp 12', NULL, '2026-05-21 01:03:14.56742+00', '2026-05-21 01:03:14.56742+00'),
('HV006', 'Đặng Thị Hương',  '2008-03-15', '0909123456', 'huong.dang@gmail.com',  'Lớp 10', NULL, '2026-05-21 02:55:58.599697+00', '2026-05-21 02:55:58.599697+00'),
('HV007', 'Bùi Văn Khôi',    '2010-08-22', '0909234567', 'khoi.bui@gmail.com',    'Lớp 8',  NULL, '2026-05-21 02:55:58.599697+00', '2026-05-21 02:55:58.599697+00'),
('HV008', 'Ngô Thanh Lan',   '2006-11-30', '0909345678', 'lan.ngo@gmail.com',     'Lớp 12', NULL, '2026-05-21 02:55:58.599697+00', '2026-05-21 02:55:58.599697+00'),
('HV009', 'Đỗ Đức Minh',     '2007-06-10', '0909456789', 'minh.do@gmail.com',     'Lớp 11', NULL, '2026-05-21 02:55:58.599697+00', '2026-05-21 02:55:58.599697+00'),
('HV010', 'Vương Thị Ngọc',  '2012-01-25', '0909567890', 'ngoc.vuong@gmail.com',  'Lớp 6',  NULL, '2026-05-21 02:55:58.599697+00', '2026-05-21 02:55:58.599697+00');

-- 10.4: gia_su
INSERT INTO public.gia_su (ma_gia_su, ho_ten, ngay_sinh, trinh_do, gioi_thieu, trong_lich, auth_id, ngay_tao, ngay_cap_nhat) VALUES
('GS001', 'Nguyễn Thanh Tùng', '1998-02-14', 'Đại học Sư phạm Toán',           'Giáo viên Toán 5 năm kinh nghiệm',                                        true, NULL, '2026-05-21 01:03:14.56742+00', '2026-05-21 01:03:14.56742+00'),
('GS002', 'Lê Thu Hà',         '1995-07-22', 'Thạc sĩ Toán học',               'Chuyên luyện thi THPT Quốc gia môn Toán',                                 true, NULL, '2026-05-21 01:03:14.56742+00', '2026-05-21 01:03:14.56742+00'),
('GS003', 'Trần Minh Khang',   '2000-10-05', 'Sinh viên năm cuối ĐH Ngoại Thương', 'IELTS 7.5, kinh nghiệm dạy Tiếng Anh 2 năm',                           true, NULL, '2026-05-21 01:03:14.56742+00', '2026-05-21 01:03:14.56742+00'),
('GS004', 'Phạm Bích Ngọc',    '1997-12-11', 'Giáo viên Ngữ Văn Cấp 2',        '6 năm dạy Văn, giáo viên giỏi cấp tỉnh',                                  true, NULL, '2026-05-21 01:03:14.56742+00', '2026-05-21 01:03:14.56742+00'),
('GS005', 'Vũ Hải Đăng',       '1996-08-09', 'Đại học Bách Khoa',              'Kỹ sư, dạy Lý-Hóa 4 năm',                                                  true, NULL, '2026-05-21 01:03:14.56742+00', '2026-05-21 01:03:14.56742+00'),
('GS006', 'Hoàng Xuân Mai',    '1996-04-18', 'Thạc sĩ Hóa học - ĐH KHTN',      'Hơn 5 năm dạy Hóa cho học sinh cấp 2, cấp 3 và luyện thi đại học. Phương pháp dạy trực quan, dễ hiểu.', true, NULL, '2026-05-21 02:55:58.599697+00', '2026-05-21 02:55:58.599697+00'),
('GS007', 'Trịnh Bảo Long',    '1998-09-05', 'Cử nhân Tiếng Anh - ĐH Sư Phạm', 'Tốt nghiệp loại Giỏi ngành Sư phạm Tiếng Anh. Có chứng chỉ TESOL, IELTS 8.0. Kinh nghiệm dạy tiếng Anh giao tiếp và luyện thi.', true, NULL, '2026-05-21 02:55:58.599697+00', '2026-05-21 02:55:58.599697+00');

-- 10.5: gia_su_mon_hoc
INSERT INTO public.gia_su_mon_hoc (ma_gia_su, ma_mon, nam_kinh_nghiem, muc_do_thanh_thao, chung_chi) VALUES
('GS001', 'MH001', 3, 'Khá',         'Chứng chỉ sư phạm'),
('GS001', 'MH002', 2, 'Trung bình',  NULL),
('GS002', 'MH001', 5, 'Tốt',         'Bằng giỏi ĐH Sư Phạm'),
('GS003', 'MH004', 2, 'Khá',         'IELTS 7.5'),
('GS003', 'MH006', 1, 'Trung bình',  NULL),
('GS004', 'MH005', 6, 'Tốt',         'Giáo viên giỏi cấp tỉnh'),
('GS004', 'MH007', 4, 'Khá',         NULL),
('GS004', 'MH008', 3, 'Khá',         NULL),
('GS005', 'MH002', 4, 'Khá',         NULL),
('GS005', 'MH003', 3, 'Khá',         NULL),
('GS006', 'MH003', 5, 'Tốt',         NULL),
('GS007', 'MH004', 4, 'Tốt',         NULL);

-- 10.6: yeu_cau_lop
INSERT INTO public.yeu_cau_lop (ma_yeu_cau, ma_hoc_vien, tieu_de, mo_ta, tien_hoc_phi, dia_chi, hinh_thuc_hoc, so_buoi_tuan, thoi_gian_mong_muon, ngay_yeu_cau, trang_thai, ma_gia_su_duoc_chon, ngay_chon_gia_su, ngay_cap_nhat) VALUES
('YC001', 'HV001', 'Cần gia sư Toán 12 luyện thi ĐH',  'Học sinh cần củng cố kiến thức Toán 12',                       '200000', 'Quận 1, TP.HCM',        'Offline', 2, 'Tối thứ 2, 4 (18h-20h)',      '2026-05-21 01:03:14.56742+00', 'approved', 'GS002', '2026-05-10 09:30:00+00', '2026-05-21 02:55:58.599697+00'),
('YC002', 'HV002', 'Luyện Văn 9 thi vào 10',            'Cần gia sư Văn giúp em tự tin thi vào 10',                     '150000', 'Quận 3, TP.HCM',        'Offline', 2, 'Cuối tuần',                    '2026-05-21 01:03:14.56742+00', 'approved', 'GS004', '2026-04-22 10:00:00+00', '2026-05-21 02:55:58.599697+00'),
('YC003', 'HV003', 'Học Tiếng Anh giao tiếp',            'Học sinh lớp 7 muốn cải thiện giao tiếp',                      '180000', 'Quận 10, TP.HCM',       'Online',  3, 'Tối 2-4-6',                    '2026-05-21 01:03:14.56742+00', 'approved', 'GS003', '2026-05-09 16:00:00+00', '2026-05-21 02:55:58.599697+00'),
('YC004', 'HV004', 'Lý 11 nâng cao',                     'Học sinh khá giỏi cần nâng cao Lý 11',                         '250000', 'Quận 5, TP.HCM',        'Offline', 1, 'Chủ nhật sáng',                '2026-05-21 01:03:14.56742+00', 'approved', 'GS005', '2026-05-06 15:00:00+00', '2026-05-21 02:55:58.599697+00'),
('YC005', 'HV005', 'Toán luyện thi THPT Quốc gia',        'Học sinh cần luyện đề và nâng cao',                            '300000', 'Quận 7, TP.HCM',        'Offline', 3, 'Tối 3-5-7',                    '2026-05-21 01:03:14.56742+00', 'approved', 'GS001', '2026-05-08 14:00:00+00', '2026-05-21 02:55:58.599697+00'),
('YC006', 'HV006', 'Cần gia sư Hóa lớp 10 cơ bản',        'Học sinh mất gốc Hóa, cần người kèm từ đầu chương trình lớp 10.', '150000', 'Quận 7, TP.HCM',        'offline', 2, 'Tối thứ 2, thứ 5',             '2026-05-18 08:00:00+00', 'open',     NULL,    NULL,                     '2026-05-21 02:55:58.599697+00'),
('YC007', 'HV008', 'Luyện Lý 12 nâng cao thi ĐH',         'Học sinh khá, cần luyện nâng cao và làm đề thi thử để đạt 9+ môn Lý.', '250000', 'Quận Tân Phú, TP.HCM',  'offline', 3, 'Chiều thứ 3, 5, 7',            '2026-05-19 10:00:00+00', 'open',     NULL,    NULL,                     '2026-05-21 02:55:58.599697+00'),
('YC008', 'HV010', 'Tiếng Anh cho bé lớp 6',              'Bé mới bắt đầu học tiếng Anh, cần gia sư kiên nhẫn, yêu trẻ em.', '120000', 'Quận Phú Nhuận, TP.HCM', 'offline', 2, 'Sáng thứ 7, Chủ nhật',         '2026-05-20 15:00:00+00', 'open',     NULL,    NULL,                     '2026-05-21 02:55:58.599697+00');

-- 10.7: yeu_cau_mon
INSERT INTO public.yeu_cau_mon (ma_yeu_cau, ma_mon, vai_tro_mon, ghi_chu) VALUES
('YC001', 'MH001', 'Chính', NULL),
('YC002', 'MH005', 'Chính', NULL),
('YC003', 'MH004', 'Chính', NULL),
('YC004', 'MH002', 'Chính', NULL),
('YC005', 'MH001', 'Chính', NULL),
('YC006', 'MH003', 'Chính', NULL),
('YC007', 'MH002', 'Chính', NULL),
('YC008', 'MH004', 'Chính', NULL);

-- 10.8: ung_tuyen
INSERT INTO public.ung_tuyen (ma_ung_tuyen, ma_yeu_cau, ma_gia_su, thu_nhap_mong_muon, loi_nhan, trang_thai, ngay_ung_tuyen, ngay_xu_ly) VALUES
('UT001', 'YC001', 'GS001', '180000', 'Tôi có 3 năm kinh nghiệm dạy Toán 12, đã giúp nhiều em đỗ đại học.',                                             'rejected', '2026-05-21 01:03:14.56742+00', '2026-05-10 09:31:00+00'),
('UT002', 'YC001', 'GS002', '220000', 'Thạc sĩ Toán, chuyên luyện thi THPT Quốc gia. Cam kết học sinh đạt điểm cao.',                                  'accepted', '2026-05-21 01:03:14.56742+00', '2026-05-10 09:30:00+00'),
('UT003', 'YC005', 'GS001', '280000', 'Kinh nghiệm dạy luyện thi, có giáo án đầy đủ.',                                                                 'accepted', '2026-05-21 01:03:14.56742+00', '2026-05-08 14:00:00+00'),
('UT004', 'YC005', 'GS002', '320000', 'Nhận dạy online hoặc offline theo yêu cầu.',                                                                     'rejected', '2026-05-21 01:03:14.56742+00', '2026-05-08 14:01:00+00'),
('UTB1', 'YC002', 'GS004', '170000', 'Giáo viên Văn cấp 2, 6 năm kinh nghiệm. Cam kết giúp học sinh thi vào 10 đạt điểm cao.',                          'accepted', '2026-04-20 08:00:00+00', '2026-04-22 10:00:00+00'),
('UTC1', 'YC003', 'GS003', '200000', 'IELTS 7.5, kinh nghiệm dạy giao tiếp. Phương pháp học tự nhiên.',                                               'accepted', '2026-05-08 14:00:00+00', '2026-05-09 16:00:00+00'),
('UTC2', 'YC003', 'GS007', '250000', 'Tốt nghiệp Sư phạm Anh, IELTS 8.0. Kinh nghiệm dạy giao tiếp.',                                                 'rejected', '2026-05-09 09:00:00+00', '2026-05-09 16:01:00+00'),
('UTD1', 'YC004', 'GS005', '190000', 'ĐH Bách Khoa, 4 năm dạy Lý. Có giáo án đầy đủ, bài tập phong phú.',                                              'accepted', '2026-05-05 10:00:00+00', '2026-05-06 15:00:00+00'),
('UTE1', 'YC005', 'GS005', '300000', 'Dạy Toán-Lý kết hợp cho học sinh lớp 12.',                                                                       'rejected', '2026-05-07 11:00:00+00', '2026-05-08 14:00:00+00'),
('UTF1', 'YC006', 'GS006', '180000', 'Thạc sĩ Hóa, 5 năm kinh nghiệm. Chuyên kèm học sinh mất gốc.',                                                  'pending',  '2026-05-19 09:00:00+00', NULL),
('UTF2', 'YC006', 'GS005', '160000', 'ĐH Bách Khoa, dạy được cả Lý và Hóa. Nhiệt tình, vui vẻ.',                                                     'pending',  '2026-05-20 10:00:00+00', NULL),
('UTF3', 'YC007', 'GS005', '280000', '4 năm kinh nghiệm dạy Lý, có bộ đề thi thử các năm.',                                                            'pending',  '2026-05-20 12:00:00+00', NULL),
('UTF4', 'YC007', 'GS001', '300000', 'Dạy Lý 12 với phương pháp tư duy logic, không học vẹt.',                                                         'pending',  '2026-05-21 08:00:00+00', NULL),
('UTF5', 'YC008', 'GS007', '150000', 'Sư phạm Anh, yêu trẻ em, có kinh nghiệm dạy tiểu học và THCS.',                                                 'pending',  '2026-05-21 10:00:00+00', NULL),
('UTF6', 'YC008', 'GS003', '140000', 'IELTS 7.5, phong cách dạy vui nhộn phù hợp với các bé.',                                                         'pending',  '2026-05-21 11:00:00+00', NULL);

-- 10.9: lop_hoc
INSERT INTO public.lop_hoc (ma_lop, ma_gia_su, ma_hoc_vien, ma_yeu_cau, ma_ung_tuyen, hoc_phi, dia_chi, hinh_thuc_day, ngay_bat_dau, ngay_ket_thuc, trang_thai, so_hv_toi_da, tong_so_buoi, ngay_tao) VALUES
('LH001', 'GS002', 'HV001', 'YC001', 'UT002', '220000', 'Quận 1, TP.HCM',        'offline', '2026-05-15', NULL,         'dang_hoc',      1, 32, '2026-05-21 02:55:58.599697+00'),
('LH002', 'GS004', 'HV002', 'YC002', 'UTB1',  '170000', 'Quận 3, TP.HCM',        'offline', '2026-04-25', '2026-06-20', 'da_hoan_thanh', 1, 24, '2026-05-21 02:55:58.599697+00'),
('LH003', 'GS003', 'HV003', 'YC003', 'UTC1',  '200000', 'Online',                 'online',  '2026-05-12', NULL,         'dang_hoc',      1, 20, '2026-05-21 02:55:58.599697+00'),
('LH004', 'GS005', 'HV004', 'YC004', 'UTD1',  '190000', 'Quận Gò Vấp, TP.HCM',   'offline', '2026-05-10', NULL,         'da_huy',        1, 20, '2026-05-21 02:55:58.599697+00'),
('LH005', 'GS001', 'HV005', 'YC005', 'UT003', '280000', 'Quận 5, TP.HCM',        'offline', '2026-05-12', NULL,         'dang_hoc',      1, 40, '2026-05-21 02:55:58.599697+00');

-- 10.10: dang_ky
INSERT INTO public.dang_ky (ma_dang_ky, ma_hoc_vien, ma_lop, ngay_dang_ky, trang_thai, ghi_chu) VALUES
('DK001', 'HV001', 'LH001', '2026-05-10 10:00:00+00', 'active',    NULL),
('DK002', 'HV002', 'LH002', '2026-04-22 11:00:00+00', 'completed', NULL),
('DK003', 'HV003', 'LH003', '2026-05-09 17:00:00+00', 'active',    NULL),
('DK004', 'HV004', 'LH004', '2026-05-06 16:00:00+00', 'cancelled', NULL),
('DK005', 'HV005', 'LH005', '2026-05-08 15:00:00+00', 'active',    NULL);

-- 10.11: lich_hoc
INSERT INTO public.lich_hoc (ma_lich, ma_lop, thu_trong_tuan, gio_bat_dau, gio_ket_thuc) VALUES
('LICHA1', 'LH001', 3, '18:00:00', '19:30:00'),
('LICHA2', 'LH001', 5, '18:00:00', '19:30:00'),
('LICHA3', 'LH001', 7, '08:00:00', '09:30:00'),
('LICHB1', 'LH002', 2, '17:00:00', '18:30:00'),
('LICHB2', 'LH002', 4, '17:00:00', '18:30:00'),
('LICHC1', 'LH003', 3, '19:00:00', '20:30:00'),
('LICHC2', 'LH003', 6, '19:00:00', '20:30:00'),
('LICHE1', 'LH005', 2, '17:30:00', '19:00:00'),
('LICHE2', 'LH005', 4, '17:30:00', '19:00:00'),
('LICHE3', 'LH005', 6, '17:30:00', '19:00:00');

-- 10.12: buoi_hoc
INSERT INTO public.buoi_hoc (ma_buoi_hoc, ma_lop, ma_lich, ngay_hoc, gio_bat_dau, gio_ket_thuc, trang_thai, ghi_chu) VALUES
('BHA1', 'LH001', NULL, '2026-05-16', '18:00:00', '19:30:00', 'da_hoc', 'Buổi 1: Ôn tập hàm số'),
('BHA2', 'LH001', NULL, '2026-05-18', '18:00:00', '19:30:00', 'da_hoc', 'Buổi 2: Đạo hàm'),
('BHA3', 'LH001', NULL, '2026-05-21', '08:00:00', '09:30:00', 'da_hoc', 'Buổi 3: Khảo sát hàm số'),
('BHA4', 'LH001', NULL, '2026-05-23', '18:00:00', '19:30:00', 'da_hoc', 'Buổi 4: Tích phân'),
('BHA5', 'LH001', NULL, '2026-05-25', '18:00:00', '19:30:00', 'da_hoc', 'Buổi 5: Số phức'),
('BHA6', 'LH001', NULL, '2026-05-28', '08:00:00', '09:30:00', 'da_hoc', 'Buổi 6: Hình không gian'),
('BHE1', 'LH005', NULL, '2026-05-13', '17:30:00', '19:00:00', 'da_hoc', 'Buổi 1: Ôn kiến thức nền'),
('BHE2', 'LH005', NULL, '2026-05-16', '17:30:00', '19:00:00', 'da_hoc', 'Buổi 2: Phương trình'),
('BHE3', 'LH005', NULL, '2026-05-19', '17:30:00', '19:00:00', 'da_hoc', 'Buổi 3: Hệ phương trình');

-- 10.13: danh_gia
INSERT INTO public.danh_gia (ma_danh_gia, ma_dang_ky, diem_sao, nhan_xet, ngay_danh_gia) VALUES
('DGA1', 'DK001', 5, 'Cô Hà dạy rất tận tâm, giảng dễ hiểu. Con tôi tiến bộ rõ rệt sau 1 tháng.',                              '2026-05-20 14:00:00+00'),
('DGB1', 'DK002', 5, 'Cô Ngọc là giáo viên tuyệt vời! Con tôi từ học sinh trung bình đã đạt 8.5 điểm Văn thi vào 10.',       '2026-05-30 10:00:00+00'),
('DGE1', 'DK005', 4, 'Thầy Tùng dạy nhiệt tình, kiến thức rộng. Con tôi bắt đầu tự tin hơn với môn Toán.',                  '2026-05-18 20:00:00+00');

-- 10.14: audit_log (reset sequence first)
SELECT setval('public.audit_log_id_seq', 6, true);

INSERT INTO public.audit_log (id, table_name, record_id, action, old_data, new_data, changed_by, changed_at) VALUES
(2, 'lop_hoc', 'LH001', 'INSERT', NULL, '{"ma_lop":"LH001","dia_chi":"Quận 1, TP.HCM","hoc_phi":220000,"ngay_tao":"2026-05-21T02:55:58.599697+00:00","ma_gia_su":"GS002","ma_yeu_cau":"YC001","trang_thai":"dang_hoc","ma_hoc_vien":"HV001","ma_ung_tuyen":"UT002","ngay_bat_dau":"2026-05-15","so_hv_toi_da":1,"tong_so_buoi":32,"hinh_thuc_day":"offline","ngay_ket_thuc":null}'::jsonb, NULL, '2026-05-21 02:55:58.599697+00'),
(3, 'lop_hoc', 'LH002', 'INSERT', NULL, '{"ma_lop":"LH002","dia_chi":"Quận 3, TP.HCM","hoc_phi":170000,"ngay_tao":"2026-05-21T02:55:58.599697+00:00","ma_gia_su":"GS004","ma_yeu_cau":"YC002","trang_thai":"da_hoan_thanh","ma_hoc_vien":"HV002","ma_ung_tuyen":"UTB1","ngay_bat_dau":"2026-04-25","so_hv_toi_da":1,"tong_so_buoi":24,"hinh_thuc_day":"offline","ngay_ket_thuc":"2026-06-20"}'::jsonb, NULL, '2026-05-21 02:55:58.599697+00'),
(4, 'lop_hoc', 'LH003', 'INSERT', NULL, '{"ma_lop":"LH003","dia_chi":"Online","hoc_phi":200000,"ngay_tao":"2026-05-21T02:55:58.599697+00:00","ma_gia_su":"GS003","ma_yeu_cau":"YC003","trang_thai":"dang_hoc","ma_hoc_vien":"HV003","ma_ung_tuyen":"UTC1","ngay_bat_dau":"2026-05-12","so_hv_toi_da":1,"tong_so_buoi":20,"hinh_thuc_day":"online","ngay_ket_thuc":null}'::jsonb, NULL, '2026-05-21 02:55:58.599697+00'),
(5, 'lop_hoc', 'LH004', 'INSERT', NULL, '{"ma_lop":"LH004","dia_chi":"Quận Gò Vấp, TP.HCM","hoc_phi":190000,"ngay_tao":"2026-05-21T02:55:58.599697+00:00","ma_gia_su":"GS005","ma_yeu_cau":"YC004","trang_thai":"da_huy","ma_hoc_vien":"HV004","ma_ung_tuyen":"UTD1","ngay_bat_dau":"2026-05-10","so_hv_toi_da":1,"tong_so_buoi":20,"hinh_thuc_day":"offline","ngay_ket_thuc":null}'::jsonb, NULL, '2026-05-21 02:55:58.599697+00'),
(6, 'lop_hoc', 'LH005', 'INSERT', NULL, '{"ma_lop":"LH005","dia_chi":"Quận 5, TP.HCM","hoc_phi":280000,"ngay_tao":"2026-05-21T02:55:58.599697+00:00","ma_gia_su":"GS001","ma_yeu_cau":"YC005","trang_thai":"dang_hoc","ma_hoc_vien":"HV005","ma_ung_tuyen":"UT003","ngay_bat_dau":"2026-05-12","so_hv_toi_da":1,"tong_so_buoi":40,"hinh_thuc_day":"offline","ngay_ket_thuc":null}'::jsonb, NULL, '2026-05-21 02:55:58.599697+00');

-- ============================================================================
-- KẾT THÚC FILE
-- ============================================================================
