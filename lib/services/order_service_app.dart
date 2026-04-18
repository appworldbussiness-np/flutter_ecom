import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_service.dart';

class OrderService {
  /// Place an order, then clear the user's cart.
  static Future<void> placeOrder(
    List<Map<String, dynamic>> items,
    double total,
    Map<String, dynamic> address, {
    String paymentMethod = "cod",
    bool isPaid = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    final email = CartService.safeEmail(user.email!);

    final orderRef = FirebaseFirestore.instance.collection('orders').doc();

    // FIX: Normalize each cart item into a consistent map structure
    // that matches exactly what Firestore stores and what the UI reads.
    final normalizedItems = items.map((item) {
      return {
        'productId': item['productId'] ?? '',
        'name': item['name'] ?? '',
        'price': item['price'] ?? 0,
        'quantity': item['quantity'] ?? 1,
        'image': item['image'] ?? '',
        'color': item['color'] ?? '',
        'colorHex': item['colorHex'] ?? '',
        'size': item['size'] ?? '',
      };
    }).toList();

    final orderData = <String, dynamic>{
      'orderId': orderRef.id,
      'userId': user.uid,
      'userEmail': user.email,

      // FIX: Store items as a normalized list — not raw cart maps
      'items': normalizedItems,
      'total': total,

      'status': 'pending',
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,

      // Address fields stored flat (matches your Firestore screenshot)
      'name': address['name'] ?? '',
      'phone': address['phone'] ?? '',
      'address': address['address'] ?? '',
      'city': address['city'] ?? '',

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Only write paidAt when actually paid
    if (isPaid) {
      orderData['paidAt'] = FieldValue.serverTimestamp();
    }

    await orderRef.set(orderData);

    // Clear the cart in a single batch
    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .collection('cart');

    final cartItems = await cartRef.get();
    if (cartItems.docs.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in cartItems.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
