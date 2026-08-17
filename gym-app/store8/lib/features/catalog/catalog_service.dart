import 'dart:io';

import '../../core/api_client.dart';
import 'catalog_models.dart';

class CatalogService {
  final ApiClient _api;
  CatalogService(this._api);

  // ---- Categories ----
  Future<List<Category>> listCategories() async {
    final data = await _api.get('/admin/categories');
    return (data as List).map((e) => Category.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<Category> createCategory(Category c) async {
    final data = await _api.post('/admin/categories', data: c.toJson());
    return Category.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Category> updateCategory(String id, Category c) async {
    final data = await _api.put('/admin/categories/$id', data: c.toJson());
    return Category.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteCategory(String id) => _api.delete('/admin/categories/$id');

  // ---- Brands ----
  Future<List<Brand>> listBrands() async {
    final data = await _api.get('/admin/brands');
    return (data as List).map((e) => Brand.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<Brand> createBrand(Brand b) async {
    final data = await _api.post('/admin/brands', data: b.toJson());
    return Brand.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Brand> updateBrand(String id, Brand b) async {
    final data = await _api.put('/admin/brands/$id', data: b.toJson());
    return Brand.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteBrand(String id) => _api.delete('/admin/brands/$id');

  // ---- Products ----
  Future<List<Product>> listProducts() async {
    final data = await _api.get('/admin/products');
    return (data as List).map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<Product> createProduct(Product p) async {
    final data = await _api.post('/admin/products', data: p.toJson());
    return Product.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Product> updateProduct(String id, Product p) async {
    final data = await _api.put('/admin/products/$id', data: p.toJson());
    return Product.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteProduct(String id) => _api.delete('/admin/products/$id');

  // ---- Items (brand + product + variants) ----
  Future<List<Item>> listItems() async {
    final data = await _api.get('/admin/items');
    return (data as List).map((e) => Item.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<Item> createItem(Item i) async {
    final data = await _api.post('/admin/items', data: i.toJson());
    return Item.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Item> updateItem(String id, Item i) async {
    final data = await _api.put('/admin/items/$id', data: i.toJson());
    return Item.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteItem(String id) => _api.delete('/admin/items/$id');

  // ---- Images ----
  /// folder is one of "products" | "brands" | "categories" — just organizes the Firebase
  /// Storage bucket, matches the same upload endpoint used everywhere images are added.
  Future<String> uploadImage(String folder, File file) async {
    final data = await _api.uploadImage(folder, file);
    return Map<String, dynamic>.from(data)['url'] as String;
  }
}
