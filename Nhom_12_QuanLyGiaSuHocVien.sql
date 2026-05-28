-- ==============================================================================
-- hệ thống quản lý gia sư - học viên (GiaSuBachKhoa)
-- ==============================================================================

use master;
go

if db_id('GiaSuBachKhoa') is not null
begin
    alter database GiaSuBachKhoa set single_user with rollback immediate;
    drop database GiaSuBachKhoa;
end
go

create database GiaSuBachKhoa;
go

use GiaSuBachKhoa;
go
set ansi_nulls on;
set quoted_identifier on;
go

-- ==============================================================================
-- phần 1: các bảng dữ liệu cốt lõi (entities)
-- ==============================================================================

-- bảng lưu thông tin học viên
create table hoc_vien (
    ma_hoc_vien     varchar(20)      primary key,
    ho_ten          nvarchar(100)    not null,
    ngay_sinh       date             null,
    gioi_tinh       nvarchar(10)     null,
    so_dien_thoai   varchar(15)      null,
    email           varchar(150)     null,
    dia_chi         nvarchar(500)    null,
    anh_dai_dien    nvarchar(500)    null,
    khoi_hien_tai   nvarchar(20)     null,
    auth_id         uniqueidentifier null,
    ngay_tao        datetime2(0)     not null default sysdatetime(),
    ngay_cap_nhat   datetime2(0)     not null default sysdatetime(),
    constraint ck_hoc_vien_gioi_tinh check (gioi_tinh is null or gioi_tinh in (N'Nam', N'Nữ', N'Nu', N'Khác', N'Khac'))
);

create table gia_su (
    ma_gia_su       varchar(20)      primary key,
    ho_ten          nvarchar(100)    not null,
    ngay_sinh       date             null,
    gioi_tinh       nvarchar(10)     null,
    so_dien_thoai   varchar(15)      null,
    email           varchar(150)     null,
    dia_chi         nvarchar(500)    null,
    anh_dai_dien    nvarchar(500)    null,
    trinh_do        nvarchar(200)    null,
    gioi_thieu      nvarchar(max)    null,
    trong_lich      bit              not null default 1,
    auth_id         uniqueidentifier null,
    ngay_tao        datetime2(0)     not null default sysdatetime(),
    ngay_cap_nhat   datetime2(0)     not null default sysdatetime(),
    constraint ck_gia_su_gioi_tinh check (gioi_tinh is null or gioi_tinh in (N'Nam', N'Nữ', N'Nu', N'Khác', N'Khac'))
);

create table mon_hoc (
    ma_mon          varchar(20)   primary key,
    ten_mon         nvarchar(100) not null,
    cap_hoc         nvarchar(50)  not null,
    mo_ta           nvarchar(max) null
);

-- bảng trung gian liên kết gia sư và môn học mà gia sư có thể dạy
create table gia_su_mon_hoc (
    ma_gia_su           varchar(20)   not null references gia_su(ma_gia_su) on delete cascade,
    ma_mon              varchar(20)   not null references mon_hoc(ma_mon) on delete cascade,
    nam_kinh_nghiem     int           not null default 0 check (nam_kinh_nghiem >= 0),
    muc_do_thanh_thao   nvarchar(20)  null,
    chung_chi           nvarchar(max) null,
    primary key (ma_gia_su, ma_mon)
);

-- phần 2: quản lý yêu cầu tìm gia sư và ứng tuyển
create table yeu_cau_lop (
    ma_yeu_cau              varchar(20)   primary key,
    ma_hoc_vien             varchar(20)   not null references hoc_vien(ma_hoc_vien),
    tieu_de                 nvarchar(200) not null,
    mo_ta                   nvarchar(max) null,
    tien_hoc_phi            decimal(12,0) not null check (tien_hoc_phi >= 0),
    dia_chi                 nvarchar(500) not null,
    hinh_thuc_hoc           varchar(20)   not null default 'offline',
    so_buoi_tuan            smallint      not null check (so_buoi_tuan between 1 and 7),
    thoi_gian_mong_muon     nvarchar(max) null,
    ngay_yeu_cau            datetime2(0)  not null default sysdatetime(),
    trang_thai              varchar(20)   not null default 'open',
    ma_gia_su_duoc_chon     varchar(20)   null references gia_su(ma_gia_su),
    ngay_chon_gia_su        datetime2(0)  null,
    ngay_cap_nhat           datetime2(0)  not null default sysdatetime(),
    constraint ck_yeu_cau_lop_hinh_thuc check (hinh_thuc_hoc in ('offline', 'online', 'hybrid')),
    constraint ck_yeu_cau_lop_trang_thai check (trang_thai in ('open', 'closed', 'approved', 'cancelled')),
    constraint ck_yeu_cau_lop_chon_gs check (
        (ma_gia_su_duoc_chon is null and ngay_chon_gia_su is null)
        or (ma_gia_su_duoc_chon is not null and ngay_chon_gia_su is not null)
    )
);

-- bảng lưu các môn học chi tiết trong một yêu cầu tìm gia sư
create table yeu_cau_mon (
    ma_yeu_cau      varchar(20)   not null references yeu_cau_lop(ma_yeu_cau) on delete cascade,
    ma_mon          varchar(20)   not null references mon_hoc(ma_mon),
    vai_tro_mon     nvarchar(20)  not null default N'chính',
    ghi_chu         nvarchar(max) null,
    primary key (ma_yeu_cau, ma_mon)
);

create table ung_tuyen (
    ma_ung_tuyen        varchar(30)   primary key,
    ma_yeu_cau          varchar(20)   not null references yeu_cau_lop(ma_yeu_cau) on delete cascade,
    ma_gia_su           varchar(20)   not null references gia_su(ma_gia_su),
    thu_nhap_mong_muon  decimal(12,0) null check (thu_nhap_mong_muon is null or thu_nhap_mong_muon >= 0),
    loi_nhan            nvarchar(max) null,
    trang_thai          varchar(20)   not null default 'pending',
    ngay_ung_tuyen      datetime2(0)  not null default sysdatetime(),
    ngay_xu_ly          datetime2(0)  null,
    constraint uq_ung_tuyen_yc_gs unique (ma_yeu_cau, ma_gia_su),
    constraint ck_ung_tuyen_trang_thai check (trang_thai in ('pending', 'accepted', 'rejected', 'withdrawn'))
);

-- phần 3: quản lý lớp học và lịch học

create table lop_hoc (
    ma_lop          varchar(20)   primary key,
    ma_gia_su       varchar(20)   not null references gia_su(ma_gia_su),
    ma_hoc_vien     varchar(20)   not null references hoc_vien(ma_hoc_vien),
    ma_yeu_cau      varchar(20)   null unique references yeu_cau_lop(ma_yeu_cau),
    ma_ung_tuyen    varchar(30)   null references ung_tuyen(ma_ung_tuyen),
    hoc_phi         decimal(12,0) not null check (hoc_phi >= 0),
    dia_chi         nvarchar(500) not null,
    hinh_thuc_day   varchar(20)   not null default 'offline',
    ngay_bat_dau    date          not null,
    ngay_ket_thuc   date          null,
    trang_thai      varchar(20)   not null default 'sapmo',
    tong_so_buoi    int           not null check (tong_so_buoi > 0),
    ngay_tao        datetime2(0)  not null default sysdatetime(),
    constraint ck_lop_hoc_ngay check (ngay_ket_thuc is null or ngay_ket_thuc >= ngay_bat_dau),
    constraint ck_lop_hoc_hinh_thuc check (hinh_thuc_day in ('offline', 'online', 'hybrid')),
    constraint ck_lop_hoc_trang_thai check (trang_thai in ('sapmo', 'dang_hoc', 'hoan_thanh', 'huy'))
);

