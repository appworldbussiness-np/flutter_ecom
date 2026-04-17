import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _filterStatus = 'all';

  final List<String> _validStatuses = [
    'pending',
    'confirmed',
    'shipped',
    'delivered',
    'cancelled',
  ];

  // ─── THEME HELPERS ───────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return const Color(0xFF6366F1);
      case 'shipped':
        return const Color(0xFF3B82F6);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'confirmed':
        return Icons.verified_rounded;
      case 'shipped':
        return Icons.local_shipping_rounded;
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _paymentColor(String method) =>
      method == 'esewa' ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

  IconData _paymentIcon(String method) => method == 'esewa'
      ? Icons.account_balance_wallet_rounded
      : Icons.payments_rounded;

  // ─── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0D1117) : const Color(0xFFF4F6FB);
    final cardBg = isDark ? const Color(0xFF161B27) : Colors.white;
    final surfaceBg = isDark
        ? const Color(0xFF1E2435)
        : const Color(0xFFF0F2F8);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark
        ? const Color(0xFF8B95A8)
        : const Color(0xFF6B7280);
    final divider = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          _buildHeader(isDark, textPrimary, textSecondary, cardBg, divider),
          _buildFilterBar(isDark, surfaceBg, textSecondary),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: const Color(0xFF6366F1),
                    ),
                  );
                }

                var orders = snapshot.data!.docs;

                if (_filterStatus != 'all') {
                  orders = orders.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['status'] ?? 'pending')
                            .toString()
                            .toLowerCase() ==
                        _filterStatus;
                  }).toList();
                }

                if (orders.isEmpty) {
                  return _buildEmptyState(textSecondary);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: orders.length,
                  itemBuilder: (_, i) => _buildOrderCard(
                    orders[i],
                    cardBg,
                    surfaceBg,
                    textPrimary,
                    textSecondary,
                    divider,
                    isDark,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color divider,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Orders',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Manage all orders',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.hourglass_empty_rounded,
                      size: 14,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$count pending',
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── FILTER BAR ──────────────────────────────────────────────────────────────

  Widget _buildFilterBar(bool isDark, Color surfaceBg, Color textSecondary) {
    final filters = ['all', ..._validStatuses];
    return Container(
      height: 52,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (_, i) {
          final f = filters[i];
          final isSelected = _filterStatus == f;
          final color = f == 'all' ? const Color(0xFF6366F1) : _statusColor(f);
          return GestureDetector(
            onTap: () => setState(() => _filterStatus = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : surfaceBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? color.withOpacity(0.5)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  if (f != 'all') ...[
                    Icon(
                      _statusIcon(f),
                      size: 13,
                      color: isSelected ? color : textSecondary,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    f == 'all'
                        ? 'All Orders'
                        : f[0].toUpperCase() + f.substring(1),
                    style: TextStyle(
                      color: isSelected ? color : textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── ORDER CARD ──────────────────────────────────────────────────────────────

  Widget _buildOrderCard(
    QueryDocumentSnapshot doc,
    Color cardBg,
    Color surfaceBg,
    Color textPrimary,
    Color textSecondary,
    Color divider,
    bool isDark,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final payment = (data['paymentMethod'] ?? 'cod').toString();
    final isPaid = data['isPaid'] ?? false;
    final name = data['name'] ?? 'No Name';
    final phone = data['phone'] ?? '';
    final address = data['address'] ?? '';
    final city = data['city'] ?? '';
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // TOP BAR with status color accent
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(color: statusColor.withOpacity(0.15)),
              ),
            ),
            child: Row(
              children: [
                Icon(_statusIcon(status), size: 15, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  'Order #${doc.id.substring(0, 8).toUpperCase()}',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                _pill(status.toUpperCase(), statusColor),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PAYMENT ROW
                Row(
                  children: [
                    _pill(
                      payment.toUpperCase(),
                      _paymentColor(payment),
                      icon: _paymentIcon(payment),
                    ),
                    const SizedBox(width: 8),
                    _pill(
                      isPaid ? 'PAID' : 'UNPAID',
                      isPaid
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      icon: isPaid
                          ? Icons.check_circle_outline_rounded
                          : Icons.pending_outlined,
                    ),
                    const Spacer(),
                    if (!isPaid)
                      GestureDetector(
                        onTap: () => FirebaseFirestore.instance
                            .collection('orders')
                            .doc(doc.id)
                            .update({'isPaid': true}),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.check_rounded,
                                size: 13,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Mark Paid',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // CUSTOMER INFO
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: surfaceBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(
                          0xFF6366F1,
                        ).withOpacity(0.15),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (phone.isNotEmpty)
                              Text(
                                phone,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            if (address.isNotEmpty)
                              Text(
                                '$address${city.isNotEmpty ? ', $city' : ''}',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ITEMS
                Text(
                  'Items (${items.length})',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                ...items.map(
                  (item) => _buildItemRow(
                    item,
                    textPrimary,
                    textSecondary,
                    surfaceBg,
                  ),
                ),

                Divider(color: divider, height: 24),

                // TOTAL + STATUS DROPDOWN
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(color: textSecondary, fontSize: 11),
                        ),
                        Text(
                          'NPR ${data['total'] ?? 0}',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _buildStatusDropdown(
                      doc,
                      status,
                      textPrimary,
                      surfaceBg,
                      divider,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ITEM ROW ────────────────────────────────────────────────────────────────

  Widget _buildItemRow(
    Map<String, dynamic> item,
    Color textPrimary,
    Color textSecondary,
    Color surfaceBg,
  ) {
    final qty = item['quantity'] ?? 1;
    final price = item['price'] ?? 0;

    /// ✅ SAFE EXTRACTION (NO CRASH)
    final size = item['size']?.toString() ?? '';
    final colorName = item['color']?.toString() ?? '';
    final colorHex = item['colorHex']?.toString() ?? '';

    /// 🎨 PARSE HEX COLOR SAFELY
    Color? swatch;
    if (colorHex.isNotEmpty) {
      try {
        swatch = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          /// 🖼 IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              item['image'] ?? '',
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: surfaceBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.image_rounded,
                  color: textSecondary,
                  size: 22,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          /// 📦 DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? '',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                /// 🔥 SIZE + COLOR (FIXED)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (size.isNotEmpty)
                      _variantBadge('Size: $size', const Color(0xFF6366F1)),

                    if (colorName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B7280).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (swatch != null) ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: swatch,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              colorName,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  '$qty × NPR $price',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),

          /// 💰 TOTAL
          Text(
            'NPR ${qty * price}',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _variantBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── STATUS DROPDOWN ─────────────────────────────────────────────────────────

  Widget _buildStatusDropdown(
    QueryDocumentSnapshot doc,
    String status,
    Color textPrimary,
    Color surfaceBg,
    Color divider,
  ) {
    final statusColor = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _validStatuses.contains(status) ? status : 'pending',
          isDense: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: statusColor,
            size: 18,
          ),
          style: TextStyle(
            color: textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: surfaceBg,
          items: _validStatuses.map((s) {
            final c = _statusColor(s);
            return DropdownMenuItem(
              value: s,
              child: Row(
                children: [
                  Icon(_statusIcon(s), size: 14, color: c),
                  const SizedBox(width: 6),
                  Text(
                    s[0].toUpperCase() + s.substring(1),
                    style: TextStyle(color: c),
                  ),
                ],
              ),
            );
          }).toList(),
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
    );
  }

  // ─── EMPTY STATE ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF6366F1),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: TextStyle(
              color: textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different filter',
            style: TextStyle(
              color: textSecondary.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ─── PILL CHIP ───────────────────────────────────────────────────────────────

  Widget _pill(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
