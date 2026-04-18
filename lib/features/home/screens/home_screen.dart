import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom_/core/theme/app_theme.dart';
import 'package:ecom_/features/auth/screens/login_screen.dart';
import 'package:ecom_/features/home/screens/edit_profile_screen.dart';
import 'package:ecom_/features/notification/screens/notification_screen.dart';
import 'package:ecom_/features/orders/screens/order_screen.dart';
import 'package:ecom_/features/products/models/product_model.dart';
import 'package:ecom_/features/products/screens/product_details_screen.dart';
import 'package:ecom_/features/products/screens/checkout_screen.dart';
import 'package:ecom_/features/products/screens/wishlist_screen.dart';
import 'package:ecom_/providers/app_product_provider.dart';
import 'package:ecom_/providers/auth_provider.dart';
import 'package:ecom_/providers/notification_provider.dart';
import 'package:ecom_/providers/theme_provider.dart';
import 'package:ecom_/providers/wishlist_provider.dart';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );

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
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search_rounded),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: cartIconWithBadge(context),
                label: "Cart",
              ),

              const BottomNavigationBarItem(
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

Widget cartIconWithBadge(BuildContext context) {
  final user = FirebaseAuth.instance.currentUser;

  /// If user not logged in
  if (user == null) {
    return const Icon(Icons.shopping_cart);
  }

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid) // ✅ MUST be UID
        .collection('cart')
        .snapshots(),
    builder: (context, snapshot) {
      int count = 0;

      /// ✅ SAFE DATA HANDLING
      if (snapshot.hasData && snapshot.data != null) {
        for (final doc in snapshot.data!.docs) {
          final rawData = doc.data();

          /// 🔥 VERY IMPORTANT: check type safely
          if (rawData is! Map<String, dynamic>) continue;

          final qty = rawData['quantity'];

          /// ✅ HANDLE ALL CASES (int, string, null)
          if (qty is int) {
            count += qty;
          } else if (qty is String) {
            count += int.tryParse(qty) ?? 1;
          } else {
            count += 1;
          }
        }
      }

      return Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_cart, size: 26),

          /// 🔥 BADGE
          if (count > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count > 99 ? "99+" : "$count",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
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
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
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
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationScreen(),
                            ),
                          );
                        },
                        child: Icon(
                          Icons.notifications_outlined,
                          color: cs.secondary,
                          size: 22,
                        ),
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
            builder: (_) => ProductDetailsScreen(
              product: product,
              initialSize: product.sizes.isNotEmpty ? product.sizes[0] : null,
              initialColor: product.colors.isNotEmpty
                  ? product.colors[0]
                  : null,
            ),
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
                          HapticFeedback.lightImpact();
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
                                          initialSize: product.sizes.isNotEmpty
                                              ? product.sizes[0]
                                              : null,
                                          initialColor:
                                              product.colors.isNotEmpty
                                              ? product.colors[0]
                                              : null,
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

