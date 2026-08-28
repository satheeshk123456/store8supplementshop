class Customer {
  final String name;
  final String phone;
  final String address;
  final String city;
  final String pincode;
  final String note;

  Customer({
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.pincode,
    required this.note,
  });

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        name: j['name'] ?? '',
        phone: j['phone'] ?? '',
        address: j['address'] ?? '',
        city: j['city'] ?? '',
        pincode: j['pincode'] ?? '',
        note: j['note'] ?? '',
      );
}

/// What the admin fills in on the "Suggest a suitable alternative product with special
/// offers" screen once a customer picks "Suggest an Alternative" for an unavailable line.
/// `finalPrice` is a one-off override for THIS order/customer only — it never changes the
/// common Store 8 Customer Price every visitor sees on the storefront for that product.
class OrderLineAlternative {
  final String itemId;
  final String variantId;
  final String productName;
  final String brandName;
  final String variantLabel;
  final double price;
  final String specialOffer;
  final double finalPrice;
  final String status; // "suggested" | "customer_accepted" | "customer_declined"

  OrderLineAlternative({
    required this.itemId,
    required this.variantId,
    required this.productName,
    required this.brandName,
    required this.variantLabel,
    required this.price,
    required this.specialOffer,
    required this.finalPrice,
    required this.status,
  });

  factory OrderLineAlternative.fromJson(Map<String, dynamic> j) => OrderLineAlternative(
        itemId: j['item_id'] ?? '',
        variantId: j['variant_id'] ?? '',
        productName: j['product_name'] ?? '',
        brandName: j['brand_name'] ?? '',
        variantLabel: j['variant_label'] ?? '',
        price: (j['price'] as num?)?.toDouble() ?? 0,
        specialOffer: j['special_offer'] ?? '',
        finalPrice: (j['final_price'] as num?)?.toDouble() ?? 0,
        status: j['status'] ?? 'suggested',
      );
}

class OrderLine {
  final String itemId;
  final String variantId;
  final String productName;
  final String brandName;
  final String variantLabel;
  final String unit;
  final int qty;
  final double price;
  final double subtotal;
  // Set by the admin's physical-stock check (see the "Items" section of the order detail
  // screen) — "unavailable" means the website showed stock but the physical shop had already
  // sold it. Defaults to "available" for every line at checkout time.
  final String availability;
  // What the customer picked in response ("notify_me" | "suggest_alternative"), null until
  // they respond on the storefront's My Orders page.
  final String? customerChoice;
  // Set once the admin has picked a replacement product on the "Suggest a suitable
  // alternative product with special offers" screen.
  final OrderLineAlternative? alternative;

  OrderLine({
    required this.itemId,
    required this.variantId,
    required this.productName,
    required this.brandName,
    required this.variantLabel,
    required this.unit,
    required this.qty,
    required this.price,
    required this.subtotal,
    this.availability = 'available',
    this.customerChoice,
    this.alternative,
  });

  factory OrderLine.fromJson(Map<String, dynamic> j) => OrderLine(
        itemId: j['item_id'] ?? '',
        variantId: j['variant_id'] ?? '',
        productName: j['product_name'] ?? '',
        brandName: j['brand_name'] ?? '',
        variantLabel: j['variant_label'] ?? '',
        unit: j['unit'] ?? '',
        qty: j['qty'] ?? 0,
        price: (j['price'] as num?)?.toDouble() ?? 0,
        subtotal: (j['subtotal'] as num?)?.toDouble() ?? 0,
        availability: j['availability'] ?? 'available',
        customerChoice: j['customer_choice'],
        alternative: j['alternative'] == null
            ? null
            : OrderLineAlternative.fromJson(Map<String, dynamic>.from(j['alternative'])),
      );
}

const kOrderStatuses = ['pending', 'confirmed', 'packed', 'shipped', 'delivered', 'cancelled'];

// Never set manually by an admin action — the backend derives it automatically whenever any
// line on the order is marked unavailable (see OrdersService.setLineAvailability). Shown as a
// separate filter chip / badge so the admin can quickly find orders that need a stock decision.
const kStockIssueStatus = 'stock_issue';

class Order {
  final String id;
  final String orderNumber;
  final Customer customer;
  final List<OrderLine> items;
  final double subtotal;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final String? paymentLink;
  final bool notified;
  final String? createdAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.customer,
    required this.items,
    required this.subtotal,
    required this.totalAmount,
    required this.status,
    this.paymentStatus = 'not_required',
    this.paymentLink,
    required this.notified,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] ?? '',
        orderNumber: j['order_number'] ?? '',
        customer: Customer.fromJson(Map<String, dynamic>.from(j['customer'] ?? const {})),
        items: (j['items'] as List? ?? const [])
            .map((e) => OrderLine.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        subtotal: (j['subtotal'] as num?)?.toDouble() ?? 0,
        totalAmount: (j['total_amount'] as num?)?.toDouble() ?? 0,
        status: j['status'] ?? 'pending',
        paymentStatus: j['payment_status'] ?? 'not_required',
        paymentLink: j['payment_link'],
        notified: j['notified'] ?? false,
        createdAt: j['created_at'],
      );

  bool get hasUnavailableLine => items.any((l) => l.availability == 'unavailable');
}
