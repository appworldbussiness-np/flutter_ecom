class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem({required this.name, required this.quantity, required this.price});

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 1,
      price: (map['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {"name": name, "quantity": quantity, "price": price};
  }
}

class Address {
  final String name;
  final String phone;
  final String address;
  final String city;

  Address({
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
  });

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {"name": name, "phone": phone, "address": address, "city": city};
  }
}

class OrderData {
  final String id;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> address;
  final double total;
  final DateTime createdAt;

  final bool isPaid; // ✅ NEW
  final String status; // ✅ NEW (pending, paid, delivered)

  OrderData({
    required this.id,
    required this.items,
    required this.address,
    required this.total,
    required this.createdAt,
    this.isPaid = false,
    this.status = "pending",
  });

  /// 🔹 Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'items': items,
      'address': address,
      'total': total,
      'createdAt': createdAt.toIso8601String(),
      'isPaid': isPaid,
      'status': status,
    };
  }

  /// 🔹 Convert from Firestore
  factory OrderData.fromMap(Map<String, dynamic> map, String id) {
    return OrderData(
      id: id,
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      address: Map<String, dynamic>.from(map['address'] ?? {}),
      total: (map['total'] ?? 0).toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
      isPaid: map['isPaid'] ?? false,
      status: map['status'] ?? "pending",
    );
  }

  /// ✅ 🔥 HELPER GETTER
  bool get paid => isPaid;

  /// ✅ OPTIONAL UI HELPERS
  bool get isPending => status == "pending";
  bool get isDelivered => status == "delivered";
}
