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
      );
}

const kOrderStatuses = ['pending', 'confirmed', 'packed', 'shipped', 'delivered', 'cancelled'];

class Order {
  final String id;
  final String orderNumber;
  final Customer customer;
  final List<OrderLine> items;
  final double subtotal;
  final double totalAmount;
  final String status;
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
        notified: j['notified'] ?? false,
        createdAt: j['created_at'],
      );
}
