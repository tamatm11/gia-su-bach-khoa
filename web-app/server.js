require('dotenv').config();
const express = require('express');
const session = require('express-session');
const path = require('path');
const { supabase, supabaseAdmin } = require('./lib/supabase');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

app.use(session({
  secret: process.env.SESSION_SECRET || 'gia-su-bach-khoa-secret',
  resave: false,
  saveUninitialized: false,
  cookie: { maxAge: 24 * 60 * 60 * 1000 } // 24h
}));

// Middleware: expose user & flash to all views
app.use((req, res, next) => {
  res.locals.user = req.session.user || null;
  res.locals.role = req.session.role || null;
  res.locals.isAdmin = req.session.isAdmin || false;
  res.locals.error = req.session.error || null;
  res.locals.success = req.session.success || null;
  delete req.session.error;
  delete req.session.success;
  next();
});


// =========================================================================
// ROUTES - TRANG CHỦ & AUTH
// =========================================================================

// Trang chủ
app.get('/', async (req, res) => {
  try {
    // Lấy danh sách yêu cầu đang mở
    const { data: yeuCauList } = await supabase
      .from('yeu_cau_lop')
      .select('*, hoc_vien(ho_ten, khoi_hien_tai)')
      .in('trang_thai', ['open', 'approved'])
      .order('ngay_yeu_cau', { ascending: false })
      .limit(6);

    // Lấy danh sách gia sư nổi bật
    const { data: giaSuList } = await supabase
      .from('gia_su')
      .select('*')
      .eq('trong_lich', true)
      .limit(4);

    res.render('index', { yeuCauList: yeuCauList || [], giaSuList: giaSuList || [] });
  } catch (err) {
    console.error('Trang chủ:', err.message);
    res.render('index', { yeuCauList: [], giaSuList: [] });
  }
});

// Auth router
app.use('/auth', require('./routes/auth'));

// Profile router
app.use('/', require('./routes/profile'));

// =========================================================================
// ROUTES - YÊU CẦU LỚP
// =========================================================================

// Danh sách yêu cầu (gia sư xem để ứng tuyển)
app.get('/yeu-cau', async (req, res) => {
  const { data: list } = await supabase
    .from('yeu_cau_lop')
    .select('*, hoc_vien(ho_ten, khoi_hien_tai)')
    .in('trang_thai', ['open', 'approved'])
    .order('ngay_yeu_cau', { ascending: false });

  // Đếm số ứng tuyển cho mỗi yêu cầu
  const { data: ungTuyenCounts } = await supabase
    .from('ung_tuyen')
    .select('ma_yeu_cau, count', { count: 'exact' });

  res.render('yeu-cau', { list: list || [], ungTuyenCounts: ungTuyenCounts || [] });
});

// Form tạo yêu cầu mới (học viên)
app.get('/dang-tin', (req, res) => {
  if (!req.session.user || req.session.role !== 'hoc_vien') {
    req.session.error = 'Vui lòng đăng nhập với tài khoản học viên.';
    return res.redirect('/');
  }
  res.render('dang-tin');
});

// Xử lý tạo yêu cầu
app.post('/dang-tin', async (req, res) => {
  if (!req.session.user || req.session.role !== 'hoc_vien') {
    return res.redirect('/');
  }

  const { tieu_de, mo_ta, tien_hoc_phi, dia_chi, hinh_thuc_hoc, so_buoi_tuan, thoi_gian_mong_muon, ma_mon } = req.body;
  const ma_yeu_cau = 'YC' + Date.now().toString(36).toUpperCase();

  try {
    await supabaseAdmin.rpc('sp_tao_yeu_cau_lop', {
      p_ma_yeu_cau: ma_yeu_cau,
      p_ma_hoc_vien: req.session.user.ma_hoc_vien,
      p_tieu_de: tieu_de,
      p_mo_ta: mo_ta || null,
      p_tien_hoc_phi: parseInt(tien_hoc_phi),
      p_dia_chi: dia_chi,
      p_hinh_thuc_hoc: hinh_thuc_hoc,
      p_so_buoi_tuan: parseInt(so_buoi_tuan),
      p_thoi_gian_mong_muon: thoi_gian_mong_muon || null
    });

    // Thêm môn học
    if (ma_mon) {
      await supabaseAdmin.from('yeu_cau_mon').insert({
        ma_yeu_cau, ma_mon, vai_tro_mon: 'Chính'
      });
    }

    req.session.success = 'Đăng tin thành công! Gia sư sẽ ứng tuyển vào yêu cầu của bạn.';
    res.redirect('/yeu-cau-cua-toi');
  } catch (err) {
    req.session.error = 'Lỗi: ' + err.message;
    res.redirect('/dang-tin');
  }
});

