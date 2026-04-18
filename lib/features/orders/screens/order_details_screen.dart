import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    /// ✅ SAFE ITEMS LIST
    final List<Map<String, dynamic>> items = (order['items'] is List)
        ? List<Map<String, dynamic>>.from(order['items'])
        : [];

    /// ✅ SAFE TOTAL
    final double total = (order['total'] is num)
        ? (order['total'] as num).toDouble()
        : double.tryParse(order['total']?.toString() ?? '0') ?? 0;

    /// ✅ SAFE STATUS + PAYMENT
    final String status = (order['status'] ?? 'pending').toString();
    final bool isPaid = order['isPaid'] == true;

    /// ✅ SAFE ADDRESS (HANDLE BOTH STRUCTURES)
    final Map<String, dynamic> address = (order['address'] is Map)
        ? Map<String, dynamic>.from(order['address'])
        : {};

    final name = order['name'] ?? address['name'] ?? '';
    final phone = order['phone'] ?? address['phone'] ?? '';
    final addressText = order['address'] is String
        ? order['address']
        : address['address'] ?? '';
    final city = order['city'] ?? address['city'] ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Order Details",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 📦 STATUS
          _statusCard(cs, status, isPaid),

          const SizedBox(height: 16),

          /// 📍 ADDRESS
          _addressCard(cs, isDark, name, phone, addressText, city),

          const SizedBox(height: 16),

          /// 🛒 ITEMS
          ...items.map((item) {
            final double price = (item['price'] is num)
                ? (item['price'] as num).toDouble()
                : double.tryParse(item['price']?.toString() ?? '0') ?? 0;

            final int qty = (item['quantity'] is int)
                ? item['quantity']
                : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;

            return _itemCard(cs, isDark, item, price, qty);
          }).toList(),

          const SizedBox(height: 16),

          /// 💰 TOTAL
          _totalCard(cs, total),
        ],
      ),
    );
  }

  /// 🔥 STATUS CARD (SYNCED WITH ADMIN)
  Widget _statusCard(ColorScheme cs, String status, bool isPaid) {
    final s = status.toLowerCase();

    Color color;
    IconData icon;
    String label;

    switch (s) {
      case "pending":
        color = const Color(0xFFF59E0B);
        icon = Icons.hourglass_empty_rounded;
        label = "Pending";
        break;

      case "confirmed":
        color = const Color(0xFF6366F1);
        icon = Icons.verified_rounded;
        label = "Confirmed";
        break;

      case "shipped":
        color = const Color(0xFF3B82F6);
        icon = Icons.local_shipping_rounded;
        label = "Shipped";
        break;

      case "delivered":
        color = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
        label = "Delivered";
        break;

      case "cancelled":
        color = const Color(0xFFEF4444);
        icon = Icons.cancel_rounded;
        label = "Cancelled";
        break;

      default:
        color = Colors.grey;
        icon = Icons.help_outline;
        label = "Unknown";
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (isPaid) const Icon(Icons.verified, color: Colors.green),
        ],
      ),
    );
  }

  /// 📍 ADDRESS
  Widget _addressCard(
    ColorScheme cs,
    bool isDark,
    String name,
    String phone,
    String address,
    String city,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Shipping Address",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(name),
          Text(phone),
          Text(address),
          Text(city),
        ],
      ),
    );
  }

  /// 🛒 ITEM CARD
  Widget _itemCard(
    ColorScheme cs,
    bool isDark,
    Map<String, dynamic> item,
    double price,
    int qty,
  ) {
    final size = item['size']?.toString() ?? '';
    final colorName = item['color']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          /// IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              item['image'] ?? '',
              width: 55,
              height: 55,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40),
            ),
          ),

          const SizedBox(width: 10),

          /// DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 4),

                if (size.isNotEmpty) Text("Size: $size"),
                if (colorName.isNotEmpty) Text("Color: $colorName"),

                Text("Qty: $qty"),
              ],
            ),
          ),

          /// PRICE
          Text(
            "NPR ${(price * qty).toStringAsFixed(0)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              // color: AppTheme.backgroundColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 💰 TOTAL
  Widget _totalCard(ColorScheme cs, double total) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        "Total: NPR ${total.toStringAsFixed(0)}",
        style: TextStyle(
          //color: cs.,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
