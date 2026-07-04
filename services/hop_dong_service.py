from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from datetime import date
import traceback
# --- 1. SỬA LẠI PHẦN IMPORT Ở ĐÂY ---
# Chỉ đích danh: Từ thư mục models, mở file phong_tro_model, lấy class PhongTro
from models.phong_tro_model import PhongTro 

# Tương tự cho Khách Thuê và Hợp Đồng (Bạn kiểm tra lại tên file và class của bạn cho khớp nhé)
from models.khach_thue_model import KhachThue 
from models.hop_dong_model import HopDong
# ------------------------------------

def lap_hop_dong_moi(db: Session, phong_id: int, nguoi_dai_dien_id: int, ngay_bat_dau: date, ngay_ket_thuc: date, tien_coc: float):
    
    # KIỂM TRA PHÒNG
    phong = db.query(PhongTro).filter(PhongTro.id == phong_id).first()
    if not phong:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail=f"Không tìm thấy phòng trọ có ID = {phong_id}. Hãy kiểm tra lại!"
        )
        
    # SỬA LỖI 1: Đổi thành "Dang_thue" không dấu
    if phong.trang_thai == "Dang_thue":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Phòng trọ này hiện tại đã có người thuê, không thể lập thêm hợp đồng!"
        )

    # KIỂM TRA KHÁCH THUÊ
    khach_thue = db.query(KhachThue).filter(KhachThue.id == nguoi_dai_dien_id).first()
    if not khach_thue:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail=f"Không tìm thấy Khách thuê có ID = {nguoi_dai_dien_id}. Vui lòng tạo khách thuê trước!"
        )

    try:
        # TẠO HỢP ĐỒNG MỚI
        hop_dong_moi = HopDong(
            phong_id=phong_id,
            nguoi_dai_dien_id=nguoi_dai_dien_id,
            ngay_bat_dau=ngay_bat_dau,
            ngay_ket_thuc=ngay_ket_thuc,
            tien_coc=tien_coc,
            trang_thai="Con_hieu_luc"  # <--- CHÍNH XÁC LÀ CHỮ NÀY! Sửa từ "Dang_thue" thành "Con_hieu_luc"
        )
        db.add(hop_dong_moi)
        
        # ĐỔI TRẠNG THÁI PHÒNG SANG ĐANG THUÊ
        # (Giữ nguyên dòng này vì bảng phong_tro của bạn chấp nhận chữ "Dang_thue")
        phong.trang_thai = "Dang_thue" 
        
        # Lưu vào SQL Server
        db.commit()
        db.refresh(hop_dong_moi)
        
        return hop_dong_moi

    except Exception as e:
        db.rollback()
        raise e

def thanh_ly_hop_dong(db: Session, hop_dong_id: int):
    # 1. Tìm hợp đồng theo ID truyền vào
    hop_dong = db.query(HopDong).filter(HopDong.id == hop_dong_id).first()
    
    if not hop_dong:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail=f"Không tìm thấy hợp đồng với ID = {hop_dong_id}"
        )
        
    # 2. Kiểm tra xem hợp đồng này đã thanh lý từ trước chưa
    if hop_dong.trang_thai == "Da_thanh_ly":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Hợp đồng này đã được thanh lý từ trước rồi!"
        )
        
    try:
        # 3. Cập nhật trạng thái hợp đồng thành "Da_thanh_ly"
        hop_dong.trang_thai = "Da_thanh_ly"
        
        # 4. Tìm phòng trọ tương ứng nằm trong hợp đồng đó
        phong = db.query(PhongTro).filter(PhongTro.id == hop_dong.phong_id).first()
        
        if phong:
            # 5. Giải phóng phòng: Đổi trạng thái từ "Dang_thue" về lại "Trong"
            phong.trang_thai = "Trong" 
            
        # 6. Lưu mọi thay đổi vào SQL Server
        db.commit()
        db.refresh(hop_dong)
        
        return {"message": "Thanh lý hợp đồng và trả phòng thành công!", "hop_dong_id": hop_dong.id}
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail=f"Lỗi hệ thống khi thanh lý: {str(e)}"
        )   

def huy_bo_hop_dong(db: Session, hop_dong_id: int):
    """
    Logic xử lý hủy/xóa hợp đồng:
    1. Kiểm tra xem hợp đồng có tồn tại không.
    2. Tìm phòng trọ liên quan và trả trạng thái về 'Trong'.
    3. Xóa sổ hợp đồng khỏi Database.
    """
    # Bước 1: Tìm xem hợp đồng này có tồn tại trong DB không
    hd = db.query(HopDong).filter(HopDong.id == hop_dong_id).first()
    if not hd:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy hợp đồng với ID {hop_dong_id} để hủy!"
        )
    
    # Bước 2: Tìm phòng trọ đang liên kết với hợp đồng này dựa vào phong_id
    phong = db.query(PhongTro).filter(PhongTro.id == hd.phong_id).first()
    
    try:
        # Bước 3: Nếu tìm thấy phòng, cập nhật trạng thái phòng quay về 'Trong'
        if phong:
            phong.trang_thai = "Trong"
        
        # Bước 4: Ra lệnh xóa bản ghi hợp đồng
        db.delete(hd)
        
        # Bước 5: Xác nhận lưu tất cả thay đổi (Cả xóa hợp đồng & cập nhật phòng) vào Database
        db.commit()
        return True
        
    except Exception as e:
        # Nếu có bất kỳ lỗi gì xảy ra (mất kết nối, lỗi DB...), hoàn tác lại mọi thứ để an toàn dữ liệu
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Lỗi hệ thống khi hủy hợp đồng: {str(e)}"
        )
# --- 4. HÀM LẤY DANH SÁCH HỢP ĐỒNG ---
def lay_danh_sach_hop_dong(db: Session):
    try:
        # Truy vấn lấy toàn bộ dữ liệu trong bảng HopDong
        danh_sach = db.query(HopDong).all()
        return danh_sach
    except Exception as e:
        print("====== [LỖI HỆ THỐNG PHÁT SINH KHI LẤY DANH SÁCH HỢP ĐỒNG] ======")
        traceback.print_exc()
        print("================================================================")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail=f"Lỗi hệ thống khi lấy danh sách: {str(e)}"
        )