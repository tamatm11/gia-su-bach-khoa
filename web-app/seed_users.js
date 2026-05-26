require('dotenv').config();
const { supabaseAdmin } = require('./lib/supabase');

async function seedUsers() {
  const usersToCreate = [
    // Admin
    { email: 'admin@giangvien.com', password: 'password123', ho_ten: 'Admin Bách Khoa', role: 'admin' },
    
    // Gia sư
    { email: 'giasu1@gmail.com', password: 'password123', ho_ten: 'Nguyễn Văn Gia Sư 1', role: 'gia_su', trinh_do: 'Sinh viên năm 3' },
    { email: 'giasu2@gmail.com', password: 'password123', ho_ten: 'Trần Thị Gia Sư 2', role: 'gia_su', trinh_do: 'Giáo viên tự do' },
    { email: 'giasu3@gmail.com', password: 'password123', ho_ten: 'Lê Hoàng Gia Sư 3', role: 'gia_su', trinh_do: 'Thạc sĩ' },
    { email: 'giasu4@gmail.com', password: 'password123', ho_ten: 'Phạm Minh Gia Sư 4', role: 'gia_su', trinh_do: 'Sinh viên năm 4' },
    
    // Học viên
    { email: 'hocvien1@gmail.com', password: 'password123', ho_ten: 'Ngô Trí Học Viên 1', role: 'hoc_vien', so_dien_thoai: '0901111111' },
    { email: 'hocvien2@gmail.com', password: 'password123', ho_ten: 'Vũ Đức Học Viên 2', role: 'hoc_vien', so_dien_thoai: '0902222222' },
    { email: 'hocvien3@gmail.com', password: 'password123', ho_ten: 'Hoàng Mai Học Viên 3', role: 'hoc_vien', so_dien_thoai: '0903333333' },
    { email: 'hocvien4@gmail.com', password: 'password123', ho_ten: 'Đinh Tuấn Học Viên 4', role: 'hoc_vien', so_dien_thoai: '0904444444' },
  ];

  const results = [];

  for (const u of usersToCreate) {
    try {
      console.log(`Đang tạo user: ${u.email}...`);
      const { data: authData, error: authErr } = await supabaseAdmin.auth.admin.createUser({
        email: u.email,
        password: u.password,
        email_confirm: true
      });

      if (authErr) {
        console.error(`Lỗi tạo auth cho ${u.email}:`, authErr.message);
        continue;
      }

      const authUserId = authData.user.id;

      if (u.role === 'admin') {
        const { error } = await supabaseAdmin.from('quan_tri_vien').insert({
          ma_qtv: 'ADMIN' + Date.now().toString(36).toUpperCase(),
          ho_ten: u.ho_ten,
          auth_id: authUserId
        });
        if (error) console.error(`Lỗi tạo profile admin:`, error);
      } else if (u.role === 'hoc_vien') {
        const ma = 'HV' + Date.now().toString(36).toUpperCase() + Math.random().toString(36).slice(2, 5).toUpperCase();
        const { error } = await supabaseAdmin.from('hoc_vien').insert({
          ma_hoc_vien: ma, ho_ten: u.ho_ten, email: u.email, so_dien_thoai: u.so_dien_thoai, auth_id: authUserId
        });
        if (error) console.error(`Lỗi tạo profile học viên:`, error);
      } else if (u.role === 'gia_su') {
        const ma = 'GS' + Date.now().toString(36).toUpperCase() + Math.random().toString(36).slice(2, 5).toUpperCase();
        const { error } = await supabaseAdmin.from('gia_su').insert({
          ma_gia_su: ma, ho_ten: u.ho_ten, auth_id: authUserId, trinh_do: u.trinh_do
        });
        if (error) console.error(`Lỗi tạo profile gia sư:`, error);
      }

      results.push({ role: u.role, email: u.email, password: u.password, ho_ten: u.ho_ten });
    } catch (e) {
      console.error(`Lỗi không mong muốn với ${u.email}:`, e.message);
    }
  }

  console.log('\n--- KẾT QUẢ ---');
  console.log(JSON.stringify(results, null, 2));
}

seedUsers();