-- bảng lưu thông tin các môn học được dạy trong lớp
create table lop_hoc_mon (
    ma_lop              varchar(20)   not null references lop_hoc(ma_lop) on delete cascade,
    ma_mon              varchar(20)   not null references mon_hoc(ma_mon),
    vai_tro_mon         nvarchar(20)  not null default N'chính',
    so_buoi_du_kien     int           null check (so_buoi_du_kien is null or so_buoi_du_kien >= 0),
    ghi_chu             nvarchar(max) null,
    primary key (ma_lop, ma_mon)
);
--- lớp hc có nhiều lịch dạy
create table lich_hoc (
    ma_lich             varchar(20)   primary key,
    ma_lop              varchar(20)   not null references lop_hoc(ma_lop) on delete cascade,
    thu_trong_tuan      smallint      not null check (thu_trong_tuan between 1 and 7),
    gio_bat_dau         time          not null,
    gio_ket_thuc        time          not null,
    constraint ck_lich_hoc_gio check (gio_ket_thuc > gio_bat_dau),
    constraint uq_lich_hoc_lop_lich unique (ma_lop, ma_lich)
);

create table buoi_hoc (
    ma_buoi_hoc     varchar(20)   primary key,
    ma_lop          varchar(20)   not null references lop_hoc(ma_lop) on delete cascade,
    ma_lich         varchar(20)   null,
    ngay_hoc        date          not null,
    gio_bat_dau     time          not null,
    gio_ket_thuc    time          not null,
    trang_thai      varchar(20)   not null default 'scheduled',
    ghi_chu         nvarchar(max) null,
    constraint ck_buoi_hoc_gio check (gio_ket_thuc > gio_bat_dau),
    constraint ck_buoi_hoc_trang_thai check (trang_thai in ('scheduled', 'completed', 'cancelled', 'rescheduled'))
);

alter table buoi_hoc
    add constraint fk_buoi_hoc_lich
    foreign key (ma_lich) references lich_hoc(ma_lich)
    on delete set null;
go

-- phần 4: đăng ký, điểm danh, đánh giá, thanh toán

-- bảng lưu trạng thái đăng ký vào lớp của học viên
create table dang_ky (
    ma_dang_ky      varchar(20)   primary key,
    ma_hoc_vien     varchar(20)   not null references hoc_vien(ma_hoc_vien),
    ma_lop          varchar(20)   not null unique references lop_hoc(ma_lop),
    ngay_dang_ky    datetime2(0)  not null default sysdatetime(),
    trang_thai      varchar(20)   not null default 'pending',
    ghi_chu         nvarchar(max) null,
    constraint ck_dang_ky_trang_thai check (trang_thai in ('pending', 'confirmed', 'cancelled', 'completed'))
);

create table tai_khoan_hv (
    ma_tk_hv            varchar(20)   primary key,
    ma_hoc_vien         varchar(20)   not null references hoc_vien(ma_hoc_vien) on delete cascade,
    so_tai_khoan        varchar(30)   not null,
    nha_cung_cap        nvarchar(100) not null,
    loai_phuong_thuc    varchar(30)   not null default 'bank',
    ten_chu_tk          nvarchar(100) not null,
    la_mac_dinh         bit           not null default 0,
    constraint uq_tk_hv unique (ma_hoc_vien, so_tai_khoan, nha_cung_cap),
    constraint ck_tk_hv_loai check (loai_phuong_thuc in ('bank', 'ewallet', 'cash'))
);

-- bảng lưu thông tin tài khoản ngân hàng của gia sư để nhận tiền
create table tai_khoan_gs (
    ma_tk_gs            varchar(20)   primary key,
    ma_gia_su           varchar(20)   not null references gia_su(ma_gia_su) on delete cascade,
    so_tai_khoan        varchar(30)   not null,
    nha_cung_cap        nvarchar(100) not null,
    loai_phuong_thuc    varchar(30)   not null default 'bank',
    ten_chu_tk          nvarchar(100) not null,
    la_mac_dinh         bit           not null default 0,
    constraint uq_tk_gs unique (ma_gia_su, so_tai_khoan, nha_cung_cap),
    constraint ck_tk_gs_loai check (loai_phuong_thuc in ('bank', 'ewallet', 'cash'))
);

-- bảng lưu lịch sử giao dịch thanh toán tiền học, hoa hồng
create table giao_dich (
    ma_giao_dich            varchar(30)   primary key,
    ma_dang_ky              varchar(20)   not null references dang_ky(ma_dang_ky),
    ma_tk_hv                varchar(20)   not null references tai_khoan_hv(ma_tk_hv),
    ma_tk_gs                varchar(20)   not null references tai_khoan_gs(ma_tk_gs),
    tong_tien_thu           decimal(15,0) not null check (tong_tien_thu > 0),
    ty_le_hoa_hong          decimal(5,2)  not null check (ty_le_hoa_hong between 0 and 100),
    phi_hoa_hong            decimal(15,0) not null check (phi_hoa_hong >= 0),
    so_tien_gia_su_nhan     decimal(15,0) not null check (so_tien_gia_su_nhan >= 0),
    ngay_thanh_toan         datetime2(0)  not null default sysdatetime(),
    ngay_doi_soat           datetime2(0)  null,
    trang_thai              varchar(20)   not null default 'success',
    loai_giao_dich          varchar(30)   not null default 'thanhtoanthang',
    ma_tham_chieu           varchar(100)  null unique,
    constraint ck_giao_dich_toan_ven check (phi_hoa_hong + so_tien_gia_su_nhan = tong_tien_thu),
    constraint ck_giao_dich_ngay check (ngay_doi_soat is null or ngay_doi_soat >= ngay_thanh_toan),
    constraint ck_giao_dich_trang_thai check (trang_thai in ('pending', 'success', 'failed', 'refunded')),
    constraint ck_giao_dich_loai check (loai_giao_dich in ('thanhtoanthang', 'thanhtoanbuoi', 'hoantra', 'phidangky'))
);

--- dánh giá của hv dành cho gs
create table danh_gia (
    ma_danh_gia     varchar(20)   primary key,
    ma_dang_ky      varchar(20)   not null unique references dang_ky(ma_dang_ky),
    diem_sao        smallint      not null check (diem_sao between 1 and 5),
    nhan_xet        nvarchar(max) null,
    ngay_danh_gia   datetime2(0)  not null default sysdatetime()
);

