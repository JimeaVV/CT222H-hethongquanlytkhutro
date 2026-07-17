import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../core/formatters.dart';
import '../core/ui_helpers.dart';
import '../models/phong_tro.dart';
import '../widgets/common_widgets.dart';

class PhongTroScreen extends StatefulWidget {
  const PhongTroScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<PhongTroScreen> createState() => _PhongTroScreenState();
}

class _PhongTroScreenState extends State<PhongTroScreen> {
  bool _loading = true;
  String? _error;
  List<PhongTro> _items = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.api.getPhongTro();
      if (mounted) setState(() => _items = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(PhongTro value) async {
    try {
      if (value.id == 0) {
        await widget.api.createPhongTro(value);
      } else {
        await widget.api.updatePhongTro(value);
      }
      if (mounted) showMessage(context, value.id == 0 ? 'Đã thêm phòng.' : 'Đã cập nhật phòng.');
      await _load();
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    }
  }

  Future<void> _delete(PhongTro item) async {
    final ok = await confirmAction(context, title: 'Xóa ${item.tenPhong}?', message: 'Phòng sẽ bị xóa khỏi hệ thống.', confirmText: 'Xóa');
    if (!ok) return;
    try {
      await widget.api.deletePhongTro(item.id);
      if (mounted) showMessage(context, 'Đã xóa phòng.');
      await _load();
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((e) => e.tenPhong.toLowerCase().contains(_query.toLowerCase())).toList();
    return ScreenPadding(
      child: Column(
        children: [
          PageHeader(
            title: 'Phòng trọ',
            subtitle: '${_items.length} phòng trong hệ thống',
            action: FilledButton.icon(onPressed: () => _openForm(), icon: const Icon(Icons.add), label: const Text('Thêm')),
          ),
          const SizedBox(height: 16),
          TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm theo tên phòng'), onChanged: (value) => setState(() => _query = value)),
          const SizedBox(height: 14),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _load)
                    : filtered.isEmpty
                        ? const EmptyState(icon: Icons.meeting_room_outlined, title: 'Không có phòng', message: 'Thêm phòng đầu tiên để bắt đầu quản lý.')
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return Card(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: const CircleAvatar(child: Icon(Icons.bed_outlined)),
                                    title: Text(item.tenPhong, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text(formatCurrency(item.giaPhong))),
                                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                      StatusChip(label: item.isTrong ? 'Trống' : 'Đang thuê', positive: item.isTrong),
                                      PopupMenuButton<String>(
                                        onSelected: (value) => value == 'edit' ? _openForm(item) : _delete(item),
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Sửa'))),
                                          PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Xóa'))),
                                        ],
                                      ),
                                    ]),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm([PhongTro? item]) async {
    final name = TextEditingController(text: item?.tenPhong);
    final price = TextEditingController(text: item == null ? '' : item.giaPhong.toStringAsFixed(0));
    var status = item?.trangThai ?? 'Trong';
    final key = GlobalKey<FormState>();
    final result = await showDialog<PhongTro>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setLocalState) => AlertDialog(
        title: Text(item == null ? 'Thêm phòng' : 'Sửa phòng'),
        content: Form(
          key: key,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Tên phòng'), validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tên phòng' : null),
            const SizedBox(height: 12),
            TextFormField(controller: price, decoration: const InputDecoration(labelText: 'Giá phòng', suffixText: 'đ'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Giá phòng phải lớn hơn 0' : null),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'Trạng thái'), items: const [DropdownMenuItem(value: 'Trong', child: Text('Trống')), DropdownMenuItem(value: 'Dang_thue', child: Text('Đang thuê'))], onChanged: (v) => setLocalState(() => status = v!)),
          ])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(context, PhongTro(id: item?.id ?? 0, tenPhong: name.text.trim(), giaPhong: double.parse(price.text), trangThai: status)); }, child: const Text('Lưu')),
        ],
      )),
    );
    name.dispose();
    price.dispose();
    if (result != null) await _save(result);
  }
}
