import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_product_provider.dart';
import '../widgets/admin_product_form.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _Tok {
  // Dark
  static const dBg = Color(0xFF080C14);
  static const dSurface = Color(0xFF0D1220);
  static const dCard = Color(0xFF111827);
  static const dElevated = Color(0xFF1A2235);
  static const dBorder = Color(0xFF1E2D42);
  static const dBorderBright = Color(0xFF2A3D56);
  static const dText = Color(0xFFE2E8F0);
  static const dTextMuted = Color(0xFF7A8BA5);
  static const dTextFaint = Color(0xFF3D4D63);

  // Light
  static const lBg = Color(0xFFF5F7FC);
  static const lSurface = Color(0xFFFFFFFF);
  static const lCard = Color(0xFFFFFFFF);
  static const lElevated = Color(0xFFF0F3FA);
  static const lBorder = Color(0xFFE4E9F2);
  static const lBorderBright = Color(0xFFCDD5E5);
  static const lText = Color(0xFF111827);
  static const lTextMuted = Color(0xFF6B7A99);
  static const lTextFaint = Color(0xFFB0BDD4);

  // Brand (same in both)
  static const accent = Color(0xFF7C6EFA);
  static const accentLight = Color(0xFF9D92FB);
  static const accentDim = Color(0x207C6EFA);
  static const accentBorder = Color(0x407C6EFA);
  static const success = Color(0xFF10D991);
  static const successDim = Color(0x1510D991);
  static const danger = Color(0xFFFF5B5B);
  static const dangerDim = Color(0x15FF5B5B);
}

// ─── Theme-aware color resolver ────────────────────────────────────────────────
extension _ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bg => isDark ? _Tok.dBg : _Tok.lBg;
  Color get surface => isDark ? _Tok.dSurface : _Tok.lSurface;
  Color get card => isDark ? _Tok.dCard : _Tok.lCard;
  Color get elevated => isDark ? _Tok.dElevated : _Tok.lElevated;
  Color get border => isDark ? _Tok.dBorder : _Tok.lBorder;
  Color get borderBright => isDark ? _Tok.dBorderBright : _Tok.lBorderBright;
  Color get text => isDark ? _Tok.dText : _Tok.lText;
  Color get textMuted => isDark ? _Tok.dTextMuted : _Tok.lTextMuted;
  Color get textFaint => isDark ? _Tok.dTextFaint : _Tok.lTextFaint;
}

LinearGradient _accentGrad() =>
    const LinearGradient(colors: [_Tok.accent, Color(0xFF5B8DEF)]);