--- điểm danh từng buổi
create table diem_danh (
    ma_buoi_hoc     varchar(20)   not null references buoi_hoc(ma_buoi_hoc) on delete cascade,
    ma_dang_ky      varchar(20)   not null references dang_ky(ma_dang_ky),
    trang_thai      varchar(20)   not null default 'comat',
    so_phut_hoc     int           null check (so_phut_hoc is null or so_phut_hoc >= 0),
    ghi_chu         nvarchar(max) null,
    primary key (ma_buoi_hoc, ma_dang_ky),
    constraint ck_diem_danh_trang_thai check (trang_thai in ('comat', 'vangmat', 'tre', 'phep'))
);

-- phần 5: thông báo và theo dõi hệ thống
-- ==============================================================================

-- bảng lưu thông báo gửi đến học viên hoặc gia sư 
create table thong_bao (
    ma_thong_bao    varchar(30)   primary key,
    ma_hoc_vien     varchar(20)   null references hoc_vien(ma_hoc_vien) on delete cascade,
    ma_gia_su       varchar(20)   null references gia_su(ma_gia_su) on delete cascade,
    loai_thong_bao  varchar(30)   not null,
    tieu_de         nvarchar(200) not null,
    noi_dung        nvarchar(max) not null,
    da_doc          bit           not null default 0,
    ngay_tao        datetime2(0)  not null default sysdatetime(),
    ma_yeu_cau      varchar(20)   null,
    ma_lop          varchar(20)   null,
    ma_giao_dich    varchar(30)   null,
    ma_buoi_hoc     varchar(20)   null,
    constraint ck_thong_bao_nguoi_nhan check (
        (case when ma_hoc_vien is null then 0 else 1 end) +
        (case when ma_gia_su is null then 0 else 1 end) = 1
    )
);
---lưu lại ls thay đổi data
create table audit_log (
    id              bigint        identity(1,1) primary key,
    table_name      varchar(50)   not null,
    record_id       varchar(30)   not null,
    action          varchar(10)   not null,
    old_data        nvarchar(max) null,
    new_data        nvarchar(max) null,
    changed_by      varchar(100)  null,
    changed_at      datetime2(0)  not null default sysdatetime(),
    constraint ck_audit_log_action check (action in ('insert', 'update', 'delete'))
);

-- bảng lưu ls dạy của gs
create table lich_su_day_hoc (
    ma_lich_su_day  varchar(30)   primary key,
    ma_gia_su       varchar(20)   not null references gia_su(ma_gia_su) on delete cascade,
    ma_lop          varchar(20)   not null,                 
    ten_hoc_vien    nvarchar(100) null,                     
    ten_mon_hoc     nvarchar(200) null,
    ngay_bat_dau    date          null,
    ngay_ket_thuc   date          null,
    tong_so_buoi    int           not null default 0,
    tong_thu_nhap   decimal(15,0) not null default 0,
    danh_gia_tb     decimal(3,2)  null,
    trang_thai_lop  varchar(30)   not null,
    ngay_ghi_nhan   datetime2(0)  not null default sysdatetime()
);

-- bảng lưu lịch sử đăng ký thuê gia sư của học viên
create table lich_su_thue_gia_su (
    ma_lich_su_thue varchar(30)   primary key,
    ma_hoc_vien     varchar(20)   not null references hoc_vien(ma_hoc_vien) on delete cascade,
    ma_gia_su       varchar(20)   null,                      -- intentionally no FK (archive)
    ten_gia_su      nvarchar(100) null,                      -- snapshot tên gia sư
    ma_yeu_cau      varchar(20)   not null,                  -- intentionally no FK (archive)
    ma_lop          varchar(20)   null,                      -- intentionally no FK (archive)
    ten_mon_hoc     nvarchar(200) null,
    ngay_bat_dau    date          null,
    ngay_ket_thuc   date          null,
    tong_chi_phi    decimal(15,0) not null default 0,
    trang_thai      varchar(30)   not null,
    ngay_ghi_nhan   datetime2(0)  not null default sysdatetime()
);
go

---chỉ mục (indexe)

create unique index ux_hoc_vien_auth  on hoc_vien(auth_id)       where auth_id is not null;
create unique index ux_hoc_vien_sdt   on hoc_vien(so_dien_thoai) where so_dien_thoai is not null;
create unique index ux_hoc_vien_email on hoc_vien(email)         where email is not null;

create unique index ux_gia_su_auth  on gia_su(auth_id)       where auth_id is not null;
create unique index ux_gia_su_sdt   on gia_su(so_dien_thoai) where so_dien_thoai is not null;
create unique index ux_gia_su_email on gia_su(email)         where email is not null;

create index ix_gia_su_trong_lich on gia_su(trong_lich) where trong_lich = 1;
create index ix_gia_su_mon_hoc_mon on gia_su_mon_hoc(ma_mon);

create index ix_yeu_cau_hoc_vien   on yeu_cau_lop(ma_hoc_vien, trang_thai);
create index ix_yeu_cau_trang_thai on yeu_cau_lop(trang_thai, ngay_yeu_cau desc);

create index ix_ung_tuyen_yeu_cau on ung_tuyen(ma_yeu_cau, trang_thai);
create index ix_ung_tuyen_gia_su  on ung_tuyen(ma_gia_su, trang_thai);

create index ix_lop_hoc_gia_su   on lop_hoc(ma_gia_su, trang_thai);
create index ix_lop_hoc_hoc_vien on lop_hoc(ma_hoc_vien, trang_thai);

create unique index ux_lich_hoc_lop_thu_gio on lich_hoc(ma_lop, thu_trong_tuan, gio_bat_dau);

create index ix_buoi_hoc_lop_ngay on buoi_hoc(ma_lop, ngay_hoc);

create index ix_buoi_hoc_ma_lich on buoi_hoc(ma_lich) where ma_lich is not null;

create index ix_buoi_hoc_ngay_hoc on buoi_hoc(ngay_hoc, trang_thai) where trang_thai != 'cancelled';

create index ix_dang_ky_lop       on dang_ky(ma_lop, trang_thai);
create index ix_giao_dich_dang_ky on giao_dich(ma_dang_ky, ngay_thanh_toan desc);

create index ix_thong_bao_hv on thong_bao(ma_hoc_vien, da_doc, ngay_tao desc) where ma_hoc_vien is not null;
create index ix_thong_bao_gs on thong_bao(ma_gia_su, da_doc, ngay_tao desc)   where ma_gia_su   is not null;

create index ix_diem_danh_dang_ky on diem_danh(ma_dang_ky, ma_buoi_hoc);

create unique index ux_tk_hv_mac_dinh on tai_khoan_hv(ma_hoc_vien) where la_mac_dinh = 1;
create unique index ux_tk_gs_mac_dinh on tai_khoan_gs(ma_gia_su)   where la_mac_dinh = 1;

-- [FIX Bug 4] Đảm bảo 1 ung_tuyen chỉ tạo được đúng 1 lop_hoc (filtered: bỏ qua NULL)
create unique index ux_lop_hoc_ung_tuyen on lop_hoc(ma_ung_tuyen) where ma_ung_tuyen is not null;

create index ix_audit_log_table_record on audit_log(table_name, record_id, changed_at desc);
go

