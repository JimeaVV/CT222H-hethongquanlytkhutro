from sqlalchemy import Column, Integer, Numeric, Date, String, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

class HopDong(Base):
    __tablename__ = 'hop_dong'

    id = Column(Integer, primary_key=True, index=True)
    phong_id = Column(Integer, ForeignKey('phong_tro.id'), nullable=False)
    nguoi_dai_dien_id = Column(Integer, ForeignKey('khach_thue.id'), nullable=False) # Khớp chuẩn tên cột của bạn
    ngay_bat_dau = Column(Date, nullable=False)
    ngay_ket_thuc = Column(Date, nullable=False)
    tien_coc = Column(Numeric(12, 2), nullable=False)
    trang_thai = Column(String(20), nullable=True) # Cột trạng thái hợp đồng: 'Hieu_luc', 'Da_thanh_ly'