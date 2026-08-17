import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../catalog/screens/catalog_home_screen.dart';
import '../orders/orders_provider.dart';
import '../orders/screens/orders_screen.dart';
import 'account_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    final orders = context.read<OrdersProvider>();
    orders.refresh();
    orders.startPolling();
  }

  @override
  void dispose() {
    context.read<OrdersProvider>().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthProvider>().profile;
    final pending = context.watch<OrdersProvider>().pendingCount;

    final screens = const [OrdersScreen(), CatalogHomeScreen(), AccountScreen()];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            activeIcon: const Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'Catalogue',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: admin?.name.isNotEmpty == true ? admin!.name.split(' ').first : 'Account',
          ),
        ],
      ),
    );
  }
}
