/// Hand-written (de)serialization on purpose — no code generation step, so the app builds with
/// nothing more than `flutter pub get` (no build_runner watch/step for a beginner to forget).

class Category {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final String icon;
  final int order;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.icon,
    required this.order,
    required this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        tagline: j['tagline'] ?? '',
        description: j['description'] ?? '',
        icon: j['icon'] ?? 'default',
        order: j['order'] ?? 0,
        isActive: j['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'tagline': tagline,
        'description': description,
        'icon': icon,
        'order': order,
        'is_active': isActive,
      };
}

class Brand {
  final String id;
  final String name;
  final String logo;
  final bool isActive;

  Brand({required this.id, required this.name, required this.logo, required this.isActive});

  factory Brand.fromJson(Map<String, dynamic> j) => Brand(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        logo: j['logo'] ?? '',
        isActive: j['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {'name': name, 'logo': logo, 'is_active': isActive};
}

/// weight -> kg/g, volume -> L/ml, count -> capsules/tablets. Drives which units the item form
/// offers, so the storefront automatically shows the right unit without any per-product code.
enum UnitKind { weight, volume, count }

UnitKind unitKindFromString(String s) =>
    UnitKind.values.firstWhere((e) => e.name == s, orElse: () => UnitKind.weight);

const kUnitsByKind = {
  UnitKind.weight: ['kg', 'g'],
  UnitKind.volume: ['l', 'ml'],
  UnitKind.count: ['capsules', 'tablets'],
};

class Product {
  final String id;
  final String name;
  final List<String> categoryIds;
  // Free-text grouping shown within a category page (e.g. "Protein Powders" inside "Muscle
  // Building & Protein") — optional, matches app/schemas.py's ProductIn.subcategory.
  final String subcategory;
  final String description;
  final UnitKind unitKind;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    required this.categoryIds,
    this.subcategory = '',
    required this.description,
    required this.unitKind,
    required this.isActive,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        categoryIds: List<String>.from(j['category_ids'] ?? const []),
        subcategory: j['subcategory'] ?? '',
        description: j['description'] ?? '',
        unitKind: unitKindFromString(j['unit_kind'] ?? 'weight'),
        isActive: j['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'category_ids': categoryIds,
        'subcategory': subcategory,
        'description': description,
        'unit_kind': unitKind.name,
        'is_active': isActive,
      };
}

class Variant {
  final String id;
  final String unit;
  final num value;
  final String label;
  final double? mrp;
  final double price;
  // Optional promotional price, shown struck-through against `price` on the storefront when
  // set and lower than it — mirrors app/schemas.py's VariantIn.offer_price.
  final double? offerPrice;
  final int stockQty;
  final String sku;
  final bool isActive;

  Variant({
    required this.id,
    required this.unit,
    required this.value,
    required this.label,
    required this.mrp,
    required this.price,
    this.offerPrice,
    required this.stockQty,
    required this.sku,
    required this.isActive,
  });

  factory Variant.fromJson(Map<String, dynamic> j) => Variant(
        id: j['id'] ?? '',
        unit: j['unit'] ?? 'kg',
        value: j['value'] ?? 0,
        label: j['label'] ?? '',
        mrp: (j['mrp'] as num?)?.toDouble(),
        price: (j['price'] as num?)?.toDouble() ?? 0,
        offerPrice: (j['offer_price'] as num?)?.toDouble(),
        stockQty: j['stock_qty'] ?? 0,
        sku: j['sku'] ?? '',
        isActive: j['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'unit': unit,
        'value': value,
        'mrp': mrp,
        'price': price,
        'offer_price': offerPrice,
        'stock_qty': stockQty,
        'sku': sku,
        'is_active': isActive,
      };
}

class Item {
  final String id;
  final String productId;
  final String brandId;
  final String title;
  final String flavor;
  final String description;
  // Free-text, optional — filled in gradually per listing, matches app/schemas.py's Item.
  final String ingredients;
  final String benefits;
  final String usage;
  // Reassures customers this isn't a grey-market import (e.g. "Sealed & sourced directly from
  // Optimum Nutrition India") and any safety notes (e.g. "Consult a physician if pregnant").
  final String authenticityInfo;
  final String warnings;
  final List<String> images;
  final List<Variant> variants;
  final bool isActive;
  final bool isFeatured;
  final String? productName;
  final String? brandName;

  Item({
    required this.id,
    required this.productId,
    required this.brandId,
    required this.title,
    required this.flavor,
    required this.description,
    this.ingredients = '',
    this.benefits = '',
    this.usage = '',
    this.authenticityInfo = '',
    this.warnings = '',
    required this.images,
    required this.variants,
    required this.isActive,
    required this.isFeatured,
    this.productName,
    this.brandName,
  });

  factory Item.fromJson(Map<String, dynamic> j) => Item(
        id: j['id'] ?? '',
        productId: j['product_id'] ?? '',
        brandId: j['brand_id'] ?? '',
        title: j['title'] ?? '',
        flavor: j['flavor'] ?? '',
        description: j['description'] ?? '',
        ingredients: j['ingredients'] ?? '',
        benefits: j['benefits'] ?? '',
        usage: j['usage'] ?? '',
        authenticityInfo: j['authenticity_info'] ?? '',
        warnings: j['warnings'] ?? '',
        images: List<String>.from(j['images'] ?? const []),
        variants: (j['variants'] as List? ?? const [])
            .map((v) => Variant.fromJson(Map<String, dynamic>.from(v)))
            .toList(),
        isActive: j['is_active'] ?? true,
        isFeatured: j['is_featured'] ?? false,
        productName: j['product_name'],
        brandName: j['brand_name'],
      );

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'brand_id': brandId,
        'title': title,
        'flavor': flavor,
        'description': description,
        'ingredients': ingredients,
        'benefits': benefits,
        'usage': usage,
        'authenticity_info': authenticityInfo,
        'warnings': warnings,
        'images': images,
        'variants': variants.map((v) => v.toJson()).toList(),
        'is_active': isActive,
        'is_featured': isFeatured,
      };
}
