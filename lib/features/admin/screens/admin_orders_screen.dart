import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ─── Design Tokens (matches AdminDashboard) ──────────────────────────────────
class _T {
  static const bg = Color(0xFF080C14);
  static const surface = Color(0xFF0D1220);
  static const card = Color(0xFF111827);
  static const elevated = Color(0xFF1A2235);
  //static const cardHover = Color(0xFF161F30);

  static const accent = Color(0xFF7C6EFA);
  static const accentLight = Color(0xFF9D92FB);
  static const accentDim = Color(0x207C6EFA);
  static const accentBorder = Color(0x407C6EFA);

  static const success = Color(0xFF10D991);
  static const successDim = Color(0x1510D991);
  static const danger = Color(0xFFFF5B5B);
  static const dangerDim = Color(0x15FF5B5B);
  static const warning = Color(0xFFF5A623);
  static const warningDim = Color(0x15F5A623);
  static const info = Color(0xFF38B6FF);
  static const infoDim = Color(0x1538B6FF);
  static const purple = Color(0xFFB57BFF);
  static const purpleDim = Color(0x15B57BFF);

  static const white = Color(0xFFFFFFFF);
  static const text = Color(0xFFE2E8F0);
  static const textMuted = Color(0xFF7A8BA5);
  static const textFaint = Color(0xFF3D4D63);
  static const border = Color(0xFF1E2D42);
  static const borderBright = Color(0xFF2A3D56);
}

