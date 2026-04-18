import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> get orders => _orders;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  StreamSubscription<QuerySnapshot>? _sub;
  bool _isListening = false;

  void refreshOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_isListening) return;

    _isListening = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    _sub = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _isLoading = false;
            _error = null;

            _orders = snapshot.docs.map((doc) {
              final data = doc.data();

              // FIX: Safely parse each item map from the Firestore array.
              // Firestore returns List<dynamic>, each element is a Map — cast
              // carefully so no field access throws at runtime.
              final rawItems = data['items'];
              final List<Map<String, dynamic>> parsedItems = [];

              if (rawItems is List) {
                for (final item in rawItems) {
                  if (item is Map) {
                    parsedItems.add({
                      'productId': item['productId'] ?? '',
                      'name': item['name'] ?? '',
                      'price': (item['price'] as num?)?.toDouble() ?? 0.0,
                      'quantity': (item['quantity'] as num?)?.toInt() ?? 1,
                      'image': item['image'] ?? '',
                      'color': item['color'] ?? '',
                      'colorHex': item['colorHex'] ?? '',
                      'size': item['size'] ?? '',
                    });
                  }
                }
              }

              return <String, dynamic>{
                'id': doc.id,
                'orderId': data['orderId'] ?? doc.id,
                'status': (data['status'] ?? 'pending')
                    .toString()
                    .toLowerCase(),
                'total': (data['total'] as num?)?.toDouble() ?? 0.0,
                'isPaid': data['isPaid'] ?? false,
                'paymentMethod': data['paymentMethod'] ?? 'cod',
                'items': parsedItems,

                // FIX: Address stored flat in Firestore — re-wrap into a map
                // so OrderDetailScreen can read order['address']['name'] etc.
                'address': {
                  'name': data['name'] ?? '',
                  'phone': data['phone'] ?? '',
                  'address': data['address'] ?? '',
                  'city': data['city'] ?? '',
                },

                'createdAt': data['createdAt'],
              };
            }).toList();

            notifyListeners();
          },
          onError: (Object err) {
            _isLoading = false;
            _isListening = false;
            _error = err.toString();
            notifyListeners();
          },
        );
  }

  void clear() {
    _sub?.cancel();
    _sub = null;
    _isListening = false;
    _orders = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
