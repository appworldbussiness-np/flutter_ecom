import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/products/models/product_model.dart';

class CartService {
  // ── Safe email for Firestore doc ID ──────────────────────────────────────
  static String safeEmail(String email) =>
      email.replaceAll('.', '_').replaceAll('@', '_at_');

  // ── Cart reference ────────────────────────────────────────────────────────
  static CollectionReference cartRef() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      throw Exception('User not logged in');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(safeEmail(user.email!))
        .collection('cart');
  }

  // ── Add or update cart ────────────────────────────────────────────────────
  static Future<void> addToCart(
    Product product, {
    int quantity = 1,
    String? size,
    String? color,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    final safeSize = (size != null && size.isNotEmpty) ? size : "default";
    final safeColor = (color != null && color.isNotEmpty) ? color : "default";

    final productId = product.id;

    if (productId.isEmpty) {
      print("❌ PRODUCT ID NULL");
      return;
    }

    /// 🔥 CLEAN FUNCTION
    String clean(String value) {
      return value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    }

    final docId = "${productId}_${clean(safeSize)}_${clean(safeColor)}";

    final docRef = cartRef.doc(docId);

    print("🛒 docId: $docId");

    try {
      final doc = await docRef.get();

      if (doc.exists) {
        final currentQty = (doc['quantity'] ?? 1) as int;

        await docRef.update({'quantity': currentQty + quantity});
      } else {
        await docRef.set({
          'productId': productId,
          'name': product.name,
          'price': (product.price as num).toDouble(),
          'quantity': quantity,
          'image': product.images.isNotEmpty ? product.images.first : '',
          'size': safeSize,
          'color': safeColor,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("🔥 ERROR: $e");
    }
  }

  // ── Remove from cart ──────────────────────────────────────────────────────
  static Future<void> removeFromCart(String productId) async {
    await cartRef().doc(productId).delete();
  }

  // ── Update quantity ───────────────────────────────────────────────────────
  static Future<void> updateQuantity(String productId, int newQty) async {
    if (newQty <= 0) {
      await removeFromCart(productId);
    } else {
      await cartRef().doc(productId).update({'quantity': newQty});
    }
  }

  // ── Clear cart ────────────────────────────────────────────────────────────
  static Future<void> clearCart() async {
    final docs = await cartRef().get();
    for (final doc in docs.docs) {
      await doc.reference.delete();
    }
  }
}
