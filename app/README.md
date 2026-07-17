# Hệ thống quản lý khu trọ — Flutter

Frontend Flutter Material 3 tối giản, gồm 6 màn hình:

1. Tổng quan
2. Phòng trọ
3. Khách thuê
4. Hợp đồng
5. Điện nước
6. Hóa đơn và công nợ

## Chuẩn bị

- Flutter SDK 3.22 trở lên
- Android Studio và Android Emulator
- FastAPI chạy trên máy tính ở cổng `8000`

Trong thư mục project, chạy:

```bash
flutter create . --platforms=android
flutter pub get
flutter run
```

Lệnh `flutter create .` chỉ bổ sung các tệp Android theo phiên bản Flutter đang cài như Gradle Wrapper và icon mặc định. Mã nguồn trong `lib/` không bị thay đổi.

## Kết nối FastAPI

Android Emulator không thể dùng `127.0.0.1` để truy cập máy tính. Project mặc định dùng:

```text
http://10.0.2.2:8000
```

Chạy FastAPI để nhận kết nối ngoài tiến trình:

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Đổi URL mà không sửa code:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Nếu chạy trên điện thoại thật, thay `10.0.2.2` bằng IP LAN của máy tính, ví dụ:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

## Endpoint đang dùng

| Nghiệp vụ | Endpoint |
|---|---|
| Phòng trọ | `GET/POST /api/phong-tro/`, `PUT/DELETE /api/phong-tro/{id}` |
| Khách thuê | `GET/POST /api/khach-thue/`, `PUT/DELETE /api/khach-thue/{id}` |
| Hợp đồng | `GET/POST /api/hop-dong/`, thanh lý và xóa hợp đồng |
| Điện nước | `POST /api/dien-nuoc/ghi-so` |
| Hóa đơn | Danh sách, lập, thanh toán và danh sách nợ quá hạn |

Màn Tổng quan tổng hợp trực tiếp từ bốn API danh sách. Backend hiện chưa có endpoint đọc lịch sử điện nước nên màn Điện nước chỉ hỗ trợ ghi/chốt chỉ số.

## Cấu trúc

```text
lib/
├── core/       # API client, theme, định dạng và thông báo
├── models/     # Model ánh xạ dữ liệu FastAPI
├── screens/    # 6 màn hình nghiệp vụ
├── widgets/    # Widget dùng chung
└── main.dart   # Điều hướng responsive
```
