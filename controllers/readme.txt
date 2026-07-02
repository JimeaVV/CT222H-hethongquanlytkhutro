4. Tầng Controller (API Routes)
Tạo thư mục controllers/ để xử lý các yêu cầu từ phía người dùng.
Các file .py ở đây sẽ tiếp nhận yêu cầu từ Flutter gửi lên, gọi sang Service xử lý và trả về kết quả JSON.
Ví dụ nghiệp vụ xem danh sách phòng sẽ tiếp nhận yêu cầu từ Flutter gọi đến link: GET /api/phong-tro.
