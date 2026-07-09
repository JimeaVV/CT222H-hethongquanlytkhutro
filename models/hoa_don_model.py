from sqlalchemy import Column, Integer, Numeric, Date, DateTime, String, ForeignKey
from database import Base


class HoaDon(Base):
    __tablename__ = 'hoa_don'

    id = Column(Integer, primary_key=True, index=True)
    hop_dong_id = Column(Integer, ForeignKey('hop_dong.id'), nullable=False)
    thang = Column(Integer, nullable=False)
    nam = Column(Integer, nullable=False)

    tien_phong = Column(Numeric(12, 2), default=0)
    tien_dien = Column(Numeric(12, 2), default=0)
    tien_nuoc = Column(Numeric(12, 2), default=0)
    tien_phat_tre = Column(Numeric(12, 2), default=0)
    tong_tien = Column(Numeric(12, 2), default=0)

    ngay_lap = Column(Date, nullable=False)          # ngày hóa đơn được tạo ra
    han_thanh_toan = Column(Date, nullable=False)    # hạn chót phải đóng tiền

    trang_thai = Column(String(20), default="Chua_thanh_toan")  # Chua_thanh_toan / Da_thanh_toan
    ngay_thanh_toan = Column(DateTime, nullable=True)
