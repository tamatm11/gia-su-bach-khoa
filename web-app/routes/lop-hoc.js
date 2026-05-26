const express = require('express');
const router = express.Router();
const { supabase, supabaseAdmin } = require('../lib/supabase');

router.get('/', async (req, res) => {
  if (!req.session.user) return res.redirect('/');

  let query = supabase.from('lop_hoc').select('*, gia_su(ho_ten), hoc_vien(ho_ten)');
  if (req.session.role === 'gia_su') {
    query = query.eq('ma_gia_su', req.session.user.ma_gia_su);
  } else {
    query = query.eq('ma_hoc_vien', req.session.user.ma_hoc_vien);
  }
  const { data: list } = await query.order('ngay_bat_dau', { ascending: false });

  res.render('lop-hoc', { list: list || [] });
});

// Chi tiết lớp học + lịch học
router.get('/:ma_lop', async (req, res) => {
  const { ma_lop } = req.params;
  const { data: lop } = await supabase
    .from('lop_hoc')
    .select('*, gia_su(ho_ten, trinh_do), hoc_vien(ho_ten)')
    .eq('ma_lop', ma_lop)
    .single();

  const { data: lichHoc } = await supabase
    .from('lich_hoc')
    .select('*')
    .eq('ma_lop', ma_lop)
    .order('thu_trong_tuan');

  const { data: buoiHoc } = await supabase
    .from('buoi_hoc')
    .select('*')
    .eq('ma_lop', ma_lop)
    .order('ngay_hoc', { ascending: false });

  res.render('lop-hoc-chi-tiet', { lop, lichHoc: lichHoc || [], buoiHoc: buoiHoc || [] });
});

// Thêm lịch học
router.post('/:ma_lop/them-lich', async (req, res) => {
  const { ma_lop } = req.params;
  const { thu_trong_tuan, gio_bat_dau, gio_ket_thuc } = req.body;
  const ma_lich = 'LICH' + Date.now().toString(36).toUpperCase();

  try {
    await supabaseAdmin.from('lich_hoc').insert({
      ma_lich, ma_lop,
      thu_trong_tuan: parseInt(thu_trong_tuan),
      gio_bat_dau, gio_ket_thuc
    });
    req.session.success = 'Đã thêm lịch học mới!';
  } catch (err) {
    req.session.error = 'Lỗi: ' + err.message + ' (Có thể bị trùng lịch giảng dạy)';
  }
  res.redirect('/lop-hoc/' + ma_lop);
});

module.exports = router;
