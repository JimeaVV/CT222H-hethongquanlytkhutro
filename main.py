import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware


# Import router từ tầng controllers của bạn
from controllers import phong_tro_controller, khach_thue_controller, hop_dong_controller, dien_nuoc_controller

# Khởi tạo ứng dụng FastAPI
app = FastAPI(
    title="Hệ thống Quản lý Khu trọ API",
    description="Backend API phục vụ cho đồ án Hệ thống quản lý khu trọ ",
    version="1.0.0"
)

# Cấu hình CORS (Bắt buộc phải có để ứng dụng Flutter hoặc React/Vue sau này gọi API không bị chặn)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Cho phép tất cả các nguồn truy cập (Phù hợp khi làm đồ án)
    allow_credentials=True,
    allow_methods=["*"],  # Cho phép tất cả các phương thức GET, POST, PUT, DELETE
    allow_headers=["*"],  # Cho phép tất cả các định dạng Header
)

# Đăng ký Route (Controller) Quản lý phòng trọ vào hệ thống FastAPI
app.include_router(phong_tro_controller.router)
app.include_router(khach_thue_controller.router)
app.include_router(hop_dong_controller.router)
app.include_router(dien_nuoc_controller.router)
# Route mặc định khi vào trang chủ ứng dụng (http://127.0.0.1:8000/)
@app.get("/", tags=["Trang chủ"])
def trang_chu():
    return {
        "status": "success",
        "message": "Chào mừng bạn đến với API Hệ thống quản lý khu trọ!",
        "docs_url": "Hãy truy cập đường dẫn /docs để xem tài liệu API chi tiết."
    }

# CHỖ BỊ LỖI: Sửa @router.get thành @app.get nhé bạn!
@app.get("/", tags=["Trang chủ"])
def trang_chu():
    return {
        "status": "success",
        "message": "Chào mừng bạn đến với API Hệ thống quản lý khu trọ!",
        "docs_url": "Hãy truy cập đường dẫn /docs để xem tài liệu API chi tiết."
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)



