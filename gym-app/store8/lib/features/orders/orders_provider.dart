import 'dart:async';

import 'package:flutter/foundation.dart';

import 'order_models.dart';
import 'orders_service.dart';

/// Since the app talks to Firestore only through the backend (never directly — see
/// gym-backend/firestore.rules), "real-time" here means: refresh immediately when a push
/// notification arrives (see main.dart wiring `onOrderTapped`/order refresh), plus a light
/// periodic poll while the Orders screen is open, plus pull-to-refresh. Good enough for a shop
/// that gets the occasional order and simpler/cheaper than a live socket connection.
class OrdersProvider extends ChangeNotifier {
  final OrdersService _service;
  OrdersProvider(this._service);

  List<Order> orders = [];
  bool loading = false;
  Object? error;
  String? statusFilter;
  Timer? _pollTimer;

  void startPolling({Duration interval = const Duration(seconds: 25)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => refresh(silent: true));
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      loading = true;
      notifyListeners();
    }
    try {
      orders = await _service.list(status: statusFilter);
      error = null;
    } catch (e) {
      if (!silent) error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setStatusFilter(String? status) {
    statusFilter = status;
    refresh();
  }

  Future<void> updateStatus(String orderId, String status) async {
    final updated = await _service.updateStatus(orderId, status);
    orders = [
      for (final o in orders) o.id == orderId ? updated : o,
    ];
    notifyListeners();
  }

  int get pendingCount => orders.where((o) => o.status == 'pending').length;
}
