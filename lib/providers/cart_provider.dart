import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom_/features/home/models/cart_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<CartItem> cart = [];
  bool isLoading = true;

  String get userId => _auth.currentUser!.uid;

  double get totalPrice => cart.fold(0, (sum, item) => sum + item.totalPrice);

  CollectionReference get _cartRef =>
      _db.collection('users').doc(userId).collection('cart');

  /// 🔥 LISTEN CART (NO FILTER)
  void listenCart() {
    _cartRef.orderBy('addedAt', descending: true).snapshots().listen((
      snapshot,
    ) {
      cart = snapshot.docs.map((e) => CartItem.fromFirestore(e)).toList();

      print("🛒 CART ITEMS: ${cart.length}");

      isLoading = false;
      notifyListeners();
    });
  }

  /// ❌ REMOVE (FIXED)
  Future<void> removeItem(String cartId) async {
    await _cartRef.doc(cartId).delete(); // ✅ USE ID
  }

  /// 🔄 UPDATE QTY (FIXED)
  Future<void> updateQty(String cartId, int qty) async {
    if (qty <= 0) {
      await removeItem(cartId);
    } else {
      await _cartRef.doc(cartId).update({'quantity': qty});
    }
  }
}
