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
}
