import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom_/features/admin/screens/admin_login_screen.dart';
import 'package:ecom_/features/admin/screens/admin_orders_screen.dart';
import 'package:ecom_/features/admin/screens/admin_product_screen.dart';
import 'package:ecom_/features/admin/screens/admin_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecom_/providers/admin_product_provider.dart';
import 'package:ecom_/features/admin/widgets/admin_product_form.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────
class _T {
  // Backgrounds
  static const bg = Color(0xFF080C14);
  static const surface = Color(0xFF0D1220);
  static const card = Color(0xFF111827);
  static const cardHover = Color(0xFF161F30);
  static const elevated = Color(0xFF1A2235);

  // Brand
  static const accent = Color(0xFF7C6EFA);
  static const accentLight = Color(0xFF9D92FB);
  static const accentDim = Color(0x207C6EFA);
  static const accentBorder = Color(0x407C6EFA);

  // Status
  static const success = Color(0xFF10D991);
  static const successDim = Color(0x1510D991);
  static const danger = Color(0xFFFF5B5B);
  static const dangerDim = Color(0x15FF5B5B);
  static const warning = Color(0xFFF5A623);
  static const warningDim = Color(0x15F5A623);
  static const info = Color(0xFF38B6FF);
  static const infoDim = Color(0x1538B6FF);

  // Neutrals
  static const white = Color(0xFFFFFFFF);
  static const text = Color(0xFFE2E8F0);
  static const textMuted = Color(0xFF7A8BA5);
  static const textFaint = Color(0xFF3D4D63);
  static const border = Color(0xFF1E2D42);
  static const borderBright = Color(0xFF2A3D56);
}

