3. Tầng Service (Nghiệp vụ)
Tạo thư mục services/ làm nơi chứa logic cốt lõi của từng nghiệp vụ.
Nên chia mỗi nghiệp vụ ra một file .py riêng, ví dụ nghiệp vụ tính hóa đơn sẽ gọi xuống DB lấy giá phòng, lấy chỉ số điện nước, cộng tiền dịch vụ, áp tiền phạt nếu trễ hạn rồi cộng tổng lại.
