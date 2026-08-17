import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../auth/auth_provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final admin = auth.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.gold,
                    child: Text(
                      (admin?.name.isNotEmpty == true ? admin!.name[0] : admin?.email[0] ?? '?').toUpperCase(),
                      style: const TextStyle(color: Color(0xFF1A1408), fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(admin?.name.isNotEmpty == true ? admin!.name : 'Store 8 Admin',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(admin?.email ?? '', style: const TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text('Role: ${admin?.role ?? '-'}', style: const TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await confirmDialog(
                context,
                title: 'Sign out?',
                message: 'You will stop receiving order notifications on this device until you sign back in.',
                confirmLabel: 'Sign out',
                danger: true,
              );
              if (confirmed) await auth.signOut();
            },
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: const Text('Sign out', style: TextStyle(color: AppColors.danger)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
