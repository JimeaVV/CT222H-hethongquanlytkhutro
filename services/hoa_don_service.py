from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from datetime import date, timedelta

from repo import hoa_don_repo
from models.hop_dong_model import HopDong
from models.phong_tro_model import PhongTro
from models.dien_nuoc_model import ChiSoDienNuoc

# Đơn giá điện/nước mặc định (đồng/kwh, đồng/khối) - có thể sửa thành cấu hình DB sau này
DON_GIA_DIEN = 3500
DON_GIA_NUOC = 15000

SO_NGAY_HAN_MAC_DINH = 10      # sau 10 ngày kể từ ngày lập phải thanh toán
SO_NGAY_AN_HAN = 5             # trễ hạn trong vòng 5 ngày thì CHƯA bị phạt
MUC_PHAT_MOI_NGAY = 50000      # phạt cố định 50k/ngày trễ (tính từ ngày hết ân hạn)


# ================== NGHIỆP VỤ 5: LẬP HÓA ĐƠN (Phòng + Điện + Nước) ==================
def tao_hoa_don_thang(db: Session, hop_dong_id: int, thang: int, nam: int,
                       so_ngay_han: int = SO_NGAY_HAN_MAC_DINH):
    # 1. Kiểm tra hợp đồng
    hop_dong = db.query(HopDong).filter(HopDong.id == hop_dong_id).first()
    if not hop_dong:
        raise HTTPException(status.HTTP_404_NOT_FOUND, f"Không tìm thấy hợp đồng ID={hop_dong_id}")

    # 2. Không cho lập trùng hóa đơn cùng tháng/năm cho cùng hợp đồng
    da_co = hoa_don_repo.lay_hoa_don_theo_hop_dong_thang_nam(db, hop_dong_id, thang, nam)
    if da_co:
        raise HTTPException(status.HTTP_400_BAD_REQUEST,
                             f"Hợp đồng #{hop_dong_id} đã có hóa đơn tháng {thang}/{nam} rồi!")

    # 3. Lấy giá phòng
    phong = db.query(PhongTro).filter(PhongTro.id == hop_dong.phong_id).first()
    if not phong:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy phòng trọ liên kết với hợp đồng này")
    tien_phong = float(phong.gia_phong)

    # 4. Lấy chỉ số điện nước đã chốt của tháng đó -> tính tiền
    chi_so = db.query(ChiSoDienNuoc).filter(
        ChiSoDienNuoc.phong_id == phong.id,
        ChiSoDienNuoc.thang == thang,
        ChiSoDienNuoc.nam == nam
    ).first()
    if not chi_so:
        raise HTTPException(status.HTTP_400_BAD_REQUEST,
                             f"Phòng chưa chốt chỉ số điện nước tháng {thang}/{nam}, hãy ghi số trước!")

    so_dien_tieu_thu = chi_so.dien_moi - chi_so.dien_cu
    so_nuoc_tieu_thu = chi_so.nuoc_moi - chi_so.nuoc_cu
    tien_dien = so_dien_tieu_thu * DON_GIA_DIEN
    tien_nuoc = so_nuoc_tieu_thu * DON_GIA_NUOC

    # 5. Tổng tiền (chưa có phạt vì hóa đơn vừa lập, chưa thể trễ hạn)
    tong_tien = tien_phong + tien_dien + tien_nuoc

    ngay_lap = date.today()

    # Hạn thanh toán gắn theo KỲ HÓA ĐƠN (tháng/năm ghi trong hóa đơn),
    # không phụ thuộc ngày bạn bấm lập hóa đơn -> dễ test và đúng nghiệp vụ hơn:
    # hạn = ngày (so_ngay_han) của tháng kế tiếp sau kỳ hóa đơn.
    thang_han = thang + 1
    nam_han = nam
    if thang_han > 12:
        thang_han = 1
        nam_han += 1
    han_thanh_toan = date(nam_han, thang_han, so_ngay_han)

    return hoa_don_repo.tao_hoa_don(
        db, hop_dong_id, thang, nam,
        tien_phong, tien_dien, tien_nuoc, tong_tien,
        ngay_lap, han_thanh_toan
    )


