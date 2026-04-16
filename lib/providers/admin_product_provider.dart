// admin_product_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom_/features/products/models/product_model.dart';
import 'package:flutter/material.dart';

class AdminProductProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'products';

  List<Product> _products = [];
  bool isLoading = false;
  String? error;

  List<Product> get products => _products;

  // ─── Listen (real-time) ───────────────────────────────────────────────────
  // admin_product_provider.dart

  void listenProducts() {
    isLoading = true;
    error = null;
    notifyListeners();

    _db
        .collection(_collection)
        .snapshots()
        .listen(
          (snapshot) {
            _products = snapshot.docs
                .map(
                  (d) => Product.fromFirestore(d),
                ) // explicit type, no cast needed
                .toList(); // Dart now infers List<Product>
            isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            error = e.toString();
            isLoading = false;
            notifyListeners();
          },
        );
  }

  // ─── Add ──────────────────────────────────────────────────────────────────
  Future<bool> addProduct(Product product) async {
    try {
      error = null;
      print('=== ADDING: ${product.name} ===');

      final docRef = await _db.collection(_collection).add(product.toMap());

      print('=== SUCCESS id: ${docRef.id} ===');
      return true;
    } catch (e, stack) {
      print('=== ADD ERROR: $e ===');
      print('=== STACK: $stack ===');
      error = 'Add failed: $e';
      notifyListeners();
      return false;
    }
  }
  // ─── Update ───────────────────────────────────────────────────────────────

  Future<bool> updateProduct(Product product) async {
    try {
      error = null;
      await _db.collection(_collection).doc(product.id).update(product.toMap());
      return true;
    } catch (e) {
      error = 'Update failed: $e';
      notifyListeners();
      return false;
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────
  Future<bool> deleteProduct(String productId) async {
    try {
      error = null;

      // Optimistic removal — remove from list immediately so UI feels instant
      _products.removeWhere((p) => p.id == productId);
      notifyListeners();

      await _db.collection(_collection).doc(productId).delete();
      return true;
    } catch (e) {
      error = 'Delete failed: $e';
      // Re-fetch to restore correct state if delete failed
      listenProducts();
      notifyListeners();
      return false;
    }
  }
}
