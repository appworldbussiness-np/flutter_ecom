// data/models/product_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final String category;
  final List<String> images;
  final List<String> sizes;
  final List<String> colors;
  final double rating;
  final int reviewCount;
  final int stock;
  final bool isFeatured;
  final bool isNew;
  final bool isInStock;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.category,
    required this.images,
    required this.sizes,
    required this.colors,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.stock = 0,
    this.isFeatured = false,
    this.isNew = false,
    required this.createdAt,
    required this.isInStock,
  });

  // ─── Computed helpers ────────────────────────────────────────────────────
  double get finalPrice => discountPrice ?? price;

  // bool get isInStock => stock > 0;

  int get discountPercentage {
    if (discountPrice == null) return 0;
    return (((price - discountPrice!) / price) * 100).round();
  }

  // ─── Firestore → Product ─────────────────────────────────────────────────
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      discountPrice: data['discountPrice']?.toDouble(),
      category: data['category'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      sizes: List<String>.from(data['sizes'] ?? []),
      colors: List<String>.from(data['colors'] ?? []),
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      stock: data['stock'] ?? 0,
      isFeatured: data['isFeatured'] ?? false,
      isNew: data['isNew'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isInStock: data['isInStock'] ?? true,
    );
  }

  // ─── Product → Firestore ─────────────────────────────────────────────────
  // Note: id is intentionally excluded — Firestore uses it as the document key
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'category': category,
      'images': images,
      'sizes': sizes,
      'colors': colors,
      'rating': rating,
      'reviewCount': reviewCount,
      'stock': stock,
      'isFeatured': isFeatured,
      'isNew': isNew,
      'createdAt': Timestamp.fromDate(createdAt),
      'isInStock': isInStock,
    };
  }

  // ─── copyWith ────────────────────────────────────────────────────────────
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? discountPrice,
    String? category,
    List<String>? images,
    List<String>? sizes,
    List<String>? colors,
    double? rating,
    int? reviewCount,
    int? stock,
    bool? isFeatured,
    bool? isNew,
    bool? isInStock, // ✅ ADD THIS
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      category: category ?? this.category,
      images: images ?? this.images,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      stock: stock ?? this.stock,
      isFeatured: isFeatured ?? this.isFeatured,
      isNew: isNew ?? this.isNew,
      isInStock: isInStock ?? this.isInStock, // ✅ FIXED (was hardcoded null)
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