class AdminProductScreen extends StatefulWidget {
  const AdminProductScreen({super.key});

  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _search = TextEditingController();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
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
    _search.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  List _filtered(AdminProductProvider provider) {
    final q = _search.text.toLowerCase();
    if (q.isEmpty) return provider.products;
    return provider.products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q),
        )
        .toList();
  }

  double get _width => MediaQuery.of(context).size.width;
  bool get _isMobile => _width < 700;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Consumer<AdminProductProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) return _buildLoader();
            if (provider.error != null) return _buildError(provider);

            final products = _filtered(provider);

            return Column(
              children: [
                _buildHeader(context, provider),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _isMobile
                        ? _buildMobileLayout(context, provider, products)
                        : _buildDesktopLayout(context, provider, products),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, AdminProductProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(bottom: BorderSide(color: context.border)),
      ),
      child: Row(
        children: [
          // Icon + title
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: _accentGrad(),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Products',
                style: TextStyle(
                  color: context.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${provider.products.length} items total',
                style: TextStyle(color: context.textMuted, fontSize: 11.5),
              ),
            ],
          ),
          SizedBox(width: 715),
          // Search
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _isMobile ? 160 : 240,
                minWidth: 100,
              ),
              child: _SearchField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                borderColor: context.border,
                cardColor: context.elevated,
                textColor: context.text,
                hintColor: context.textMuted,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Add button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminProductForm(product: null),
              ),
            ),
            child: Container(
              padding: _isMobile
                  ? const EdgeInsets.all(9)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: _accentGrad(),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _Tok.accent.withOpacity(0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isMobile
                  ? const Icon(Icons.add_rounded, color: Colors.white, size: 18)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add_rounded, color: Colors.white, size: 15),
                        SizedBox(width: 6),
                        Text(
                          'Add Product',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── LAYOUTS ─────────────────────────────────────────────────────────────────
  Widget _buildDesktopLayout(
    BuildContext context,
    AdminProductProvider provider,
    List products,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: _buildProductList(context, provider, products),
        ),
        SizedBox(width: 270, child: _buildInventoryPanel(context, provider)),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AdminProductProvider provider,
    List products,
  ) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: context.surface,
            child: TabBar(
              labelColor: _Tok.accent,
              unselectedLabelColor: context.textMuted,
              indicatorColor: _Tok.accent,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Products'),
                Tab(text: 'Inventory'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildProductList(context, provider, products),
                _buildInventoryPanel(context, provider, scrollable: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PRODUCT LIST ────────────────────────────────────────────────────────────
  Widget _buildProductList(
    BuildContext context,
    AdminProductProvider provider,
    List products,
  ) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _Tok.accentDim,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _Tok.accentBorder, width: 0.5),
              ),
              child: const Icon(
                Icons.inbox_outlined,
                color: _Tok.accent,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No products found',
              style: TextStyle(
                color: context.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Try a different search term',
              style: TextStyle(color: context.textMuted, fontSize: 12.5),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      itemCount: products.length,
      itemBuilder: (_, i) => _ProductCard(
        product: products[i],
        onEdit: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminProductForm(product: products[i]),
          ),
        ),
        onDelete: () =>
            _confirmDelete(context, provider, products[i].id, products[i].name),
      ),
    );
  }

  // ── INVENTORY PANEL ─────────────────────────────────────────────────────────
  Widget _buildInventoryPanel(
    BuildContext context,
    AdminProductProvider provider, {
    bool scrollable = false,
  }) {
    final outOfStock = provider.products.where((p) => p.stock == 0).length;
    final totalStock = provider.products.fold<int>(
      0,
      (sum, p) => sum + (p.stock),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: scrollable ? MainAxisSize.min : MainAxisSize.max,
      children: [
        // Panel header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.layers_rounded,
                    size: 14,
                    color: _Tok.accent,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Inventory',
                    style: TextStyle(
                      color: context.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Summary chips
              Row(
                children: [
                  Expanded(
                    child: _SummaryChip(
                      label: 'Total Stock',
                      value: totalStock.toString(),
                      color: _Tok.success,
                      dim: _Tok.successDim,
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryChip(
                      label: 'Out of Stock',
                      value: outOfStock.toString(),
                      color: _Tok.danger,
                      dim: _Tok.dangerDim,
                      icon: Icons.remove_shopping_cart_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Divider(height: 1, color: context.border),
        const SizedBox(height: 6),

        if (provider.products.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No products yet',
                style: TextStyle(color: context.textMuted, fontSize: 13),
              ),
            ),
          )
        else if (scrollable)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.products.length,
            itemBuilder: (_, i) => _InventoryRow(product: provider.products[i]),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: provider.products.length,
              itemBuilder: (_, i) =>
                  _InventoryRow(product: provider.products[i]),
            ),
          ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(left: BorderSide(color: context.border)),
      ),
      child: content,
    );
  }

  // ── CONFIRM DELETE ───────────────────────────────────────────────────────────
  void _confirmDelete(
    BuildContext context,
    AdminProductProvider provider,
    String id,
    String name,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) => Dialog(
        backgroundColor: context.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
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
                      color: _Tok.dangerDim,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: _Tok.danger,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Delete Product',
                    style: TextStyle(
                      color: context.text,
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
                    color: context.textMuted,
                    fontSize: 13,
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(text: 'Delete '),
                    TextSpan(
                      text: '"$name"',
                      style: TextStyle(
                        color: context.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: '? This cannot be undone.'),
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
                      style: TextStyle(color: context.textMuted, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final success = await provider.deleteProduct(id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? '$name deleted'
                                  : provider.error ?? 'Failed',
                            ),
                            backgroundColor: success
                                ? _Tok.success
                                : _Tok.danger,
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
                      backgroundColor: _Tok.danger,
                      foregroundColor: Colors.white,
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

  // ── LOADING / ERROR ──────────────────────────────────────────────────────────
  Widget _buildLoader() {
    return Center(child: _PulseLoader());
  }

  Widget _buildError(AdminProductProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _Tok.dangerDim,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: _Tok.danger,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            provider.error ?? 'Something went wrong',
            style: TextStyle(color: context.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: provider.listenProducts,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: _accentGrad(),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Product Card ─────────────────────────────────────────────────────────────
class _ProductCard extends StatefulWidget {
  final dynamic product;
  final VoidCallback onEdit, onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final inStock = (p.stock as int) > 0;
    final imageUrl = (p.images as List).isNotEmpty ? p.images[0] : '';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _hovered ? context.elevated : context.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered ? context.borderBright : context.border,
            width: 0.5,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      context.isDark ? 0.25 : 0.07,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 54,
                height: 54,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgPlaceholder(context),
                      )
                    : _imgPlaceholder(context),
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
                    style: TextStyle(
                      color: context.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Chip(p.category, _Tok.accentDim, _Tok.accentLight),
                      const SizedBox(width: 5),
                      _Chip(
                        inStock ? 'x${p.stock}' : 'Out of Stock',
                        inStock ? _Tok.successDim : _Tok.dangerDim,
                        inStock ? _Tok.success : _Tok.danger,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Price + Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'NPR ${p.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: _Tok.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IconBtn(
                      icon: Icons.edit_outlined,
                      color: _Tok.accent,
                      bg: _Tok.accentDim,
                      onTap: widget.onEdit,
                    ),
                    const SizedBox(width: 6),
                    _IconBtn(
                      icon: Icons.delete_outline_rounded,
                      color: _Tok.danger,
                      bg: _Tok.dangerDim,
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

  Widget _imgPlaceholder(BuildContext context) => Container(
    color: context.elevated,
    child: Icon(Icons.image_outlined, color: context.textFaint, size: 22),
  );
}

// ─── Inventory Row ────────────────────────────────────────────────────────────
class _InventoryRow extends StatelessWidget {
  final dynamic product;
  const _InventoryRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final inStock = (p.stock as int) > 0;
    final pct = ((p.stock as int).clamp(0, 100)) / 100.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: context.border, width: 0.5),
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
                      color: context.text,
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
                    color: inStock ? _Tok.successDim : _Tok.dangerDim,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'x${p.stock}',
                    style: TextStyle(
                      color: inStock ? _Tok.success : _Tok.danger,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 4,
                backgroundColor: context.border,
                valueColor: AlwaysStoppedAnimation(
                  inStock ? _Tok.success : _Tok.danger,
                ),
              ),
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
                          color: context.elevated,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: context.borderBright,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            color: context.textMuted,
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
}

// ─── Summary Chip ─────────────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final String label, value;
  final Color color, dim;
  final IconData icon;
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    required this.dim,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: dim,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: context.textMuted, fontSize: 9.5),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─── Search Field ─────────────────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Color borderColor, cardColor, textColor, hintColor;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.borderColor,
    required this.cardColor,
    required this.textColor,
    required this.hintColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: borderColor, width: 0.5),
    ),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: textColor, fontSize: 12.5),
      cursorColor: _Tok.accent,
      decoration: InputDecoration(
        hintText: 'Search products...',
        hintStyle: TextStyle(color: hintColor, fontSize: 12),
        prefixIcon: Icon(Icons.search_rounded, color: hintColor, size: 16),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    ),
  );
}

// ─── Shared tiny widgets ──────────────────────────────────────────────────────
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

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  final VoidCallback onTap;
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 13),
    ),
  );
}

class _PulseLoader extends StatefulWidget {
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
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_Tok.accent, const Color(0xFF5B8DEF)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.inventory_2_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    ),
  );
}