-- phần 7: hàm (functions)
create or alter function fn_tinh_diem_tb_gia_su(@p_ma_gia_su varchar(20))
returns decimal(3,2) as
begin
    declare @v_diem decimal(3,2);
    select @v_diem = cast(avg(cast(dg.diem_sao as decimal(5,2))) as decimal(3,2))
    from danh_gia dg
    join dang_ky dk on dg.ma_dang_ky = dk.ma_dang_ky
    join lop_hoc lh on dk.ma_lop     = lh.ma_lop
    where lh.ma_gia_su = @p_ma_gia_su;

    return isnull(@v_diem, 0);
end;
go

-- xem gia sư có bị trùng lịch hay ko
-- vis dụ gia sư tâm có đang dạy thứ 2, 18:00-19:30 lớp nào khác không?,nhận lớp / tạo lịch cố định trong lớp

create or alter function fn_kiem_tra_trung_lich_lichhoc(
    @p_ma_gia_su       varchar(20),
    @p_thu             smallint,
    @p_gio_bat_dau     time,
    @p_gio_ket_thuc    time,
    @p_ma_lich_exclude varchar(20) = null
)
returns bit as
begin
    declare @v_trung bit = 0;
    if exists (
        select 1
        from lich_hoc lh
        join lop_hoc l on lh.ma_lop = l.ma_lop
        where l.ma_gia_su        = @p_ma_gia_su
          and lh.thu_trong_tuan  = @p_thu
          and l.trang_thai       in ('sapmo', 'dang_hoc')
          and (@p_ma_lich_exclude is null or lh.ma_lich != @p_ma_lich_exclude)
          and @p_gio_bat_dau < lh.gio_ket_thuc
          and @p_gio_ket_thuc > lh.gio_bat_dau
    )
        set @v_trung = 1;
    return @v_trung;
end;
go
-- check buổi hc cụ thể theo ngày có bị trùng ko
create or alter function fn_kiem_tra_trung_buoihoc(
    @p_ma_gia_su       varchar(20),
    @p_ngay_hoc        date,
    @p_gio_bat_dau     time,
    @p_gio_ket_thuc    time,
    @p_ma_buoi_exclude varchar(20) = null
)
returns bit as
begin
    declare @v_trung bit = 0;
    if exists (
        select 1
        from buoi_hoc bh
        join lop_hoc l on bh.ma_lop = l.ma_lop
        where l.ma_gia_su   = @p_ma_gia_su
          and bh.ngay_hoc   = @p_ngay_hoc
          and l.trang_thai  in ('sapmo', 'dang_hoc')
          and bh.trang_thai != 'cancelled'
          and (@p_ma_buoi_exclude is null or bh.ma_buoi_hoc != @p_ma_buoi_exclude)
          and @p_gio_bat_dau < bh.gio_ket_thuc
          and @p_gio_ket_thuc > bh.gio_bat_dau
    )
        set @v_trung = 1;
    return @v_trung;
end;
go

-- count số lớp gs đang dạy
create or alter function fn_dem_lop_dang_day(@p_ma_gia_su varchar(20))
returns int as
begin
    declare @v_so_lop int;
    select @v_so_lop = count(*)
    from lop_hoc
    where ma_gia_su = @p_ma_gia_su and trang_thai in ('sapmo', 'dang_hoc');
    return isnull(@v_so_lop, 0);
end;
go

-- hàm tính tổng doanh thu của gia sư trong tháng
create or alter function fn_doanh_thu_gia_su(
    @p_ma_gia_su varchar(20),
    @p_thang     int,
    @p_nam       int
)
returns decimal(15,0) as
begin
    declare @v_tong decimal(15,0);
    select @v_tong = isnull(sum(gd.so_tien_gia_su_nhan), 0)
    from giao_dich gd
    join tai_khoan_gs tk on gd.ma_tk_gs = tk.ma_tk_gs
    where tk.ma_gia_su = @p_ma_gia_su
      and month(gd.ngay_thanh_toan) = @p_thang
      and year(gd.ngay_thanh_toan)  = @p_nam
      and gd.trang_thai = 'success';
    return isnull(@v_tong, 0);
end;
go

-- check hv có hợp lệ hay k dựa trên thanh toán ( đã thanh toán hc phí hay chưa)
create or alter function fn_hoc_vien_hop_le(@p_ma_hoc_vien varchar(20))
returns bit as
begin
    if exists (
        select 1
        from giao_dich gd
        join dang_ky dk on gd.ma_dang_ky = dk.ma_dang_ky
        where dk.ma_hoc_vien      = @p_ma_hoc_vien and gd.trang_thai  = 'failed' 
        and gd.ngay_thanh_toan >= dateadd(day, -30, sysdatetime())
        -- sau khi gd lỗi, có gd khác thành công hay ko, nếu có thì hc viên hợp lệ
          and not exists (
              select 1 from giao_dich gd2
              where gd2.ma_dang_ky      = gd.ma_dang_ky
                and gd2.trang_thai      = 'success'
                and gd2.ngay_thanh_toan > gd.ngay_thanh_toan
          )
    )return 0;
        
    return 1;
end;
go

-- hàm định dạng giờ học (vd: 07:00 - 09:00)
create or alter function fn_format_gio_hoc(@p_gio_bd time, @p_gio_kt time)
returns varchar(50) as
begin
    return convert(varchar(5), @p_gio_bd, 108) + ' - ' + convert(varchar(5), @p_gio_kt, 108);
end;
go

--lấy danh sách khung giờ đã có lịch của gia sư trong một thứ cụ thể
create or alter function fn_khung_gio_dang_co(@p_ma_gia_su varchar(20), @p_thu smallint)
returns table as
return (
    select lh.gio_bat_dau, lh.gio_ket_thuc, lh.ma_lop, lh.ma_lich
    from lich_hoc lh
    join lop_hoc l on lh.ma_lop = l.ma_lop
    where l.ma_gia_su       = @p_ma_gia_su
      and lh.thu_trong_tuan = @p_thu
      and l.trang_thai      in ('sapmo', 'dang_hoc')
);
go

---- TRIGGER   

-- trigger tự động cập nhật ngay_cap_nhat khi sửa học viên
create or alter trigger tr_hoc_vien_updated_at on hoc_vien after update as
begin
    if trigger_nestlevel(@@procid) > 1 return; -- cái trigger_nestlevel này để xem coi trigger có đang gọi trigger kahcs ko, tránh bị vòng lặp vô hạn
    if not exists (select 1 from inserted) return;
    update hv set ngay_cap_nhat = sysdatetime()
    from hoc_vien hv
    join inserted i on hv.ma_hoc_vien = i.ma_hoc_vien;
end;
go

create or alter trigger tr_gia_su_updated_at on gia_su after update as
begin
    if trigger_nestlevel(@@procid) > 1 return;
    if not exists (select 1 from inserted) return;
    update gs set ngay_cap_nhat = sysdatetime()
    from gia_su gs
    join inserted i on gs.ma_gia_su = i.ma_gia_su;
end;
go

create or alter trigger tr_yeu_cau_lop_updated_at on yeu_cau_lop after update as
begin
    if trigger_nestlevel(@@procid) > 1 return;
    if not exists (select 1 from inserted) return;
    update yc set ngay_cap_nhat = sysdatetime()
    from yeu_cau_lop yc
    join inserted i on yc.ma_yeu_cau = i.ma_yeu_cau;
