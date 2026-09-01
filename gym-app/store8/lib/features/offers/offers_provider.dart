import 'dart:io';

import 'package:flutter/foundation.dart';

import 'offer_models.dart';
import 'offers_service.dart';

class OffersProvider extends ChangeNotifier {
  final OffersService _service;
  OffersProvider(this._service);

  List<Offer> offers = [];
  bool loading = false;
  Object? error;
  bool _loadedOnce = false;

  Offer? offerById(String id) => offers.where((o) => o.id == id).firstOrNull;

  Future<void> loadAll({bool force = false}) async {
    if (_loadedOnce && !force) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      offers = await _service.listOffers()
        ..sort((a, b) => a.order.compareTo(b.order));
      _loadedOnce = true;
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> saveOffer(Offer o, {String? existingId}) async {
    final saved = existingId == null ? await _service.createOffer(o) : await _service.updateOffer(existingId, o);
    offers = [
      for (final existing in offers)
        if (existing.id != saved.id) existing,
      saved,
    ]..sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
  }

  Future<void> deleteOffer(String id) async {
    await _service.deleteOffer(id);
    offers = offers.where((o) => o.id != id).toList();
    notifyListeners();
  }

  Future<String> uploadImage(File file) => _service.uploadImage(file);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
