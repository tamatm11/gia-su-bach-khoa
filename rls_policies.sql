-- ============================================================
-- RLS POLICIES & INDEXES CHO GIA SƯ BÁCH KHOA PLATFORM
-- Chạy file này trong Supabase SQL Editor
-- ============================================================

-- 1. Bật RLS trên các bảng chính (nếu chưa bật)
ALTER TABLE IF EXISTS hoc_vien ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS gia_su ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS yeu_cau_lop ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS ung_tuyen ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS lop_hoc ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 2. POLICIES CHO HOC_VIEN
-- ============================================================

-- Cho phép insert (đăng ký tài khoản mới)
DROP POLICY IF EXISTS "Cho phép đăng ký học viên" ON hoc_vien;
CREATE POLICY "Cho phép đăng ký học viên" ON hoc_vien
  FOR INSERT WITH CHECK (true);

-- Cho phép học viên đọc thông tin của chính mình
DROP POLICY IF EXISTS "Học viên đọc thông tin của mình" ON hoc_vien;
CREATE POLICY "Học viên đọc thông tin của mình" ON hoc_vien
  FOR SELECT USING (auth.uid() = auth_id);

-- Cho phép học viên cập nhật thông tin của mình
DROP POLICY IF EXISTS "Học viên cập nhật thông tin của mình" ON hoc_vien;
CREATE POLICY "Học viên cập nhật thông tin của mình" ON hoc_vien
  FOR UPDATE USING (auth.uid() = auth_id);

-- Cho phép tất cả đọc thông tin cơ bản của học viên (cho gia sư xem)
DROP POLICY IF EXISTS "Đọc thông tin cơ bản học viên" ON hoc_vien;
CREATE POLICY "Đọc thông tin cơ bản học viên" ON hoc_vien
  FOR SELECT USING (true);

-- ============================================================
-- 3. POLICIES CHO GIA_SU
-- ============================================================

-- Cho phép insert (đăng ký tài khoản mới)
DROP POLICY IF EXISTS "Cho phép đăng ký gia sư" ON gia_su;
CREATE POLICY "Cho phép đăng ký gia sư" ON gia_su
  FOR INSERT WITH CHECK (true);

-- Cho phép gia sư đọc thông tin của chính mình
DROP POLICY IF EXISTS "Gia sư đọc thông tin của mình" ON gia_su;
CREATE POLICY "Gia sư đọc thông tin của mình" ON gia_su
  FOR SELECT USING (auth.uid() = auth_id);

-- Cho phép gia sư cập nhật thông tin của mình
DROP POLICY IF EXISTS "Gia sư cập nhật thông tin của mình" ON gia_su;
CREATE POLICY "Gia sư cập nhật thông tin của mình" ON gia_su
  FOR UPDATE USING (auth.uid() = auth_id);

-- Cho phép tất cả đọc thông tin cơ bản của gia sư (cho học viên xem)
DROP POLICY IF EXISTS "Đọc thông tin cơ bản gia sư" ON gia_su;
CREATE POLICY "Đọc thông tin cơ bản gia sư" ON gia_su
  FOR SELECT USING (true);

-- ============================================================
-- 4. POLICIES CHO YEU_CAU_LOP
-- ============================================================

DROP POLICY IF EXISTS "Tất cả đọc yêu cầu đang mở" ON yeu_cau_lop;
CREATE POLICY "Tất cả đọc yêu cầu đang mở" ON yeu_cau_lop
  FOR SELECT USING (trang_thai IN ('open', 'approved') OR ma_hoc_vien IN (SELECT ma_hoc_vien FROM hoc_vien WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS "Học viên tạo yêu cầu" ON yeu_cau_lop;
CREATE POLICY "Học viên tạo yêu cầu" ON yeu_cau_lop
  FOR INSERT WITH CHECK (ma_hoc_vien IN (SELECT ma_hoc_vien FROM hoc_vien WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS "Học viên cập nhật yêu cầu của mình" ON yeu_cau_lop;
CREATE POLICY "Học viên cập nhật yêu cầu của mình" ON yeu_cau_lop
  FOR UPDATE USING (ma_hoc_vien IN (SELECT ma_hoc_vien FROM hoc_vien WHERE auth_id = auth.uid()));

-- ============================================================
-- 5. POLICIES CHO UNG_TUYEN
-- ============================================================

DROP POLICY IF EXISTS "Gia sư tạo ứng tuyển" ON ung_tuyen;
CREATE POLICY "Gia sư tạo ứng tuyển" ON ung_tuyen
  FOR INSERT WITH CHECK (ma_gia_su IN (SELECT ma_gia_su FROM gia_su WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS "Xem ứng tuyển liên quan" ON ung_tuyen;
CREATE POLICY "Xem ứng tuyển liên quan" ON ung_tuyen
  FOR SELECT USING (
    ma_gia_su IN (SELECT ma_gia_su FROM gia_su WHERE auth_id = auth.uid())
    OR ma_yeu_cau IN (SELECT ma_yeu_cau FROM yeu_cau_lop WHERE ma_hoc_vien IN (SELECT ma_hoc_vien FROM hoc_vien WHERE auth_id = auth.uid()))
  );

-- ============================================================
-- 6. POLICIES CHO LOP_HOC
-- ============================================================

DROP POLICY IF EXISTS "Xem lớp học của mình" ON lop_hoc;
CREATE POLICY "Xem lớp học của mình" ON lop_hoc
  FOR SELECT USING (
    ma_hoc_vien IN (SELECT ma_hoc_vien FROM hoc_vien WHERE auth_id = auth.uid())
    OR ma_gia_su IN (SELECT ma_gia_su FROM gia_su WHERE auth_id = auth.uid())
  );
