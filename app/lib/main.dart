import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/dien_nuoc_screen.dart';
import 'screens/hoa_don_screen.dart';
import 'screens/hop_dong_screen.dart';
import 'screens/khach_thue_screen.dart';
import 'screens/phong_tro_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TroManagerApp());
}

class TroManagerApp extends StatelessWidget {
  const TroManagerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Nhà Trọ',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const AppShell(),
      );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _NavigationItem {
  const _NavigationItem(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _AppShellState extends State<AppShell> {
  final _api = ApiClient();
  int _selected = 0;

  static const _items = [
    _NavigationItem('Tổng quan', Icons.space_dashboard_outlined, Icons.space_dashboard),
    _NavigationItem('Phòng trọ', Icons.apartment_outlined, Icons.apartment),
    _NavigationItem('Khách thuê', Icons.people_outline, Icons.people),
    _NavigationItem('Hợp đồng', Icons.description_outlined, Icons.description),
    _NavigationItem('Điện nước', Icons.bolt_outlined, Icons.bolt),
    _NavigationItem('Hóa đơn', Icons.receipt_long_outlined, Icons.receipt_long),
  ];

  late final List<Widget> _screens = [
    DashboardScreen(api: _api),
    PhongTroScreen(api: _api),
    KhachThueScreen(api: _api),
    HopDongScreen(api: _api),
    DienNuocScreen(api: _api),
    HoaDonScreen(api: _api),
  ];

  void _select(int index) {
    setState(() => _selected = index);
    if (Scaffold.maybeOf(context)?.isDrawerOpen == true) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        if (wide) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    extended: constraints.maxWidth >= 1050,
                    selectedIndex: _selected,
                    onDestinationSelected: _select,
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: _Brand(compact: true),
                    ),
                    destinations: _items
                        .map((e) => NavigationRailDestination(
                              icon: Icon(e.icon),
                              selectedIcon: Icon(e.selectedIcon),
                              label: Text(e.label),
                            ))
                        .toList(),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: IndexedStack(index: _selected, children: _screens)),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(_items[_selected].label)),
          drawer: NavigationDrawer(
            selectedIndex: _selected,
            onDestinationSelected: (index) {
              Navigator.pop(context);
              setState(() => _selected = index);
            },
            children: [
              const Padding(padding: EdgeInsets.fromLTRB(20, 28, 16, 18), child: _Brand()),
              ..._items.map((e) => NavigationDrawerDestination(
                    icon: Icon(e.icon),
                    selectedIcon: Icon(e.selectedIcon),
                    label: Text(e.label),
                  )),
              const Padding(
                padding: EdgeInsets.fromLTRB(28, 24, 20, 12),
                child: Text('FASTAPI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(ApiClient.baseUrl, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ),
            ],
          ),
          body: IndexedStack(index: _selected, children: _screens),
        );
      });
}

class _Brand extends StatelessWidget {
  const _Brand({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.home_work_outlined, color: Colors.white),
          ),
          if (!compact) ...[
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NHÀ TRỌ', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .4)),
                Text('Quản lý đơn giản', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ],
      );
}
