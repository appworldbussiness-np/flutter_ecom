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

  // 🔥 LISTEN CART
  void listenCart() {
    _cartRef.orderBy('addedAt', descending: true).snapshots().listen((
      snapshot,
    ) {
      cart = snapshot.docs.map((e) => CartItem.fromFirestore(e)).toList();
      isLoading = false;
      notifyListeners();
    });
  }

  // ➕ ADD TO CART (FIXED)
  Future<void> addToCart(CartItem item) async {
    final docRef = _cartRef.doc(item.productId); // 🔥 IMPORTANT

    final doc = await docRef.get();

    if (doc.exists) {
      // ✅ already exists → increase qty
      final currentQty = (doc['quantity'] ?? 1) as int;

      await docRef.update({'quantity': currentQty + item.quantity});
    } else {
      // ✅ new item
      await docRef.set({
        ...item.toMap(),

        // 🔥 CRITICAL FIELD
        'productId': item.productId,

        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ➖ REMOVE
  Future<void> removeItem(String productId) async {
    await _cartRef.doc(productId).delete();
  }

  // 🔄 UPDATE QTY
  Future<void> updateQty(String productId, int qty) async {
    if (qty <= 0) {
      await removeItem(productId);
    } else {
      await _cartRef.doc(productId).update({'quantity': qty});
    }
  }
}
