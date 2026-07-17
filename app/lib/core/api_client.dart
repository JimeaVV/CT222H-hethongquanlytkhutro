import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/hoa_don.dart';
import '../models/hop_dong.dart';
import '../models/khach_thue.dart';
import '../models/phong_tro.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  final http.Client _client;
  static const _timeout = Duration(seconds: 15);

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      late http.Response response;
      final headers = {'Content-Type': 'application/json; charset=UTF-8'};
      final encodedBody = body == null ? null : jsonEncode(body);

      switch (method) {
        case 'GET':
          response = await _client.get(_uri(path), headers: headers).timeout(_timeout);
          break;
        case 'POST':
          response = await _client
              .post(_uri(path), headers: headers, body: encodedBody)
              .timeout(_timeout);
          break;
        case 'PUT':
          response = await _client
              .put(_uri(path), headers: headers, body: encodedBody)
              .timeout(_timeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(_uri(path), headers: headers)
              .timeout(_timeout);
          break;
        default:
          throw const ApiException('Phương thức API không được hỗ trợ.');
      }

      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          decoded['detail']?.toString() ??
              decoded['message']?.toString() ??
              'Máy chủ trả về lỗi ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }
      return decoded;
    } on SocketException {
      throw const ApiException(
        'Không kết nối được FastAPI. Hãy kiểm tra server và địa chỉ API.',
      );
    } on TimeoutException {
      throw const ApiException('Kết nối FastAPI quá thời gian chờ.');
    } on FormatException {
      throw const ApiException('Dữ liệu phản hồi từ máy chủ không hợp lệ.');
    }
  }

  List<Map<String, dynamic>> _dataList(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! List) return [];
    return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<PhongTro>> getPhongTro() async =>
      _dataList(await _request('GET', '/api/phong-tro/'))
          .map(PhongTro.fromJson)
          .toList();

  Future<void> createPhongTro(PhongTro value) async =>
      _request('POST', '/api/phong-tro/', body: value.toRequest());

  Future<void> updatePhongTro(PhongTro value) async =>
      _request('PUT', '/api/phong-tro/${value.id}', body: value.toRequest());

  Future<void> deletePhongTro(int id) async =>
      _request('DELETE', '/api/phong-tro/$id');

  Future<List<KhachThue>> getKhachThue() async =>
      _dataList(await _request('GET', '/api/khach-thue/'))
          .map(KhachThue.fromJson)
          .toList();

  Future<void> createKhachThue(KhachThue value) async =>
      _request('POST', '/api/khach-thue/', body: value.toRequest());

  Future<void> updateKhachThue(KhachThue value) async =>
      _request('PUT', '/api/khach-thue/${value.id}', body: value.toRequest());

  Future<void> deleteKhachThue(int id) async =>
      _request('DELETE', '/api/khach-thue/$id');

  Future<List<HopDong>> getHopDong() async =>
      _dataList(await _request('GET', '/api/hop-dong/'))
          .map(HopDong.fromJson)
          .toList();

  Future<void> createHopDong({
    required int phongId,
    required int nguoiDaiDienId,
    required DateTime ngayBatDau,
    required DateTime ngayKetThuc,
    required double tienCoc,
  }) async =>
      _request('POST', '/api/hop-dong/', body: {
        'phong_id': phongId,
        'nguoi_dai_dien_id': nguoiDaiDienId,
        'ngay_bat_dau': _apiDate(ngayBatDau),
        'ngay_ket_thuc': _apiDate(ngayKetThuc),
        'tien_coc': tienCoc,
      });

  Future<void> thanhLyHopDong(int id) async =>
      _request('PUT', '/api/hop-dong/$id/thanh-ly');

  Future<void> deleteHopDong(int id) async =>
      _request('DELETE', '/api/hop-dong/$id');

  Future<void> ghiDienNuoc({
    required int phongId,
    required int thang,
    required int nam,
    required int dienCu,
    required int dienMoi,
    required int nuocCu,
    required int nuocMoi,
  }) async =>
      _request('POST', '/api/dien-nuoc/ghi-so', body: {
        'phong_id': phongId,
        'thang': thang,
        'nam': nam,
        'dien_cu': dienCu,
        'dien_moi': dienMoi,
        'nuoc_cu': nuocCu,
        'nuoc_moi': nuocMoi,
      });

  Future<List<HoaDon>> getHoaDon() async =>
      _dataList(await _request('GET', '/api/hoa-don/'))
          .map(HoaDon.fromJson)
          .toList();

  Future<List<HoaDon>> getHoaDonQuaHan() async =>
      _dataList(await _request('GET', '/api/hoa-don/no-qua-han'))
          .map(HoaDon.fromJson)
          .toList();

  Future<void> createHoaDon(int hopDongId, int thang, int nam) async =>
      _request('POST', '/api/hoa-don/lap', body: {
        'hop_dong_id': hopDongId,
        'thang': thang,
        'nam': nam,
      });

  Future<void> thanhToanHoaDon(int id) async =>
      _request('PUT', '/api/hoa-don/$id/thanh-toan');

  String _apiDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
