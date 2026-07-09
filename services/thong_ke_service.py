from sqlalchemy.orm import Session
from datetime import date

from repo import hoa_don_repo, phong_tro_repo
from services import hoa_don_service
from models.hop_dong_model import HopDong
from models.khach_thue_model import KhachThue


def doanh_thu_theo_thang(db: Session, thang: int, nam: int):
    """Tổng doanh thu = tổng tong_tien các hóa đơn ĐÃ thanh toán trong tháng/năm đó."""
    hoa_don_da_tt = hoa_don_repo.lay_hoa_don_theo_thang_nam(db, thang, nam, trang_thai="Da_thanh_toan")
    tong_doanh_thu = sum(float(hd.tong_tien) for hd in hoa_don_da_tt)
    so_hoa_don_chua_tt = len(hoa_don_repo.lay_hoa_don_theo_thang_nam(db, thang, nam, trang_thai="Chua_thanh_toan"))

    return {
        "thang": thang,
        "nam": nam,
        "so_hoa_don_da_thu": len(hoa_don_da_tt),
        "so_hoa_don_con_no": so_hoa_don_chua_tt,
        "tong_doanh_thu": tong_doanh_thu,
    }


def danh_sach_phong_trong(db: Session):
    tat_ca_phong = phong_tro_repo.lay_tat_ca_phong(db)
    return [p for p in tat_ca_phong if p.trang_thai == "Trong"]


def danh_sach_khach_tre_han(db: Session, ngay_hien_tai: date = None):
    """Ghép danh sách nợ (Nghiệp vụ 4) với thông tin khách thuê đứng tên hợp đồng."""
    danh_sach_no = hoa_don_service.lay_danh_sach_no(db, ngay_hien_tai)

    ket_qua = []
    for dong in danh_sach_no:
        hop_dong = db.query(HopDong).filter(HopDong.id == dong["hop_dong_id"]).first()
        khach = db.query(KhachThue).filter(KhachThue.id == hop_dong.nguoi_dai_dien_id).first() if hop_dong else None
        ket_qua.append({
            **dong,
            "khach_thue": khach.ho_ten if khach else None,
            "sdt": khach.sdt if khach else None,
        })
    return ket_qua
