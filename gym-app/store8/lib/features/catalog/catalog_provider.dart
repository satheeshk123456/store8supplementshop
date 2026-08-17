import 'dart:io';

// `hide Category`: package:flutter/foundation.dart exports its own `Category` (a doc-only
// annotation class, @Category(['...'])) which collides with our Category model below.
import 'package:flutter/foundation.dart' hide Category;

import 'catalog_models.dart';
import 'catalog_service.dart';

/// Holds categories/brands/products/items together (not four separate providers) because the
/// admin screens constantly cross-reference them — e.g. the item form needs the full product
/// and brand lists for its dropdowns, and a product card needs to know its category's name.
class CatalogProvider extends ChangeNotifier {
  final CatalogService _service;
  CatalogProvider(this._service);

  List<Category> categories = [];
  List<Brand> brands = [];
  List<Product> products = [];
  List<Item> items = [];

  bool loading = false;
  Object? error;
  bool _loadedOnce = false;

  Category? categoryById(String id) => categories.where((c) => c.id == id).firstOrNull;
  Brand? brandById(String id) => brands.where((b) => b.id == id).firstOrNull;
  Product? productById(String id) => products.where((p) => p.id == id).firstOrNull;

  List<Product> productsInCategory(String categoryId) =>
      products.where((p) => p.categoryIds.contains(categoryId)).toList();

  List<Item> itemsForProduct(String productId) => items.where((i) => i.productId == productId).toList();

  Future<void> loadAll({bool force = false}) async {
    if (_loadedOnce && !force) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.listCategories(),
        _service.listBrands(),
        _service.listProducts(),
        _service.listItems(),
      ]);
      categories = results[0] as List<Category>;
      brands = results[1] as List<Brand>;
      products = results[2] as List<Product>;
      items = results[3] as List<Item>;
      _loadedOnce = true;
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ---- Categories ----
  Future<void> saveCategory(Category c, {String? existingId}) async {
    final saved = existingId == null
        ? await _service.createCategory(c)
        : await _service.updateCategory(existingId, c);
    categories = [
      for (final existing in categories)
        if (existing.id != saved.id) existing,
      saved,
    ]..sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    await _service.deleteCategory(id);
    categories = categories.where((c) => c.id != id).toList();
    notifyListeners();
  }

  // ---- Brands ----
  Future<void> saveBrand(Brand b, {String? existingId}) async {
    final saved = existingId == null ? await _service.createBrand(b) : await _service.updateBrand(existingId, b);
    brands = [
      for (final existing in brands)
        if (existing.id != saved.id) existing,
      saved,
    ]..sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> deleteBrand(String id) async {
    await _service.deleteBrand(id);
    brands = brands.where((b) => b.id != id).toList();
    notifyListeners();
  }

  // ---- Products ----
  Future<void> saveProduct(Product p, {String? existingId}) async {
    final saved =
        existingId == null ? await _service.createProduct(p) : await _service.updateProduct(existingId, p);
    products = [
      for (final existing in products)
        if (existing.id != saved.id) existing,
      saved,
    ]..sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    await _service.deleteProduct(id);
    products = products.where((p) => p.id != id).toList();
    notifyListeners();
  }

  // ---- Items ----
  Future<void> saveItem(Item i, {String? existingId}) async {
    final saved = existingId == null ? await _service.createItem(i) : await _service.updateItem(existingId, i);
    items = [
      for (final existing in items)
        if (existing.id != saved.id) existing,
      saved,
    ];
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    await _service.deleteItem(id);
    items = items.where((i) => i.id != id).toList();
    notifyListeners();
  }

  Future<String> uploadImage(String folder, File file) => _service.uploadImage(folder, file);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
