const express = require('express');
const router = express.Router();
const { supabase, supabaseAdmin } = require('../lib/supabase');

// Middleware yêu cầu đăng nhập
function requireLogin(req, res, next) {
  if (!req.session.user) {
    req.session.error = 'Vui lòng đăng nhập để tiếp tục.';
    return res.redirect('/');
  }
  next();
}

// -----------------------------------------------------
// HO-SO CHUNG (CHO CẢ HỌC VIÊN & GIA SƯ)
// -----------------------------------------------------

// Form chỉnh sửa hồ sơ
router.get('/ho-so/chinh-sua', requireLogin, async (req, res) => {
  const isGiaSu = req.session.role === 'gia_su';
  const table = isGiaSu ? 'gia_su' : 'hoc_vien';
  const primaryKey = isGiaSu ? 'ma_gia_su' : 'ma_hoc_vien';
  const idValue = isGiaSu ? req.session.user.ma_gia_su : req.session.user.ma_hoc_vien;

  try {
    const { data: profile } = await supabase.from(table).select('*').eq(primaryKey, idValue).single();
    res.render('ho-so-chinh-sua', { profile: profile || req.session.user, isGiaSu });
  } catch (err) {
    req.session.error = 'Lỗi tải hồ sơ: ' + err.message;
    res.redirect('/');
  }
});

// Xử lý cập nhật hồ sơ
router.post('/ho-so/chinh-sua', requireLogin, async (req, res) => {
  const isGiaSu = req.session.role === 'gia_su';
  const table = isGiaSu ? 'gia_su' : 'hoc_vien';
  const primaryKey = isGiaSu ? 'ma_gia_su' : 'ma_hoc_vien';
  const idValue = isGiaSu ? req.session.user.ma_gia_su : req.session.user.ma_hoc_vien;

  const { ho_ten, so_dien_thoai, gioi_thieu, trinh_do, khoi_hien_tai, ngay_sinh } = req.body;

  let updateData = {
    ho_ten,
    gioi_thieu: gioi_thieu || null,
    ngay_cap_nhat: new Date().toISOString()
  };

  if (ngay_sinh) updateData.ngay_sinh = ngay_sinh;

  if (isGiaSu) {
    updateData.trinh_do = trinh_do || null;
  } else {
    updateData.so_dien_thoai = so_dien_thoai || null;
    updateData.khoi_hien_tai = khoi_hien_tai || null;
  }

  try {
    // Dùng admin API để bypass RLS (update profile của chính user)
    const { data, error } = await supabaseAdmin.from(table).update(updateData).eq(primaryKey, idValue).select().single();
    if (error) throw error;
    
    // Cập nhật lại session
    req.session.user = { ...req.session.user, ...data };
    req.session.success = 'Cập nhật hồ sơ thành công!';
    res.redirect('/'); // Quay về trang chủ, hoặc có thể là trang profile (tùy ý)
  } catch (err) {
    req.session.error = 'Lỗi cập nhật: ' + err.message;
    res.redirect('/ho-so/chinh-sua');
  }
});

// -----------------------------------------------------
// PUBLIC PROFILE HỌC VIÊN
// -----------------------------------------------------

router.get('/ho-so-hoc-vien/:ma_hoc_vien', async (req, res) => {
  const { ma_hoc_vien } = req.params;
  
  try {
    // Lấy thông tin học viên
    const { data: hv } = await supabase.from('hoc_vien').select('*').eq('ma_hoc_vien', ma_hoc_vien).single();
    
    if (!hv) {
      req.session.error = 'Không tìm thấy học viên này.';
      return res.redirect('/');
    }

    // Lấy các yêu cầu đang mở của học viên này
    const { data: yeuCauList } = await supabase
      .from('yeu_cau_lop')
      .select('*')
      .eq('ma_hoc_vien', ma_hoc_vien)
      .eq('trang_thai', 'open')
      .order('ngay_yeu_cau', { ascending: false });

    res.render('ho-so-hoc-vien', { hv, yeuCauList: yeuCauList || [] });
  } catch (err) {
    req.session.error = 'Lỗi: ' + err.message;
    res.redirect('/');
  }
});

module.exports = router;
