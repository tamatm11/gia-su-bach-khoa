USE GiaSuBachKhoa;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

SET NOCOUNT ON;

PRINT N'========================================================================'
PRINT N'DEMO: LUỒNG HOẠT ĐỘNG VÀ XUNG ĐỘT LỊCH HỌC TRONG HỆ THỐNG GIA SƯ'
PRINT N'========================================================================'

-- Sửa lỗi trigger tạo mã thông báo dài hơn 30 ký tự (ma_thong_bao là varchar(30))
GO
ALTER TRIGGER tr_ung_tuyen_notify ON ung_tuyen AFTER INSERT AS
BEGIN
    INSERT INTO thong_bao (ma_thong_bao, ma_hoc_vien, loai_thong_bao, tieu_de, noi_dung, ma_yeu_cau)
    SELECT
        LEFT('TB_' + REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 30),
        yc.ma_hoc_vien,
        'ung_tuyen',
        N'Gia sư ' + gs.ho_ten + N' đã ứng tuyển vào yêu cầu ' + i.ma_yeu_cau,
        N'Gia sư ' + gs.ho_ten + N' đã ứng tuyển. Xem chi tiết và phản hồi trong mục "Yêu cầu của tôi".',
        i.ma_yeu_cau
    FROM inserted i
    JOIN yeu_cau_lop yc ON i.ma_yeu_cau = yc.ma_yeu_cau
    JOIN gia_su gs      ON i.ma_gia_su  = gs.ma_gia_su;
END;
GO
ALTER TRIGGER tr_yeu_cau_chon_gia_su ON yeu_cau_lop AFTER UPDATE AS
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM inserted i
        JOIN deleted d ON i.ma_yeu_cau = d.ma_yeu_cau
        WHERE d.ma_gia_su_duoc_chon IS NULL AND i.ma_gia_su_duoc_chon IS NOT NULL
    ) RETURN;

    -- thông báo cho gia sư được chọn
    INSERT INTO thong_bao (ma_thong_bao, ma_gia_su, loai_thong_bao, tieu_de, noi_dung, ma_yeu_cau)
    SELECT
        LEFT('TB_' + REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 30),
        i.ma_gia_su_duoc_chon,
        'duoc_chon',
        N'Bạn đã được chọn cho yêu cầu ' + i.ma_yeu_cau,
        N'Học viên ' + hv.ho_ten + N' đã chọn bạn. Lớp học sẽ sớm được tạo.',
        i.ma_yeu_cau
    FROM inserted i
    JOIN deleted d  ON i.ma_yeu_cau  = d.ma_yeu_cau
    JOIN hoc_vien hv ON i.ma_hoc_vien = hv.ma_hoc_vien
    WHERE d.ma_gia_su_duoc_chon IS NULL AND i.ma_gia_su_duoc_chon IS NOT NULL;

    -- thông báo cho các gia sư bị từ chối
    INSERT INTO thong_bao (ma_thong_bao, ma_gia_su, loai_thong_bao, tieu_de, noi_dung, ma_yeu_cau)
    SELECT
        LEFT('TB_' + REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 30),
        ut.ma_gia_su,
        'tu_choi',
        N'Yêu cầu ' + i.ma_yeu_cau + N' đã có gia sư được chọn',
        N'Học viên ' + hv.ho_ten + N' đã chọn gia sư khác cho yêu cầu này.',
        i.ma_yeu_cau
    FROM inserted i
    JOIN deleted   d   ON i.ma_yeu_cau  = d.ma_yeu_cau
    JOIN hoc_vien  hv  ON i.ma_hoc_vien = hv.ma_hoc_vien
    JOIN ung_tuyen ut  ON ut.ma_yeu_cau = i.ma_yeu_cau
    WHERE d.ma_gia_su_duoc_chon IS NULL
      AND i.ma_gia_su_duoc_chon IS NOT NULL
      AND ut.ma_gia_su   != i.ma_gia_su_duoc_chon
      AND ut.trang_thai  = 'pending';

    -- cập nhật trạng thái
    UPDATE ut
    SET trang_thai = 'rejected', ngay_xu_ly = SYSDATETIME()
    FROM ung_tuyen ut
    JOIN inserted i ON ut.ma_yeu_cau = i.ma_yeu_cau
    JOIN deleted  d ON i.ma_yeu_cau  = d.ma_yeu_cau
    WHERE d.ma_gia_su_duoc_chon IS NULL
      AND i.ma_gia_su_duoc_chon IS NOT NULL
      AND ut.ma_gia_su   != i.ma_gia_su_duoc_chon
      AND ut.trang_thai  = 'pending';

    UPDATE ut
    SET trang_thai = 'accepted', ngay_xu_ly = SYSDATETIME()
    FROM ung_tuyen ut
    JOIN inserted i ON ut.ma_yeu_cau = i.ma_yeu_cau
    JOIN deleted  d ON i.ma_yeu_cau  = d.ma_yeu_cau
    WHERE d.ma_gia_su_duoc_chon IS NULL
      AND i.ma_gia_su_duoc_chon IS NOT NULL
      AND ut.ma_gia_su = i.ma_gia_su_duoc_chon;
