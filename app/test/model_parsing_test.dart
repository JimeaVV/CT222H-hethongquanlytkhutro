import 'package:flutter_test/flutter_test.dart';
import 'package:tro_manager/models/hoa_don.dart';
import 'package:tro_manager/models/phong_tro.dart';

void main() {
  test('PhongTro parses numeric strings from SQLAlchemy response', () {
    final room = PhongTro.fromJson({
      'id': 1,
      'ten_phong': 'P101',
      'gia_phong': '2500000.00',
      'trang_thai': 'Trong',
    });
    expect(room.id, 1);
    expect(room.giaPhong, 2500000);
    expect(room.isTrong, isTrue);
  });

  test('HoaDon parses backend response', () {
    final bill = HoaDon.fromJson({
      'id': 3,
      'hop_dong_id': 2,
      'thang': 7,
      'nam': 2026,
      'tong_tien': '3200000',
      'trang_thai': 'Da_thanh_toan',
    });
    expect(bill.tongTien, 3200000);
    expect(bill.isPaid, isTrue);
  });
}
