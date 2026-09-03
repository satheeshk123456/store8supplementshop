import 'package:flutter/material.dart';

import '../../../core/theme.dart';

Color statusColor(String status) {
  switch (status) {
    case 'pending':
      return AppColors.warning;
    case 'confirmed':
    case 'packed':
      return AppColors.gold;
    case 'shipped':
      return const Color(0xFF4A90D9);
    case 'delivered':
      return AppColors.success;
    case 'cancelled':
      return AppColors.danger;
    case 'stock_issue':
      return AppColors.danger;
    default:
      return AppColors.textMuted;
  }
}

/// Client requested a more descriptive status list (Order Received → Stock Checking → Admin
/// Confirmation Pending → Confirmed → Payment Pending → Payment Received → Processing →
/// Shipped → Delivered) than the backend actually tracks as distinct statuses. Rather than
/// adding real new order-status values (a bigger, riskier change touching the backend, both
/// apps, and every status-driven code path), this only relabels what's already tracked — the
/// existing `status` value plus the existing `payment_status` field (see app/schemas.py) — to
/// read the way the client asked for. No new state is introduced.
String statusLabel(String status, {String? paymentStatus}) {
  switch (status) {
    case 'pending':
      return 'Order Received';
    case 'confirmed':
      return paymentStatus == 'link_shared' ? 'Confirmed — Payment Pending' : 'Confirmed';
    case 'packed':
      return 'Processing';
    case 'shipped':
      return 'Shipped / Ready for Delivery';
    case 'delivered':
      return 'Delivered';
    case 'cancelled':
      return 'Cancelled';
    case 'stock_issue':
      return 'Out of Stock — Action Needed';
    default:
      return status.isEmpty ? status : status[0].toUpperCase() + status.substring(1);
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final String? paymentStatus;
  const StatusBadge({super.key, required this.status, this.paymentStatus});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        statusLabel(status, paymentStatus: paymentStatus),
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
