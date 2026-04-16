import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom_/features/home/screens/edit_profile_screen.dart';
import 'package:ecom_/features/products/models/product_model.dart';
import 'package:ecom_/features/products/screens/product_details_screen.dart';
import 'package:ecom_/features/products/screens/checkout_screen.dart';
import 'package:ecom_/features/products/screens/wishlist_screen.dart';
import 'package:ecom_/providers/app_product_provider.dart';
import 'package:ecom_/providers/auth_provider.dart';
import 'package:ecom_/providers/theme_provider.dart';
import 'package:ecom_/providers/wishlist_provider.dart';
import 'package:ecom_/services/cart_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    HomeTab(),
    SearchTab(),
    CartTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            selectedItemColor: Theme.of(context).colorScheme.secondary,
            unselectedItemColor: Theme.of(
              context,
            ).colorScheme.onSurface.withOpacity(0.4),
            backgroundColor: Theme.of(context).colorScheme.surface,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            onTap: (index) => setState(() => currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search_rounded),
                label: 'Search',
              ),
              BottomNavigationBarItem(icon: CartBadgeIcon(), label: "Cart"),

              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CartBadgeIcon extends StatelessWidget {
  const CartBadgeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      return const Icon(Icons.shopping_cart_outlined);
    }

    final email = CartService.safeEmail(user.email!);

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .collection('cart');

    return StreamBuilder<QuerySnapshot>(
      stream: cartRef.snapshots(),
      builder: (context, snapshot) {
        int count = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            count += (data['quantity'] ?? 1) as int;
          }
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.shopping_cart_outlined),

            if (count > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME TAB
// ─────────────────────────────────────────────────────────────────────────────
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _selectedCategory = 0;

  final List<Map<String, String>> _categories = [
    {'label': 'All', 'emoji': '🛍️'},
    {'label': 'Socks', 'emoji': '🧦'},
    {'label': 'Underpants', 'emoji': '👙'},
    {'label': 'Innervest', 'emoji': '👕'},
  ];

  final List<String?> _categoryValues = [
    null,
    'socks',
    'underpants',
    'innervest',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AppProductProvider>(context, listen: false).listenProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              color: cs.surface,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CozyWear',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Comfort redefined',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: cs.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: cs.secondary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Category pills ────────────────────────────────────────
            Container(
              color: cs.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_categories.length, (index) {
                    final isSelected = _selectedCategory == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cs.secondary
                              : cs.onSurface.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: cs.secondary.withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Text(
                              _categories[index]['emoji']!,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _categories[index]['label']!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : cs.onSurface.withOpacity(0.6),
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

            // ── Divider ───────────────────────────────────────────────
            Divider(
              height: 1,
              thickness: 1,
              color: cs.onSurface.withOpacity(0.07),
            ),

            // ── Product grid ──────────────────────────────────────────
            Expanded(
              child: ProductGrid(category: _categoryValues[_selectedCategory]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT GRID
// ─────────────────────────────────────────────────────────────────────────────
class ProductGrid extends StatelessWidget {
  final String? category;

  const ProductGrid({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProductProvider>();
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    final isTablet = size.width > 600;

    if (provider.isLoading) {
      return _buildSkeletonGrid(context);
    }

    final products = category == null
        ? provider.products
        : provider.products
              .where((p) => p.category.toLowerCase() == category!.toLowerCase())
              .toList();

    if (products.isEmpty) {
      return _emptyState(cs);
    }

    return RefreshIndicator(
      color: cs.secondary,
      onRefresh: () async => provider.listenProducts(),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: 12,
        ),
        itemCount: products.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 3 : 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.68,
        ),
        itemBuilder: (_, i) => _ProductCard(product: products[i]),
      ),
    );
  }

  /// 🧊 EMPTY STATE
  Widget _emptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 60,
            color: cs.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 10),
          Text(
            category == null ? 'No products yet' : 'No $category found',
            style: TextStyle(
              fontSize: 15,
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔄 SKELETON LOADER
  Widget _buildSkeletonGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ProductCard extends StatefulWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final product = widget.product;

    // ✅ FIX: use provider inside build
    final wishlist = context.watch<WishlistProvider>();
    final isLiked = wishlist.isInWishlist(product);

    final String imageUrl = product.images.isNotEmpty ? product.images[0] : '';

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        );
      },

      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: isPressed ? 0.97 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// IMAGE
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: cs.surfaceContainerHighest,
                              child: Icon(
                                Icons.image_outlined,
                                color: cs.onSurface.withOpacity(0.3),
                              ),
                            ),
                    ),

                    /// ❤️ Wishlist (FIXED)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _iconCircle(
                        context,
                        icon: isLiked ? Icons.favorite : Icons.favorite_border,
                        isLiked: isLiked,
                        onTap: () {
                          final wasLiked = isLiked;

                          wishlist.toggle(product);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                wasLiked
                                    ? "Removed from wishlist"
                                    : "Added to wishlist",
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(12),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),

                    if (product.isNew)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _badge("NEW", cs.primary),
                      ),

                    if (product.discountPrice != null)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: _badge(
                          "-${product.discountPercentage}%",
                          cs.error,
                        ),
                      ),
                  ],
                ),
              ),

              /// INFO
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        product.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                      ),

                      const Spacer(),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'NPR ${product.finalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: cs.secondary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: product.isInStock
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailsScreen(
                                          product: product,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: product.isInStock
                                    ? cs.secondary
                                    : cs.onSurface.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.arrow_forward,
                                size: 14,
                                color: product.isInStock
                                    ? Colors.white
                                    : cs.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Better Wishlist Icon (UX UPGRADE)
  Widget _iconCircle(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required bool isLiked,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withOpacity(0.7)
              : Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: isLiked ? 1.2 : 1,
          child: Icon(
            icon,
            size: 14,
            color: isLiked ? Colors.red : cs.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH TAB
// ─────────────────────────────────────────────────────────────────────────────
class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  String _activeFilter = 'All';
  List<String> _history = [];

  static const _maxHistory = 8;
  static const _historyKey = 'search_history';

  final List<String> _filters = [
    'All',
    'Socks',
    'Underpants',
    'Innervest',
    'Thermal',
    'On Sale',
    'In Stock',
  ];

  final List<String> _trending = [
    '🔥 merino wool',
    '🔥 ankle socks',
    '🔥 boxer briefs',
    '🔥 thermal',
    '🔥 innervest',
    '🔥 3-pack',
    '🔥 compression',
  ];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── History persistence ────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw != null) {
      setState(() {
        _history = List<String>.from(jsonDecode(raw));
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(_history));
  }

  void _addHistory(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _history.remove(trimmed);
      _history.insert(0, trimmed);
      if (_history.length > _maxHistory) _history.removeLast();
    });
    _saveHistory();
  }

  void _deleteHistory(String item) {
    setState(() => _history.remove(item));
    _saveHistory();
  }

  void _clearAllHistory() {
    setState(() => _history.clear());
    _saveHistory();
  }

  void _tapHistory(String item) {
    _searchController.text = item;
    setState(() => _query = item);
    _focusNode.unfocus();
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  void _onChanged(String value) {
    setState(() => _query = value);
    _animController
      ..reset()
      ..forward();
  }

  void _onSubmitted(String value) {
    _addHistory(value);
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
    _focusNode.requestFocus();
  }

  // ── Filter ────────────────────────────────────────────────────────────────

  bool _matchesFilter(dynamic product) {
    switch (_activeFilter) {
      case 'On Sale':
        return product.discountPrice != null;
      case 'In Stock':
        return product.isInStock;
      case 'All':
        return true;
      default:
        return product.category.toLowerCase() == _activeFilter.toLowerCase();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProductProvider>(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isSearching = _query.trim().isNotEmpty;

    final results = isSearching
        ? provider.products.where((p) {
            final ql = _query.toLowerCase();
            final matchQuery =
                p.name.toLowerCase().contains(ql) ||
                p.category.toLowerCase().contains(ql) ||
                p.description.toLowerCase().contains(ql);
            return matchQuery && _matchesFilter(p);
          }).toList()
        : <dynamic>[];

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F14)
          : const Color(0xFFF7F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _buildHeader(cs, isDark),

            // ── Filter chips (only when searching) ──────────────────────────
            if (isSearching) _buildFilterRow(cs, isDark),

            // ── Body ────────────────────────────────────────────────────────
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: isSearching
                    ? _buildResults(results, cs, isDark)
                    : _buildHomeState(cs, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header (AppBar + search field) ────────────────────────────────────────

  Widget _buildHeader(ColorScheme cs, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Text(
                'Search',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              if (_query.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _query = '';
                      _activeFilter = 'All';
                    });
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Search field
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF0F0F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _focusNode.hasFocus
                    ? cs.primary.withOpacity(0.5)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: isDark ? Colors.white38 : const Color(0xFFAAAAAA),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    onChanged: _onChanged,
                    onSubmitted: _onSubmitted,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Socks, underpants, innervest…',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white30
                            : const Color(0xFFBBBBBB),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: _clearSearch,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white24
                            : const Color(0xFFCCCCCC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter chips ───────────────────────────────────────────────────────────

  Widget _buildFilterRow(ColorScheme cs, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f = _filters[i];
            final active = _activeFilter == f;
            return GestureDetector(
              onTap: () => setState(() => _activeFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF1A1A2E)
                      : (isDark
                            ? const Color(0xFF2A2A3E)
                            : const Color(0xFFF0F0F5)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? const Color(0xFF1A1A2E)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? Colors.white
                        : (isDark ? Colors.white60 : const Color(0xFF666666)),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Home state (history + trending) ───────────────────────────────────────

  Widget _buildHomeState(ColorScheme cs, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Recent searches
        if (_history.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('Recent searches', isDark),
              GestureDetector(
                onTap: _clearAllHistory,
                child: const Text(
                  'Clear all',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE94560),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(_history.length, (i) {
            final item = _history[i];
            return _HistoryTile(
              item: item,
              isDark: isDark,
              onTap: () => _tapHistory(item),
              onDelete: () => _deleteHistory(item),
            );
          }),
          const SizedBox(height: 24),
        ],

        // Trending
        _sectionLabel('Trending now', isDark),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _trending.map((t) {
            final label = t.replaceFirst('🔥 ', '');
            return GestureDetector(
              onTap: () => _tapHistory(label),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A3E)
                      : const Color(0xFFF0F0F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Text(
                  t,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF555555),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Results ────────────────────────────────────────────────────────────────

  Widget _buildResults(List results, ColorScheme cs, bool isDark) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$_query"',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try different keywords or filters',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  children: [
                    TextSpan(
                      text:
                          '${results.length} result${results.length == 1 ? '' : 's'} for ',
                    ),
                    TextSpan(
                      text: '"$_query"',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _SortButton(isDark: isDark),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: results.length,
            itemBuilder: (_, i) {
              final p = results[i];
              return _ProductCard(
                product: p,
                // isDark: isDark,
                // cs: cs,
                // onTap: () => _addHistory(_query),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text, bool isDark) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: isDark ? Colors.white38 : Colors.black38,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.item,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  final String item;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A3E)
                    : const Color(0xFFF0F0F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 16,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      border: Border.all(
        color: isDark ? const Color(0xFF3A3A50) : const Color(0xFFE0E0E8),
        width: 1.5,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Sort',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : const Color(0xFF888888),
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 16,
          color: isDark ? Colors.white38 : const Color(0xFFAAAAAA),
        ),
      ],
    ),
  );
}
// ─────────────────────────────────────────────────────────────────────────────
// CART TAB
// ─────────────────────────────────────────────────────────────────────────────

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  CollectionReference getCartRef() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      throw Exception("User not logged in");
    }

    final email = CartService.safeEmail(user.email!);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .collection('cart');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'My cart',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getCartRef().snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!.docs;

          if (items.isEmpty) {
            return _emptyState(context);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final doc = items[i];
                    final data = doc.data() as Map<String, dynamic>;

                    return _cartItemCard(context, doc.id, data);
                  },
                ),
              ),
              _checkoutSection(context, items),
            ],
          );
        },
      ),
    );
  }

  /// 🧾 CART ITEM (UI SAME, FIXED LOGIC)
  Widget _cartItemCard(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        final productId = data['productId'];

        if (productId == null) return;

        /// ✅ FIX: pass correct productId via Product object
        final product = Product(
          id: productId, // 🔥 FIXED
          name: data['name'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          images: [data['image'] ?? ''],
          description: data['description'] ?? 'No description available',
          sizes: List<String>.from(data['sizes'] ?? []),
          colors: List<String>.from(data['colors'] ?? []),
          isInStock: data['isInStock'] ?? true,
          category: data['category'] ?? 'general',
          createdAt: data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            /// IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                data['image'] ?? '',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: cs.surfaceVariant,
                  width: 80,
                  height: 80,
                  child: const Icon(Icons.image),
                ),
              ),
            ),

            const SizedBox(width: 14),

            /// INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    "NPR ${(data['price'] ?? 0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// QUANTITY
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: cs.surfaceVariant,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _qtyBtn(Icons.remove, () => _updateQty(id, data, -1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "${data['quantity'] ?? 1}",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        _qtyBtn(Icons.add, () => _updateQty(id, data, 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// DELETE
            IconButton(
              onPressed: () => _deleteItem(id),
              icon: Icon(Icons.close, color: cs.error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18),
      ),
    );
  }

  /// 💰 CHECKOUT (FIXED productId)
  Widget _checkoutSection(
    BuildContext context,
    List<QueryDocumentSnapshot> items,
  ) {
    final cs = Theme.of(context).colorScheme;

    double subtotal = 0;
    int totalItems = 0;

    for (var item in items) {
      final data = item.data() as Map<String, dynamic>;
      final price = (data['price'] ?? 0).toDouble();
      final qty = (data['quantity'] ?? 1) as int;

      subtotal += price * qty;
      totalItems += qty;
    }

    double deliveryFee = subtotal > 1000 ? 0 : 100;
    double discount = subtotal > 2000 ? 100 : 0;
    double total = subtotal + deliveryFee - discount;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Items ($totalItems)"),
                Text("NPR ${subtotal.toStringAsFixed(0)}"),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Delivery Fee"),
                Text(deliveryFee == 0 ? "Free" : "NPR $deliveryFee"),
              ],
            ),

            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total"),
                Text(
                  "NPR ${total.toStringAsFixed(0)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final checkoutItems = items.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {
                      'productId': data['productId'], // 🔥 FIXED
                      'name': data['name'],
                      'price': data['price'],
                      'quantity': data['quantity'],
                      'image': data['image'],
                    };
                  }).toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CheckoutScreen(items: checkoutItems, total: total),
                    ),
                  );
                },
                child: Text("Checkout ($totalItems items)"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// EMPTY
  Widget _emptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: cs.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text("Your cart is empty"),
        ],
      ),
    );
  }

  /// UPDATE QTY
  void _updateQty(String id, Map<String, dynamic> data, int change) async {
    final int currentQty = (data['quantity'] ?? 1) as int;
    final int newQty = currentQty + change;

    if (newQty <= 0) {
      await getCartRef().doc(id).delete();
    } else {
      await getCartRef().doc(id).update({'quantity': newQty});
    }
  }

  /// DELETE
  void _deleteItem(String id) async {
    await getCartRef().doc(id).delete();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS TAB
// ─────────────────────────────────────────────────────────────────────────────
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        elevation: 0,
        title: Text(
          'Settings',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _settingsCard(
              context,
              children: [
                _settingsTile(
                  context: context,
                  icon: Icons.person_outline_rounded,
                  iconColor: Colors.blue,
                  title: 'Profile',
                  subtitle: 'Manage your account',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
                _settingsTile(
                  context: context,
                  icon: Icons.payment_outlined,
                  iconColor: Colors.green,
                  title: 'Payment Methods',
                  subtitle: 'eSewa and Cash on Delivery (COD) options',
                ),
                _settingsTile(
                  context: context,
                  icon: Icons.favorite_border,
                  iconColor: Colors.green,
                  title: 'Wishlists',
                  subtitle: 'quick access to your favourite products',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WishlistScreen()),
                    );
                  },
                ),
              ],
            ),
            _settingsCard(
              context,
              children: [
                Selector<StorageProvider, bool>(
                  selector: (_, provider) => provider.isDarktheme,
                  builder: (context, isDark, child) {
                    final theme = Theme.of(context);
                    final colorScheme = theme.colorScheme;

                    return _settingsTile(
                      context: context,
                      icon: Icons.dark_mode_outlined,
                      iconColor: Colors.blue,
                      title: 'Dark Mode',
                      subtitle: 'Switch between light and dark themes',
                      trailing: Switch(
                        value: isDark,
                        // Change color depending on dark/light mode
                        activeColor: isDark
                            ? colorScheme.secondary
                            : colorScheme.primary,
                        inactiveThumbColor: colorScheme.onSurface.withOpacity(
                          0.5,
                        ),
                        onChanged: (value) {
                          context.read<StorageProvider>().setdarktheme(value);
                        },
                      ),
                    );
                  },
                ),

                _settingsTile(
                  context: context,
                  icon: Icons.notifications,
                  iconColor: Colors.green,
                  title: 'Notifications',
                  subtitle: 'Push notifications settings',
                  trailing: Switch(
                    value: false,
                    // Change color depending on dark/light mode
                    // activeColor: isDark
                    //     ? colorScheme.secondary
                    //     : colorScheme.primary,
                    // inactiveThumbColor: colorScheme.onSurface.withOpacity(0.5),
                    onChanged: (value) {
                      //must add push enabling logic here
                    },
                  ),
                ),
              ],
            ),

            _settingsCard(
              context,
              children: [
                _settingsTile(
                  context: context,
                  icon: Icons.logout_rounded,
                  iconColor: Colors.red,
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  trailing: const SizedBox.shrink(),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: const Text("Confirm Logout"),
                        content: const Text(
                          "Are you sure you want to log out?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.error,
                            ),
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              ).logout();
                              Navigator.pop(context);
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text("Logout"),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard(BuildContext context, {required List<Widget> children}) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10), // 👈 spacing between cards
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14, // 👈 smaller & cleaner
        ),
      ),

      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),

      trailing:
          trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
      onTap: onTap,
    );
  }
}
