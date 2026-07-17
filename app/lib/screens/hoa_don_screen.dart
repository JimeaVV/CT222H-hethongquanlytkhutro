import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/formatters.dart';
import '../core/ui_helpers.dart';
import '../models/hoa_don.dart';
import '../models/hop_dong.dart';
import '../widgets/common_widgets.dart';

class HoaDonScreen extends StatefulWidget {
  const HoaDonScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<HoaDonScreen> createState() => _HoaDonScreenState();
}

class _HoaDonScreenState extends State<HoaDonScreen> {
  bool _loading = true;
  String? _error;
  List<HoaDon> _items = [];
  List<HoaDon> _overdue = [];
  List<HopDong> _contracts = [];
  String _filter = 'all';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await Future.wait([widget.api.getHoaDon(), widget.api.getHoaDonQuaHan(), widget.api.getHopDong()]);
      if (mounted) setState(() { _items = data[0] as List<HoaDon>; _overdue = data[1] as List<HoaDon>; _contracts = data[2] as List<HopDong>; });
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _pay(HoaDon item) async {
    if (!await confirmAction(context, title: 'Xác nhận thanh toán?', message: 'Ghi nhận hóa đơn #${item.id} đã được thanh toán với tổng ${formatCurrency(item.tongTien)}.')) return;
    try { await widget.api.thanhToanHoaDon(item.id); if (mounted) showMessage(context, 'Thanh toán thành công.'); await _load(); }
    catch (e) { if (mounted) showMessage(context, e.toString(), error: true); }
  }

  @override
  Widget build(BuildContext context) {
    final shown = _filter == 'paid' ? _items.where((e) => e.isPaid).toList() : _filter == 'unpaid' ? _items.where((e) => !e.isPaid).toList() : _filter == 'overdue' ? _overdue : _items;
    return ScreenPadding(child: Column(children: [
      PageHeader(title: 'Hóa đơn', subtitle: '${_items.where((e) => !e.isPaid).length} hóa đơn chưa thanh toán', action: FilledButton.icon(onPressed: _openCreate, icon: const Icon(Icons.add), label: const Text('Lập hóa đơn'))),
      const SizedBox(height: 16),
      SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, children: [
        _Filter(label: 'Tất cả', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
        _Filter(label: 'Chưa thanh toán', selected: _filter == 'unpaid', onTap: () => setState(() => _filter = 'unpaid')),
        _Filter(label: 'Đã thanh toán', selected: _filter == 'paid', onTap: () => setState(() => _filter = 'paid')),
        _Filter(label: 'Quá hạn (${_overdue.length})', selected: _filter == 'overdue', onTap: () => setState(() => _filter = 'overdue')),
      ])),
      const SizedBox(height: 12),
      Expanded(child: _loading ? const LoadingView() : _error != null ? ErrorView(message: _error!, onRetry: _load) : shown.isEmpty
        ? const EmptyState(icon: Icons.receipt_long_outlined, title: 'Không có hóa đơn', message: 'Không có dữ liệu phù hợp với bộ lọc.')
        : RefreshIndicator(onRefresh: _load, child: ListView.separated(
            itemCount: shown.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) { final bill = shown[i]; final late = _overdue.any((e) => e.id == bill.id); return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text('Hóa đơn #${bill.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))), StatusChip(label: bill.isPaid ? 'Đã thanh toán' : late ? 'Quá hạn' : 'Chưa thanh toán', positive: bill.isPaid)]),
              const SizedBox(height: 4), Text('Hợp đồng #${bill.hopDongId} · Tháng ${bill.thang}/${bill.nam}', style: TextStyle(color: Colors.grey.shade600)),
              const Divider(height: 24),
              _MoneyRow(label: 'Tiền phòng', value: bill.tienPhong), _MoneyRow(label: 'Tiền điện', value: bill.tienDien), _MoneyRow(label: 'Tiền nước', value: bill.tienNuoc),
              if (bill.tienPhatTre > 0) _MoneyRow(label: 'Phạt trễ', value: bill.tienPhatTre),
              const Divider(height: 20), Row(children: [const Expanded(child: Text('Tổng tiền', style: TextStyle(fontWeight: FontWeight.w700))), Text(formatCurrency(bill.tongTien), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary))]),
              const SizedBox(height: 8), Text('Hạn thanh toán: ${formatDate(bill.hanThanhToan)}', style: TextStyle(fontSize: 12, color: late ? Colors.red : Colors.grey.shade600)),
              if (!bill.isPaid) ...[const SizedBox(height: 12), Align(alignment: Alignment.centerRight, child: FilledButton.tonalIcon(onPressed: () => _pay(bill), icon: const Icon(Icons.check_circle_outline), label: const Text('Thanh toán')))],
            ]))); },
          ))),
    ]));
  }

  Future<void> _openCreate() async {
    final active = _contracts.where((e) => e.isActive).toList();
    if (active.isEmpty) { showMessage(context, 'Chưa có hợp đồng hiệu lực để lập hóa đơn.', error: true); return; }
    int contractId = active.first.id; int month = DateTime.now().month; int year = DateTime.now().year;
    final ok = await showDialog<bool>(context: context, builder: (context) => StatefulBuilder(builder: (context, setLocal) => AlertDialog(
      title: const Text('Lập hóa đơn tháng'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<int>(value: contractId, decoration: const InputDecoration(labelText: 'Hợp đồng'), items: active.map((e) => DropdownMenuItem(value: e.id, child: Text('Hợp đồng #${e.id} · Phòng #${e.phongId}'))).toList(), onChanged: (v) => setLocal(() => contractId = v!)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<int>(value: month, decoration: const InputDecoration(labelText: 'Tháng'), items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))), onChanged: (v) => setLocal(() => month = v!))),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<int>(value: year, decoration: const InputDecoration(labelText: 'Năm'), items: List.generate(5, (i) => DateTime.now().year - 2 + i).map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(), onChanged: (v) => setLocal(() => year = v!))),
        ]),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lập hóa đơn'))],
    )));
    if (ok == true) {
      try { await widget.api.createHoaDon(contractId, month, year); if (mounted) showMessage(context, 'Đã lập hóa đơn tháng $month/$year.'); await _load(); }
      catch (e) { if (mounted) showMessage(context, e.toString(), error: true); }
    }
  }
}

class _Filter extends StatelessWidget { const _Filter({required this.label, required this.selected, required this.onTap}); final String label; final bool selected; final VoidCallback onTap; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap())); }
class _MoneyRow extends StatelessWidget { const _MoneyRow({required this.label, required this.value}); final String label; final double value; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Expanded(child: Text(label, style: TextStyle(color: Colors.grey.shade700))), Text(formatCurrency(value))])); }