// ─── Gradient helper ────────────────────────────────────────────────────────
LinearGradient _accentGrad([AlignmentGeometry begin = Alignment.topLeft]) =>
    LinearGradient(
      begin: begin,
      end: Alignment.bottomRight,
      colors: [_T.accent, Color(0xFF5B8DEF)],
    );

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  int _selectedNav = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    Future.microtask(() {
      context.read<AdminProductProvider>().listenProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  double get _width => MediaQuery.of(context).size.width;
  bool get _isMobile => _width < 650;
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

  void _switchNav(int index) {
    setState(() => _selectedNav = index);
    _fadeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
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
                          return Center(child: _PulseLoader());
                        }
                        if (provider.error != null) {
                          return _buildError(provider);
                        }
                        return FadeTransition(
                          opacity: _fadeAnim,
                          child: _buildBody(provider),
                        );
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

  // ── SIDEBAR ────────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    final items = [
      {'icon': Icons.grid_view_rounded, 'label': 'Dashboard'},
      {'icon': Icons.person_rounded, 'label': 'Profile & More'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Orders'},
      {'icon': Icons.production_quantity_limits, 'label': 'Products'},
    ];

    final double w = _isMobile ? 240.0 : (_isDesktop ? 220.0 : 64.0);
    final bool showLabel = _isMobile || _isDesktop;

    return Container(
      width: w,
      decoration: BoxDecoration(
        color: _T.surface,
        border: Border(right: BorderSide(color: _T.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Logo
          Padding(
            padding: EdgeInsets.symmetric(horizontal: showLabel ? 18 : 12),
            child: Row(
              mainAxisAlignment: showLabel
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: _accentGrad(),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: _T.white,
                    size: 19,
                  ),
                ),
                if (showLabel) ...[
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'ECOM',
                        style: TextStyle(
                          color: _T.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'ADMIN',
                        style: TextStyle(
                          color: _T.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Label
          if (showLabel)
            Padding(
              padding: const EdgeInsets.only(left: 18, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'NAVIGATION',
                  style: TextStyle(
                    color: _T.textFaint,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

          // Nav items
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final selected = _selectedNav == i;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: InkWell(
                onTap: () {
                  _switchNav(i);
                  if (_isMobile) Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: showLabel ? 12 : 0,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? _T.accentDim : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: selected
                        ? Border.all(color: _T.accentBorder, width: 0.5)
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: showLabel
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      // Icon with gradient when selected
                      if (selected)
                        ShaderMask(
                          shaderCallback: (b) => _accentGrad().createShader(b),
                          child: Icon(
                            item['icon'] as IconData,
                            color: _T.white,
                            size: 19,
                          ),
                        )
                      else
                        Icon(
                          item['icon'] as IconData,
                          color: _T.textMuted,
                          size: 19,
                        ),
                      if (showLabel) ...[
                        const SizedBox(width: 10),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            color: selected ? _T.accentLight : _T.textMuted,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),

          const Spacer(),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Divider(color: _T.border, height: 1),
          ),
          const SizedBox(height: 8),

          // Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: InkWell(
              onTap: _handleLogout,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: showLabel ? 12 : 0,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: showLabel
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: _T.danger, size: 19),
                    if (showLabel) ...[
                      const SizedBox(width: 10),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: _T.danger,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _handleLogout() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const AdminLoginScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final navLabels = [
      'Dashboard',
      'Orders',
      'Profile',
      'Products',
      'Settings',
    ];

    final bool showActions = _selectedNav == 0 || _selectedNav == 1;
    // 0 = Dashboard, 1 = Orders

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: _isMobile ? 10 : 20),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          if (_isMobile)
            Builder(
              builder: (ctx) => IconButton(
                icon: Icon(Icons.menu_rounded, color: cs.onSurface),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),

          if (_isMobile) const SizedBox(width: 8),

          /// Title
          if (_width > 360)
            Text(
              navLabels[_selectedNav],
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),

          const Spacer(),

          /// 👇 ONLY SHOW ON DASHBOARD / ORDERS
          if (showActions) ...[
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _isMobile ? 150 : (_isTablet ? 220 : 280),
                ),
                child: _GlassSearchField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(width: 10),

            _isMobile
                ? _GradientIconButton(
                    icon: Icons.add_rounded,
                    onTap: _openAddForm,
                  )
                : _GradientButton(
                    label: 'Add Product',
                    icon: Icons.add_rounded,
                    onTap: _openAddForm,
                  ),
          ],
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

  // ── BODY ───────────────────────────────────────────────────────────────────
  Widget _buildBody(AdminProductProvider provider) {
    final products = _filtered(provider);

    switch (_selectedNav) {
      case 0:
        return _dashboardLayout(provider, products);
      case 1:
        return AdminProfileScreen();
      case 2:
        return AdminOrdersScreen();
      case 3:
        return const AdminProductScreen();

      default:
        return _dashboardLayout(provider, products);
    }
  }

  Widget _dashboardLayout(AdminProductProvider provider, List products) {
    if (_isMobile) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalytics(provider),
            const SizedBox(height: 16),
            _buildMonthlySales(),
            const SizedBox(height: 16),
            _buildDailySales(),
            const SizedBox(height: 16),
            _buildProductList(products),
            const SizedBox(height: 16),
            _buildInventoryPanel(provider, scrollable: true),
          ],
        ),
      );
    }

    if (_isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _buildAnalytics(provider),
                  const SizedBox(height: 18),
                  _buildMonthlySales(),
                  const SizedBox(height: 18),
                  _buildDailySales(),
                  const SizedBox(height: 18),
                  _buildProductList(products),
                ],
              ),
            ),
          ),
          SizedBox(width: 240, child: _buildInventoryPanel(provider)),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                _buildAnalytics(provider),
                const SizedBox(height: 22),
                _buildMonthlySales(),
                const SizedBox(height: 22),
                _buildDailySales(),
                const SizedBox(height: 22),
                _buildProductList(products),
              ],
            ),
          ),
        ),
        SizedBox(width: 290, child: _buildInventoryPanel(provider)),
      ],
    );
  }

  // ── ANALYTICS ──────────────────────────────────────────────────────────────
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
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final total = (data['total'] ?? 0).toDouble();
            final method = (data['paymentMethod'] ?? 'cod').toString();
            final isPaid = data['isPaid'] ?? false;
            totalOrders++;
            totalRevenue += total;
            if (method == 'esewa')
              esewaRevenue += total;
            else
              codRevenue += total;
            if (isPaid) paidOrders++;
          }
        }

        final cards = [
          _AnalyticsData(
            'Products',
            provider.products.length.toString(),
            Icons.inventory_2_outlined,
            _T.accent,
            _T.accentDim,
          ),
          _AnalyticsData(
            'Total Stock',
            totalStock.toString(),
            Icons.warehouse_outlined,
            _T.success,
            _T.successDim,
          ),
          _AnalyticsData(
            'Out of Stock',
            outOfStock.toString(),
            Icons.remove_shopping_cart_outlined,
            _T.danger,
            _T.dangerDim,
          ),
          _AnalyticsData(
            'Orders',
            totalOrders.toString(),
            Icons.receipt_long_rounded,
            _T.info,
            _T.infoDim,
          ),
          _AnalyticsData(
            'Revenue',
            'NPR ${totalRevenue.toStringAsFixed(0)}',
            Icons.attach_money_rounded,
            _T.success,
            _T.successDim,
          ),
          _AnalyticsData(
            'eSewa',
            'NPR ${esewaRevenue.toStringAsFixed(0)}',
            Icons.account_balance_wallet_rounded,
            _T.accent,
            _T.accentDim,
          ),
          _AnalyticsData(
            'COD',
            'NPR ${codRevenue.toStringAsFixed(0)}',
            Icons.payments_rounded,
            _T.warning,
            _T.warningDim,
          ),
          _AnalyticsData(
            'Paid Orders',
            paidOrders.toString(),
            Icons.verified_rounded,
            _T.success,
            _T.successDim,
          ),
        ];

        if (_isMobile) {
          return SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _analyticsCard(cards[i], width: 155),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth < 600 ? 2 : 4;
            final w = (constraints.maxWidth - (12.0 * (count - 1))) / count;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards
                  .map((c) => _analyticsCard(c, width: w.clamp(130.0, 270.0)))
                  .toList(),
            );
          },
        );
      },
    );
  }

  Widget _analyticsCard(_AnalyticsData d, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: d.dimColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(d.icon, color: d.color, size: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  d.title,
                  style: TextStyle(
                    color: _T.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  d.value,
                  style: TextStyle(
                    color: _T.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PRODUCT LIST ───────────────────────────────────────────────────────────
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
                color: _T.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: _T.accentDim,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _T.accentBorder, width: 0.5),
              ),
              child: Text(
                '${products.length} items',
                style: TextStyle(
                  color: _T.accentLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (products.isEmpty)
          _EmptyState(icon: Icons.inbox_outlined, message: 'No products found')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            itemBuilder: (_, i) {
              final p = products[i];
              final imageUrl = p.images.isNotEmpty ? p.images[0] : '';
              return _ProductTile(
                product: p,
                imageUrl: imageUrl,
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminProductForm(product: p),
                  ),
                ),
                onDelete: () => _confirmDelete(p.id, p.name),
              );
            },
          ),
      ],
    );
  }

  // ── INVENTORY PANEL ────────────────────────────────────────────────────────
  Widget _buildInventoryPanel(
    AdminProductProvider provider, {
    bool scrollable = false,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: scrollable ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: const [
              Icon(Icons.layers_rounded, size: 15, color: _T.accent),
              SizedBox(width: 7),
              Text(
                'Inventory',
                style: TextStyle(
                  color: _T.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (provider.products.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No products yet',
                style: TextStyle(color: _T.textMuted, fontSize: 13),
              ),
            ),
          )
        else if (scrollable)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.products.length,
            itemBuilder: (_, i) => _inventoryItem(provider.products[i]),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: provider.products.length,
              itemBuilder: (_, i) => _inventoryItem(provider.products[i]),
            ),
          ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        border: Border(left: BorderSide(color: _T.border)),
      ),
      child: content,
    );
  }

  Widget _inventoryItem(dynamic p) {
    final inStock = (p.stock as int) > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _T.border),
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
                    style: TextStyle(
                      color: _T.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: inStock ? _T.successDim : _T.dangerDim,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'x${p.stock}',
                    style: TextStyle(
                      color: inStock ? _T.success : _T.danger,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if ((p.sizes as List).isNotEmpty) ...[
              const SizedBox(height: 7),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: (p.sizes as List)
                    .map<Widget>(
                      (s) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _T.elevated,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _T.borderBright,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            color: _T.textMuted,
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
      ),
    );
  }

  // ── MONTHLY SALES ──────────────────────────────────────────────────────────
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
          return const SizedBox(
            height: 60,
            child: Center(child: _PulseLoader()),
          );
        }

        final orders = snapshot.data!.docs;
        double totalRevenue = 0;
        double esewaRevenue = 0;
        double codRevenue = 0;
        int totalUnits = 0;
        Map<String, int> categoryUnits = {};

        for (var doc in orders) {
          final data = doc.data() as Map<String, dynamic>;
          final total = (data['total'] ?? 0).toDouble();
          final method = (data['paymentMethod'] ?? 'cod').toString();
          final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

          totalRevenue += total;
          if (method == 'esewa')
            esewaRevenue += total;
          else
            codRevenue += total;

          for (var item in items) {
            final qty = (item['quantity'] ?? 1) as int;
            final category = (item['category'] ?? 'other').toString();
            totalUnits += qty;
            categoryUnits[category] = (categoryUnits[category] ?? 0) + qty;
          }
        }

        final avgOrder = orders.isNotEmpty ? totalRevenue / orders.length : 0;
        final sortedCats = categoryUnits.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Container(
          decoration: BoxDecoration(
            color: _T.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _T.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: _accentGrad(),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: _T.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Sales',
                          style: TextStyle(
                            color: _T.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${_monthName(now.month)} ${now.year}',
                          style: TextStyle(color: _T.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Sales cards horizontal scroll
              SizedBox(
                height: 88,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    _salesCard(
                      'Revenue',
                      'NPR ${totalRevenue.toStringAsFixed(0)}',
                      '${orders.length} orders',
                      icon: Icons.trending_up_rounded,
                      color: _T.success,
                      dimColor: _T.successDim,
                    ),
                    _salesCard(
                      'Units Sold',
                      totalUnits.toString(),
                      'items dispatched',
                      icon: Icons.inventory_2_rounded,
                      color: _T.info,
                      dimColor: _T.infoDim,
                    ),
                    _salesCard(
                      'Avg. Order',
                      'NPR ${avgOrder.toStringAsFixed(0)}',
                      'per order',
                      icon: Icons.bar_chart_rounded,
                      color: _T.warning,
                      dimColor: _T.warningDim,
                    ),
                    _salesCard(
                      'eSewa',
                      'NPR ${esewaRevenue.toStringAsFixed(0)}',
                      'COD: NPR ${codRevenue.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_rounded,
                      color: _T.accent,
                      dimColor: _T.accentDim,
                    ),
                  ],
                ),
              ),

              // Category breakdown
              if (sortedCats.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Top Categories',
                    style: TextStyle(
                      color: _T.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ...sortedCats.take(5).map((entry) {
                  final pct = totalUnits > 0 ? entry.value / totalUnits : 0.0;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                color: _T.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '${entry.value} units',
                              style: TextStyle(
                                color: _T.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 5,
                            backgroundColor: _T.border,
                            valueColor: AlwaysStoppedAnimation(_T.accent),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              if (orders.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No orders this month',
                      style: TextStyle(color: _T.textMuted, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _salesCard(
    String label,
    String value,
    String sub, {
    required IconData icon,
    required Color color,
    required Color dimColor,
  }) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _T.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: dimColor,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(color: _T.textMuted, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: _T.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sub,
                  style: TextStyle(color: _T.textFaint, fontSize: 9.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const n = [
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
    return n[month - 1];
  }

  //daily

  Widget _buildDailySales() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 60,
            child: Center(child: _PulseLoader()),
          );
        }

        final orders = snapshot.data!.docs;
        double totalRevenue = 0;
        double esewaRevenue = 0;
        double codRevenue = 0;
        int totalUnits = 0;
        int pendingOrders = 0;
        int completedOrders = 0;
        Map<String, int> categoryUnits = {};
        Map<int, double> hourlyRevenue = {};

        for (var doc in orders) {
          final data = doc.data() as Map<String, dynamic>;
          final total = (data['total'] ?? 0).toDouble();
          final method = (data['paymentMethod'] ?? 'cod').toString();
          final status = (data['status'] ?? '').toString();
          final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

          totalRevenue += total;
          if (method == 'esewa')
            esewaRevenue += total;
          else
            codRevenue += total;

          if (status == 'pending') pendingOrders++;
          if (status == 'completed' || status == 'delivered') completedOrders++;

          if (createdAt != null) {
            final hour = createdAt.hour;
            hourlyRevenue[hour] = (hourlyRevenue[hour] ?? 0) + total;
          }

          for (var item in items) {
            final qty = (item['quantity'] ?? 1) as int;
            final category = (item['category'] ?? 'other').toString();
            totalUnits += qty;
            categoryUnits[category] = (categoryUnits[category] ?? 0) + qty;
          }
        }

        final avgOrder = orders.isNotEmpty ? totalRevenue / orders.length : 0.0;
        final sortedCats = categoryUnits.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Peak hour
        int? peakHour;
        double peakVal = 0;
        hourlyRevenue.forEach((h, v) {
          if (v > peakVal) {
            peakVal = v;
            peakHour = h;
          }
        });
        final peakLabel = peakHour != null
            ? '${peakHour.toString().padLeft(2, '0')}:00–${(peakHour! + 1).toString().padLeft(2, '0')}:00'
            : '—';

        // Hourly sparkline (0–23 bucketed into 8 segments of 3h)
        final sparkData = List.generate(8, (i) {
          double sum = 0;
          for (int h = i * 3; h < i * 3 + 3; h++) {
            sum += hourlyRevenue[h] ?? 0;
          }
          return sum;
        });
        final sparkMax = sparkData.fold(0.0, (a, b) => b > a ? b : a);

        return Container(
          decoration: BoxDecoration(
            color: _T.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _T.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: _accentGrad(),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.today_rounded,
                        color: _T.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Sales',
                            style: TextStyle(
                              color: _T.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${now.day} ${_monthName(now.month)} ${now.year}',
                            style: TextStyle(color: _T.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    // Live badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _T.successDim,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _T.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Live',
                            style: TextStyle(
                              color: _T.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Sales cards horizontal scroll ───────────────────────────
              SizedBox(
                height: 88,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    _salesCard(
                      'Revenue',
                      'NPR ${totalRevenue.toStringAsFixed(0)}',
                      '${orders.length} orders today',
                      icon: Icons.trending_up_rounded,
                      color: _T.success,
                      dimColor: _T.successDim,
                    ),
                    _salesCard(
                      'Units Sold',
                      totalUnits.toString(),
                      'items dispatched',
                      icon: Icons.inventory_2_rounded,
                      color: _T.info,
                      dimColor: _T.infoDim,
                    ),
                    _salesCard(
                      'Avg. Order',
                      'NPR ${avgOrder.toStringAsFixed(0)}',
                      'per order',
                      icon: Icons.bar_chart_rounded,
                      color: _T.warning,
                      dimColor: _T.warningDim,
                    ),
                    _salesCard(
                      'eSewa',
                      'NPR ${esewaRevenue.toStringAsFixed(0)}',
                      'COD: NPR ${codRevenue.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_rounded,
                      color: _T.accent,
                      dimColor: _T.accentDim,
                    ),
                  ],
                ),
              ),

              // ── Order status row ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    _statusChip(
                      Icons.hourglass_top_rounded,
                      'Pending',
                      pendingOrders.toString(),
                      _T.warning,
                      _T.warningDim,
                    ),
                    const SizedBox(width: 8),
                    _statusChip(
                      Icons.check_circle_rounded,
                      'Completed',
                      completedOrders.toString(),
                      _T.success,
                      _T.successDim,
                    ),
                    const SizedBox(width: 8),
                    _statusChip(
                      Icons.schedule_rounded,
                      'Peak Hour',
                      peakLabel,
                      _T.accent,
                      _T.accentDim,
                    ),
                  ],
                ),
              ),

              // ── Hourly sparkline ────────────────────────────────────────
              if (sparkMax > 0) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Revenue by Hour',
                        style: TextStyle(
                          color: _T.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '3h buckets',
                        style: TextStyle(color: _T.textFaint, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: SizedBox(
                    height: 44,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(sparkData.length, (i) {
                        final pct = sparkMax > 0
                            ? sparkData[i] / sparkMax
                            : 0.0;
                        final labels = [
                          '12a',
                          '3a',
                          '6a',
                          '9a',
                          '12p',
                          '3p',
                          '6p',
                          '9p',
                        ];
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      curve: Curves.easeOut,
                                      width: double.infinity,
                                      height: pct > 0
                                          ? (pct * 32).clamp(3.0, 32.0)
                                          : 3.0,
                                      decoration: BoxDecoration(
                                        color: pct > 0.7
                                            ? _T.accent
                                            : _T.accentDim,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  labels[i],
                                  style: TextStyle(
                                    color: _T.textFaint,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],

              // ── Top categories ──────────────────────────────────────────
              if (sortedCats.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Top Categories',
                    style: TextStyle(
                      color: _T.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ...sortedCats.take(5).map((entry) {
                  final pct = totalUnits > 0 ? entry.value / totalUnits : 0.0;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                color: _T.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '${entry.value} units',
                              style: TextStyle(
                                color: _T.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 5,
                            backgroundColor: _T.border,
                            valueColor: AlwaysStoppedAnimation(_T.accent),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              if (orders.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No orders today',
                      style: TextStyle(color: _T.textMuted, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Compact status chip used in the daily widget.
  Widget _statusChip(
    IconData icon,
    String label,
    String value,
    Color color,
    Color dimColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: dimColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: TextStyle(color: _T.textFaint, fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CONFIRM DELETE ─────────────────────────────────────────────────────────
  void _confirmDelete(String productId, String productName) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => Dialog(
        backgroundColor: _T.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _T.dangerDim,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: _T.danger,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Delete Product',
                    style: TextStyle(
                      color: _T.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: _T.textMuted,
                    fontSize: 13,
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(text: 'Are you sure you want to delete '),
                    TextSpan(
                      text: '"$productName"',
                      style: const TextStyle(
                        color: _T.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: '? This action cannot be undone.'),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: _T.textMuted, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                            backgroundColor: success ? _T.success : _T.danger,
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
                      backgroundColor: _T.danger,
                      foregroundColor: _T.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
  }

  // ── ERROR ──────────────────────────────────────────────────────────────────
  Widget _buildError(AdminProductProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _T.dangerDim,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: _T.danger,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              provider.error ?? 'Something went wrong',
              style: TextStyle(color: _T.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _GradientButton(
              label: 'Try Again',
              icon: Icons.refresh_rounded,
              onTap: provider.listenProducts,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data Model ─────────────────────────────────────────────────────────────
class _AnalyticsData {
  final String title, value;
  final IconData icon;
  final Color color, dimColor;
  const _AnalyticsData(
    this.title,
    this.value,
    this.icon,
    this.color,
    this.dimColor,
  );
}

// ─── Product Tile ────────────────────────────────────────────────────────────
class _ProductTile extends StatefulWidget {
  final dynamic product;
  final String imageUrl;
  final VoidCallback onEdit, onDelete;

  const _ProductTile({
    required this.product,
    required this.imageUrl,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<_ProductTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final inStock = (p.stock as int) > 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _hovered ? _T.cardHover : _T.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered ? _T.borderBright : _T.border,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 50,
                height: 50,
                child: widget.imageUrl.isNotEmpty
                    ? Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      color: _T.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Chip(p.category, _T.accentDim, _T.accentLight),
                      const SizedBox(width: 5),
                      _Chip(
                        'x${p.stock}',
                        inStock ? _T.successDim : _T.dangerDim,
                        inStock ? _T.success : _T.danger,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Price + actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'NPR ${p.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: _T.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IconAction(
                      icon: Icons.edit_outlined,
                      color: _T.accent,
                      bgColor: _T.accentDim,
                      onTap: widget.onEdit,
                    ),
                    const SizedBox(width: 6),
                    _IconAction(
                      icon: Icons.delete_outline_rounded,
                      color: _T.danger,
                      bgColor: _T.dangerDim,
                      onTap: widget.onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    color: _T.elevated,
    child: const Icon(Icons.image_outlined, color: _T.textFaint, size: 20),
  );
}

// ─── Reusable Widgets ────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final Color bg, textColor;
  const _Chip(this.label, this.bg, this.textColor);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: textColor,
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color, bgColor;
  final VoidCallback onTap;
  const _IconAction({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 13),
    ),
  );
}

class _GlassSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _GlassSearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    decoration: BoxDecoration(
      color: _T.card,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _T.border),
    ),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: _T.text, fontSize: 12.5),
      cursorColor: _T.accent,
      decoration: const InputDecoration(
        hintText: 'Search products...',
        hintStyle: TextStyle(color: _T.textMuted, fontSize: 12),
        prefixIcon: Icon(Icons.search_rounded, color: _T.textMuted, size: 16),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 10),
      ),
    ),
  );
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_T.accent, Color(0xFF5B8DEF)]),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: _T.accent.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _T.white, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _T.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _GradientIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GradientIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_T.accent, const Color(0xFF5B8DEF)]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: _T.white, size: 18),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(36),
    decoration: BoxDecoration(
      color: _T.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _T.border),
    ),
    child: Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _T.elevated,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _T.textFaint, size: 24),
        ),
        const SizedBox(height: 12),
        Text(message, style: TextStyle(color: _T.textMuted, fontSize: 13)),
      ],
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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
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
            Icons.storefront_rounded,
            color: _T.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
