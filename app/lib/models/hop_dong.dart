import '../core/formatters.dart';

class HopDong {
  const HopDong({
    required this.id,
    required this.phongId,
    required this.nguoiDaiDienId,
    required this.ngayBatDau,
    required this.ngayKetThuc,
    required this.tienCoc,
    required this.trangThai,
  });

  final int id;
  final int phongId;
  final int nguoiDaiDienId;
  final DateTime? ngayBatDau;
  final DateTime? ngayKetThuc;
  final double tienCoc;
  final String trangThai;

  bool get isActive => trangThai.toLowerCase() == 'hieu_luc';

  factory HopDong.fromJson(Map<String, dynamic> json) => HopDong(
        id: toInt(json['id']),
        phongId: toInt(json['phong_id']),
        nguoiDaiDienId: toInt(json['nguoi_dai_dien_id']),
        ngayBatDau: DateTime.tryParse(json['ngay_bat_dau']?.toString() ?? ''),
        ngayKetThuc: DateTime.tryParse(json['ngay_ket_thuc']?.toString() ?? ''),
        tienCoc: toDouble(json['tien_coc']),
        trangThai: json['trang_thai']?.toString() ?? 'Hieu_luc',
      );
}
