from sqlalchemy.orm import Session
from fastapi import HTTPException
import traceback

from models.dien_nuoc_model import ChiSoDienNuoc
from models.phong_tro_model import PhongTro 

def ghi_nhan_chi_so(db: Session, phong_id: int, thang: int, nam: int, dien_moi: int, nuoc_moi: int, dien_cu: int = 0, nuoc_cu: int = 0):
    
    # 1. Kiểm tra phòng
    phong = db.query(PhongTro).filter(PhongTro.id == phong_id).first()
    if not phong:
        raise HTTPException(status_code=404, detail="Không tìm thấy phòng trọ này!")
    if phong.trang_thai != "Dang_thue":
        raise HTTPException(status_code=400, detail="Phòng này đang trống, không thể ghi điện nước!")

    # 2. Kiểm tra trùng lặp
    da_ghi = db.query(ChiSoDienNuoc).filter(
        ChiSoDienNuoc.phong_id == phong_id,
        ChiSoDienNuoc.thang == thang,
        ChiSoDienNuoc.nam == nam
    ).first()
    if da_ghi:
        raise HTTPException(status_code=400, detail=f"Phòng đã chốt số tháng {thang}/{nam} rồi!")

    # 3. Tìm số tháng trước
    thang_truoc = 12 if thang == 1 else thang - 1
    nam_truoc = nam - 1 if thang == 1 else nam

    du_lieu_thang_truoc = db.query(ChiSoDienNuoc).filter(
        ChiSoDienNuoc.phong_id == phong_id,
        ChiSoDienNuoc.thang == thang_truoc,
        ChiSoDienNuoc.nam == nam_truoc
    ).first()

    # 4. Gán số cũ
    dien_cu_chuan = du_lieu_thang_truoc.dien_moi if du_lieu_thang_truoc else dien_cu
    nuoc_cu_chuan = du_lieu_thang_truoc.nuoc_moi if du_lieu_thang_truoc else nuoc_cu

    # 5. Kiểm tra logic
    if dien_moi < dien_cu_chuan or nuoc_moi < nuoc_cu_chuan:
        raise HTTPException(status_code=400, detail="Số mới không được nhỏ hơn số cũ!")

    # 6. Lưu vào Database
    try:
        ban_ghi_moi = ChiSoDienNuoc(
            phong_id=phong_id,
            thang=thang,
            nam=nam,
            dien_cu=dien_cu_chuan,
            dien_moi=dien_moi,
            nuoc_cu=nuoc_cu_chuan,
            nuoc_moi=nuoc_moi
        )
        db.add(ban_ghi_moi)
        db.commit()
        db.refresh(ban_ghi_moi)
        return ban_ghi_moi
    except Exception as e:
        db.rollback()
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Lỗi DB: {str(e)}")