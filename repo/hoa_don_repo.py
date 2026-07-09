from sqlalchemy.orm import Session
from datetime import date, datetime
from models.hoa_don_model import HoaDon


def tao_hoa_don(db: Session, hop_dong_id: int, thang: int, nam: int,
                 tien_phong, tien_dien, tien_nuoc, tong_tien,
                 ngay_lap: date, han_thanh_toan: date):
    hd = HoaDon(
        hop_dong_id=hop_dong_id,
        thang=thang,
        nam=nam,
        tien_phong=tien_phong,
        tien_dien=tien_dien,
        tien_nuoc=tien_nuoc,
        tien_phat_tre=0,
        tong_tien=tong_tien,
        ngay_lap=ngay_lap,
        han_thanh_toan=han_thanh_toan,
        trang_thai="Chua_thanh_toan",
    )
    db.add(hd)
    db.commit()
    db.refresh(hd)
    return hd


def lay_hoa_don_theo_id(db: Session, hoa_don_id: int):
    return db.query(HoaDon).filter(HoaDon.id == hoa_don_id).first()


def lay_hoa_don_theo_hop_dong_thang_nam(db: Session, hop_dong_id: int, thang: int, nam: int):
    return db.query(HoaDon).filter(
        HoaDon.hop_dong_id == hop_dong_id,
        HoaDon.thang == thang,
        HoaDon.nam == nam
    ).first()


def lay_tat_ca_hoa_don(db: Session):
    return db.query(HoaDon).all()


def lay_danh_sach_qua_han(db: Session, ngay_hien_tai: date = None):
    """Nghiệp vụ 4: lấy các hóa đơn CHƯA thanh toán và đã quá hạn thanh toán."""
    ngay_hien_tai = ngay_hien_tai or date.today()
    return db.query(HoaDon).filter(
        HoaDon.trang_thai == "Chua_thanh_toan",
        HoaDon.han_thanh_toan < ngay_hien_tai
    ).all()


def lay_hoa_don_theo_thang_nam(db: Session, thang: int, nam: int, trang_thai: str = None):
    """Dùng cho Nghiệp vụ 6: doanh thu theo tháng."""
    query = db.query(HoaDon).filter(HoaDon.thang == thang, HoaDon.nam == nam)
    if trang_thai:
        query = query.filter(HoaDon.trang_thai == trang_thai)
    return query.all()


def cap_nhat_thanh_toan(db: Session, hoa_don: HoaDon, tien_phat: float, tong_tien_moi: float):
    hoa_don.tien_phat_tre = tien_phat
    hoa_don.tong_tien = tong_tien_moi
    hoa_don.trang_thai = "Da_thanh_toan"
    hoa_don.ngay_thanh_toan = datetime.now()
    db.commit()
    db.refresh(hoa_don)
    return hoa_don


def cap_nhat_phat_tre(db: Session, hoa_don: HoaDon, tien_phat: float, tong_tien_moi: float):
    """Cập nhật tiền phạt mà KHÔNG đổi trạng thái (dùng khi chỉ đang xem báo cáo nợ)."""
    hoa_don.tien_phat_tre = tien_phat
    hoa_don.tong_tien = tong_tien_moi
    db.commit()
    db.refresh(hoa_don)
    return hoa_don
