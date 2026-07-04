from database import Base
from sqlalchemy import Column, Integer, ForeignKey

class ChiSoDienNuoc(Base):
    __tablename__ = "chi_so_dien_nuoc"
    
    id = Column(Integer, primary_key=True, index=True)
    phong_id = Column(Integer, ForeignKey("phong_tro.id"), nullable=False)
    thang = Column(Integer, nullable=False)
    nam = Column(Integer, nullable=False)
    
    # Dùng Integer theo đúng thiết kế của bạn
    dien_cu = Column(Integer, default=0)
    dien_moi = Column(Integer, default=0)
    nuoc_cu = Column(Integer, default=0)
    nuoc_moi = Column(Integer, default=0)