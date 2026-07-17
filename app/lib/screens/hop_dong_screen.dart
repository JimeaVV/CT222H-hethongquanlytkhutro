import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../core/formatters.dart';
import '../core/ui_helpers.dart';
import '../models/hop_dong.dart';
import '../models/khach_thue.dart';
import '../models/phong_tro.dart';
import '../widgets/common_widgets.dart';

class HopDongScreen extends StatefulWidget {
  const HopDongScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<HopDongScreen> createState() => _HopDongScreenState();
}

class _HopDongScreenState extends State<HopDongScreen> {
  bool _loading = true;
  String? _error;
  List<HopDong> _items = [];
  List<PhongTro> _rooms = [];
  List<KhachThue> _tenants = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await Future.wait([widget.api.getHopDong(), widget.api.getPhongTro(), widget.api.getKhachThue()]);
      if (mounted) setState(() { _items = data[0] as List<HopDong>; _rooms = data[1] as List<PhongTro>; _tenants = data[2] as List<KhachThue>; });
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  String _roomName(int id) { for (final x in _rooms) { if (x.id == id) return x.tenPhong; } return 'Phòng #$id'; }
  String _tenantName(int id) { for (final x in _tenants) { if (x.id == id) return x.hoTen; } return 'Khách #$id'; }

  Future<void> _settle(HopDong item) async {
    if (!await confirmAction(context, title: 'Thanh lý hợp đồng?', message: 'Hợp đồng #${item.id} sẽ kết thúc và phòng được chuyển về trạng thái trống.')) return;
    try { await widget.api.thanhLyHopDong(item.id); if (mounted) showMessage(context, 'Đã thanh lý hợp đồng.'); await _load(); }
    catch (e) { if (mounted) showMessage(context, e.toString(), error: true); }
  }

  Future<void> _delete(HopDong item) async {
    if (!await confirmAction(context, title: 'Hủy hợp đồng?', message: 'Hợp đồng #${item.id} sẽ bị xóa.', confirmText: 'Hủy hợp đồng')) return;
    try { await widget.api.deleteHopDong(item.id); if (mounted) showMessage(context, 'Đã hủy hợp đồng.'); await _load(); }
    catch (e) { if (mounted) showMessage(context, e.toString(), error: true); }
  }

  @override
  Widget build(BuildContext context) => ScreenPadding(child: Column(children: [
    PageHeader(title: 'Hợp đồng', subtitle: '${_items.where((e) => e.isActive).length} hợp đồng hiệu lực', action: FilledButton.icon(onPressed: _openForm, icon: const Icon(Icons.add), label: const Text('Lập mới'))),
    const SizedBox(height: 16),
    Expanded(child: _loading ? const LoadingView() : _error != null ? ErrorView(message: _error!, onRetry: _load) : _items.isEmpty
      ? const EmptyState(icon: Icons.description_outlined, title: 'Chưa có hợp đồng', message: 'Cần có phòng trống và khách thuê để lập hợp đồng.')
      : RefreshIndicator(onRefresh: _load, child: ListView.separated(
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final item = _items[i];
            return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text('Hợp đồng #${item.id}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))), StatusChip(label: item.isActive ? 'Hiệu lực' : 'Đã thanh lý', positive: item.isActive)]),
              const SizedBox(height: 12),
              _Info(icon: Icons.meeting_room_outlined, text: _roomName(item.phongId)),
              _Info(icon: Icons.person_outline, text: _tenantName(item.nguoiDaiDienId)),
              _Info(icon: Icons.date_range_outlined, text: '${formatDate(item.ngayBatDau)} — ${formatDate(item.ngayKetThuc)}'),
              _Info(icon: Icons.savings_outlined, text: 'Tiền cọc: ${formatCurrency(item.tienCoc)}'),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton.icon(onPressed: () => _delete(item), icon: const Icon(Icons.delete_outline), label: const Text('Hủy')),
                if (item.isActive) ...[const SizedBox(width: 8), FilledButton.tonal(onPressed: () => _settle(item), child: const Text('Thanh lý'))],
              ]),
            ])));
          },
        ))),
  ]));

  Future<void> _openForm() async {
    if (_rooms.isEmpty || _tenants.isEmpty) { showMessage(context, 'Hãy thêm phòng và khách thuê trước.', error: true); return; }
    final emptyRooms = _rooms.where((e) => e.isTrong).toList();
    int? roomId = emptyRooms.isEmpty ? null : emptyRooms.first.id;
    int? tenantId = _tenants.first.id;
    var start = DateTime.now();
    var end = DateTime(start.year + 1, start.month, start.day);
    final deposit = TextEditingController();
    final key = GlobalKey<FormState>();
    final saved = await showDialog<bool>(context: context, builder: (context) => StatefulBuilder(builder: (context, setLocal) => AlertDialog(
      title: const Text('Lập hợp đồng mới'),
      content: Form(key: key, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<int>(value: roomId, decoration: const InputDecoration(labelText: 'Phòng trống'), items: _rooms.where((e) => e.isTrong).map((e) => DropdownMenuItem(value: e.id, child: Text(e.tenPhong))).toList(), onChanged: (v) => setLocal(() => roomId = v), validator: (v) => v == null ? 'Không có phòng trống' : null),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(value: tenantId, decoration: const InputDecoration(labelText: 'Người đại diện'), items: _tenants.map((e) => DropdownMenuItem(value: e.id, child: Text(e.hoTen))).toList(), onChanged: (v) => setLocal(() => tenantId = v)),
        const SizedBox(height: 12),
        _DateField(label: 'Ngày bắt đầu', value: start, onChanged: (v) => setLocal(() => start = v)),
        const SizedBox(height: 12),
        _DateField(label: 'Ngày kết thúc', value: end, onChanged: (v) => setLocal(() => end = v)),
        const SizedBox(height: 12),
        TextFormField(controller: deposit, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Tiền cọc', suffixText: 'đ'), validator: (v) => (double.tryParse(v ?? '') ?? -1) < 0 ? 'Nhập tiền cọc hợp lệ' : null),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), FilledButton(onPressed: () => key.currentState!.validate() ? Navigator.pop(context, true) : null, child: const Text('Lập hợp đồng'))],
    )));
    final depositValue = double.tryParse(deposit.text) ?? 0;

    await Future<void>.delayed(const Duration(milliseconds: 350));

    deposit.dispose();

    if (!mounted || saved != true) return;

    try {
      await widget.api.createHopDong(
        phongId: roomId!,
        nguoiDaiDienId: tenantId!,
        ngayBatDau: start,
        ngayKetThuc: end,
        tienCoc: depositValue,
      );

      if (mounted) {
        showMessage(context, 'Đã lập hợp đồng.');
      }

      await _load();
    } catch (e) {
      if (mounted) {
        showMessage(context, e.toString(), error: true);
      }
    }
  }
}

class _Info extends StatelessWidget { const _Info({required this.icon, required this.text}); final IconData icon; final String text; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(children: [Icon(icon, size: 18, color: Colors.grey.shade600), const SizedBox(width: 8), Expanded(child: Text(text))])); }

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onChanged});
  final String label; final DateTime value; final ValueChanged<DateTime> onChanged;
  @override Widget build(BuildContext context) => InkWell(
    onTap: () async { final picked = await showDatePicker(context: context, initialDate: value, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (picked != null) onChanged(picked); },
    child: InputDecorator(decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today_outlined)), child: Text(formatDate(value))),
  );
}
