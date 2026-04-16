import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  /// 🎨 COLORS
  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.teal;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _paymentColor(String method) {
    return method == 'esewa' ? Colors.green : Colors.deepOrange;
  }

  Color _paymentStatusColor(bool isPaid) {
    return isPaid ? Colors.green : Colors.red;
  }

  IconData _paymentIcon(String method) {
    return method == 'esewa' ? Icons.account_balance_wallet : Icons.money;
  }

  @override
  Widget build(BuildContext context) {
    final validStatuses = [
      'pending',
      'confirmed',
      'shipped',
      'delivered',
      'cancelled',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(
              child: Text(
                "No orders yet",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final doc = orders[i];
              final data = doc.data() as Map<String, dynamic>;

              final status = (data['status'] ?? 'pending')
                  .toString()
                  .toLowerCase();

              final payment = (data['paymentMethod'] ?? 'cod').toString();
              final isPaid = data['isPaid'] ?? false;

              final name = data['name'] ?? 'No Name';
              final phone = data['phone'] ?? '';
              final address = data['address'] ?? '';
              final city = data['city'] ?? '';

              final items = List<Map<String, dynamic>>.from(
                data['items'] ?? [],
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF121826),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔝 HEADER
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Order #${doc.id.substring(0, 6)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        _chip(status.toUpperCase(), _statusColor(status)),
                      ],
                    ),

                    const SizedBox(height: 12),

                    /// 💳 PAYMENT
                    Wrap(
                      spacing: 8,
                      children: [
                        _chip(
                          payment.toUpperCase(),
                          _paymentColor(payment),
                          icon: _paymentIcon(payment),
                        ),
                        _chip(
                          isPaid ? "PAID" : "UNPAID",
                          _paymentStatusColor(isPaid),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    /// 👤 CUSTOMER
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2135),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.white12,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  phone,
                                  style: const TextStyle(color: Colors.white54),
                                ),
                                Text(
                                  "$address ${city.isNotEmpty ? ', $city' : ''}",
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    /// 🛒 ITEMS
                    Column(
                      children: items.map((item) {
                        final qty = item['quantity'] ?? 1;
                        final price = item['price'] ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  item['image'] ?? '',
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 52,
                                    height: 52,
                                    color: Colors.white12,
                                    child: const Icon(
                                      Icons.image,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      "$qty × NPR $price",
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                "NPR ${qty * price}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const Divider(color: Colors.white12),

                    /// 💰 TOTAL + ACTIONS
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Total: NPR ${data['total'] ?? 0}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),

                        /// STATUS DROPDOWN
                        SizedBox(
                          width: 140,
                          child: DropdownButtonFormField<String>(
                            value: validStatuses.contains(status)
                                ? status
                                : 'pending',
                            dropdownColor: const Color(0xFF1C2336),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF1A2135),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            items: validStatuses
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.toUpperCase()),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                FirebaseFirestore.instance
                                    .collection('orders')
                                    .doc(doc.id)
                                    .update({'status': value});
                              }
                            },
                          ),
                        ),

                        const SizedBox(width: 8),

                        /// MARK PAID BUTTON
                        if (!isPaid)
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('orders')
                                  .doc(doc.id)
                                  .update({'isPaid': true});
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 🔹 CHIP
  Widget _chip(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(text, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
