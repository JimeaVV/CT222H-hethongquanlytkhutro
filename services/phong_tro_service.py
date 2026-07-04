from sqlalchemy.orm import Session
from fastapi import HTTPException
from repo import phong_tro_repo

# --- HÀM KIỂM TRA CHUNG ---
def kiem_tra_du_lieu_hop_le(ten_phong, gia_phong, trang_thai):
    if not ten_phong or ten_phong.strip() == "":
        raise HTTPException(status_code=400, detail="Tên phòng không được để trống")
    if gia_phong <= 0:
        raise HTTPException(status_code=400, detail="Giá phòng phải lớn hơn 0")
    if trang_thai not in ["Trong", "Dang_thue", "Bao_tri"]:
        raise HTTPException(status_code=400, detail="Trạng thái không hợp lệ.")

# --- CÁC NGHIỆP VỤ ---
def lay_danh_sach_phong(db: Session):
    return phong_tro_repo.lay_tat_ca_phong(db)

def them_phong_moi(db: Session, ten_phong: str, gia_phong: float, trang_thai: str):
    kiem_tra_du_lieu_hop_le(ten_phong, gia_phong, trang_thai)
    return phong_tro_repo.tao_phong(db, ten_phong, gia_phong, trang_thai)

def sua_thong_tin_phong(db: Session, phong_id: int, ten_phong: str, gia_phong: float, trang_thai: str):
    # 1. Kiểm tra phòng có tồn tại không
    phong_hien_tai = phong_tro_repo.lay_phong_theo_id(db, phong_id)
    if not phong_hien_tai:
        raise HTTPException(status_code=404, detail=f"Không tìm thấy phòng trọ có ID = {phong_id}")
    
    # 2. Kiểm tra dữ liệu đầu vào
    kiem_tra_du_lieu_hop_le(ten_phong, gia_phong, trang_thai)
    
    # 3. Tiến hành cập nhật
    return phong_tro_repo.cap_nhat_phong(db, phong_id, ten_phong, gia_phong, trang_thai)

def xoa_phong_tro(db: Session, phong_id: int):
    # Kiểm tra phòng có tồn tại không trước khi xóa
    phong_hien_tai = phong_tro_repo.lay_phong_theo_id(db, phong_id)
    if not phong_hien_tai:
        raise HTTPException(status_code=404, detail=f"Không tìm thấy phòng trọ có ID = {phong_id}")
    
    if phong_hien_tai.trang_thai == "Dang_thue":
         raise HTTPException(status_code=400, detail="Không thể xóa phòng đang có khách thuê!")

    return phong_tro_repo.xoa_phong(db, phong_id)