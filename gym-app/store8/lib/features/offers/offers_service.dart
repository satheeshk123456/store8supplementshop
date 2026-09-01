import 'dart:io';

import '../../core/api_client.dart';
import 'offer_models.dart';

class OffersService {
  final ApiClient _api;
  OffersService(this._api);

  Future<List<Offer>> listOffers() async {
    final data = await _api.get('/admin/offers');
    return (data as List).map((e) => Offer.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<Offer> createOffer(Offer o) async {
    final data = await _api.post('/admin/offers', data: o.toJson());
    return Offer.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Offer> updateOffer(String id, Offer o) async {
    final data = await _api.put('/admin/offers/$id', data: o.toJson());
    return Offer.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteOffer(String id) => _api.delete('/admin/offers/$id');

  Future<String> uploadImage(File file) async {
    final data = await _api.uploadImage('offers', file);
    return Map<String, dynamic>.from(data)['url'] as String;
  }
}