class _SearchTabState extends State<SearchTab> {
  String query = "";

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Search",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          /// 🔍 SEARCH BAR (NOW IN BODY)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                onChanged: (val) => setState(() => query = val.toLowerCase()),
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: "Search products...",
                  hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.5)),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: cs.onSurface),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          /// 🔥 RESULT AREA
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final category = (data['category'] ?? '')
                      .toString()
                      .toLowerCase();

                  return name.contains(query) || category.contains(query);
                }).toList();

                /// 💤 BEFORE SEARCH
                if (query.isEmpty) {
                  return Center(
                    child: Text(
                      "Start typing to search...",
                      style: TextStyle(color: cs.onSurface.withOpacity(0.5)),
                    ),
                  );
                }

                /// ❌ NO RESULT
                if (filtered.isEmpty) {
                  return const Center(child: Text("No products found"));
                }

                /// ✅ LIST
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final doc = filtered[i];
                    final data = doc.data() as Map<String, dynamic>;

                    return _productTile(context, doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 PRODUCT TILE (same working one)
  Widget _productTile(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        final product = Product.fromMap(data, id);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(
              initialColor: product.colors.isNotEmpty
                  ? product.colors[0]
                  : null,
              product: product,
              initialSize: product.sizes.isNotEmpty ? product.sizes[0] : null,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            /// IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                data['image'] ??
                    (data['images'] != null &&
                            (data['images'] as List).isNotEmpty
                        ? data['images'][0]
                        : ''),
                width: 65,
                height: 65,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 12),

            /// INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "NPR ${(data['price'] ?? 0)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            Icon(Icons.arrow_forward_ios, size: 14, color: cs.onSurface),
          ],
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// CART TAB
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

class CartTab extends StatelessWidget {
  const CartTab({super.key, this.initialSize, this.initialColor});

  /// ✅ FIXED: USE UID (NOT EMAIL)
  CollectionReference getCartRef() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid) // 🔥 FIXED HERE
        .collection('cart');
  }

  final String? initialSize;
  final String? initialColor;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "My Cart",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
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
                child: ListView(
                  children: [
                    ...items.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _cartItemCard(context, doc.id, data);
                    }),
                  ],
                ),
              ),
              _checkoutSection(context, items),
            ],
          );
        },
      ),
    );
  }

  /// 🧾 CART ITEM CARD
  Widget _cartItemCard(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Surfaces
    final cardBg = cs.surface;
    final elevated = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F3FA);
    final border = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE4E9F2);

    // Text
    final textCol = cs.onSurface;
    final muted = theme.textTheme.bodyMedium?.color?.withOpacity(0.7);
    final faint = theme.textTheme.bodyMedium?.color?.withOpacity(0.4);

    // Brand (from your AppTheme)
    final accent = cs.secondary;
    final accentDim = cs.secondary.withOpacity(0.12);

    // Danger (keep custom or move to theme later)
    const danger = Color(0xFFFF5B5B);
    const dangerDim = Color(0x15FF5B5B);

    final qty = (data['quantity'] ?? 1) as int;
    final price = (data['price'] ?? 0).toDouble();
    final total = price * qty;
    final size = data['size']?.toString() ?? '';
    final colorName = data['color']?.toString() ?? '';
    final colorHex = data['colorHex']?.toString() ?? '';
    final imageUrl = data['image'] ?? '';
    final name = data['name'] ?? '';

    Color? swatch;
    if (colorHex.isNotEmpty) {
      try {
        swatch = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () {
        final product = Product(
          id: data['productId'],
          name: name,
          price: price,
          images: [imageUrl],
          description: data['description'] ?? '',
          sizes: [],
          colors: [],
          isInStock: true,
          category: 'general',
          createdAt: DateTime.now(),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(
              product: product,
              initialSize: data['size'],
              initialColor: data['color'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── TOP ROW: image + info + remove ──────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail with qty badge overlay
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: SizedBox(
                          width: 78,
                          height: 88,
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: elevated,
                                    child: Icon(
                                      Icons.image_outlined,
                                      color: faint,
                                      size: 28,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: elevated,
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: faint,
                                    size: 28,
                                  ),
                                ),
                        ),
                      ),
                      if (qty > 1)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '×$qty',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // Info column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product name
                        Text(
                          name,
                          style: TextStyle(
                            color: textCol,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),

                        // Variant chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: [
                            if (size.isNotEmpty && size != 'default')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: accentDim,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Size: $size',
                                  style: const TextStyle(
                                    // color: accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (colorName.isNotEmpty && colorName != 'default')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: elevated,
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
                                            color: Colors.white.withOpacity(
                                              0.4,
                                            ),
                                            width: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                    ],
                                    Text(
                                      colorName,
                                      style: TextStyle(
                                        color: muted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (qty > 1) ...[
                              Text(
                                'NPR ${price.toStringAsFixed(0)}',
                                style: TextStyle(color: swatch, fontSize: 11),
                              ),
                              Text(
                                ' × $qty  =  ',
                                style: TextStyle(color: faint, fontSize: 11),
                              ),
                              Text(
                                'NPR ${total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  //  color: accent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ] else
                              Text(
                                'NPR ${price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  // color: accent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Remove ×
                  GestureDetector(
                    onTap: () => _deleteItem(id),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: dangerDim,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: danger,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── BOTTOM BAR: quantity stepper ─────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
                border: Border(top: BorderSide(color: border, width: 0.5)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 13, color: faint),
                  const SizedBox(width: 5),
                  Text(
                    'Quantity',
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  // Stepper pill
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: border, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Minus
                        GestureDetector(
                          onTap: qty > 1
                              ? () => _updateQty(id, data, -1)
                              : null,
                          child: Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.remove_rounded,
                              size: 15,
                              color: qty > 1 ? textCol : faint,
                            ),
                          ),
                        ),
                        // Count with pop animation
                        SizedBox(
                          width: 36,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(scale: anim, child: child),
                            child: Text(
                              '$qty',
                              key: ValueKey(qty),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textCol,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        // Plus
                        GestureDetector(
                          onTap: () => _updateQty(id, data, 1),
                          child: Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: accentDim,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              size: 15,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ),
                      ],
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

  // Widget _qtyBtn(VoidCallback onTap, IconData icon) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       width: 34,
  //       height: 34,
  //       alignment: Alignment.center,
  //       decoration: BoxDecoration(
  //         color: const Color(0x207C6EFA),
  //         borderRadius: BorderRadius.circular(9),
  //       ),
  //       child: Icon(icon, size: 15, color: const Color(0xFF7C6EFA)),
  //     ),
  //   );
  // }

  /// 💰 CHECKOUT SECTION
  Widget _checkoutSection(
    BuildContext context,
    List<QueryDocumentSnapshot> items,
  ) {
    double total = 0;
    int totalItems = 0;

    for (var item in items) {
      final data = item.data() as Map<String, dynamic>;
      final price = (data['price'] ?? 0).toDouble();
      final qty = (data['quantity'] ?? 1) as int;

      total += price * qty;
      totalItems += qty;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total ($totalItems items)"),
              Text("NPR ${total.toStringAsFixed(0)}"),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                /// ✅ FIXED: INCLUDE SIZE & COLOR
                final checkoutItems = items.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return {
                    'productId': data['productId'],
                    'name': data['name'],
                    'price': data['price'],
                    'quantity': data['quantity'],
                    'image': data['image'],
                    'size': data['size'], // 🔥 FIX
                    'color': data['color'], // 🔥 FIX
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
              child: const Text("Checkout"),
            ),
          ),
        ],
      ),
    );
  }

  /// ❌ EMPTY STATE
  Widget _emptyState(BuildContext context) {
    return const Center(child: Text("Your cart is empty"));
  }

  /// 🔄 UPDATE QTY
  void _updateQty(String id, Map<String, dynamic> data, int change) async {
    final int currentQty = (data['quantity'] ?? 1) as int;
    final int newQty = currentQty + change;

    if (newQty <= 0) {
      await getCartRef().doc(id).delete();
    } else {
      await getCartRef().doc(id).update({'quantity': newQty});
    }
  }

  /// 🗑 DELETE ITEM
  void _deleteItem(String id) async {
    await getCartRef().doc(id).delete();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS TAB
// ─────────────────────────────────────────────────────────────────────────────
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  bool get isDark => false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          //   height: 360,
          child: SingleChildScrollView(
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
                          MaterialPageRoute(
                            builder: (_) => const WishlistScreen(),
                          ),
                        );
                      },
                    ),
                    _settingsTile(
                      context: context,
                      icon: Icons.shopping_bag,
                      iconColor: Colors.blue,
                      title: 'Orders',
                      subtitle: 'get access to your orders',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OrderScreen()),
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
                            inactiveThumbColor: colorScheme.onSurface
                                .withOpacity(0.5),
                            onChanged: (value) {
                              context.read<StorageProvider>().setdarktheme(
                                value,
                              );
                            },
                          ),
                        );
                      },
                    ),

                    Selector<NotificationProvider, bool>(
                      selector: (_, provider) => provider.isEnabled,
                      builder: (context, isEnabled, _) {
                        return Selector<StorageProvider, bool>(
                          selector: (_, provider) => provider.isDarktheme,
                          builder: (context, isDark, __) {
                            final theme = Theme.of(context);
                            final colorScheme = theme.colorScheme;

                            return _settingsTile(
                              context: context,
                              icon: Icons.notifications,
                              iconColor: Colors.green,
                              title: 'Notifications',
                              subtitle: 'Push notifications settings',
                              trailing: Switch(
                                value: isEnabled,
                                activeColor: isDark
                                    ? colorScheme.secondary
                                    : colorScheme.primary,
                                onChanged: (value) async {
                                  context
                                      .read<NotificationProvider>()
                                      .setEnabled(
                                        value,
                                        activeColor: colorScheme.onSurface,
                                      );

                                  if (value) {
                                    await FirebaseMessaging.instance
                                        .requestPermission();
                                    await FirebaseMessaging.instance
                                        .subscribeToTopic("all");
                                    showNotificationSnackBar(context, value);
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
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
                                  Navigator.of(ctx).pop(); // close dialog

                                  await Provider.of<AuthProvider>(
                                    context,
                                    listen: false,
                                  ).logout();

                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
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
        ),
      ),
    );
  }

  void showNotificationSnackBar(BuildContext context, bool isEnabled) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      backgroundColor: isEnabled ? Colors.green : Colors.red,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      content: Row(
        children: [
          Icon(
            isEnabled ? Icons.notifications_active : Icons.notifications_off,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Text(
            isEnabled ? "Notifications Enabled" : "Notifications Disabled",
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
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
