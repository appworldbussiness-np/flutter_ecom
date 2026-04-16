import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id;
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String image;
  final String? size;
  final String? color;
  final DateTime createdAt;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
    this.size,
    this.color,
    required this.createdAt,
  });

  double get totalPrice => price * quantity;

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CartItem(
      id: doc.id,
      productId: data['productId'],
      name: data['name'],
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 1,
      image: data['image'] ?? '',
      size: data['size'],
      color: data['color'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image': image,
      'size': size,
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