// Yêu cầu của tôi (học viên xem)
app.get('/yeu-cau-cua-toi', async (req, res) => {
  if (!req.session.user || req.session.role !== 'hoc_vien') return res.redirect('/');

  const { data: list } = await supabase
    .from('yeu_cau_lop')
    .select('*')
    .eq('ma_hoc_vien', req.session.user.ma_hoc_vien)
    .order('ngay_yeu_cau', { ascending: false });

  // Lấy danh sách ứng tuyển cho từng yêu cầu
  const { data: utList } = await supabase
    .from('ung_tuyen')
    .select('*, gia_su(ho_ten, trinh_do, gioi_thieu)')
    .in('ma_yeu_cau', (list || []).map(y => y.ma_yeu_cau));

  res.render('yeu-cau-cua-toi', { list: list || [], utList: utList || [] });
});

// Học viên chọn gia sư
app.post('/chon-gia-su', async (req, res) => {
  const { ma_yeu_cau, ma_gia_su } = req.body;
  try {
    await supabaseAdmin.rpc('sp_chon_gia_su', {
      p_ma_yeu_cau: ma_yeu_cau,
      p_ma_gia_su: ma_gia_su
    });
    req.session.success = 'Đã chọn gia sư thành công! Hệ thống sẽ tạo lớp học.';
  } catch (err) {
    req.session.error = 'Lỗi: ' + err.message;
  }
  res.redirect('/yeu-cau-cua-toi');
});

// Tạo lớp học từ yêu cầu đã chọn
app.post('/tao-lop-hoc', async (req, res) => {
  const { ma_yeu_cau, ngay_bat_dau, tong_so_buoi } = req.body;
  const ma_lop = 'LH' + Date.now().toString(36).toUpperCase();
  try {
    await supabaseAdmin.rpc('sp_tao_lop_hoc', {
      p_ma_lop: ma_lop,
      p_ma_yeu_cau: ma_yeu_cau,
      p_ngay_bat_dau: ngay_bat_dau,
      p_tong_so_buoi: parseInt(tong_so_buoi)
    });
    req.session.success = 'Lớp học đã được tạo thành công!';
  } catch (err) {
    req.session.error = 'Lỗi: ' + err.message;
  }
  res.redirect('/lop-hoc');
});

// =========================================================================
// ROUTES - ỨNG TUYỂN (GIA SƯ)
// =========================================================================

// Gia sư ứng tuyển
app.post('/ung-tuyen', async (req, res) => {
  if (!req.session.user || req.session.role !== 'gia_su') {
    req.session.error = 'Vui lòng đăng nhập với tài khoản gia sư.';
    return res.redirect('/');
  }

  const { ma_yeu_cau, thu_nhap_mong_muon, loi_nhan } = req.body;
  const ma_ung_tuyen = 'UT' + Date.now().toString(36).toUpperCase();

  try {
    await supabaseAdmin.rpc('sp_ung_tuyen', {
      p_ma_ung_tuyen: ma_ung_tuyen,
      p_ma_yeu_cau: ma_yeu_cau,
      p_ma_gia_su: req.session.user.ma_gia_su,
      p_thu_nhap_mong_muon: thu_nhap_mong_muon ? parseInt(thu_nhap_mong_muon) : null,
      p_loi_nhan: loi_nhan || null
    });
    req.session.success = 'Ứng tuyển thành công! Học viên sẽ xem xét hồ sơ của bạn.';
  } catch (err) {
    req.session.error = 'Lỗi: ' + err.message;
  }
  res.redirect('/yeu-cau');
});

// =========================================================================
// ROUTES - LỚP ĐÃ ỨNG TUYỂN (GIA SƯ)
// =========================================================================

app.get('/lop-da-ung-tuyen', async (req, res) => {
  if (!req.session.user || req.session.role !== 'gia_su') return res.redirect('/');

  const { data: utList } = await supabase
    .from('ung_tuyen')
    .select('*, yeu_cau_lop(*, hoc_vien(ho_ten))')
    .eq('ma_gia_su', req.session.user.ma_gia_su)
    .order('ngay_ung_tuyen', { ascending: false });

  res.render('lop-da-ung-tuyen', { utList: utList || [] });
});

// =========================================================================
// ROUTES - LỚP HỌC
// =========================================================================

// Lớp học router
app.use('/lop-hoc', require('./routes/lop-hoc'));

// =========================================================================
// ROUTES - THỜI KHÓA BIỂU GIA SƯ
// =========================================================================

