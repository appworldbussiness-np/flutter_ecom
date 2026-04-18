import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecom_/providers/order_provider_app.dart';
import 'package:ecom_/features/orders/screens/order_details_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OrderProvider>().refreshOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final orders = provider.orders;

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "My Orders ",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: _buildBody(context, provider, orders),
    );
  }

  Widget _buildBody(
    BuildContext context,
    OrderProvider provider,
    List<Map<String, dynamic>> orders,
  ) {
    /// 🔄 LOADING
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    /// ❌ ERROR
    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text(
                "Failed to load orders",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                provider.error!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<OrderProvider>().clear();
                  context.read<OrderProvider>().refreshOrders();
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    /// 📭 EMPTY
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              "No orders yet",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    /// 📦 LIST
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final order = orders[i];

        final status = (order['status'] ?? 'pending').toString().toLowerCase();

        final isPaid = order['isPaid'] == true;

        final total = (order['total'] as num?)?.toDouble() ?? 0.0;

        final rawId = (order['orderId'] ?? order['id'] ?? '').toString();
        final shortId = rawId.length >= 6
            ? rawId.substring(0, 6).toUpperCase()
            : rawId.toUpperCase();

        final items = order['items'] as List? ?? [];
        final itemCount = items.length;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(order: order),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  /// 📦 ICON
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// 🧾 ORDER INFO
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order #$shortId",
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$itemCount item${itemCount == 1 ? '' : 's'} • NPR ${total.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// 🔥 STATUS + PAID
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _statusChip(status),

                      const SizedBox(height: 6),

                      if (isPaid)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "PAID",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 🏷 STATUS CHIP
  Widget _statusChip(String status) {
    Color color;

    switch (status) {
      case "pending":
        color = Colors.orange;
        break;
      case "confirmed":
        color = Colors.indigo;
        break;
      case "shipped":
        color = Colors.blue;
        break;
      case "delivered":
        color = Colors.green;
        break;
      case "cancelled":
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
