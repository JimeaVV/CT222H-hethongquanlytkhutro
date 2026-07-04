from sqlalchemy.orm import Session
from models.hop_dong_model import HopDong
from datetime import date

def lay_tat_ca_hop_dong(db: Session):
    return db.query(HopDong).all()

def lay_hop_dong_theo_id(db: Session, hop_dong_id: int):
    return db.query(HopDong).filter(HopDong.id == hop_dong_id).first()

def tao_hop_dong(db: Session, phong_id: int, nguoi_dai_dien_id: int, ngay_bat_dau: date, ngay_ket_thuc: date, tien_coc: float):
    hop_dong_moi = HopDong(
        phong_id=phong_id,
        nguoi_dai_dien_id=nguoi_dai_dien_id,
        ngay_bat_dau=ngay_bat_dau,
        ngay_ket_thuc=ngay_ket_thuc,
        tien_coc=tien_coc,
        trang_thai="Hieu_luc" # Khi mới lập, hợp đồng mặc định có Hiệu lực
    )
    db.add(hop_dong_moi)
    db.commit()
    db.refresh(hop_dong_moi)
    return hop_dong_moi

def xoa_hop_dong(db: Session, hop_dong: HopDong):
    db.delete(hop_dong)
    db.commit()