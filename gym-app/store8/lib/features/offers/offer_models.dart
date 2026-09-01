/// Admin-posted banner shown in a strip at the top of the storefront (e.g. "🎁 Diwali combo
/// offer — ask our team on WhatsApp"). Purely marketing/announcement content — completely
/// separate from the per-order special-offer/alternative-product system in
/// features/orders/order_models.dart's OrderLineAlternative. Neither ever changes MRP or the
/// common Store 8 Customer Price shown on any product.
class Offer {
  final String id;
  final String title;
  final String description;
  final String image;
  final String link;
  final int order;
  final bool isActive;

  Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.link,
    required this.order,
    required this.isActive,
  });

  factory Offer.fromJson(Map<String, dynamic> j) => Offer(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        image: j['image'] ?? '',
        link: j['link'] ?? '',
        order: j['order'] ?? 0,
        isActive: j['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'image': image,
        'link': link,
        'order': order,
        'is_active': isActive,
      };
}
