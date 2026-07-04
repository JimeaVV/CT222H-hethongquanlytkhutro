from sqlalchemy import Column, Integer, String
from database import Base

class KhachThue(Base):
    __tablename__ = 'khach_thue'

    id = Column(Integer, primary_key=True, index=True)
    ho_ten = Column(String(100), nullable=False)
    cccd = Column(String(20), nullable=False, unique=True)
    sdt = Column(String(15), nullable=True)  # Đặt tên chuẩn theo cột 'sdt' trong database của bạn
    que_quan = Column(String(255), nullable=True)