def lay_danh_sach_hoa_don(db: Session):
    return hoa_don_repo.lay_tat_ca_hoa_don(db)


# ================== NGHIỆP VỤ 4: CẢNH BÁO NỢ & PHẠT TRỄ HẠN ==================
def tinh_so_ngay_tre_va_phat(han_thanh_toan: date, ngay_hien_tai: date = None) -> tuple:
    """Trả về (so_ngay_tre, tien_phat). Chỉ phạt khi trễ quá SO_NGAY_AN_HAN ngày."""
    ngay_hien_tai = ngay_hien_tai or date.today()
    so_ngay_tre = (ngay_hien_tai - han_thanh_toan).days
    if so_ngay_tre <= 0:
        return 0, 0
    if so_ngay_tre <= SO_NGAY_AN_HAN:
        return so_ngay_tre, 0
    so_ngay_bi_phat = so_ngay_tre - SO_NGAY_AN_HAN
    tien_phat = so_ngay_bi_phat * MUC_PHAT_MOI_NGAY
    return so_ngay_tre, tien_phat


def lay_danh_sach_no(db: Session, ngay_hien_tai: date = None):
    """
    Nghiệp vụ 4:
    1. So sánh ngày hiện tại với hạn thanh toán.
    2. Lọc hóa đơn (=> phòng) đang nợ.
    3. Tự động cộng tiền phạt nếu trễ quá 5 ngày, đồng thời lưu lại tiền phạt vào DB.
    """
    ngay_hien_tai = ngay_hien_tai or date.today()
    hoa_don_qua_han = hoa_don_repo.lay_danh_sach_qua_han(db, ngay_hien_tai)

    ket_qua = []
    for hd in hoa_don_qua_han:
        so_ngay_tre, tien_phat = tinh_so_ngay_tre_va_phat(hd.han_thanh_toan, ngay_hien_tai)

        # Số tiền gốc chưa gồm phạt = tiền phòng + điện + nước
        tien_goc = float(hd.tien_phong) + float(hd.tien_dien) + float(hd.tien_nuoc)
        tong_phai_tra = tien_goc + tien_phat

        # Cập nhật lại tiền phạt mới nhất vào DB để chủ trọ xem báo cáo thấy số đúng
        hoa_don_repo.cap_nhat_phat_tre(db, hd, tien_phat, tong_phai_tra)

        hop_dong = db.query(HopDong).filter(HopDong.id == hd.hop_dong_id).first()
        phong = db.query(PhongTro).filter(PhongTro.id == hop_dong.phong_id).first() if hop_dong else None

        ket_qua.append({
            "hoa_don_id": hd.id,
            "hop_dong_id": hd.hop_dong_id,
            "phong": phong.ten_phong if phong else None,
            "thang": hd.thang,
            "nam": hd.nam,
            "han_thanh_toan": hd.han_thanh_toan,
            "so_ngay_tre": so_ngay_tre,
            "tien_phat": tien_phat,
            "tong_phai_tra": tong_phai_tra,
        })

    # Sắp xếp phòng nợ lâu nhất lên đầu cho chủ trọ dễ theo dõi
    ket_qua.sort(key=lambda x: x["so_ngay_tre"], reverse=True)
    return ket_qua


def thanh_toan_hoa_don(db: Session, hoa_don_id: int):
    hd = hoa_don_repo.lay_hoa_don_theo_id(db, hoa_don_id)
    if not hd:
        raise HTTPException(status.HTTP_404_NOT_FOUND, f"Không tìm thấy hóa đơn ID={hoa_don_id}")
    if hd.trang_thai == "Da_thanh_toan":
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Hóa đơn này đã được thanh toán rồi!")

    so_ngay_tre, tien_phat = tinh_so_ngay_tre_va_phat(hd.han_thanh_toan, date.today())
    tien_goc = float(hd.tien_phong) + float(hd.tien_dien) + float(hd.tien_nuoc)
    tong_tien_cuoi = tien_goc + tien_phat

    return hoa_don_repo.cap_nhat_thanh_toan(db, hd, tien_phat, tong_tien_cuoi)
