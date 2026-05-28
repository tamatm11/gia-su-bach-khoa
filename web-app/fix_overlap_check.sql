-- ============================================================
-- FIX: Thêm kiểm tra trùng lịch vào sp_chon_gia_su_va_tao_lop_va_lich
-- Chạy file này trong Supabase SQL Editor
-- ============================================================
CREATE OR REPLACE FUNCTION public.sp_chon_gia_su_va_tao_lop_va_lich(
    p_ma_lop character varying,
    p_ma_yeu_cau character varying,
    p_ma_gia_su character varying,
    p_ngay_bat_dau date,
    p_tong_so_buoi integer,
    p_list_thu integer[],
    p_list_gio_bd time without time zone[],
    p_list_gio_kt time without time zone[]
)
RETURNS void
LANGUAGE plpgsql
SET search_path TO 'public'
AS $function$
DECLARE
    i integer;
    v_ma_lich varchar(30);
    v_trung_bd time;
    v_trung_kt time;
    v_trung_thu smallint;
BEGIN
    -- Kiểm tra trùng lịch gia sư với từng slot lịch mới TRƯỚC khi tạo lớp
    IF p_list_thu IS NOT NULL THEN
        FOR i IN 1..cardinality(p_list_thu) LOOP
            IF public.fn_kiem_tra_trung_lich(
                p_ma_gia_su,
                p_list_thu[i]::smallint,
                p_list_gio_bd[i],
                p_list_gio_kt[i]
            ) THEN
                SELECT lh.thu_trong_tuan, lh.gio_bat_dau, lh.gio_ket_thuc
                INTO v_trung_thu, v_trung_bd, v_trung_kt
                FROM lich_hoc lh
                JOIN lop_hoc l ON lh.ma_lop = l.ma_lop
                WHERE l.ma_gia_su = p_ma_gia_su
                  AND lh.thu_trong_tuan = p_list_thu[i]::smallint
                  AND l.trang_thai IN ('SapMo', 'dang_hoc')
                  AND (p_list_gio_bd[i] < lh.gio_ket_thuc AND p_list_gio_kt[i] > lh.gio_bat_dau)
                LIMIT 1;

                RAISE EXCEPTION 'Trùng lịch dạy: Gia sư đã có lịch vào thứ %, từ % đến %. Vui lòng chọn khung giờ khác.',
                    v_trung_thu,
                    to_char(v_trung_bd, 'HH24:MI'),
                    to_char(v_trung_kt, 'HH24:MI');
            END IF;
        END LOOP;
    END IF;

    -- Chấp nhận gia sư
    PERFORM public.sp_chon_gia_su(p_ma_yeu_cau, p_ma_gia_su);

    -- Tạo lớp học
    PERFORM public.sp_tao_lop_hoc(p_ma_lop, p_ma_yeu_cau, p_ngay_bat_dau, p_tong_so_buoi);

    -- Tạo lịch học
    IF p_list_thu IS NOT NULL THEN
        FOR i IN 1..cardinality(p_list_thu) LOOP
            v_ma_lich := 'LH' || i || '_' || p_ma_lop;
            INSERT INTO public.lich_hoc (ma_lich, ma_lop, thu_trong_tuan, gio_bat_dau, gio_ket_thuc)
            VALUES (v_ma_lich, p_ma_lop, p_list_thu[i], p_list_gio_bd[i], p_list_gio_kt[i]);
        END LOOP;
    END IF;
END;
$function$;
