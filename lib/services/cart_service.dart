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
    final ref = cartRef();

    final String docId = product.id;

    final doc = await ref.doc(docId).get();

    if (doc.exists) {
      final existing = doc.data() as Map<String, dynamic>;
      final int currentQty = (existing['quantity'] as num?)?.toInt() ?? 1;

      await ref.doc(docId).update({'quantity': currentQty + quantity});
    } else {
      await ref.doc(docId).set({
        'productId': product.id, // ✅ MUST NEVER BE NULL
        'name': product.name,
        'price': product.finalPrice,
        'image': product.images.isNotEmpty ? product.images[0] : '',
        'quantity': quantity,
        'size': size ?? '',
        'color': color ?? '',
        'addedAt': FieldValue.serverTimestamp(),
      });
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
