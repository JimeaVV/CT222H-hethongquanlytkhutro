from sqlalchemy.orm import Session
from fastapi import HTTPException
from repo import khach_thue_repo

# --- HÀM KIỂM TRA DỮ LIỆU ĐẦU VÀO ---
def kiem_tra_thong_tin_khach(ho_ten: str, cccd: str):
    if not ho_ten or ho_ten.strip() == "":
        raise HTTPException(status_code=400, detail="Họ tên khách thuê không được để trống")
    if not cccd or cccd.strip() == "":
        raise HTTPException(status_code=400, detail="Số CCCD không được để trống")
    if len(cccd.strip()) < 9:
        raise HTTPException(status_code=400, detail="Số CCCD không hợp lệ (phải từ 9 số trở lên)")

# --- CÁC NGHIỆP VỤ CHÍNH ---
def lay_danh_sach_khach(db: Session):
    return khach_thue_repo.lay_tat_ca_khach(db)

def them_khach_moi(db: Session, ho_ten: str, cccd: str, sdt: str, que_quan: str):
    kiem_tra_thong_tin_khach(ho_ten, cccd)
    
    # Kiểm tra xem số CCCD này đã có ai đăng ký chưa
    khach_trung = khach_thue_repo.lay_khach_theo_cccd(db, cccd.strip())
    if khach_trung:
        raise HTTPException(status_code=400, detail=f"Số CCCD '{cccd}' đã tồn tại trên hệ thống!")
        
    return khach_thue_repo.tao_khach_thue(db, ho_ten.strip(), cccd.strip(), sdt, que_quan)

def sua_thong_tin_khach(db: Session, khach_id: int, ho_ten: str, cccd: str, sdt: str, que_quan: str):
    khach_hien_tai = khach_thue_repo.lay_khach_theo_id(db, khach_id)
    if not khach_hien_tai:
        raise HTTPException(status_code=404, detail=f"Không tìm thấy khách thuê có ID = {khach_id}")
    
    kiem_tra_thong_tin_khach(ho_ten, cccd)
    
    # Nếu người dùng thay đổi CCCD, phải kiểm tra xem CCCD mới có bị trùng với người khác không
    if khach_hien_tai.cccd != cccd.strip():
        khach_trung = khach_thue_repo.lay_khach_theo_cccd(db, cccd.strip())
        if khach_trung:
            raise HTTPException(status_code=400, detail=f"Số CCCD '{cccd}' đã bị trùng với một khách thuê khác!")

    return khach_thue_repo.cap_nhat_khach_thue(db, khach_id, ho_ten.strip(), cccd.strip(), sdt, que_quan)

def xoa_khach_hang(db: Session, khach_id: int):
    khach_hien_tai = khach_thue_repo.lay_khach_theo_id(db, khach_id)
    if not khach_hien_tai:
        raise HTTPException(status_code=404, detail=f"Không tìm thấy khách thuê có ID = {khach_id}")
        
    return khach_thue_repo.xoa_khach_thue(db, khach_id)