end;
go

-- trigger kiểm tra tính hợp lệ khi điểm danh: buổi học và đăng ký phải cùng lớp
create or alter trigger tr_diem_danh_validate on diem_danh after insert, update as
begin
    if exists (
        select 1
        from inserted i
        join buoi_hoc bh on i.ma_buoi_hoc = bh.ma_buoi_hoc
        join dang_ky  dk on i.ma_dang_ky  = dk.ma_dang_ky
        where bh.ma_lop != dk.ma_lop
    )
        throw 50001, 'diem_danh: buổi học và đăng ký không cùng lớp học.', 1;
end;
go

-- trigger kiểm tra giao dịch kiểm tra tài khoản chính chủ
create or alter trigger tr_giao_dich_validate on giao_dich after insert, update as
begin
    if exists (
        select 1
        from inserted i
        join dang_ky      dk   on i.ma_dang_ky = dk.ma_dang_ky
        join lop_hoc      lh   on dk.ma_lop    = lh.ma_lop
        join tai_khoan_hv tkhv on i.ma_tk_hv   = tkhv.ma_tk_hv
        join tai_khoan_gs tkgs on i.ma_tk_gs   = tkgs.ma_tk_gs
        where tkhv.ma_hoc_vien != dk.ma_hoc_vien
           or tkgs.ma_gia_su   != lh.ma_gia_su
    )
        throw 50002, 'giao_dich: tài khoản không khớp với chủ đăng ký hoặc gia sư.', 1;
end;
go

-- trigger ngăn chặn xếp lịch học định kỳ bị trùng giờ của gia sư.
create or alter trigger tr_lich_hoc_check_trung on lich_hoc after insert, update as
begin
    if exists (
        select 1
        from inserted i
        join lop_hoc l on i.ma_lop = l.ma_lop
        join lich_hoc lh2 on lh2.ma_lich != i.ma_lich
        join lop_hoc l2 on lh2.ma_lop = l2.ma_lop
        where l2.ma_gia_su      = l.ma_gia_su
          and lh2.thu_trong_tuan = i.thu_trong_tuan
          and l2.trang_thai      in ('sapmo', 'dang_hoc')
          and i.gio_bat_dau  < lh2.gio_ket_thuc
          and i.gio_ket_thuc > lh2.gio_bat_dau
    )
        throw 50003, 'lich_hoc: gia sư đã có lịch trùng.', 1;
end;
go

-- khi tạo 1 buổi học, check xem cái buổi đấy có bị trùng với lịch của gs hay ko
create or alter trigger tr_buoi_hoc_check_trung on buoi_hoc after insert, update as
begin
    if exists (
        select 1
        from inserted i
        join lop_hoc l on i.ma_lop = l.ma_lop
        join buoi_hoc bh2 on bh2.ma_buoi_hoc != i.ma_buoi_hoc and bh2.ngay_hoc = i.ngay_hoc
        join lop_hoc l2 on bh2.ma_lop = l2.ma_lop
        where l2.ma_gia_su   = l.ma_gia_su
          and l2.trang_thai  in ('sapmo', 'dang_hoc')
          and bh2.trang_thai != 'cancelled'
          and i.trang_thai   != 'cancelled'
          and i.gio_bat_dau  < bh2.gio_ket_thuc
          and i.gio_ket_thuc > bh2.gio_bat_dau
    )
        throw 50004, 'buoi_hoc: gia sư đã có lịch trùng.', 1;
end;
go

-- trigger tự động gửi thông báo cho học viên khi có gia sư ứng tuyển
create or alter trigger tr_ung_tuyen_notify on ung_tuyen after insert as
begin
    insert into thong_bao (ma_thong_bao, ma_hoc_vien, loai_thong_bao, tieu_de, noi_dung, ma_yeu_cau)
    select
        'TB_' + replace(cast(newid() as varchar(36)), '-', ''),
        yc.ma_hoc_vien,
        'ung_tuyen',
        N'Gia sư ' + gs.ho_ten + N' đã ứng tuyển vào yêu cầu ' + i.ma_yeu_cau,
        N'Gia sư ' + gs.ho_ten + N' đã ứng tuyển. Xem chi tiết và phản hồi trong mục "Yêu cầu của tôi".',
        i.ma_yeu_cau
    from inserted i
    join yeu_cau_lop yc on i.ma_yeu_cau = yc.ma_yeu_cau
    join gia_su gs      on i.ma_gia_su  = gs.ma_gia_su;
end;
go

-- trigger xử lý khi học viên chọn gia sư: gửi thông báo, từ chối các gia sư khác
create or alter trigger tr_yeu_cau_chon_gia_su on yeu_cau_lop after update as
begin
    -- chỉ chạy khi có dòng được set ma_gia_su_duoc_chon từ null sang non-null
    if not exists (
        select 1 from inserted i
        join deleted d on i.ma_yeu_cau = d.ma_yeu_cau
        where d.ma_gia_su_duoc_chon is null and i.ma_gia_su_duoc_chon is not null
    ) return;

    -- thông báo cho gia sư được chọn
    insert into thong_bao (ma_thong_bao, ma_gia_su, loai_thong_bao, tieu_de, noi_dung, ma_yeu_cau)
    select
        'TB_' + replace(cast(newid() as varchar(36)), '-', ''),
        i.ma_gia_su_duoc_chon,
        'duoc_chon',
        N'Bạn đã được chọn cho yêu cầu ' + i.ma_yeu_cau,
        N'Học viên ' + hv.ho_ten + N' đã chọn bạn. Lớp học sẽ sớm được tạo.',
        i.ma_yeu_cau
    from inserted i
    join deleted d  on i.ma_yeu_cau  = d.ma_yeu_cau
    join hoc_vien hv on i.ma_hoc_vien = hv.ma_hoc_vien
    where d.ma_gia_su_duoc_chon is null and i.ma_gia_su_duoc_chon is not null;

    -- thông báo cho các gia sư bị từ chối
    insert into thong_bao (ma_thong_bao, ma_gia_su, loai_thong_bao, tieu_de, noi_dung, ma_yeu_cau)
    select
        'TB_' + replace(cast(newid() as varchar(36)), '-', ''),
        ut.ma_gia_su,
        'tu_choi',
        N'Yêu cầu ' + i.ma_yeu_cau + N' đã có gia sư được chọn',
        N'Học viên ' + hv.ho_ten + N' đã chọn gia sư khác cho yêu cầu này.',
        i.ma_yeu_cau
    from inserted i
    join deleted   d   on i.ma_yeu_cau  = d.ma_yeu_cau
    join hoc_vien  hv  on i.ma_hoc_vien = hv.ma_hoc_vien
    join ung_tuyen ut  on ut.ma_yeu_cau = i.ma_yeu_cau
    where d.ma_gia_su_duoc_chon is null
      and i.ma_gia_su_duoc_chon is not null
      and ut.ma_gia_su   != i.ma_gia_su_duoc_chon
      and ut.trang_thai  = 'pending';

    -- cập nhật trạng thái ung_tuyen: rejected cho các gia sư khác
    update ut
    set trang_thai = 'rejected', ngay_xu_ly = sysdatetime()
    from ung_tuyen ut
    join inserted i on ut.ma_yeu_cau = i.ma_yeu_cau
    join deleted  d on i.ma_yeu_cau  = d.ma_yeu_cau
    where d.ma_gia_su_duoc_chon is null
      and i.ma_gia_su_duoc_chon is not null
      and ut.ma_gia_su   != i.ma_gia_su_duoc_chon
      and ut.trang_thai  = 'pending';

    -- accepted cho gia sư được chọn
    update ut
    set trang_thai = 'accepted', ngay_xu_ly = sysdatetime()
    from ung_tuyen ut
    join inserted i on ut.ma_yeu_cau = i.ma_yeu_cau
    join deleted  d on i.ma_yeu_cau  = d.ma_yeu_cau
    where d.ma_gia_su_duoc_chon is null
      and i.ma_gia_su_duoc_chon is not null
      and ut.ma_gia_su = i.ma_gia_su_duoc_chon;
