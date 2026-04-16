// lib/providers/app_product_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../features/products/models/product_model.dart';

class AppProductProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'products';

  List<Product> _products = [];
  bool isLoading = false;
  String? error;

  List<Product> get products => _products;

  // ─── Listen (real-time) ───────────────────────────────────────────────────
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
                .map((d) => Product.fromFirestore(d))
                .toList();
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

  // ─── Filter by category ───────────────────────────────────────────────────
  List<Product> byCategory(String category) {
    return _products
        .where((p) => p.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  // ─── Search by name or category ───────────────────────────────────────────
  List<Product> search(String query) {
    if (query.trim().isEmpty) return _products;
    final q = query.toLowerCase();
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q),
        )
        .toList();
  }

  // ─── Featured products ────────────────────────────────────────────────────
  List<Product> get featured => _products.where((p) => p.isFeatured).toList();

  // ─── New arrivals ─────────────────────────────────────────────────────────
  List<Product> get newArrivals => _products.where((p) => p.isNew).toList();

  // ─── In stock only ────────────────────────────────────────────────────────
  List<Product> get inStock => _products.where((p) => p.isInStock).toList();

  // ─── Get single product by id ─────────────────────────────────────────────
  Product? getById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      // For local list :
      _products.removeWhere((p) => p.id == productId);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error deleting product: $e");
      return false;
    }
  }
}