END;
GO

-- [Cleanup Data Mẫu (nếu chạy lại nhiều lần)]
BEGIN TRY
    DELETE FROM lich_hoc WHERE ma_lop IN ('LOP_DEMO1', 'LOP_DEMO2', 'LOP_DEMO3');
    DELETE FROM buoi_hoc WHERE ma_lop IN ('LOP_DEMO1', 'LOP_DEMO2', 'LOP_DEMO3');
    DELETE FROM lop_hoc_mon WHERE ma_lop IN ('LOP_DEMO1', 'LOP_DEMO2', 'LOP_DEMO3');
    DELETE FROM dang_ky WHERE ma_lop IN ('LOP_DEMO1', 'LOP_DEMO2', 'LOP_DEMO3');
    DELETE FROM thong_bao WHERE ma_yeu_cau IN ('YC_DEMO1', 'YC_DEMO2', 'YC_DEMO3');
    DELETE FROM lop_hoc WHERE ma_lop IN ('LOP_DEMO1', 'LOP_DEMO2', 'LOP_DEMO3');
    DELETE FROM ung_tuyen WHERE ma_yeu_cau IN ('YC_DEMO1', 'YC_DEMO2', 'YC_DEMO3');
    DELETE FROM yeu_cau_mon WHERE ma_yeu_cau IN ('YC_DEMO1', 'YC_DEMO2', 'YC_DEMO3');
    DELETE FROM yeu_cau_lop WHERE ma_yeu_cau IN ('YC_DEMO1', 'YC_DEMO2', 'YC_DEMO3');
END TRY
BEGIN CATCH
    -- Bỏ qua lỗi khóa ngoại khi xóa
END CATCH;

PRINT N'------------------------------------------------------------------------'
PRINT N'KỊCH BẢN 1: Học viên 1 tạo yêu cầu, nhiều gia sư ứng tuyển, chọn GS 1'
PRINT N'------------------------------------------------------------------------'

-- 1. HV_D01 (Học viên 1) tạo yêu cầu
EXEC sp_tao_yeu_cau_lop 
    @p_ma_yeu_cau = 'YC_DEMO1', @p_ma_hoc_vien = 'HV_D01', @p_tieu_de = N'Tìm gia sư Toán',
    @p_mo_ta = N'Cần học tối thứ 2, 4', @p_tien_hoc_phi = 200000, @p_dia_chi = N'Q1', 
    @p_hinh_thuc_hoc = 'offline', @p_so_buoi_tuan = 2, @p_thoi_gian_mong_muon = N'Tối T2, T4';

