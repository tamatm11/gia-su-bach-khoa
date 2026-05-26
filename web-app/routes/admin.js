const express = require('express');
const router = express.Router();
const { supabase, supabaseAdmin } = require('../lib/supabase');

// Middleware kiểm tra admin
function requireAdmin(req, res, next) {
  if (!req.session.isAdmin) {
    req.session.error = 'Bạn không có quyền truy cập trang quản trị.';
    return res.redirect('/');
  }
  next();
}

router.use(requireAdmin);

// Dashboard Admin
router.get('/', async (req, res) => {
  try {
    const { data: stats } = await supabase
      .from('vw_admin_thong_ke')
      .select('*')
      .single();

    const { data: recentYC } = await supabase
      .from('yeu_cau_lop')
      .select('*, hoc_vien(ho_ten), gia_su(ho_ten)')
      .order('ngay_yeu_cau', { ascending: false })
      .limit(5);

    const { data: recentLH } = await supabase
      .from('lop_hoc')
      .select('*, gia_su(ho_ten), hoc_vien(ho_ten)')
      .order('ngay_bat_dau', { ascending: false })
      .limit(5);

    res.render('admin/index', {
      stats: stats || {},
      recentYC: recentYC || [],
      recentLH: recentLH || []
    });
  } catch (err) {
    console.error('Admin dashboard:', err.message);
    res.render('admin/index', { stats: {}, recentYC: [], recentLH: [] });
  }
});

// Admin - Quản lý yêu cầu
router.get('/yeu-cau', async (req, res) => {
  const { trang_thai, search } = req.query;
  let query = supabase
    .from('yeu_cau_lop')
    .select('*, hoc_vien(ho_ten), gia_su(ho_ten)')
    .order('ngay_yeu_cau', { ascending: false });

  if (trang_thai && trang_thai !== 'all') query = query.eq('trang_thai', trang_thai);
  if (search) query = query.or(`tieu_de.ilike.%${search}%,ma_yeu_cau.ilike.%${search}%`);

  const { data: list } = await query;
  res.render('admin/yeu-cau', { list: list || [], trang_thai: trang_thai || 'all', search: search || '' });
});

// Admin - Quản lý lớp học
router.get('/lop-hoc', async (req, res) => {
  const { trang_thai, search } = req.query;
  let query = supabase
    .from('lop_hoc')
    .select('*, gia_su(ho_ten), hoc_vien(ho_ten)')
    .order('ngay_bat_dau', { ascending: false });

  if (trang_thai && trang_thai !== 'all') query = query.eq('trang_thai', trang_thai);
  if (search) query = query.or(`ma_lop.ilike.%${search}%`);

  const { data: list } = await query;
  res.render('admin/lop-hoc', { list: list || [], trang_thai: trang_thai || 'all', search: search || '' });
});

module.exports = router;
