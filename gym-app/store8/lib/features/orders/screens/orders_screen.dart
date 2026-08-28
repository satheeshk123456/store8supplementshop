import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../order_models.dart';
import '../orders_provider.dart';
import '../widgets/status_badge.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ordersProvider = context.watch<OrdersProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Column(
        children: [
          _StatusFilterBar(ordersProvider: ordersProvider),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.gold,
              onRefresh: () => ordersProvider.refresh(),
              child: AsyncSection<List<Order>>(
                loading: ordersProvider.loading,
                error: ordersProvider.error,
                data: ordersProvider.orders,
                onRetry: () => ordersProvider.refresh(),
                isEmpty: (data) => data.isEmpty,
                emptyMessage: 'No orders yet — new orders will show up here the moment a customer checks out.',
                builder: (orders) => ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _OrderCard(order: orders[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  final OrdersProvider ordersProvider;
  const _StatusFilterBar({required this.ordersProvider});

  @override
  Widget build(BuildContext context) {
    // stock_issue sits outside the normal pending→delivered progression (it's derived, never
    // set directly), so it's appended here just for filtering rather than living in
    // kOrderStatuses, which order_detail_screen.dart also uses to compute "next status" options.
    final filters = [null, kStockIssueStatus, ...kOrderStatuses];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final status = filters[i];
          final selected = ordersProvider.statusFilter == status;
          return ChoiceChip(
            label: Text(status == null ? 'All' : statusLabel(status)),
            selected: selected,
            onSelected: (_) => ordersProvider.setStatusFilter(status),
            selectedColor: AppColors.gold.withValues(alpha: 0.22),
            labelStyle: TextStyle(color: selected ? AppColors.goldLight : AppColors.textMuted),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(order.orderNumber,
                        style: const TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                  ),
                  StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(order.customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(order.customer.phone, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${order.items.length} item(s)', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  Text(formatInr(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.goldLight)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
