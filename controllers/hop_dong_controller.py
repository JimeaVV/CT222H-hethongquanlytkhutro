from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.encoders import jsonable_encoder  # <--- 1. THÊM IMPORT NÀY VÀO
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import date
from database import get_db
from services import hop_dong_service

router = APIRouter(prefix="/api/hop-dong", tags=["Quản lý Hợp Đồng"])

class HopDongSchema(BaseModel):
    phong_id: int
    nguoi_dai_dien_id: int 
    ngay_bat_dau: date
    ngay_ket_thuc: date
    tien_coc: float

# --- API LẤY DANH SÁCH HỢP ĐỒNG ---
@router.get("/")
def api_lay_danh_sach_hop_dong(db: Session = Depends(get_db)):
    danh_sach = hop_dong_service.lay_danh_sach_hop_dong(db)
    return {"status": "success", "data": jsonable_encoder(danh_sach)} # Bọc jsonable_encoder

# --- API LẬP HỢP ĐỒNG MỚI ---
@router.post("/")
def api_lap_hop_dong(hd: HopDongSchema, db: Session = Depends(get_db)):
    try:
        hop_dong_moi = hop_dong_service.lap_hop_dong_moi(
            db, hd.phong_id, hd.nguoi_dai_dien_id, hd.ngay_bat_dau, hd.ngay_ket_thuc, hd.tien_coc
        )
        # 2. SỬA Ở ĐÂY: Bọc jsonable_encoder quanh biến hop_dong_moi
        return {
            "status": "success", 
            "message": "Lập hợp đồng thành công!", 
            "data": jsonable_encoder(hop_dong_moi) 
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Lỗi hệ thống khi lập hợp đồng: {str(e)}"
        )

# --- API THANH LÝ HỢP ĐỒNG ---
@router.put("/{hop_dong_id}/thanh-ly", summary="Thanh lý hợp đồng")
def api_thanh_ly_hop_dong(hop_dong_id: int, db: Session = Depends(get_db)):
    hd_da_thanh_ly = hop_dong_service.thanh_ly_hop_dong(db, hop_dong_id)
    return {
        "status": "success", 
        "message": "Thanh lý hợp đồng thành công! Phòng đã được chuyển về trạng thái Trống.", 
        "data": jsonable_encoder(hd_da_thanh_ly) # Bọc jsonable_encoder cho đồng bộ
    }

# --- API HỦY HỢP ĐỒNG ---
@router.delete("/{hop_dong_id}")
def api_huy_hop_dong(hop_dong_id: int, db: Session = Depends(get_db)):
    hop_dong_service.huy_bo_hop_dong(db, hop_dong_id)
    return {"status": "success", "message": "Xóa/Hủy hợp đồng thành công! Phòng liên quan đã được trả lại trạng thái Trống."}