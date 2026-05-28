const express = require('express');
const router = express.Router();
const { supabase, supabaseAdmin } = require('../lib/supabase');

// Auth - Đăng ký
router.post('/register', async (req, res) => {
  const { email, password, ho_ten, role, so_dien_thoai } = req.body;

  if (!email || !password || !ho_ten || !role) {
    req.session.error = 'Vui lòng điền đầy đủ thông tin bắt buộc.';
    return res.redirect('/');
  }
  if (password.length < 6) {
    req.session.error = 'Mật khẩu phải có ít nhất 6 ký tự.';
    return res.redirect('/');
  }
  if (!['hoc_vien', 'gia_su'].includes(role)) {
    req.session.error = 'Vai trò không hợp lệ.';
    return res.redirect('/');
  }

  let authUserId = null;
  try {
    const { data: authData, error: authErr } = await supabaseAdmin.auth.admin.createUser({
      email, password, email_confirm: true
    });

    if (authErr) {
      if (authErr.message.includes('already been registered')) {
        req.session.error = 'Email này đã được đăng ký. Vui lòng dùng email khác hoặc đăng nhập.';
        return res.redirect('/');
      }
      throw authErr;
    }

    authUserId = authData.user.id;

    let profileErr = null;
    if (role === 'hoc_vien') {
      const ma = 'HV' + Date.now().toString(36).toUpperCase() + Math.random().toString(36).slice(2, 5).toUpperCase();
      const { error } = await supabaseAdmin.from('hoc_vien').insert({
        ma_hoc_vien: ma, ho_ten, email, so_dien_thoai: so_dien_thoai || null, auth_id: authUserId
      });
      profileErr = error;
    } else {
      const ma = 'GS' + Date.now().toString(36).toUpperCase() + Math.random().toString(36).slice(2, 5).toUpperCase();
      const { error } = await supabaseAdmin.from('gia_su').insert({
        ma_gia_su: ma, ho_ten, email, so_dien_thoai: so_dien_thoai || null, auth_id: authUserId
      });
      profileErr = error;
    }

    if (profileErr) {
      await supabaseAdmin.auth.admin.deleteUser(authUserId);
      throw new Error('Không thể tạo hồ sơ: ' + profileErr.message);
    }

    req.session.success = 'Đăng ký thành công! Vui lòng đăng nhập.';
    res.redirect('/');
  } catch (err) {
    if (authUserId) {
      try { await supabaseAdmin.auth.admin.deleteUser(authUserId); } catch (_) {}
    }
    req.session.error = 'Lỗi đăng ký: ' + err.message;
    res.redirect('/');
  }
});

// Auth - Đăng nhập
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const { data: authData, error: authErr } = await supabase.auth.signInWithPassword({ email, password });
    if (authErr) throw authErr;

    const { data: qtv } = await supabase.from('quan_tri_vien').select('*').eq('auth_id', authData.user.id).maybeSingle();

    if (qtv) {
      req.session.user = qtv;
      req.session.role = 'quan_tri_vien';
      req.session.isAdmin = true;
    } else {
      const { data: hv } = await supabase.from('hoc_vien').select('*').eq('auth_id', authData.user.id).maybeSingle();
      const { data: gs } = await supabase.from('gia_su').select('*').eq('auth_id', authData.user.id).maybeSingle();

      if (!hv && !gs) {
        throw new Error('Tài khoản chưa được liên kết với hồ sơ học viên hoặc gia sư.');
      }

      req.session.user = hv || gs;
      req.session.role = hv ? 'hoc_vien' : 'gia_su';
      req.session.isAdmin = false;
    }

    req.session.auth_id = authData.user.id;
    req.session.access_token = authData.session.access_token;

    req.session.success = 'Đăng nhập thành công!';
    res.redirect('/');
  } catch (err) {
    req.session.error = 'Sai email hoặc mật khẩu.';
    res.redirect('/');
  }
});

// Đăng xuất
router.post('/logout', (req, res) => {
  req.session.destroy(() => res.redirect('/'));
});

// Quên mật khẩu
router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  if (!email) {
    req.session.error = 'Vui lòng nhập email.';
    return res.redirect('/');
  }
  try {
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${req.protocol}://${req.get('host')}/auth/reset-password`,
    });
    if (error) throw error;
    req.session.success = 'Đã gửi liên kết đặt lại mật khẩu. Vui lòng kiểm tra hộp thư đến (hoặc thư mục Spam) của bạn.';
  } catch (err) {
    req.session.error = 'Lỗi gửi email: ' + err.message;
  }
  res.redirect('/');
});

// Trang đặt lại mật khẩu (được gọi từ liên kết email)
router.get('/reset-password', (req, res) => {
  res.render('reset-password', {
    supabaseUrl: process.env.SUPABASE_URL,
    supabaseAnonKey: process.env.SUPABASE_ANON_KEY
  });
});

module.exports = router;
