// hide Category: collides with our own Category model (see catalog_provider.dart for why)
import 'package:flutter/material.dart' hide Category;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../catalog_models.dart';
import '../catalog_provider.dart';
import 'products_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();

    return AsyncSection<List<Category>>(
      loading: catalog.loading,
      error: catalog.error,
      data: catalog.categories,
      onRetry: () => catalog.loadAll(force: true),
      isEmpty: (d) => d.isEmpty,
      emptyMessage: 'No categories yet. Tap + to add "Weight Gain", "Muscle Building", etc.',
      builder: (categories) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final c = categories[i];
          final productCount = catalog.productsInCategory(c.id).length;
          return Card(
            child: ListTile(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProductsScreen(category: c)),
              ),
              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('$productCount product(s) · ${c.isActive ? "visible" : "hidden"}'),
              trailing: PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'edit') {
                    context.push('/catalog/category/${c.id}/edit');
                  } else if (action == 'delete') {
                    final ok = await confirmDialog(context,
                        title: 'Delete category?', message: 'This cannot be undone.', danger: true);
                    if (ok) {
                      try {
                        await catalog.deleteCategory(c.id);
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
