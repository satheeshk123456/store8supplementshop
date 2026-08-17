import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../catalog_models.dart';
import '../catalog_provider.dart';

class BrandsScreen extends StatelessWidget {
  const BrandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();

    return AsyncSection<List<Brand>>(
      loading: catalog.loading,
      error: catalog.error,
      data: catalog.brands,
      onRetry: () => catalog.loadAll(force: true),
      isEmpty: (d) => d.isEmpty,
      emptyMessage: 'No brands yet. Tap + to add "Optimum Nutrition", "MuscleBlaze", etc.',
      builder: (brands) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: brands.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final b = brands[i];
          return Card(
            child: ListTile(
              onTap: () => context.push('/catalog/brand/${b.id}/edit'),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: b.logo.isNotEmpty
                    ? CachedNetworkImage(imageUrl: b.logo, width: 40, height: 40, fit: BoxFit.contain)
                    : Container(
                        width: 40,
                        height: 40,
                        color: AppColors.surfaceAlt,
                        child: const Icon(Icons.storefront_outlined, size: 20, color: AppColors.textMuted),
                      ),
              ),
              title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(b.isActive ? 'Visible' : 'Hidden'),
              trailing: PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'delete') {
                    final ok = await confirmDialog(context,
                        title: 'Delete brand?', message: 'This cannot be undone.', danger: true);
                    if (ok) {
                      try {
                        await catalog.deleteBrand(b.id);
                      } catch (e) {
                        if (context.mounted) showSnack(context, e.toString(), isError: true);
                      }
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.danger))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