end;
go

-- trigger ghi audit_log cho yeu_cau_lop khi đổi trạng thái
create or alter trigger tr_yeu_cau_lop_audit on yeu_cau_lop after update as
begin
    if not update(trang_thai) return;
    insert into audit_log (table_name, record_id, action, old_data, new_data)
    select 'yeu_cau_lop', i.ma_yeu_cau, 'update',
           N'trang_thai=' + d.trang_thai,
           N'trang_thai=' + i.trang_thai
    from inserted i
    join deleted  d on i.ma_yeu_cau = d.ma_yeu_cau
    where isnull(i.trang_thai, '') != isnull(d.trang_thai, '');
end;
go

-- trigger ghi audit_log cho lop_hoc khi đổi trạng thái
create or alter trigger tr_lop_hoc_audit on lop_hoc after update as
begin
    if not update(trang_thai) return;
    insert into audit_log (table_name, record_id, action, old_data, new_data)
    select 'lop_hoc', i.ma_lop, 'update',
           N'trang_thai=' + d.trang_thai,
           N'trang_thai=' + i.trang_thai
    from inserted i
    join deleted  d on i.ma_lop = d.ma_lop
    where isnull(i.trang_thai, '') != isnull(d.trang_thai, '');
end;
go

-- phần 9: khung nhìn (views)
-- ==============================================================================

-- view tổng hợp thông tin, điểm đánh giá và số lớp của gia sư
create or alter view vw_gia_su_tong_hop as
select
    gs.ma_gia_su,
    gs.ho_ten,
    gs.gioi_tinh,
    gs.anh_dai_dien,
    gs.trinh_do,
    gs.trong_lich,
    gs.gioi_thieu,
    isnull(dbo.fn_tinh_diem_tb_gia_su(gs.ma_gia_su), 0) as diem_danh_gia_tb,
    isnull(dbo.fn_dem_lop_dang_day(gs.ma_gia_su),    0) as so_lop_dang_day,
    isnull((
        select count(*) from ung_tuyen ut
        where ut.ma_gia_su = gs.ma_gia_su and ut.trang_thai = 'accepted'
    ), 0) as so_lop_da_nhan
from gia_su gs;
go

-- view hiển thị chi tiết các đánh giá kèm thông tin học viên, gia sư
create or alter view vw_danh_gia_chi_tiet as
select
    dg.ma_danh_gia,
    dg.diem_sao,
    dg.nhan_xet,
    dg.ngay_danh_gia,
    dk.ma_dang_ky,
    dk.ma_hoc_vien,
    hv.ho_ten as ten_hoc_vien,
    dk.ma_lop,
    lh.ma_gia_su,
    gs.ho_ten as ten_gia_su
from danh_gia dg
join dang_ky  dk on dg.ma_dang_ky = dk.ma_dang_ky
join hoc_vien hv on dk.ma_hoc_vien = hv.ma_hoc_vien
join lop_hoc  lh on dk.ma_lop      = lh.ma_lop
join gia_su   gs on lh.ma_gia_su   = gs.ma_gia_su;
go

-- view hiển thị chi tiết lịch sử giao dịch thanh toán
create or alter view vw_giao_dich_chi_tiet as
select
    gd.ma_giao_dich,
    gd.tong_tien_thu,
    gd.ty_le_hoa_hong,
    gd.phi_hoa_hong,
    gd.so_tien_gia_su_nhan,
    gd.ngay_thanh_toan,
    gd.trang_thai,
    gd.loai_giao_dich,
    dk.ma_hoc_vien,
    hv.ho_ten as ten_hoc_vien,
    dk.ma_lop,
    lh.ma_gia_su,
    gs.ho_ten as ten_gia_su
from giao_dich gd
join dang_ky  dk on gd.ma_dang_ky = dk.ma_dang_ky
join hoc_vien hv on dk.ma_hoc_vien = hv.ma_hoc_vien
join lop_hoc  lh on dk.ma_lop      = lh.ma_lop
join gia_su   gs on lh.ma_gia_su   = gs.ma_gia_su;
go

-- view tổng hợp chi tiết lớp học
create or alter view vw_lop_hoc_chi_tiet as
select
    l.ma_lop,
    l.hoc_phi,
    l.hinh_thuc_day,
    l.dia_chi,
    l.trang_thai,
    l.tong_so_buoi,
    l.ngay_bat_dau,
    l.ngay_ket_thuc,
    gs.ma_gia_su,
    gs.ho_ten as ten_gia_su,
    hv.ma_hoc_vien,
    hv.ho_ten as ten_hoc_vien,
    l.ma_yeu_cau,
    (select count(*) from lich_hoc lh where lh.ma_lop = l.ma_lop) as so_lich_hoc,
    (select count(*) from buoi_hoc bh where bh.ma_lop = l.ma_lop) as so_buoi_da_hoc
from lop_hoc l join gia_su   gs on l.ma_gia_su   = gs.ma_gia_su
join hoc_vien hv on l.ma_hoc_vien = hv.ma_hoc_vien;
go

-- view hiển thị lịch trình giảng dạy định kỳ của các gia sư
create or alter view vw_lich_trinh_gia_su as
select
    gs.ma_gia_su,
    gs.ho_ten as ten_gia_su,
    l.ma_lop,
    l.trang_thai as trang_thai_lop,
    lh.thu_trong_tuan,
    lh.gio_bat_dau,
    lh.gio_ket_thuc,
    dbo.fn_format_gio_hoc(lh.gio_bat_dau, lh.gio_ket_thuc) as khoang_thoi_gian
from lich_hoc lh
join lop_hoc  l  on lh.ma_lop    = l.ma_lop
join gia_su   gs on l.ma_gia_su  = gs.ma_gia_su
where l.trang_thai in ('sapmo', 'dang_hoc');
go

-- view thống kê doanh thu, lợi nhuận, chi trả theo từng tháng
create or alter view vw_thong_ke_doanh_thu as
select
    year(ngay_thanh_toan)  as nam,
    month(ngay_thanh_toan) as thang,
    trang_thai,
    count(*)  as so_luong_giao_dich,
    sum(tong_tien_thu)  as tong_doanh_thu,
    sum(phi_hoa_hong)           as tong_loi_nhuan,
    sum(so_tien_gia_su_nhan)    as tong_chi_tra_gia_su