LinearGradient _accentGrad() =>
    const LinearGradient(colors: [_T.accent, Color(0xFF5B8DEF)]);

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  String _filterStatus = 'all';
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final List<String> _validStatuses = [
    'pending',
    'confirmed',
    'shipped',
    'delivered',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── STATUS HELPERS ──────────────────────────────────────────────────────────
  Color _statusColor(String s) => switch (s) {
    'pending' => _T.warning,
    'confirmed' => _T.purple,
    'shipped' => _T.info,
    'delivered' => _T.success,
    'cancelled' => _T.danger,
    _ => _T.textMuted,
  };

  Color _statusDim(String s) => switch (s) {
    'pending' => _T.warningDim,
    'confirmed' => _T.purpleDim,
    'shipped' => _T.infoDim,
    'delivered' => _T.successDim,
    'cancelled' => _T.dangerDim,
    _ => _T.elevated,
  };

  IconData _statusIcon(String s) => switch (s) {
    'pending' => Icons.schedule_rounded,
    'confirmed' => Icons.task_alt_rounded,
    'shipped' => Icons.local_shipping_rounded,
    'delivered' => Icons.check_circle_rounded,
    'cancelled' => Icons.cancel_rounded,
    _ => Icons.radio_button_unchecked,
  };

  Color _paymentColor(String m) => m == 'esewa' ? _T.success : _T.warning;
  Color _paymentDim(String m) => m == 'esewa' ? _T.successDim : _T.warningDim;
  IconData _paymentIcon(String m) => m == 'esewa'
      ? Icons.account_balance_wallet_rounded
      : Icons.payments_rounded;

  // ── BUILD ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: _PulseLoader());
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

                if (orders.isEmpty) return _buildEmptyState();

                return FadeTransition(
                  opacity: _fadeAnim,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                    itemCount: orders.length,
                    itemBuilder: (_, i) => _OrderCard(
                      doc: orders[i],
                      validStatuses: _validStatuses,
                      statusColor: _statusColor,
                      statusDim: _statusDim,
                      statusIcon: _statusIcon,
                      paymentColor: _paymentColor,
                      paymentDim: _paymentDim,
                      paymentIcon: _paymentIcon,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: _T.surface,
        border: Border(bottom: BorderSide(color: _T.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: _accentGrad(),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: _T.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Orders',
                style: TextStyle(
                  color: _T.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Manage all customer orders',
                style: TextStyle(color: _T.textMuted, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),

          // Live pending badge
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
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _T.warningDim,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _T.warning.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulseDot(color: _T.warning),
                    const SizedBox(width: 6),
                    Text(
                      '$count pending',
                      style: const TextStyle(
                        color: _T.warning,
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

  // ── FILTER BAR ──────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    final filters = ['all', ..._validStatuses];
    return Container(
      height: 54,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: filters.length,
        itemBuilder: (_, i) {
          final f = filters[i];
          final isSelected = _filterStatus == f;
          final color = f == 'all' ? _T.accent : _statusColor(f);
          final dimColor = f == 'all' ? _T.accentDim : _statusDim(f);

          return GestureDetector(
            onTap: () {
              setState(() => _filterStatus = f);
              _fadeCtrl.forward(from: 0);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? dimColor : _T.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? color.withOpacity(0.4) : _T.border,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (f != 'all') ...[
                    Icon(
                      _statusIcon(f),
                      size: 12,
                      color: isSelected ? color : _T.textMuted,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    f == 'all'
                        ? 'All Orders'
                        : f[0].toUpperCase() + f.substring(1),
                    style: TextStyle(
                      color: isSelected ? color : _T.textMuted,
                      fontSize: 12.5,
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

  // ── EMPTY STATE ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: _T.accentDim,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _T.accentBorder, width: 0.5),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: _T.accent,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No orders found',
            style: TextStyle(
              color: _T.text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different filter',
            style: TextStyle(color: _T.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Order Card (stateful for hover) ─────────────────────────────────────────
class _OrderCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final List<String> validStatuses;
  final Color Function(String) statusColor;
  final Color Function(String) statusDim;
  final IconData Function(String) statusIcon;
  final Color Function(String) paymentColor;
  final Color Function(String) paymentDim;
  final IconData Function(String) paymentIcon;

  const _OrderCard({
    required this.doc,
    required this.validStatuses,
    required this.statusColor,
    required this.statusDim,
    required this.statusIcon,
    required this.paymentColor,
    required this.paymentDim,
    required this.paymentIcon,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final payment = (data['paymentMethod'] ?? 'cod').toString();
    final isPaid = data['isPaid'] ?? false;
    final name = data['name'] ?? 'Unknown';
    final phone = data['phone'] ?? '';
    final address = data['address'] ?? '';
    final city = data['city'] ?? '';
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    final total = data['total'] ?? 0;
    final orderId = widget.doc.id.substring(0, 8).toUpperCase();

    final sColor = widget.statusColor(status);
    final sDim = widget.statusDim(status);
    final sIcon = widget.statusIcon(status);
    final pColor = widget.paymentColor(payment);
    final pDim = widget.paymentDim(payment);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.border, width: 0.5),
      ),
      child: Column(
        children: [
          // ── TOP ACCENT STRIP ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: sDim,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              border: Border(
                bottom: BorderSide(color: sColor.withOpacity(0.2), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: sColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(sIcon, size: 15, color: sColor),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#$orderId',
                      style: const TextStyle(
                        color: _T.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${items.length} item${items.length != 1 ? 's' : ''}',
                      style: TextStyle(color: _T.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                const Spacer(),
                _StatusPill(
                  status: status,
                  color: sColor,
                  dim: sDim,
                  icon: sIcon,
                ),
              ],
            ),
          ),

          // ── CARD BODY ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment + paid status row
                Row(
                  children: [
                    _MiniPill(
                      label: payment.toUpperCase(),
                      color: pColor,
                      dim: pDim,
                      icon: widget.paymentIcon(payment),
                    ),
                    const SizedBox(width: 8),
                    _MiniPill(
                      label: isPaid ? 'PAID' : 'UNPAID',
                      color: isPaid ? _T.success : _T.danger,
                      dim: isPaid ? _T.successDim : _T.dangerDim,
                      icon: isPaid
                          ? Icons.check_circle_outline_rounded
                          : Icons.highlight_off_rounded,
                    ),
                    const Spacer(),
                    if (!isPaid)
                      GestureDetector(
                        onTap: () => FirebaseFirestore.instance
                            .collection('orders')
                            .doc(widget.doc.id)
                            .update({'isPaid': true}),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _T.successDim,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _T.success.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: _T.success,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Mark Paid',
                                style: TextStyle(
                                  color: _T.success,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Customer info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _T.elevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _T.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      _Avatar(name: name),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: _T.text,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (phone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 11,
                                    color: _T.textFaint,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    phone,
                                    style: TextStyle(
                                      color: _T.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (address.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 11,
                                    color: _T.textFaint,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '$address${city.isNotEmpty ? ', $city' : ''}',
                                      style: TextStyle(
                                        color: _T.textMuted,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Items section — collapsible
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    children: [
                      Text(
                        'Items (${items.length})',
                        style: const TextStyle(
                          color: _T.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: _T.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: _expanded
                      ? Column(
                          children: [
                            const SizedBox(height: 8),
                            ...items.map((item) => _ItemRow(item: item)),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 12),
                Divider(color: _T.border, height: 1),
                const SizedBox(height: 12),

                // Total + status dropdown
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(color: _T.textMuted, fontSize: 10.5),
                        ),
                        Text(
                          'NPR $total',
                          style: const TextStyle(
                            color: _T.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _StatusDropdown(
                      doc: widget.doc,
                      status: status,
                      validStatuses: widget.validStatuses,
                      statusColor: widget.statusColor,
                      statusIcon: widget.statusIcon,
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
}

// ─── Item Row ─────────────────────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final qty = item['quantity'] ?? 1;
    final price = item['price'] ?? 0;
    final size = item['size']?.toString() ?? '';
    final colorName = item['color']?.toString() ?? '';
    final colorHex = item['colorHex']?.toString() ?? '';

    Color? swatch;
    if (colorHex.isNotEmpty) {
      try {
        swatch = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _T.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              width: 52,
              height: 52,
              child: Image.network(
                item['image'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: _T.card,
                  child: const Icon(
                    Icons.image_outlined,
                    color: _T.textFaint,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? '',
                  style: const TextStyle(
                    color: _T.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    if (size.isNotEmpty)
                      _VariantBadge(
                        label: 'Size: $size',
                        color: _T.accent,
                        dim: _T.accentDim,
                      ),
                    if (colorName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _T.card,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _T.border, width: 0.5),
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
                                    color: _T.borderBright,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              colorName,
                              style: TextStyle(
                                color: _T.textMuted,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '$qty × NPR $price',
                  style: TextStyle(color: _T.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),

          // Subtotal
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'NPR ${qty * price}',
                style: const TextStyle(
                  color: _T.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'subtotal',
                style: TextStyle(color: _T.textFaint, fontSize: 9.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Status Dropdown ──────────────────────────────────────────────────────────
class _StatusDropdown extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String status;
  final List<String> validStatuses;
  final Color Function(String) statusColor;
  final IconData Function(String) statusIcon;

  const _StatusDropdown({
    required this.doc,
    required this.status,
    required this.validStatuses,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final safeStatus = validStatuses.contains(status) ? status : 'pending';
    final color = statusColor(safeStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _T.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeStatus,
          isDense: true,
          icon: Icon(Icons.unfold_more_rounded, color: color, size: 16),
          style: const TextStyle(
            color: _T.text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: _T.card,
          items: validStatuses.map((s) {
            final c = statusColor(s);
            return DropdownMenuItem(
              value: s,
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: c.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(statusIcon(s), size: 13, color: c),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s[0].toUpperCase() + s.substring(1),
                    style: TextStyle(
                      color: c,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final String status;
  final Color color, dim;
  final IconData icon;
  const _StatusPill({
    required this.status,
    required this.color,
    required this.dim,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3), width: 0.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 5),
        Text(
          status[0].toUpperCase() + status.substring(1),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
  );
}

class _MiniPill extends StatelessWidget {
  final String label;
  final Color color, dim;
  final IconData icon;
  const _MiniPill({
    required this.label,
    required this.color,
    required this.dim,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: dim,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _VariantBadge extends StatelessWidget {
  final String label;
  final Color color, dim;
  const _VariantBadge({
    required this.label,
    required this.color,
    required this.dim,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: dim,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _T.accent.withOpacity(0.4),
            const Color(0xFF5B8DEF).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: _T.accentLight,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.5 + 0.5 * _anim.value),
        shape: BoxShape.circle,
      ),
    ),
  );
}

class _PulseLoader extends StatefulWidget {
  const _PulseLoader();

  @override
  State<_PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<_PulseLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Opacity(
      opacity: 0.4 + 0.6 * _anim.value,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_T.accent, const Color(0xFF5B8DEF)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.receipt_long_rounded,
          color: _T.white,
          size: 19,
        ),
      ),
    ),
  );
}
