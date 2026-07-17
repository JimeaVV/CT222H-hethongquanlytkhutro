import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../core/ui_helpers.dart';
import '../models/khach_thue.dart';
import '../widgets/common_widgets.dart';

class KhachThueScreen extends StatefulWidget {
  const KhachThueScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<KhachThueScreen> createState() => _KhachThueScreenState();
}

class _KhachThueScreenState extends State<KhachThueScreen> {
  bool _loading = true;
  String? _error;
  List<KhachThue> _items = [];
  String _query = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.api.getKhachThue();
      if (mounted) setState(() => _items = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(KhachThue item) async {
    try {
      if (item.id == 0) await widget.api.createKhachThue(item); else await widget.api.updateKhachThue(item);
      if (mounted) showMessage(context, item.id == 0 ? 'Đã thêm khách thuê.' : 'Đã cập nhật khách thuê.');
      await _load();
    } catch (e) { if (mounted) showMessage(context, e.toString(), error: true); }
  }

  Future<void> _delete(KhachThue item) async {
    if (!await confirmAction(context, title: 'Xóa khách thuê?', message: 'Xóa ${item.hoTen} khỏi hệ thống?', confirmText: 'Xóa')) return;
    try {
      await widget.api.deleteKhachThue(item.id);
      if (mounted) showMessage(context, 'Đã xóa khách thuê.');
      await _load();
    } catch (e) { if (mounted) showMessage(context, e.toString(), error: true); }
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final filtered = _items.where((e) => e.hoTen.toLowerCase().contains(q) || e.cccd.contains(q) || (e.sdt ?? '').contains(q)).toList();
    return ScreenPadding(child: Column(children: [
      PageHeader(title: 'Khách thuê', subtitle: '${_items.length} người đã đăng ký', action: FilledButton.icon(onPressed: () => _openForm(), icon: const Icon(Icons.person_add_alt_1), label: const Text('Thêm'))),
      const SizedBox(height: 16),
      TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm tên, CCCD hoặc số điện thoại'), onChanged: (v) => setState(() => _query = v)),
      const SizedBox(height: 14),
      Expanded(child: _loading ? const LoadingView() : _error != null ? ErrorView(message: _error!, onRetry: _load) : filtered.isEmpty
          ? const EmptyState(icon: Icons.people_outline, title: 'Không có khách thuê', message: 'Thêm khách thuê để lập hợp đồng.')
          : RefreshIndicator(onRefresh: _load, child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final item = filtered[i];
                return Card(child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(child: Text(item.hoTen.isEmpty ? '?' : item.hoTen[0].toUpperCase())),
                  title: Text(item.hoTen, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text('CCCD: ${item.cccd}\n${item.sdt?.isNotEmpty == true ? item.sdt : 'Chưa có SĐT'}')),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(onSelected: (v) => v == 'edit' ? _openForm(item) : _delete(item), itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Sửa'))),
                    PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Xóa'))),
                  ]),
                ));
              },
            ))),
    ]));
  }

  Future<void> _openForm([KhachThue? item]) async {
    final name = TextEditingController(text: item?.hoTen);
    final cccd = TextEditingController(text: item?.cccd);
    final phone = TextEditingController(text: item?.sdt);
    final hometown = TextEditingController(text: item?.queQuan);
    final key = GlobalKey<FormState>();
    final result = await showDialog<KhachThue>(context: context, builder: (context) => AlertDialog(
      title: Text(item == null ? 'Thêm khách thuê' : 'Sửa khách thuê'),
      content: Form(key: key, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Họ tên'), validator: (v) => v == null || v.trim().isEmpty ? 'Nhập họ tên' : null),
        const SizedBox(height: 12),
        TextFormField(controller: cccd, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'CCCD'), validator: (v) => (v?.length ?? 0) < 9 ? 'CCCD phải có ít nhất 9 số' : null),
        const SizedBox(height: 12),
        TextFormField(controller: phone, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Số điện thoại')),
        const SizedBox(height: 12),
        TextFormField(controller: hometown, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Quê quán')),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(context, KhachThue(id: item?.id ?? 0, hoTen: name.text.trim(), cccd: cccd.text.trim(), sdt: phone.text.trim(), queQuan: hometown.text.trim())); }, child: const Text('Lưu')),
      ],
    ));
    await Future<void>.delayed(const Duration(milliseconds: 350));

    name.dispose();
    cccd.dispose();
    phone.dispose();
    hometown.dispose();

    if (!mounted || result == null) return;

    await _save(result);

  }
}
