import '../core/formatters.dart';

class PhongTro {
  const PhongTro({
    required this.id,
    required this.tenPhong,
    required this.giaPhong,
    required this.trangThai,
  });

  final int id;
  final String tenPhong;
  final double giaPhong;
  final String trangThai;

  bool get isTrong => trangThai.toLowerCase() == 'trong';

  factory PhongTro.fromJson(Map<String, dynamic> json) => PhongTro(
        id: toInt(json['id']),
        tenPhong: json['ten_phong']?.toString() ?? '',
        giaPhong: toDouble(json['gia_phong']),
        trangThai: json['trang_thai']?.toString() ?? 'Trong',
      );

  Map<String, dynamic> toRequest() => {
        'ten_phong': tenPhong,
        'gia_phong': giaPhong,
        'trang_thai': trangThai,
      };
}
