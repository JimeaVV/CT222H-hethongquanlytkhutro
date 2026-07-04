from sqlalchemy.orm import Session
from models.phong_tro_model import PhongTro

def lay_tat_ca_phong(db: Session):
    return db.query(PhongTro).all()

def lay_phong_theo_id(db: Session, phong_id: int):
    # Tìm phòng theo ID
    return db.query(PhongTro).filter(PhongTro.id == phong_id).first()

def tao_phong(db: Session, ten_phong: str, gia_phong: float, trang_thai: str = "Trong"):
    phong_moi = PhongTro(ten_phong=ten_phong, gia_phong=gia_phong, trang_thai=trang_thai)
    db.add(phong_moi)
    db.commit()
    db.refresh(phong_moi)
    return phong_moi

def cap_nhat_phong(db: Session, phong_id: int, ten_phong: str, gia_phong: float, trang_thai: str):
    phong = lay_phong_theo_id(db, phong_id)
    if phong:
        phong.ten_phong = ten_phong
        phong.gia_phong = gia_phong
        phong.trang_thai = trang_thai
        db.commit()
        db.refresh(phong)
    return phong

def xoa_phong(db: Session, phong_id: int):
    phong = lay_phong_theo_id(db, phong_id)
    if phong:
        db.delete(phong)
        db.commit()
    return phong