const express = require('express');
const router = express.Router();
const { supabaseAdmin } = require('../lib/supabase');

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
    const { data: stats } = await supabaseAdmin
      .from('vw_admin_thong_ke')
      .select('*')
      .single();

    const { data: recentYC } = await supabaseAdmin
      .from('yeu_cau_lop')
      .select('*, hoc_vien(ho_ten), gia_su(ho_ten)')
      .order('ngay_yeu_cau', { ascending: false })
      .limit(5);

    const { data: recentLH } = await supabaseAdmin
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
  let query = supabaseAdmin
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
  let query = supabaseAdmin
    .from('lop_hoc')
    .select('*, gia_su(ho_ten), hoc_vien(ho_ten)')
    .order('ngay_bat_dau', { ascending: false });

  if (trang_thai && trang_thai !== 'all') query = query.eq('trang_thai', trang_thai);
  if (search) query = query.or(`ma_lop.ilike.%${search}%`);

  const { data: list } = await query;
  res.render('admin/lop-hoc', { list: list || [], trang_thai: trang_thai || 'all', search: search || '' });
});

// Admin - Quản lý gia sư
router.get('/gia-su', async (req, res) => {
  const { search } = req.query;
  let query = supabaseAdmin.from('gia_su').select('*').order('ngay_tao', { ascending: false });

  if (search) query = query.or(`ho_ten.ilike.%${search}%,email.ilike.%${search}%,ma_gia_su.ilike.%${search}%`);

  const { data: list } = await query;
  res.render('admin/gia-su', { list: list || [], search: search || '' });
});

// Admin - Quản lý học viên
router.get('/hoc-vien', async (req, res) => {
  const { search } = req.query;
  let query = supabaseAdmin.from('hoc_vien').select('*').order('ngay_tao', { ascending: false });

  if (search) query = query.or(`ho_ten.ilike.%${search}%,email.ilike.%${search}%,ma_hoc_vien.ilike.%${search}%`);

  const { data: list } = await query;
  res.render('admin/hoc-vien', { list: list || [], search: search || '' });
});

// Admin - Audit Logs
router.get('/audit-logs', async (req, res) => {
  try {
    const { data: logs } = await supabaseAdmin
      .from('audit_log')
      .select('*')
      .order('changed_at', { ascending: false })
      .limit(100);
      
    res.render('admin/audit-logs', { logs: logs || [] });
  } catch (err) {
    console.error('Lỗi lấy audit logs:', err.message);
    res.render('admin/audit-logs', { logs: [] });
  }
});

module.exports = router;