app.get('/lich-day', async (req, res) => {
  if (!req.session.user || req.session.role !== 'gia_su') return res.redirect('/');

  const { data: lich } = await supabase
    .from('vw_lich_trinh_gia_su')
    .select('*')
    .eq('ma_gia_su', req.session.user.ma_gia_su)
    .order('thu_trong_tuan');

  res.render('lich-day', { lich: lich || [] });
});

// Toggle trạng thái trống lịch
app.post('/toggle-trong-lich', async (req, res) => {
  if (!req.session.user || req.session.role !== 'gia_su') return res.redirect('/');

  const newState = !req.session.user.trong_lich;
  await supabaseAdmin.rpc('sp_toggle_trong_lich', {
    p_ma_gia_su: req.session.user.ma_gia_su,
    p_trong_lich: newState
  });

  req.session.user.trong_lich = newState;
  req.session.success = newState ? 'Bạn đã bật trạng thái trống lịch.' : 'Bạn đã tắt trạng thái trống lịch.';
  res.redirect('/lich-day');
});

// =========================================================================
// ROUTES - ĐÁNH GIÁ
// =========================================================================

app.post('/danh-gia', async (req, res) => {
  const { ma_dang_ky, diem_sao, nhan_xet } = req.body;
  const ma_danh_gia = 'DG' + Date.now().toString(36).toUpperCase();
  try {
    await supabaseAdmin.rpc('sp_danh_gia', {
      p_ma_danh_gia: ma_danh_gia,
      p_ma_dang_ky: ma_dang_ky,
      p_diem_sao: parseInt(diem_sao),
      p_nhan_xet: nhan_xet || null
    });
    req.session.success = 'Đánh giá thành công!';
  } catch (err) {
    req.session.error = 'Lỗi: ' + err.message;
  }
  res.redirect('/lop-hoc');
});

// Admin router
app.use('/admin', require('./routes/admin'));

// =========================================================================
// ROUTES - HỒ SƠ GIA SƯ
// =========================================================================

app.get('/ho-so-gia-su/:ma_gia_su', async (req, res) => {
  const { ma_gia_su } = req.params;
  const { ma_yeu_cau } = req.query;

  const { data: gs } = await supabase
    .from('vw_gia_su_tong_hop')
    .select('*')
    .eq('ma_gia_su', ma_gia_su)
    .single();

  if (!gs) {
    req.session.error = 'Không tìm thấy gia sư.';
    return res.redirect('/');
  }

  const { data: monHoc } = await supabase
    .from('gia_su_mon_hoc')
    .select('*, mon_hoc(ten_mon)')
    .eq('ma_gia_su', ma_gia_su);

  const { data: lopDangDay } = await supabase
    .from('lop_hoc')
    .select('*, hoc_vien(ho_ten)')
    .eq('ma_gia_su', ma_gia_su)
    .eq('trang_thai', 'dang_hoc');

  const { data: lopDaDay } = await supabase
    .from('lop_hoc')
    .select('*, hoc_vien(ho_ten)')
    .eq('ma_gia_su', ma_gia_su)
    .eq('trang_thai', 'da_hoan_thanh');

  const { data: danhGia } = await supabase
    .from('danh_gia')
    .select('*, dang_ky(ma_lop, lop_hoc!inner(ma_gia_su, hoc_vien(ho_ten)))')
    .eq('dang_ky.lop_hoc.ma_gia_su', ma_gia_su)
    .order('ngay_danh_gia', { ascending: false });

  res.render('ho-so-gia-su', {
    gs,
    monHoc: monHoc || [],
    lopDangDay: lopDangDay || [],
    lopDaDay: lopDaDay || [],
    danhGia: danhGia || [],
    ma_yeu_cau: ma_yeu_cau || null
  });
});

// =========================================================================
// API ROUTES (cho frontend JS)
// =========================================================================

// API lấy danh sách gia sư cho yêu cầu
app.get('/api/gia-su-tim-kiem', async (req, res) => {
  const { ma_mon, tinh_trang } = req.query;
  let query = supabase.from('gia_su').select('*, gia_su_mon_hoc!inner(ma_mon)');

  if (ma_mon) query = query.eq('gia_su_mon_hoc.ma_mon', ma_mon);
  if (tinh_trang === 'trong_lich') query = query.eq('trong_lich', true);

  const { data } = await query.limit(20);
  res.json(data || []);
});

// API lấy số ứng tuyển của một yêu cầu
app.get('/api/ung-tuyen-count/:ma_yeu_cau', async (req, res) => {
  const { count } = await supabase
    .from('ung_tuyen')
    .select('*', { count: 'exact', head: true })
    .eq('ma_yeu_cau', req.params.ma_yeu_cau);

  res.json({ count });
});

// =========================================================================
// START SERVER
// =========================================================================

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Server ready on http://localhost:${PORT}`);
  });
}

module.exports = app;
