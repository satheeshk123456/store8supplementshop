import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../catalog_models.dart';
import '../catalog_provider.dart';

class ItemsScreen extends StatelessWidget {
  final Product product;
  const ItemsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final items = catalog.itemsForProduct(product.id);

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/catalog/item/new?productId=${product.id}'),
        child: const Icon(Icons.add),
      ),
      body: items.isEmpty
          ? const EmptyView(message: 'No brands listed for this product yet. Tap + to add one.')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = items[i];
                final brand = catalog.brandById(item.brandId);
                final minPrice = item.variants.isEmpty
                    ? null
                    : item.variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
                return Card(
                  child: ListTile(
                    onTap: () => context.push('/catalog/item/${item.id}/edit'),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: item.images.isNotEmpty
                          ? CachedNetworkImage(imageUrl: item.images.first, width: 48, height: 48, fit: BoxFit.cover)
                          : Container(
                              width: 48,
                              height: 48,
                              color: AppColors.surfaceAlt,
                              child: const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted),
                            ),
                    ),
                    title: Text(brand?.name ?? item.brandName ?? 'Unknown brand',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${item.variants.length} size(s)${minPrice != null ? " · from ${formatInr(minPrice)}" : ""}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'delete') {
                          final ok = await confirmDialog(context,
                              title: 'Delete listing?', message: 'This cannot be undone.', danger: true);
                          if (ok) {
                            try {
                              await catalog.deleteItem(item.id);
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
