import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom_/features/admin/screens/admin_login_screen.dart';
import 'package:ecom_/features/admin/screens/admin_orders_screen.dart';
import 'package:ecom_/features/admin/screens/admin_profile_screen.dart';
import 'package:ecom_/features/admin/screens/admin_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecom_/providers/admin_product_provider.dart';
import 'package:ecom_/features/admin/widgets/admin_product_form.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedNav = 0;

  static const Color _bg = Color(0xFF0B0F1A);
  static const Color _surface = Color(0xFF0F1524);
  static const Color _card = Color(0xFF141B2D);
  static const Color _accent = Color(0xFF6C5CE7);
  static const Color _white = Colors.white;
  static const Color _white54 = Colors.white54;
  static const Color _white12 = Colors.white12;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AdminProductProvider>().listenProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Fixed breakpoints ─────────────────────────────────────────────────────
  double get _width => MediaQuery.of(context).size.width;
  bool get _isMobile => _width < 650; // ← was 350, now correct
  bool get _isTablet => _width >= 650 && _width < 1100;
  bool get _isDesktop => _width >= 1100;

  List _filtered(AdminProductProvider provider) {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return provider.products;
    return provider.products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      drawer: _isMobile ? _buildSidebar() : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!_isMobile) _buildSidebar(),
            Expanded(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Consumer<AdminProductProvider>(
                      builder: (context, provider, _) {
                        if (provider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(color: _accent),
                          );
                        }
                        if (provider.error != null) {
                          return _buildError(provider);
                        }
                        return _buildBody(provider);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SIDEBAR
  // ────────────────────────────────────────────────────────────────────────

  Widget _buildSidebar() {
    final items = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
      {'icon': Icons.outbox_rounded, 'label': 'Orders'},
      {'icon': Icons.person_outline, 'label': 'Profile'},
      {'icon': Icons.settings_outlined, 'label': 'Settings'},
    ];

    final sidebarWidth = _isMobile ? 220.0 : (_isDesktop ? 220.0 : 68.0);
    final showLabel = _isMobile || _isDesktop;

    return Container(
      width: sidebarWidth,
      color: _surface,
      child: Column(
        children: [
          const SizedBox(height: 28),

          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: _white,
                    size: 18,
                  ),
                ),
                if (showLabel) ...[
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'ECOM ADMIN',
                      style: TextStyle(
                        color: _white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Nav Items
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = _selectedNav == index;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedNav = index);
                if (_isMobile) Navigator.pop(context);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                padding: EdgeInsets.symmetric(
                  horizontal: showLabel ? 12 : 0,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _accent.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(color: _accent.withOpacity(0.3))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: showLabel
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: isSelected ? _accent : _white54,
                      size: 20,
                    ),
                    if (showLabel) ...[
                      const SizedBox(width: 10),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          color: isSelected ? _accent : _white54,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

          const Spacer(),

          // 🔴 Logout Button
          GestureDetector(
            onTap: _handleLogout,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: EdgeInsets.symmetric(
                horizontal: showLabel ? 12 : 0,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: showLabel
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                  if (showLabel) ...[
                    const SizedBox(width: 10),
                    const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  } // ─────────────────────────────────────────────────────────────────────────

  void _handleLogout() {
    // Example logic (adjust based on your auth system)

    // Clear session / token if needed

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminLoginScreen(), // or LoginScreen
      ),
    );
  }

  // HEADER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isMobile ? 8 : 16,
        vertical: 12,
      ),
      color: _surface,
      child: Row(
        children: [
          // Hamburger — mobile only
          if (_isMobile)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: _white, size: 22),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
            ),

          if (_isMobile) const SizedBox(width: 4),

          // Title — hide on very small screens to save space
          if (_width > 360)
            Text(
              _isMobile ? 'Dashboard' : 'Admin Dashboard',
              style: TextStyle(
                color: _white,
                fontSize: _isMobile ? 15 : 17,
                fontWeight: FontWeight.w700,
              ),
            ),

          const Spacer(),

          // Search bar — flexible width
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _isMobile ? 150 : (_isTablet ? 220 : 300),
                minWidth: 100,
              ),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _white12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: _white, fontSize: 12),
                  cursorColor: _accent,
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: _white54, fontSize: 12),
                    prefixIcon: Icon(Icons.search, color: _white54, size: 16),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: _card,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Add button
          _isMobile
              ? GestureDetector(
                  onTap: _openAddForm,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: _white,
                      size: 18,
                    ),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: _openAddForm,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Add Product',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: _white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  void _openAddForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminProductForm(product: null)),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BODY
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBody(AdminProductProvider provider) {
    final products = _filtered(provider);

    switch (_selectedNav) {
      // 🟣 DASHBOARD
      case 0:
        return _dashboardLayout(provider, products);

      case 1:
        return AdminOrdersScreen();

      // 👤 PROFILE
      case 2:
        return const AdminProfileScreen();

      // ⚙️ SETTINGS
      case 3:
        return const AdminSettingsScreen();

      default:
        return _dashboardLayout(provider, products);
    }
  }

  Widget _dashboardLayout(AdminProductProvider provider, List products) {
    // Mobile — single column
    if (_isMobile) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalytics(provider),
            const SizedBox(height: 16),
            _buildProductList(products),
            const SizedBox(height: 16),
            _buildMonthlySales(),
            const SizedBox(height: 16),

            _buildInventoryPanel(provider, scrollable: true),
          ],
        ),
      );
    }

    // Tablet — two column
    if (_isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildAnalytics(provider),
                  const SizedBox(height: 16),
                  _buildProductList(products),
                  const SizedBox(height: 16),
                  _buildMonthlySales(),
                ],
              ),
            ),
          ),
          SizedBox(width: 240, child: _buildInventoryPanel(provider)),
        ],
      );
    }

    // Desktop — wide layout
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildAnalytics(provider),
                const SizedBox(height: 20),
                _buildProductList(products),
                const SizedBox(height: 20),
                _buildMonthlySales(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SizedBox(width: 280, child: _buildInventoryPanel(provider)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ANALYTICS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAnalytics(AdminProductProvider provider) {
    int totalStock = 0;
    int outOfStock = 0;

    for (var p in provider.products) {
      totalStock += p.stock;
      if (p.stock == 0) outOfStock++;
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        double totalRevenue = 0;
        double esewaRevenue = 0;
        double codRevenue = 0;
        int totalOrders = 0;
        int paidOrders = 0;

        if (snapshot.hasData) {
          final orders = snapshot.data!.docs;

          for (var doc in orders) {
            final data = doc.data() as Map<String, dynamic>;

            final total = (data['total'] ?? 0).toDouble();
            final method = (data['paymentMethod'] ?? 'cod').toString();
            final isPaid = data['isPaid'] ?? false;

            totalOrders++;
            totalRevenue += total;

            if (method == 'esewa') {
              esewaRevenue += total;
            } else {
              codRevenue += total;
            }

            if (isPaid) paidOrders++;
          }
        }

        final cards = [
          {
            'title': 'Products',
            'value': provider.products.length.toString(),
            'icon': Icons.inventory_2_outlined,
            'color': _accent,
          },
          {
            'title': 'Total Stock',
            'value': totalStock.toString(),
            'icon': Icons.warehouse_outlined,
            'color': const Color(0xFF00B894),
          },
          {
            'title': 'Out of Stock',
            'value': outOfStock.toString(),
            'icon': Icons.remove_shopping_cart_outlined,
            'color': Colors.red,
          },

          // 🔥 NEW ANALYTICS
          {
            'title': 'Orders',
            'value': totalOrders.toString(),
            'icon': Icons.receipt_long,
            'color': Colors.blue,
          },
          {
            'title': 'Revenue',
            'value': 'NPR ${totalRevenue.toStringAsFixed(0)}',
            'icon': Icons.attach_money,
            'color': Colors.green,
          },
          {
            'title': 'eSewa',
            'value': 'NPR ${esewaRevenue.toStringAsFixed(0)}',
            'icon': Icons.account_balance_wallet,
            'color': Colors.greenAccent,
          },
          {
            'title': 'COD',
            'value': 'NPR ${codRevenue.toStringAsFixed(0)}',
            'icon': Icons.money,
            'color': Colors.orange,
          },
          {
            'title': 'Paid Orders',
            'value': paidOrders.toString(),
            'icon': Icons.verified,
            'color': Colors.teal,
          },
        ];

        if (_isMobile) {
          return SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _analyticsCard(cards[i], width: 160),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth < 600 ? 2 : 4;
            final w = (constraints.maxWidth - (12 * (count - 1))) / count;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards
                  .map((c) => _analyticsCard(c, width: w.clamp(140.0, 260.0)))
                  .toList(),
            );
          },
        );
      },
    );
  }

  Widget _analyticsCard(Map card, {required double width}) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _white12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (card['color'] as Color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                card['icon'] as IconData,
                color: card['color'] as Color,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card['title'] as String,
                    style: const TextStyle(color: _white54, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    card['value'] as String,
                    style: const TextStyle(
                      color: _white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRODUCT LIST
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProductList(List products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Products',
              style: TextStyle(
                color: _white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${products.length} items',
              style: const TextStyle(color: _white54, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (products.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.inbox_outlined, color: _white54, size: 36),
                SizedBox(height: 10),
                Text(
                  'No products found',
                  style: TextStyle(color: _white54, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            itemBuilder: (_, i) {
              final p = products[i];
              final imageUrl = p.images.isNotEmpty ? p.images[0] : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _white12),
                ),
                child: Row(
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: _white12,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: _white54,
                                    size: 18,
                                  ),
                                ),
                              )
                            : Container(
                                color: _white12,
                                child: const Icon(
                                  Icons.image_outlined,
                                  color: _white54,
                                  size: 18,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              color: _white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: [
                              _pill(
                                p.category,
                                _accent.withOpacity(0.2),
                                _accent,
                              ),
                              _pill(
                                'x${p.stock}',
                                p.stock > 0
                                    ? Colors.green.withOpacity(0.15)
                                    : Colors.red.withOpacity(0.15),
                                p.stock > 0 ? Colors.green : Colors.red,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Price + actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'NPR ${p.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _actionBtn(
                              icon: Icons.edit_outlined,
                              color: _accent,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminProductForm(product: p),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _actionBtn(
                              icon: Icons.delete_outline_rounded,
                              color: Colors.red,
                              onTap: () => _confirmDelete(p.id, p.name),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INVENTORY PANEL
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildInventoryPanel(
    AdminProductProvider provider, {
    bool scrollable = false,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: scrollable ? MainAxisSize.min : MainAxisSize.max,
      children: [
        const Text(
          'Inventory',
          style: TextStyle(
            color: _white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),

        if (provider.products.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No products yet', style: TextStyle(color: _white54)),
            ),
          )
        else if (scrollable)
          // Mobile: shrinkwrap inside scroll
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.products.length,
            itemBuilder: (_, i) => _inventoryItem(provider.products[i]),
          )
        else
          // Tablet/Desktop: Expanded scrollable
          Expanded(
            child: ListView.builder(
              itemCount: provider.products.length,
              itemBuilder: (_, i) => _inventoryItem(provider.products[i]),
            ),
          ),
      ],
    );

    return Container(
      color: _surface,
      padding: const EdgeInsets.all(14),
      child: scrollable ? content : content,
    );
  }

  Widget _inventoryItem(dynamic p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  p.name,
                  style: const TextStyle(
                    color: _white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'x${p.stock}',
                style: TextStyle(
                  color: p.stock > 0 ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (p.sizes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: p.sizes
                  .map<Widget>(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          color: _accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //monthly sales placeholder
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMonthlySales() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(color: _accent)),
          );
        }

        final orders = snapshot.data!.docs;

        double totalRevenue = 0;
        double esewaRevenue = 0;
        double codRevenue = 0;
        int totalUnits = 0;
        int totalOrders = orders.length;
        Map<String, int> categoryUnits = {};

        for (var doc in orders) {
          final data = doc.data() as Map<String, dynamic>;
          final total = (data['total'] ?? 0).toDouble();
          final method = (data['paymentMethod'] ?? 'cod').toString();
          final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

          totalRevenue += total;

          if (method == 'esewa') {
            esewaRevenue += total;
          } else {
            codRevenue += total;
          }

          for (var item in items) {
            final qty = (item['quantity'] ?? 1) as int;
            final category = (item['category'] ?? 'other').toString();

            totalUnits += qty;
            categoryUnits[category] = (categoryUnits[category] ?? 0) + qty;
          }
        }

        final avgOrder = totalOrders > 0 ? totalRevenue / totalOrders : 0;

        final sortedCats = categoryUnits.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            border: Border(top: BorderSide(color: _white12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                children: [
                  const Icon(Icons.insights, color: _accent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Monthly Sales — ${_monthName(now.month)} ${now.year}',
                    style: const TextStyle(
                      color: _white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// 🔥 HORIZONTAL CARDS
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _cardWrapper(
                      _salesCard(
                        'Revenue',
                        'NPR ${totalRevenue.toStringAsFixed(0)}',
                        '${totalOrders} orders',
                        icon: Icons.attach_money,
                        color: Colors.green,
                      ),
                    ),
                    _cardWrapper(
                      _salesCard(
                        'Units Sold',
                        totalUnits.toString(),
                        'items dispatched',
                        icon: Icons.inventory_2_outlined,
                        color: Colors.blue,
                      ),
                    ),
                    _cardWrapper(
                      _salesCard(
                        'Avg. Order',
                        'NPR ${avgOrder.toStringAsFixed(0)}',
                        'per order',
                        icon: Icons.bar_chart,
                        color: Colors.orange,
                      ),
                    ),
                    _cardWrapper(
                      _salesCard(
                        'eSewa',
                        'NPR ${esewaRevenue.toStringAsFixed(0)}',
                        'COD: NPR ${codRevenue.toStringAsFixed(0)}',
                        icon: Icons.account_balance_wallet,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// CATEGORY BREAKDOWN
              if (sortedCats.isNotEmpty) ...[
                const Text(
                  'Top categories',
                  style: TextStyle(color: _white54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ...sortedCats.take(5).map((entry) {
                  final pct = totalUnits > 0 ? entry.value / totalUnits : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                color: _white54,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '${entry.value} units',
                              style: const TextStyle(
                                color: _white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: _white12,
                            valueColor: const AlwaysStoppedAnimation(_accent),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              if (orders.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'No orders this month',
                      style: TextStyle(color: _white54, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _cardWrapper(Widget child) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 10),
      child: child,
    );
  }

  Widget _salesCard(
    String label,
    String value,
    String sub, {
    IconData icon = Icons.bar_chart,
    Color color = Colors.blue,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 140;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _white12),
          ),
          child: Row(
            children: [
              /// ICON
              Container(
                width: isSmall ? 32 : 40,
                height: isSmall ? 32 : 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: isSmall ? 16 : 20),
              ),

              const SizedBox(width: 10),

              /// TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: _white54,
                        fontSize: isSmall ? 9 : 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        color: _white,
                        fontSize: isSmall ? 13 : 16,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      sub,
                      style: TextStyle(
                        color: _white54,
                        fontSize: isSmall ? 8 : 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONFIRM DELETE
  // ─────────────────────────────────────────────────────────────────────────
  void _confirmDelete(String productId, String productName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text(
              'Delete Product',
              style: TextStyle(color: _white, fontSize: 15),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: _white54, fontSize: 13, height: 1.5),
            children: [
              const TextSpan(text: 'Delete '),
              TextSpan(
                text: '"$productName"',
                style: const TextStyle(
                  color: _white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: '? This cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _white54)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<AdminProductProvider>();
              final success = await provider.deleteProduct(productId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '$productName deleted'
                          : provider.error ?? 'Delete failed',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 15),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: _white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ERROR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildError(AdminProductProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              provider.error ?? 'Something went wrong',
              style: const TextStyle(color: _white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.listenProducts(),
              style: ElevatedButton.styleFrom(backgroundColor: _accent),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pill(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: color, size: 13),
      ),
    );
  }
}
