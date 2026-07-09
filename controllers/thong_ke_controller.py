from fastapi import APIRouter, Depends, Query
from fastapi.encoders import jsonable_encoder
from sqlalchemy.orm import Session

from database import get_db
from services import thong_ke_service

router = APIRouter(prefix="/api/thong-ke", tags=["Thống Kê & Báo Cáo"])


@router.get("/doanh-thu", summary="Doanh thu theo tháng")
def api_doanh_thu(thang: int = Query(...), nam: int = Query(...), db: Session = Depends(get_db)):
    ket_qua = thong_ke_service.doanh_thu_theo_thang(db, thang, nam)
    return {"status": "success", "data": ket_qua}


@router.get("/phong-trong", summary="Danh sách phòng đang trống")
def api_phong_trong(db: Session = Depends(get_db)):
    danh_sach = thong_ke_service.danh_sach_phong_trong(db)
    return {"status": "success", "total": len(danh_sach), "data": jsonable_encoder(danh_sach)}


@router.get("/khach-tre-han", summary="Danh sách khách đang trễ hạn đóng tiền")
def api_khach_tre_han(db: Session = Depends(get_db)):
    danh_sach = thong_ke_service.danh_sach_khach_tre_han(db)
    return {"status": "success", "total": len(danh_sach), "data": jsonable_encoder(danh_sach)}
