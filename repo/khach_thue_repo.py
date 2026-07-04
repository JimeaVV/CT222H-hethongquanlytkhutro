from sqlalchemy.orm import Session
from models.khach_thue_model import KhachThue

def lay_tat_ca_khach(db: Session):
    return db.query(KhachThue).all()

def lay_khach_theo_id(db: Session, khach_id: int):
    return db.query(KhachThue).filter(KhachThue.id == khach_id).first()

def lay_khach_theo_cccd(db: Session, cccd: str):
    return db.query(KhachThue).filter(KhachThue.cccd == cccd).first()

def tao_khach_thue(db: Session, ho_ten: str, cccd: str, sdt: str, que_quan: str):
    khach_moi = KhachThue(ho_ten=ho_ten, cccd=cccd, sdt=sdt, que_quan=que_quan)
    db.add(khach_moi)
    db.commit()
    db.refresh(khach_moi)
    return khach_moi

def cap_nhat_khach_thue(db: Session, khach_id: int, ho_ten: str, cccd: str, sdt: str, que_quan: str):
    khach = lay_khach_theo_id(db, khach_id)
    if khach:
        khach.ho_ten = ho_ten
        khach.cccd = cccd
        khach.sdt = sdt
        khach.que_quan = que_quan
        db.commit()
        db.refresh(khach)
    return khach

def xoa_khach_thue(db: Session, khach_id: int):
    khach = lay_khach_theo_id(db, khach_id)
    if khach:
        db.delete(khach)
        db.commit()
    return khach