from giao_dich
group by year(ngay_thanh_toan), month(ngay_thanh_toan), trang_thai;
go

-- view danh sách các yêu cầu tìm gia sư đang mở
create or alter view vw_yeu_cau_dang_mo as
select
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
    hv.ho_ten as ten_hoc_vien,
    hv.khoi_hien_tai,
    (select count(*) from ung_tuyen ut where ut.ma_yeu_cau = yc.ma_yeu_cau) as so_luong_ung_tuyen,
    (select string_agg(mh.ten_mon, ', ')
       from yeu_cau_mon ycm
       join mon_hoc mh on ycm.ma_mon = mh.ma_mon
      where ycm.ma_yeu_cau = yc.ma_yeu_cau) as cac_mon_hoc
from yeu_cau_lop yc
join hoc_vien hv on yc.ma_hoc_vien = hv.ma_hoc_vien
where yc.trang_thai = 'open';
go

-- thủ tục stored proc
--- ======================================
if object_id(N'dbo.sp_tao_yeu_cau_lop', N'p') is not null drop procedure dbo.sp_tao_yeu_cau_lop;
go
create procedure dbo.sp_tao_yeu_cau_lop
    @p_ma_yeu_cau          varchar(20),
    @p_ma_hoc_vien         varchar(20),
    @p_tieu_de             nvarchar(200),
    @p_mo_ta               nvarchar(max),
    @p_tien_hoc_phi        decimal(12,0),
    @p_dia_chi             nvarchar(500),
    @p_hinh_thuc_hoc       varchar(20),
    @p_so_buoi_tuan        smallint,
    @p_thoi_gian_mong_muon nvarchar(max)
as
begin
    set nocount on;
    insert into yeu_cau_lop (
        ma_yeu_cau, ma_hoc_vien, tieu_de, mo_ta, tien_hoc_phi,
        dia_chi, hinh_thuc_hoc, so_buoi_tuan, thoi_gian_mong_muon, trang_thai
    )
    values (
        @p_ma_yeu_cau, @p_ma_hoc_vien, @p_tieu_de, @p_mo_ta, @p_tien_hoc_phi,
        @p_dia_chi, @p_hinh_thuc_hoc, @p_so_buoi_tuan, @p_thoi_gian_mong_muon, 'open'
    );
end;
go

if object_id(N'dbo.sp_ung_tuyen', N'p') is not null drop procedure dbo.sp_ung_tuyen;
go
create procedure dbo.sp_ung_tuyen
    @p_ma_ung_tuyen       varchar(30),
    @p_ma_yeu_cau         varchar(20),
    @p_ma_gia_su          varchar(20),
    @p_thu_nhap_mong_muon decimal(12,0) = null,
    @p_loi_nhan           nvarchar(max) = null
as
begin
    set nocount on;
    if not exists (select 1 from yeu_cau_lop where ma_yeu_cau = @p_ma_yeu_cau and trang_thai = 'open')
        throw 50010, 'yêu cầu này không còn mở để ứng tuyển.', 1;

    if not exists (select 1 from gia_su where ma_gia_su = @p_ma_gia_su and trong_lich = 1)
        throw 50011, 'gia sư đang bận, không thể ứng tuyển.', 1;

    insert into ung_tuyen (ma_ung_tuyen, ma_yeu_cau, ma_gia_su, thu_nhap_mong_muon, loi_nhan)
    values (@p_ma_ung_tuyen, @p_ma_yeu_cau, @p_ma_gia_su, @p_thu_nhap_mong_muon, @p_loi_nhan);
end;
go

if object_id(N'dbo.sp_chon_gia_su', N'p') is not null drop procedure dbo.sp_chon_gia_su;
go



-- yêu cầu phải đang 'open' trước khi cho phép chọn gia sư.
create procedure dbo.sp_chon_gia_su
    @p_ma_yeu_cau varchar(20),
    @p_ma_gia_su  varchar(20)
as
begin
    set nocount on;
    set xact_abort on;  -- bất kỳ lỗi nào (kể cả từ trigger) đều tự rollback

    -- validate: gia sư phải có ứng tuyển pending cho yêu cầu này
    if not exists (
        select 1 from ung_tuyen
        where ma_yeu_cau = @p_ma_yeu_cau
          and ma_gia_su  = @p_ma_gia_su
          and trang_thai = 'pending'
    )
        throw 50012, N'Gia sư chưa ứng tuyển hoặc ứng tuyển đã được xử lý.', 1;

    if not exists (
        select 1 from yeu_cau_lop
        where ma_yeu_cau = @p_ma_yeu_cau
          and trang_thai = 'open'
    )
        throw 50015, N'Yêu cầu không tồn tại hoặc đã được đóng/hủy.', 1;

    begin try
        begin transaction;

        -- trigger tr_yeu_cau_chon_gia_su sẽ tự động:
        --    ung_tuyen của GS được chọn  → 'accepted'
        --  các ung_tuyen còn lại        → 'rejected'
        --   Gửi thông báo cho tất cả các bên
        update yeu_cau_lop
        set ma_gia_su_duoc_chon = @p_ma_gia_su,
            ngay_chon_gia_su    = sysdatetime(),
            trang_thai          = 'closed'
        where ma_yeu_cau = @p_ma_yeu_cau;

        commit transaction;
    end try
    begin catch
        if @@trancount > 0 rollback transaction;
        throw;
    end catch;
end;
go

if object_id(N'dbo.sp_tao_lop_hoc', N'p') is not null drop procedure dbo.sp_tao_lop_hoc;
go
-- procedure tự động tạo lớp học khi học viên chọn gia sư thành công
create procedure dbo.sp_tao_lop_hoc
    @p_ma_lop        varchar(20),
    @p_ma_yeu_cau    varchar(20),
    @p_ngay_bat_dau  date,
    @p_tong_so_buoi  int
as
begin
    set nocount on;
    set xact_abort on;

    declare @v_ma_hoc_vien varchar(20);
    declare @v_ma_gia_su   varchar(20);
    declare @v_hoc_phi     decimal(12,0);
    declare @v_dia_chi     nvarchar(500);
    declare @v_hinh_thuc   varchar(20);

    select @v_ma_hoc_vien = ma_hoc_vien,
           @v_ma_gia_su   = ma_gia_su_duoc_chon,
           @v_hoc_phi     = tien_hoc_phi,
           @v_dia_chi     = dia_chi,
           @v_hinh_thuc   = hinh_thuc_hoc
    from yeu_cau_lop
    where ma_yeu_cau = @p_ma_yeu_cau
      and trang_thai = 'closed'
      and ma_gia_su_duoc_chon is not null;

    if @v_ma_hoc_vien is null
        throw 50013, 'yêu cầu chưa được chọn gia sư hoặc không tồn tại.', 1;

    begin try
        begin transaction;

        insert into lop_hoc (
            ma_lop, ma_gia_su, ma_hoc_vien, ma_yeu_cau,
            hoc_phi, dia_chi, hinh_thuc_day, ngay_bat_dau, tong_so_buoi, trang_thai
        )
        values (
            @p_ma_lop, @v_ma_gia_su, @v_ma_hoc_vien, @p_ma_yeu_cau,
            @v_hoc_phi, @v_dia_chi, @v_hinh_thuc, @p_ngay_bat_dau, @p_tong_so_buoi, 'sapmo'
        );

        update yeu_cau_lop set trang_thai = 'approved' where ma_yeu_cau = @p_ma_yeu_cau;

        insert into dang_ky (ma_dang_ky, ma_hoc_vien, ma_lop, trang_thai)
        values ('DK_' + @p_ma_lop, @v_ma_hoc_vien, @p_ma_lop, 'confirmed');

        insert into lop_hoc_mon (ma_lop, ma_mon, vai_tro_mon)
        select @p_ma_lop, ma_mon, vai_tro_mon
        from yeu_cau_mon
        where ma_yeu_cau = @p_ma_yeu_cau;

        commit transaction;
    end try
    begin catch
        if @@trancount > 0 rollback transaction;
        throw;
    end catch;
