from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional

from database import get_db
from services import phong_tro_service

router = APIRouter(prefix="/api/phong-tro", tags=["Quản lý Phòng Trọ"])

# Schema dùng chung cho cả Thêm và Sửa
class PhongTroSchema(BaseModel):
    ten_phong: str
    gia_phong: float
    trang_thai: Optional[str] = "Trong" 

@router.get("/")
def api_lay_danh_sach(db: Session = Depends(get_db)):
    danh_sach = phong_tro_service.lay_danh_sach_phong(db)
    return {"status": "success", "total": len(danh_sach), "data": danh_sach}

@router.post("/")
def api_them_phong(phong: PhongTroSchema, db: Session = Depends(get_db)):
    phong_moi = phong_tro_service.them_phong_moi(db, phong.ten_phong, phong.gia_phong, phong.trang_thai)
    return {"status": "success", "message": "Thêm phòng thành công!", "data": phong_moi}

@router.put("/{phong_id}")
def api_sua_phong(phong_id: int, phong: PhongTroSchema, db: Session = Depends(get_db)):
    phong_da_sua = phong_tro_service.sua_thong_tin_phong(
        db, phong_id, phong.ten_phong, phong.gia_phong, phong.trang_thai
    )
    return {"status": "success", "message": "Cập nhật thành công!", "data": phong_da_sua}

@router.delete("/{phong_id}")
def api_xoa_phong(phong_id: int, db: Session = Depends(get_db)):
    phong_tro_service.xoa_phong_tro(db, phong_id)
    return {"status": "success", "message": "Xóa phòng thành công!"}