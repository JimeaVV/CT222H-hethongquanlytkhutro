from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional

from database import get_db
from services import khach_thue_service

router = APIRouter(prefix="/api/khach-thue", tags=["Quản lý Khách Thuê"])

class KhachThueSchema(BaseModel):
    ho_ten: str
    cccd: str
    sdt: Optional[str] = None  # Đồng bộ biến sdt nhận từ client
    que_quan: Optional[str] = None

@router.get("/")
def api_lay_danh_sach_khach(db: Session = Depends(get_db)):
    danh_sach = khach_thue_service.lay_danh_sach_khach(db)
    return {"status": "success", "total": len(danh_sach), "data": danh_sach}

@router.post("/")
def api_them_khach(khach: KhachThueSchema, db: Session = Depends(get_db)):
    khach_moi = khach_thue_service.them_khach_moi(
        db, khach.ho_ten, khach.cccd, khach.sdt, khach.que_quan
    )
    return {"status": "success", "message": "Thêm khách thuê thành công!", "data": khach_moi}

@router.put("/{khach_id}")
def api_sua_khach(khach_id: int, khach: KhachThueSchema, db: Session = Depends(get_db)):
    khach_da_sua = khach_thue_service.sua_thong_tin_khach(
        db, khach_id, khach.ho_ten, khach.cccd, khach.sdt, khach.que_quan
    )
    return {"status": "success", "message": "Cập nhật thông tin thành công!", "data": khach_da_sua}

@router.delete("/{khach_id}")
def api_xoa_khach(khach_id: int, db: Session = Depends(get_db)):
    khach_thue_service.xoa_khach_hang(db, khach_id)
    return {"status": "success", "message": "Xóa khách thuê thành công!"}