import '../core/formatters.dart';

class HoaDon {
  const HoaDon({
    required this.id,
    required this.hopDongId,
    required this.thang,
    required this.nam,
    required this.tienPhong,
    required this.tienDien,
    required this.tienNuoc,
    required this.tienPhatTre,
    required this.tongTien,
    required this.trangThai,
    this.ngayLap,
    this.hanThanhToan,
    this.ngayThanhToan,
  });

  final int id;
  final int hopDongId;
  final int thang;
  final int nam;
  final double tienPhong;
  final double tienDien;
  final double tienNuoc;
  final double tienPhatTre;
  final double tongTien;
  final String trangThai;
  final DateTime? ngayLap;
  final DateTime? hanThanhToan;
  final DateTime? ngayThanhToan;

  bool get isPaid => trangThai.toLowerCase() == 'da_thanh_toan';

  factory HoaDon.fromJson(Map<String, dynamic> json) => HoaDon(
        id: toInt(json['id']),
        hopDongId: toInt(json['hop_dong_id']),
        thang: toInt(json['thang']),
        nam: toInt(json['nam']),
        tienPhong: toDouble(json['tien_phong']),
        tienDien: toDouble(json['tien_dien']),
        tienNuoc: toDouble(json['tien_nuoc']),
        tienPhatTre: toDouble(json['tien_phat_tre']),
        tongTien: toDouble(json['tong_tien']),
        trangThai: json['trang_thai']?.toString() ?? 'Chua_thanh_toan',
        ngayLap: DateTime.tryParse(json['ngay_lap']?.toString() ?? ''),
        hanThanhToan:
            DateTime.tryParse(json['han_thanh_toan']?.toString() ?? ''),
        ngayThanhToan:
            DateTime.tryParse(json['ngay_thanh_toan']?.toString() ?? ''),
      );
}