-- 2. GS_D01, GS_D02, GS_D03 cùng ứng tuyển vào YC_DEMO1
EXEC sp_ung_tuyen 'UT_DEMO1_1', 'YC_DEMO1', 'GS_D01', 200000, N'Mình dạy được nhé';
EXEC sp_ung_tuyen 'UT_DEMO1_2', 'YC_DEMO1', 'GS_D02', 200000, N'Mình có kinh nghiệm';
EXEC sp_ung_tuyen 'UT_DEMO1_3', 'YC_DEMO1', 'GS_D03', 200000, N'Mình rất nhiệt tình';

PRINT N'>> Trạng thái ứng tuyển TRƯỚC khi Học viên chọn:';
SELECT ma_ung_tuyen, ma_gia_su, trang_thai FROM ung_tuyen WHERE ma_yeu_cau = 'YC_DEMO1';

-- 3. HV_D01 chọn GS_D01 (Lúc này trigger sẽ update trạng thái các GS khác thành rejected)
EXEC sp_chon_gia_su 'YC_DEMO1', 'GS_D01';

PRINT N'';
PRINT N'>> Trạng thái ứng tuyển SAU khi chọn (GS_D01 accepted, GS_D02 & GS_D03 rejected):';
SELECT ma_ung_tuyen, ma_gia_su, trang_thai FROM ung_tuyen WHERE ma_yeu_cau = 'YC_DEMO1';

-- Xem thông báo gửi đến các gia sư
PRINT N'>> Xem các thông báo gửi đến các Gia sư sau khi chọn:';
SELECT ma_gia_su, tieu_de, noi_dung FROM thong_bao WHERE ma_yeu_cau = 'YC_DEMO1' AND ma_gia_su IS NOT NULL;

-- 4. Tạo lớp học và lịch học cố định (Thứ 2: 18:00 - 20:00)
EXEC sp_tao_lop_hoc 'LOP_DEMO1', 'YC_DEMO1', '2026-06-01', 10;
INSERT INTO lich_hoc (ma_lich, ma_lop, thu_trong_tuan, gio_bat_dau, gio_ket_thuc)
VALUES ('LICH_DEMO1_T2', 'LOP_DEMO1', 2, '18:00', '20:00');

PRINT N'>> Đã tạo Lớp 1 và Lịch học: LOP_DEMO1, GS_D01, Thứ 2 (18:00 - 20:00)';


PRINT N'';
PRINT N'------------------------------------------------------------------------'
PRINT N'KỊCH BẢN 2: HV_D02 tạo lớp học mới, trùng giờ GS_D01 đang dạy'
PRINT N'------------------------------------------------------------------------'
-- 1. HV_D02 (Học viên 2) tạo yêu cầu mới
EXEC sp_tao_yeu_cau_lop 
    @p_ma_yeu_cau = 'YC_DEMO2', @p_ma_hoc_vien = 'HV_D02', @p_tieu_de = N'Tìm gia sư Lý',
    @p_mo_ta = N'Cần học tối thứ 2', @p_tien_hoc_phi = 200000, @p_dia_chi = N'Q2', 
    @p_hinh_thuc_hoc = 'offline', @p_so_buoi_tuan = 1, @p_thoi_gian_mong_muon = N'Tối T2, 19h-21h';

-- 2. GS_D01 (Gia sư 1) ứng tuyển và HV_D02 chọn GS_D01
EXEC sp_ung_tuyen 'UT_DEMO2_1', 'YC_DEMO2', 'GS_D01', 200000, N'Mình nhận lớp này';
EXEC sp_chon_gia_su 'YC_DEMO2', 'GS_D01';
EXEC sp_tao_lop_hoc 'LOP_DEMO2', 'YC_DEMO2', '2026-06-01', 10;

-- Tắt XACT_ABORT để đảm bảo TRY...CATCH bắt được lỗi của trigger (sp_tao_lop_hoc đã bật nó lên)
SET XACT_ABORT OFF;

