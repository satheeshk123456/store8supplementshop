// hide Category: collides with our own Category model (see catalog_provider.dart for why)
import 'package:flutter/material.dart' hide Category;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../catalog_models.dart';
import '../catalog_provider.dart';
import 'items_screen.dart';

class ProductsScreen extends StatelessWidget {
  final Category category;
  const ProductsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final products = catalog.productsInCategory(category.id);

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/catalog/product/new?categoryId=${category.id}'),
        child: const Icon(Icons.add),
      ),
      body: products.isEmpty
          ? const EmptyView(message: 'No products in this category yet. Tap + to add one.')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = products[i];
                final itemCount = catalog.itemsForProduct(p.id).length;
                return Card(
                  child: ListTile(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ItemsScreen(product: p)),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('$itemCount brand listing(s) · sold by ${p.unitKind.name}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'edit') {
                          context.push('/catalog/product/${p.id}/edit');
                        } else if (action == 'delete') {
                          final ok = await confirmDialog(context,
                              title: 'Delete product?', message: 'This cannot be undone.', danger: true);
                          if (ok) {
                            try {
                              await catalog.deleteProduct(p.id);
                            } catch (e) {
                              if (context.mounted) showSnack(context, e.toString(), isError: true);
                            }
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
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