end;
go

if object_id(N'dbo.sp_danh_gia', N'p') is not null drop procedure dbo.sp_danh_gia;
go
create procedure dbo.sp_danh_gia
    @p_ma_danh_gia varchar(20),
    @p_ma_dang_ky  varchar(20),
    @p_diem_sao    smallint,
    @p_nhan_xet    nvarchar(max) = null
as
begin
    set nocount on;
    insert into danh_gia (ma_danh_gia, ma_dang_ky, diem_sao, nhan_xet)
    values (@p_ma_danh_gia, @p_ma_dang_ky, @p_diem_sao, @p_nhan_xet);
end;
go

if object_id(N'dbo.sp_diem_danh', N'p') is not null drop procedure dbo.sp_diem_danh;
go
create procedure dbo.sp_diem_danh
    @p_ma_buoi_hoc varchar(20),
    @p_ma_dang_ky  varchar(20),
    @p_trang_thai  varchar(20),
    @p_so_phut_hoc int = null
as
begin
    set nocount on;
    insert into diem_danh (ma_buoi_hoc, ma_dang_ky, trang_thai, so_phut_hoc)
    values (@p_ma_buoi_hoc, @p_ma_dang_ky, @p_trang_thai, @p_so_phut_hoc);
end;
go

if object_id(N'dbo.sp_toggle_trong_lich', N'p') is not null drop procedure dbo.sp_toggle_trong_lich;
go
create procedure dbo.sp_toggle_trong_lich
    @p_ma_gia_su  varchar(20),
    @p_trong_lich bit
as
begin
    set nocount on;
    update gia_su set trong_lich = @p_trong_lich where ma_gia_su = @p_ma_gia_su;
end;
go

if object_id(N'dbo.sp_ghi_nhan_thanh_toan', N'p') is not null drop procedure dbo.sp_ghi_nhan_thanh_toan;
go
-- ghi nhận giao dịch thanh toán, tự tính hoa hồng và số tiền gia sư nhận
create procedure dbo.sp_ghi_nhan_thanh_toan
    @p_ma_giao_dich   varchar(30),
    @p_ma_dang_ky     varchar(20),
    @p_ma_tk_hv       varchar(20),
    @p_ma_tk_gs       varchar(20),
    @p_tong_tien      decimal(15,0),
    @p_ty_le          decimal(5,2),
    @p_loai_giao_dich varchar(30) = 'thanhtoanthang'
as
begin
    set nocount on;
    set xact_abort on;

    declare @v_phi       decimal(15,0) = floor(@p_tong_tien * @p_ty_le / 100);
    declare @v_tien_nhan decimal(15,0) = @p_tong_tien - @v_phi;

    begin try
        begin transaction;

        insert into giao_dich (
            ma_giao_dich, ma_dang_ky, ma_tk_hv, ma_tk_gs,
            tong_tien_thu, ty_le_hoa_hong, phi_hoa_hong, so_tien_gia_su_nhan, loai_giao_dich
        )
        values (
            @p_ma_giao_dich, @p_ma_dang_ky, @p_ma_tk_hv, @p_ma_tk_gs,
            @p_tong_tien, @p_ty_le, @v_phi, @v_tien_nhan, @p_loai_giao_dich
        );

        update dang_ky set trang_thai = 'confirmed' where ma_dang_ky = @p_ma_dang_ky;

        commit transaction;
    end try
    begin catch
        if @@trancount > 0 rollback transaction;
        throw;
    end catch;
end;
go

-- ==============================================================================
-- phần 11: dữ liệu mẫu (seed data)
-- ==============================================================================

insert into hoc_vien (ma_hoc_vien, ho_ten, ngay_sinh, gioi_tinh, so_dien_thoai, email, dia_chi, khoi_hien_tai)
values
('HV_T01', N'Nguyen Van Test 1', '2008-01-15', N'Nam', '0900000001', 'hv1@test.local', N'Quan 1, TP HCM',  N'Lop 11'),
('HV_T02', N'Tran Thi Test 2',   '2009-03-20', N'Nu',  '0900000002', 'hv2@test.local', N'Quan 3, TP HCM',  N'Lop 10');

insert into gia_su (ma_gia_su, ho_ten, ngay_sinh, gioi_tinh, so_dien_thoai, email, dia_chi, trinh_do, gioi_thieu, trong_lich)
values
('GS_T01', N'Le Gia Su 1',  '1999-05-01', N'Nam', '0910000001', 'gs1@test.local', N'Quan 7, TP HCM',  N'Dai hoc Su pham', N'Gia su Toan',    1),
('GS_T02', N'Pham Gia Su 2','1998-08-10', N'Nu',  '0910000002', 'gs2@test.local', N'Thu Duc, TP HCM', N'Dai hoc KHTN',   N'Gia su Anh van', 1);

insert into mon_hoc (ma_mon, ten_mon, cap_hoc, mo_ta)
values
('MON_T01', N'Toan',      N'THPT', N'Mon Toan THPT'),
('MON_T02', N'Tieng Anh', N'THPT', N'Mon Tieng Anh THPT');

insert into gia_su_mon_hoc (ma_gia_su, ma_mon, nam_kinh_nghiem, muc_do_thanh_thao)
values
('GS_T01', 'MON_T01', 3, N'Tot'),
('GS_T02', 'MON_T02', 2, N'Kha');

insert into tai_khoan_hv (ma_tk_hv, ma_hoc_vien, so_tai_khoan, nha_cung_cap, loai_phuong_thuc, ten_chu_tk, la_mac_dinh)
values
('TKHV_T01', 'HV_T01', '100000001', N'VCB', 'bank', N'NGUYEN VAN TEST 1', 1),
('TKHV_T02', 'HV_T02', '100000002', N'ACB', 'bank', N'TRAN THI TEST 2',   1);

insert into tai_khoan_gs (ma_tk_gs, ma_gia_su, so_tai_khoan, nha_cung_cap, loai_phuong_thuc, ten_chu_tk, la_mac_dinh)
values
('TKGS_T01', 'GS_T01', '200000001', N'MBBank', 'bank', N'LE GIA SU 1',     1),
('TKGS_T02', 'GS_T02', '200000002', N'TPB',    'bank', N'PHAM GIA SU 2',   1);
go

