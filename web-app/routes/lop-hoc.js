const express = require('express');
const router = express.Router();
const { supabase, supabaseAdmin } = require('../lib/supabase');

router.get('/', async (req, res) => {
  if (!req.session.user) return res.redirect('/');

  let query = supabaseAdmin.from('lop_hoc').select('*, gia_su(ho_ten), hoc_vien(ho_ten)');
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
  const { data: lop } = await supabaseAdmin
    .from('lop_hoc')
    .select('*, gia_su(ho_ten, trinh_do), hoc_vien(ho_ten)')
    .eq('ma_lop', ma_lop)
    .single();

  const { data: lichHoc } = await supabaseAdmin
    .from('lich_hoc')
    .select('*')
    .eq('ma_lop', ma_lop)
    .order('thu_trong_tuan');

  const { data: buoiHocData } = await supabaseAdmin
    .from('buoi_hoc')
    .select('*')
    .eq('ma_lop', ma_lop)
    .order('ngay_hoc', { ascending: false });
    
  const buoiHoc = buoiHocData || [];
  
  if (buoiHoc.length > 0) {
    const { data: diemDanhList } = await supabaseAdmin
      .from('diem_danh')
      .select('*')
      .in('ma_buoi_hoc', buoiHoc.map(b => b.ma_buoi_hoc));
      
    if (diemDanhList && diemDanhList.length > 0) {
      buoiHoc.forEach(bh => {
        bh.diem_danh = diemDanhList.find(dd => dd.ma_buoi_hoc === bh.ma_buoi_hoc);
      });
    }
  }

  res.render('lop-hoc-chi-tiet', { lop, lichHoc: lichHoc || [], buoiHoc });
});

// Điểm danh buổi học
router.post('/:ma_lop/diem-danh/:ma_buoi_hoc', async (req, res) => {
  if (!req.session.user || req.session.role !== 'gia_su') {
    req.session.error = 'Chỉ gia sư mới được điểm danh.';
    return res.redirect('/lop-hoc/' + req.params.ma_lop);
  }
  
  const { ma_lop, ma_buoi_hoc } = req.params;
  const { trang_thai } = req.body;
  
  try {
    const { data: dangKy } = await supabaseAdmin
      .from('dang_ky')
      .select('ma_dang_ky')
      .eq('ma_lop', ma_lop)
      .single();
      
    if (!dangKy) throw new Error('Không tìm thấy dữ liệu đăng ký lớp này.');
    
    const { error } = await supabaseAdmin.rpc('sp_diem_danh', {
      p_ma_buoi_hoc: ma_buoi_hoc,
      p_ma_dang_ky: dangKy.ma_dang_ky,
      p_trang_thai: trang_thai,
      p_so_phut_hoc: null
    });
    
    if (error) throw error;
    
    // Update buoi_hoc status to completed
    await supabaseAdmin.from('buoi_hoc').update({trang_thai: 'completed'}).eq('ma_buoi_hoc', ma_buoi_hoc);
    
    req.session.success = 'Điểm danh thành công!';
  } catch (err) {
    req.session.error = 'Lỗi điểm danh: ' + err.message;
  }
  res.redirect('/lop-hoc/' + ma_lop);
});

// Thêm lịch học
router.post('/:ma_lop/them-lich', async (req, res) => {
  const { ma_lop } = req.params;
  const { thu_trong_tuan, gio_bat_dau, gio_ket_thuc } = req.body;
  const ma_lich = 'LICH' + Date.now().toString(36).toUpperCase();

  try {
    const { error } = await supabaseAdmin.from('lich_hoc').insert({
      ma_lich, ma_lop,
      thu_trong_tuan: parseInt(thu_trong_tuan),
      gio_bat_dau, gio_ket_thuc
    });
    if (error) throw error;
    req.session.success = 'Đã thêm lịch học mới!';
  } catch (err) {
    req.session.error = 'Lỗi: ' + err.message + ' (Có thể bị trùng lịch giảng dạy)';
  }
  res.redirect('/lop-hoc/' + ma_lop);
});

// Xóa lịch học
router.post('/:ma_lop/xoa-lich/:ma_lich', async (req, res) => {
  const { ma_lop, ma_lich } = req.params;

  try {
    const { error } = await supabaseAdmin
      .from('lich_hoc')
      .delete()
      .eq('ma_lop', ma_lop)
      .eq('ma_lich', ma_lich);
      
    if (error) throw error;
    req.session.success = 'Đã xóa lịch học!';
  } catch (err) {
    req.session.error = 'Lỗi: ' + err.message;
  }
  res.redirect('/lop-hoc/' + ma_lop);
});

module.exports = router;
