import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../catalog_provider.dart';
import 'brands_screen.dart';
import 'categories_screen.dart';

/// Mirrors the storefront's browsing order on purpose: Categories first (tap one to manage its
/// products, tap a product to manage its brand listings/sizes) — the same "correct flow" the
/// client asked for on the admin side. Brands are separate because they're shared master data.
class CatalogHomeScreen extends StatefulWidget {
  const CatalogHomeScreen({super.key});

  @override
  State<CatalogHomeScreen> createState() => _CatalogHomeScreenState();
}

class _CatalogHomeScreenState extends State<CatalogHomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    context.read<CatalogProvider>().loadAll();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'Categories'), Tab(text: 'Brands')],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tab,
        builder: (context, _) => FloatingActionButton(
          onPressed: () => context.push(_tab.index == 0 ? '/catalog/category/new' : '/catalog/brand/new'),
          child: const Icon(Icons.add),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<CatalogProvider>().loadAll(force: true),
        child: TabBarView(
          controller: _tab,
          children: const [CategoriesScreen(), BrandsScreen()],
        ),
      ),
    );
  }
}
