import '../core/formatters.dart';

class KhachThue {
  const KhachThue({
    required this.id,
    required this.hoTen,
    required this.cccd,
    this.sdt,
    this.queQuan,
  });

  final int id;
  final String hoTen;
  final String cccd;
  final String? sdt;
  final String? queQuan;

  factory KhachThue.fromJson(Map<String, dynamic> json) => KhachThue(
        id: toInt(json['id']),
        hoTen: json['ho_ten']?.toString() ?? '',
        cccd: json['cccd']?.toString() ?? '',
        sdt: json['sdt']?.toString(),
        queQuan: json['que_quan']?.toString(),
      );

  Map<String, dynamic> toRequest() => {
        'ho_ten': hoTen,
        'cccd': cccd,
        'sdt': sdt,
        'que_quan': queQuan,
      };
}
