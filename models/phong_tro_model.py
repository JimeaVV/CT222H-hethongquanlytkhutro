from sqlalchemy import Column, Integer, String, Numeric
from database import Base

class PhongTro(Base):
    __tablename__ = 'phong_tro'

    id = Column(Integer, primary_key=True, index=True)
    ten_phong = Column(String(50), nullable=False)
    gia_phong = Column(Numeric(12, 2), nullable=False)
    trang_thai = Column(String(20), default="Trong")