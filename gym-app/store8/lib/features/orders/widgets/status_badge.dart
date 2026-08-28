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

String statusLabel(String status) {
  if (status == 'stock_issue') return 'Stock issue';
  return status.isEmpty ? status : status[0].toUpperCase() + status.substring(1);
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

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
        statusLabel(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
