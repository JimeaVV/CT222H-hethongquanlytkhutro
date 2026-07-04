from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from database import get_db

from services import dien_nuoc_service

router = APIRouter(prefix="/api/dien-nuoc", tags=["Nghiệp Vụ Điện Nước"])

# TẠO SCHEMA NGAY TRONG FILE CONTROLLER LUÔN, KHỎI TẠO FILE MỚI
class ChiSoInput(BaseModel):
    phong_id: int
    thang: int
    nam: int
    dien_moi: int
    nuoc_moi: int
    dien_cu: int = 0
    nuoc_cu: int = 0

@router.post("/ghi-so", summary="Ghi nhận chỉ số hàng tháng")
def api_ghi_chi_so(data: ChiSoInput, db: Session = Depends(get_db)):
    # Đẩy từng biến vào hàm service
    ket_qua = dien_nuoc_service.ghi_nhan_chi_so(
        db=db,
        phong_id=data.phong_id,
        thang=data.thang,
        nam=data.nam,
        dien_moi=data.dien_moi,
        nuoc_moi=data.nuoc_moi,
        dien_cu=data.dien_cu,
        nuoc_cu=data.nuoc_cu
    )
    return {
        "status": "success",
        "message": "Đã chốt chỉ số điện nước thành công!",
        "data": ket_qua
    }