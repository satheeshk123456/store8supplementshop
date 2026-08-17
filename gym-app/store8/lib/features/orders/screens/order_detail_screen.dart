import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../order_models.dart';
import '../orders_provider.dart';
import '../orders_service.dart';
import '../widgets/status_badge.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  Object? _error;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final order = await context.read<OrdersService>().get(widget.orderId);
      if (mounted) setState(() => _order = order);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _advanceStatus(String newStatus) async {
    setState(() => _updating = true);
    try {
      await context.read<OrdersProvider>().updateStatus(widget.orderId, newStatus);
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_order?.orderNumber ?? 'Order')),
      body: _error != null
          ? ErrorView(message: _error.toString(), onRetry: _load)
          : _order == null
              ? const LoadingView()
              : _buildBody(_order!),
    );
  }

  Widget _buildBody(Order order) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StatusBadge(status: order.status),
            if (!order.notified)
              const Tooltip(
                message: "The push notification for this order may not have been delivered",
                child: Icon(Icons.notifications_off_outlined, color: AppColors.warning, size: 20),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Customer',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.customer.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(order.customer.phone, style: const TextStyle(color: AppColors.textMuted)),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16, color: AppColors.textMuted),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: order.customer.phone));
                      showSnack(context, 'Phone number copied');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(order.customer.address, style: const TextStyle(color: AppColors.textMuted)),
              if (order.customer.city.isNotEmpty || order.customer.pincode.isNotEmpty)
                Text('${order.customer.city} ${order.customer.pincode}'.trim(),
                    style: const TextStyle(color: AppColors.textMuted)),
              if (order.customer.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Note: ${order.customer.note}', style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Items',
          child: Column(
            children: [
              for (final line in order.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${line.brandName} ${line.productName} (${line.variantLabel}) × ${line.qty}'),
                      ),
                      Text(formatInr(line.subtotal)),
                    ],
                  ),
                ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.w800)),
                  Text(formatInr(order.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.goldLight)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (order.status != 'delivered' && order.status != 'cancelled') ...[
          const Text('Update status', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final s in _nextStatuses(order.status))
                OutlinedButton(
                  onPressed: _updating ? null : () => _advanceStatus(s),
                  child: Text('Mark ${s[0].toUpperCase()}${s.substring(1)}'),
                ),
              TextButton(
                onPressed: _updating ? null : () => _advanceStatus('cancelled'),
                child: const Text('Cancel order', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  List<String> _nextStatuses(String current) {
    final idx = kOrderStatuses.indexOf(current);
    if (idx == -1 || idx >= kOrderStatuses.length - 2) return [];
    return kOrderStatuses.sublist(idx + 1, kOrderStatuses.length - 1);
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
