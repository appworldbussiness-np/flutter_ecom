import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_service.dart';

class OrderService {
  static Future<void> placeOrder(
    List<Map<String, dynamic>> items,
    double total,
    Map<String, dynamic> address, {
    String paymentMethod = "cod",
    bool isPaid = false, // 🔥 NEW
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      throw Exception("User not logged in");
    }

    final email = CartService.safeEmail(user.email!);
    final firestore = FirebaseFirestore.instance;

    /// 🔥 ORDER DATA
    final orderData = {
      'userEmail': user.email,
      'items': items,
      'total': total,

      /// 📦 ORDER STATUS
      'status': paymentMethod == 'esewa' && isPaid ? 'confirmed' : 'pending',

      /// 💳 PAYMENT
      'paymentMethod': paymentMethod,
      'isPaid': isPaid, // ✅ IMPORTANT
      'paidAt': isPaid ? FieldValue.serverTimestamp() : null,

      /// 👤 USER INFO
      'name': address['name'],
      'phone': address['phone'],
      'address': address['address'],
      'city': address['city'],

      /// ⏱ TIME
      'createdAt': FieldValue.serverTimestamp(),
    };

    /// 📝 SAVE ORDER
    await firestore.collection('orders').add(orderData);

    /// 🧹 CLEAR CART (BATCH)
    final cartRef = firestore.collection('users').doc(email).collection('cart');

    final cartItems = await cartRef.get();
    final batch = firestore.batch();

    for (var doc in cartItems.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
