import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/formatters.dart';
import '../models/hoa_don.dart';
import '../models/hop_dong.dart';
import '../models/khach_thue.dart';
import '../models/phong_tro.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardData {
  const _DashboardData(this.phong, this.khach, this.hopDong, this.hoaDon);
  final List<PhongTro> phong;
  final List<KhachThue> khach;
  final List<HopDong> hopDong;
  final List<HoaDon> hoaDon;
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = Future.wait([
      widget.api.getPhongTro(),
      widget.api.getKhachThue(),
      widget.api.getHopDong(),
      widget.api.getHoaDon(),
    ]).then((value) => _DashboardData(
          value[0] as List<PhongTro>,
          value[1] as List<KhachThue>,
          value[2] as List<HopDong>,
          value[3] as List<HoaDon>,
        ));
  }

  void _refresh() => setState(_load);

  @override
  Widget build(BuildContext context) => ScreenPadding(
        child: FutureBuilder<_DashboardData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
            if (snapshot.hasError) return ErrorView(message: snapshot.error.toString(), onRetry: _refresh);
            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                _refresh();
                await _future;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  PageHeader(
                    title: 'Tổng quan',
                    subtitle: 'Tình hình khu trọ hôm nay',
                    action: IconButton.filledTonal(onPressed: _refresh, icon: const Icon(Icons.refresh)),
                  ),
                  const SizedBox(height: 20),
                  _StatsGrid(data: data),
                  const SizedBox(height: 24),
                  Text('Hóa đơn gần đây', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (data.hoaDon.isEmpty)
                    const Card(child: EmptyState(icon: Icons.receipt_long_outlined, title: 'Chưa có hóa đơn', message: 'Hóa đơn mới lập sẽ xuất hiện tại đây.'))
                  else
                    ...data.hoaDon.reversed.take(5).map((bill) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              leading: CircleAvatar(child: Text('${bill.thang}')),
                              title: Text('Hóa đơn #${bill.id} · HĐ #${bill.hopDongId}'),
                              subtitle: Text('Tháng ${bill.thang}/${bill.nam}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(formatCurrency(bill.tongTien), style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text(bill.isPaid ? 'Đã thanh toán' : 'Chưa thanh toán', style: TextStyle(fontSize: 12, color: bill.isPaid ? Colors.green : Colors.orange)),
                                ],
                              ),
                            ),
                          ),
                        )),
                ],
              ),
            );
          },
        ),
      );
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.data});
  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final revenue = data.hoaDon
        .where((e) => e.isPaid && e.thang == now.month && e.nam == now.year)
        .fold<double>(0, (sum, e) => sum + e.tongTien);
    final cards = [
      StatCard(label: 'Tổng số phòng', value: '${data.phong.length}', icon: Icons.apartment_outlined, color: Colors.blue),
      StatCard(label: 'Phòng còn trống', value: '${data.phong.where((e) => e.isTrong).length}', icon: Icons.meeting_room_outlined, color: Colors.green),
      StatCard(label: 'Khách thuê', value: '${data.khach.length}', icon: Icons.people_outline, color: Colors.indigo),
      StatCard(label: 'Hợp đồng hiệu lực', value: '${data.hopDong.where((e) => e.isActive).length}', icon: Icons.description_outlined, color: Colors.teal),
      StatCard(label: 'Hóa đơn còn nợ', value: '${data.hoaDon.where((e) => !e.isPaid).length}', icon: Icons.pending_actions_outlined, color: Colors.orange),
      StatCard(label: 'Doanh thu tháng', value: formatCurrency(revenue), icon: Icons.payments_outlined, color: Colors.purple),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900 ? 3 : constraints.maxWidth >= 560 ? 2 : 1;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(spacing: 12, runSpacing: 12, children: cards.map((e) => SizedBox(width: width, child: e)).toList());
    });
  }
}