-- 3. Cố gắng thêm lịch học trùng giờ với lớp 1 (Thứ 2, 19:00 - 21:00 giao với 18:00 - 20:00)
PRINT N'>> Thử gán lịch học Thứ 2 (19:00 - 21:00) cho Lớp 2...';
BEGIN TRY
    INSERT INTO lich_hoc (ma_lich, ma_lop, thu_trong_tuan, gio_bat_dau, gio_ket_thuc)
    VALUES ('LICH_DEMO2_T2', 'LOP_DEMO2', 2, '19:00', '21:00');
    PRINT N'[LỖI LOGIC] Dữ liệu được insert thành công dù bị trùng lịch!';
END TRY
BEGIN CATCH
    PRINT N'[THÀNH CÔNG] Đã bị chặn bởi Trigger (Lỗi do trùng lịch):';
    PRINT N' -> ' + ERROR_MESSAGE();
END CATCH;


PRINT N'';
PRINT N'------------------------------------------------------------------------'
PRINT N'KỊCH BẢN 3: HV_D03 tạo lớp KHÔNG trùng giờ GS_D01 đang dạy'
PRINT N'------------------------------------------------------------------------'
-- 1. HV_D03 (Học viên 3) tạo yêu cầu
EXEC sp_tao_yeu_cau_lop 
    @p_ma_yeu_cau = 'YC_DEMO3', @p_ma_hoc_vien = 'HV_D03', @p_tieu_de = N'Tìm gia sư Anh',
    @p_mo_ta = N'Cần học tối thứ 3', @p_tien_hoc_phi = 200000, @p_dia_chi = N'Q3', 
    @p_hinh_thuc_hoc = 'offline', @p_so_buoi_tuan = 1, @p_thoi_gian_mong_muon = N'Tối T3, 18h-20h';

-- 2. GS_D01 ứng tuyển & HV_D03 chọn GS_D01
EXEC sp_ung_tuyen 'UT_DEMO3_1', 'YC_DEMO3', 'GS_D01', 200000, N'Mình nhận lớp này';
EXEC sp_chon_gia_su 'YC_DEMO3', 'GS_D01';
EXEC sp_tao_lop_hoc 'LOP_DEMO3', 'YC_DEMO3', '2026-06-02', 10;

-- 3. Thêm lịch học hợp lệ (Thứ 3, 18:00 - 20:00)
BEGIN TRY
    INSERT INTO lich_hoc (ma_lich, ma_lop, thu_trong_tuan, gio_bat_dau, gio_ket_thuc)
    VALUES ('LICH_DEMO3_T3', 'LOP_DEMO3', 3, '18:00', '20:00');
    PRINT N'>> [THÀNH CÔNG] Đã tạo Lớp 3 và Lịch học HỢP LỆ: LOP_DEMO3, GS_D01, Thứ 3 (18:00 - 20:00)';
END TRY
BEGIN CATCH
    PRINT N'[LỖI LOGIC] Không thể thêm lịch học hợp lệ!';
    PRINT N' -> ' + ERROR_MESSAGE();
END CATCH;


PRINT N'';
PRINT N'------------------------------------------------------------------------'
PRINT N'KỊCH BẢN 4: Thêm lịch học mới vào lớp 1 bị trùng với lớp 3 của GS_D01'
PRINT N'------------------------------------------------------------------------'
PRINT N'>> Thử thêm lịch Thứ 3 (19:00 - 21:00) vào Lớp 1 (Sẽ trùng lịch Lớp 3 ở trên)...';
BEGIN TRY
    INSERT INTO lich_hoc (ma_lich, ma_lop, thu_trong_tuan, gio_bat_dau, gio_ket_thuc)
    VALUES ('LICH_DEMO1_T3', 'LOP_DEMO1', 3, '19:00', '21:00');
    PRINT N'[LỖI LOGIC] Dữ liệu được insert thành công dù bị trùng lịch!';
END TRY
BEGIN CATCH
    PRINT N'[THÀNH CÔNG] Đã bị chặn bởi Trigger (Lỗi do trùng lịch):';
    PRINT N' -> ' + ERROR_MESSAGE();
END CATCH;

PRINT N'========================================================================'
PRINT N'KẾT THÚC DEMO'
PRINT N'========================================================================'
GO
