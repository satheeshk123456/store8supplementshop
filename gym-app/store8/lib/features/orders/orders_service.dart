import '../../core/api_client.dart';
import 'order_models.dart';

class OrdersService {
  final ApiClient _api;
  OrdersService(this._api);

  Future<List<Order>> list({String? status}) async {
    final data = await _api.get('/admin/orders', query: status != null ? {'status': status} : null);
    return (data as List).map((e) => Order.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<Order> get(String id) async {
    final data = await _api.get('/admin/orders/$id');
    return Order.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Order> updateStatus(String id, String status) async {
    final data = await _api.put('/admin/orders/$id/status', data: {'status': status});
    return Order.fromJson(Map<String, dynamic>.from(data));
  }

  /// Records the outcome of the physical-stock check for one line. Marking a line
  /// "unavailable" automatically flips the whole order to "stock_issue" server-side so the
  /// customer sees the Notify-me / Suggest-an-alternative choice on the storefront.
  Future<Order> setLineAvailability(
    String orderId,
    String itemId,
    String variantId,
    String availability,
  ) async {
    final data = await _api.put(
      '/admin/orders/$orderId/lines/$itemId/$variantId/availability',
      data: {'availability': availability},
    );
    return Order.fromJson(Map<String, dynamic>.from(data));
  }

  /// Only succeeds once every line is available — matches the required flow: stock confirmed
  /// first, payment link second. Marks the order "confirmed" and payment_status "link_shared".
  Future<Order> setPaymentLink(String orderId, String paymentLink) async {
    final data = await _api.put('/admin/orders/$orderId/payment-link', data: {'payment_link': paymentLink});
    return Order.fromJson(Map<String, dynamic>.from(data));
  }

  /// The "Suggest a suitable alternative product with special offers" action — picks a
  /// currently-available catalog item/variant to offer in place of the unavailable one, with an
  /// optional one-off special offer / discount price for this order only. [itemId]/[variantId]
  /// identify the ORIGINAL unavailable line; [altItemId]/[altVariantId] is the replacement.
  Future<Order> suggestAlternative(
    String orderId,
    String itemId,
    String variantId, {
    required String altItemId,
    required String altVariantId,
    String specialOffer = '',
    double? finalPrice,
  }) async {
    final data = await _api.put(
      '/admin/orders/$orderId/lines/$itemId/$variantId/alternative',
      data: {
        'item_id': altItemId,
        'variant_id': altVariantId,
        'special_offer': specialOffer,
        'final_price': finalPrice,
      },
    );
    return Order.fromJson(Map<String, dynamic>.from(data));
  }
}
