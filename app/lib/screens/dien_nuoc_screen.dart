import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../core/ui_helpers.dart';
import '../models/phong_tro.dart';
import '../widgets/common_widgets.dart';

class DienNuocScreen extends StatefulWidget {
  const DienNuocScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<DienNuocScreen> createState() => _DienNuocScreenState();
}

class _DienNuocScreenState extends State<DienNuocScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dienCu = TextEditingController(text: '0');
  final _dienMoi = TextEditingController();
  final _nuocCu = TextEditingController(text: '0');
  final _nuocMoi = TextEditingController();
  List<PhongTro> _rooms = [];
  int? _roomId;
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() { super.initState(); _loadRooms(); }

  @override
  void dispose() { _dienCu.dispose(); _dienMoi.dispose(); _nuocCu.dispose(); _nuocMoi.dispose(); super.dispose(); }

  Future<void> _loadRooms() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.api.getPhongTro();
      if (mounted) setState(() { _rooms = data; if (data.isNotEmpty) _roomId ??= data.first.id; });
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  int _number(TextEditingController c) => int.tryParse(c.text) ?? 0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _roomId == null) return;
    setState(() => _saving = true);
    try {
      await widget.api.ghiDienNuoc(
        phongId: _roomId!, thang: _month, nam: _year,
        dienCu: _number(_dienCu), dienMoi: _number(_dienMoi),
        nuocCu: _number(_nuocCu), nuocMoi: _number(_nuocMoi),
      );
      if (mounted) showMessage(context, 'Đã chốt chỉ số điện nước tháng $_month/$_year.');
      _dienCu.text = _dienMoi.text; _nuocCu.text = _nuocMoi.text; _dienMoi.clear(); _nuocMoi.clear();
    } catch (e) { if (mounted) showMessage(context, e.toString(), error: true); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) => ScreenPadding(child: _loading ? const LoadingView() : _error != null ? ErrorView(message: _error!, onRetry: _loadRooms) : ListView(children: [
    const PageHeader(title: 'Điện nước', subtitle: 'Ghi nhận chỉ số sử dụng hàng tháng'),
    const SizedBox(height: 20),
    Card(child: Padding(padding: const EdgeInsets.all(18), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Thông tin kỳ ghi số', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      DropdownButtonFormField<int>(value: _roomId, decoration: const InputDecoration(labelText: 'Phòng'), items: _rooms.map((e) => DropdownMenuItem(value: e.id, child: Text(e.tenPhong))).toList(), onChanged: (v) => setState(() => _roomId = v), validator: (v) => v == null ? 'Chọn phòng' : null),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: DropdownButtonFormField<int>(value: _month, decoration: const InputDecoration(labelText: 'Tháng'), items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('Tháng ${i + 1}'))), onChanged: (v) => setState(() => _month = v!))),
        const SizedBox(width: 12),
        Expanded(child: DropdownButtonFormField<int>(value: _year, decoration: const InputDecoration(labelText: 'Năm'), items: List.generate(6, (i) => DateTime.now().year - 2 + i).map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(), onChanged: (v) => setState(() => _year = v!))),
      ]),
      const SizedBox(height: 22),
      Text('Chỉ số điện (kWh)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      _MeterRow(oldController: _dienCu, newController: _dienMoi),
      const SizedBox(height: 20),
      Text('Chỉ số nước (m³)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      _MeterRow(oldController: _nuocCu, newController: _nuocMoi),
      const SizedBox(height: 22),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _saving ? null : _submit, icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Đang lưu...' : 'Chốt chỉ số'))),
    ])))),
    const SizedBox(height: 14),
    Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline, color: Colors.blue.shade700), const SizedBox(width: 12),
      const Expanded(child: Text('Backend hiện chỉ có API ghi chỉ số, chưa có API xem lịch sử. Khi thêm endpoint GET, màn hình này có thể bổ sung bảng lịch sử theo phòng.')),
    ]))),
  ]));
}

class _MeterRow extends StatelessWidget {
  const _MeterRow({required this.oldController, required this.newController});
  final TextEditingController oldController; final TextEditingController newController;
  String? _validate(String? value) => value == null || int.tryParse(value) == null ? 'Nhập chỉ số' : null;
  @override Widget build(BuildContext context) => Row(children: [
    Expanded(child: TextFormField(controller: oldController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Chỉ số cũ'), validator: _validate)),
    const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward, size: 18)),
    Expanded(child: TextFormField(controller: newController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Chỉ số mới'), validator: (v) { final basic = _validate(v); if (basic != null) return basic; if ((int.tryParse(v!) ?? 0) < (int.tryParse(oldController.text) ?? 0)) return 'Phải ≥ chỉ số cũ'; return null; })),
  ]);
}
