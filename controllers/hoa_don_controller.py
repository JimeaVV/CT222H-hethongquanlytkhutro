from fastapi import APIRouter, Depends
from fastapi.encoders import jsonable_encoder
from sqlalchemy.orm import Session
from pydantic import BaseModel

from database import get_db
from services import hoa_don_service

router = APIRouter(prefix="/api/hoa-don", tags=["Quản lý Hóa Đơn & Công Nợ"])


class HoaDonInput(BaseModel):
    hop_dong_id: int
    thang: int
    nam: int


# --- NGHIỆP VỤ 5: LẬP HÓA ĐƠN THÁNG ---
@router.post("/lap")
def api_lap_hoa_don(data: HoaDonInput, db: Session = Depends(get_db)):
    hoa_don = hoa_don_service.tao_hoa_don_thang(db, data.hop_dong_id, data.thang, data.nam)
    return {
        "status": "success",
        "message": "Lập hóa đơn thành công!",
        "data": jsonable_encoder(hoa_don)
    }


@router.get("/")
def api_danh_sach_hoa_don(db: Session = Depends(get_db)):
    danh_sach = hoa_don_service.lay_danh_sach_hoa_don(db)
    return {"status": "success", "total": len(danh_sach), "data": jsonable_encoder(danh_sach)}


# --- NGHIỆP VỤ 5: THANH TOÁN HÓA ĐƠN ---
@router.put("/{hoa_don_id}/thanh-toan")
def api_thanh_toan(hoa_don_id: int, db: Session = Depends(get_db)):
    hoa_don = hoa_don_service.thanh_toan_hoa_don(db, hoa_don_id)
    return {
        "status": "success",
        "message": "Thanh toán hóa đơn thành công!",
        "data": jsonable_encoder(hoa_don)
    }


# --- NGHIỆP VỤ 4: CẢNH BÁO NỢ & PHẠT TRỄ HẠN ---
@router.get("/no-qua-han", summary="Danh sách phòng đang nợ + tiền phạt trễ hạn")
def api_danh_sach_no(db: Session = Depends(get_db)):
    danh_sach = hoa_don_service.lay_danh_sach_no(db)
    return {"status": "success", "total": len(danh_sach), "data": jsonable_encoder(danh_sach)}
