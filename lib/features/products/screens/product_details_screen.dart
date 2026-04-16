import 'package:ecom_/core/theme/app_theme.dart';
import 'package:ecom_/providers/wishlist_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../../../services/cart_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with TickerProviderStateMixin {
  int selectedImage = 0;
  String? selectedSize;
  String? selectedColor;
  int quantity = 1;
  bool showFullDescription = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _heartController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _heartScale;

  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();

  // ── Theme-neutral accent constants (never change between light/dark) ───────
  static const Color _gold = Color(0xFFC9A84C);
  //  static const Color _goldLight = Color(0xFFE8D5A3);
  static const Color _errorRed = Color(0xFFFF5A5A);
  static const Color _successGreen = Color(0xFF2ECC71);

  // ── Computed theme tokens (resolved from context at build time) ────────────

  /// AppTheme.primaryColor — Deep Navy #0A1F44
  Color get _primary => AppTheme.primaryColor;

  /// AppTheme.accentColor — Coral #FF6B6B
  Color get _accent => AppTheme.accentColor;

  /// Scaffold background: warm cream in light, #121212 in dark
  Color get _bg => Theme.of(context).scaffoldBackgroundColor;

  /// Card / sheet background
  Color get _surface => Theme.of(context).colorScheme.surface;

  /// Primary text colour
  Color get _onSurface => Theme.of(context).colorScheme.onSurface;

  /// Muted / secondary text
  Color get _muted => Theme.of(context).brightness == Brightness.dark
      ? Colors.grey.shade500
      : const Color(0xFF8A8A8A);

  /// Divider / border lines
  Color get _border => Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withOpacity(0.10)
      : const Color(0xFFEAEAEA);

  /// Chip / tag background (subtle surface tint)
  Color get _chipBg => Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withOpacity(0.07)
      : AppTheme.backgroundColor; // warm cream

  /// Status-bar icon brightness
  SystemUiOverlayStyle get _overlayStyle =>
      Theme.of(context).brightness == Brightness.dark
      ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
      : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent);

  // ══════════════════════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _heartScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(_heartController);

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _heartController.dispose();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: Scaffold(
        backgroundColor: _bg,
        extendBodyBehindAppBar: true,
        appBar: _appBar(),
        body: width < 650 ? _mobile() : _desktop(),
        bottomNavigationBar: _bottomBar(),
      ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _surface.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: _onSurface,
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _surface.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.share_outlined, size: 18, color: _onSurface),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ),
      ],
    );
  }

  // ─── LAYOUTS ─────────────────────────────────────────────────────────────
  Widget _mobile() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _images()),
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: _contentCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktop() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Row(
        children: [
          Expanded(flex: 5, child: _images()),
          Expanded(
            flex: 4,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(child: _contentCard()),
            ),
          ),
        ],
      ),
    );
  }

  // ─── IMAGE GALLERY ────────────────────────────────────────────────────────
  Widget _images() {
    final images = widget.product.images;

    return SizedBox(
      height: 420,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => selectedImage = i),
            itemBuilder: (_, i) => Image.network(
              images[i],
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),

          // Gradient fades into current scaffold bg colour
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 120,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, _bg.withOpacity(0.95)],
                ),
              ),
            ),
          ),

          if (images.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: _thumbnailStrip(images),
            ),

          // Counter badge — tinted with primaryColor
          Positioned(
            top: 100,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${selectedImage + 1} / ${images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbnailStrip(List<String> images) {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: images.length,
        itemBuilder: (_, i) {
          final active = i == selectedImage;
          return GestureDetector(
            onTap: () => _pageController.animateToPage(
              i,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 8),
              width: active ? 60 : 52,
              height: active ? 60 : 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active ? _gold : Colors.transparent,
                  width: 2,
                ),
                boxShadow: active
                    ? [BoxShadow(color: _gold.withOpacity(0.3), blurRadius: 8)]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(images[i], fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── CONTENT CARD ─────────────────────────────────────────────────────────
  Widget _contentCard() {
    final p = widget.product;

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            //_categoryTag(),
            const SizedBox(height: 10),
            _nameAndRating(p),
            const SizedBox(height: 16),
            _priceRow(p),
            const SizedBox(height: 20),
            _divider(),
            const SizedBox(height: 20),

            if (p.colors.isNotEmpty) ...[
              _sectionLabel('Select Color'),
              const SizedBox(height: 12),
              _colorSelector(p.colors),
              const SizedBox(height: 20),
            ],

            if (p.sizes.isNotEmpty) ...[
              _sectionLabel('Select Size'),
              const SizedBox(height: 12),
              _sizeSelector(p.sizes),
              const SizedBox(height: 20),
            ],

            _divider(),
            const SizedBox(height: 20),
            _quantityRow(),
            const SizedBox(height: 20),
            _divider(),
            const SizedBox(height: 20),

            _descriptionSection(p),
            const SizedBox(height: 20),
            _featureChips(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ─── CONTENT SUB-WIDGETS ──────────────────────────────────────────────────

  // Widget _categoryTag() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
  //     decoration: BoxDecoration(
  //       color: _goldLight.withOpacity(0.25),
  //       borderRadius: BorderRadius.circular(6),
  //     ),
  //     child: Text(
  //       'PREMIUM COLLECTION',
  //       style: TextStyle(
  //         fontSize: 10,
  //         fontWeight: FontWeight.w700,
  //         letterSpacing: 1.8,
  //         color: _gold.withOpacity(0.9),
  //       ),
  //     ),
  //   );
  // }

  Widget _nameAndRating(Product p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            p.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _onSurface,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _chipBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 14, color: _gold),
              const SizedBox(width: 4),
              Text(
                '4.8',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceRow(Product p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.discountPrice != null)
              Text(
                'NPR ${p.price}',
                style: TextStyle(
                  fontSize: 13,
                  decoration: TextDecoration.lineThrough,
                  color: _muted,
                ),
              ),
            Text(
              'NPR ${p.finalPrice.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (p.discountPrice != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _errorRed.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${(((p.price - p.finalPrice) / p.price) * 100).toStringAsFixed(0)}% OFF',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _errorRed,
                letterSpacing: 0.5,
              ),
            ),
          ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: p.isInStock
                ? _successGreen.withOpacity(0.10)
                : _errorRed.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: p.isInStock ? _successGreen : _errorRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                p.isInStock ? 'In Stock' : 'Out of Stock',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: p.isInStock ? _successGreen : _errorRed,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _onSurface,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: _border);

  // ─── COLOR SELECTOR ───────────────────────────────────────────────────────
  Widget _colorSelector(List<String> colors) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: colors.map((c) {
        final isSelected = selectedColor == c;
        final parsedColor = _parseColor(c);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => selectedColor = c);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: parsedColor,
              border: Border.all(
                color: isSelected ? _gold : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: parsedColor.withOpacity(0.4),
                  blurRadius: isSelected ? 10 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSelected
                ? const Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  // ─── SIZE SELECTOR ────────────────────────────────────────────────────────
  Widget _sizeSelector(List<String> sizes) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: sizes.map((s) {
        final selected = selectedSize == s;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => selectedSize = s);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              // Selected → primaryColor (Deep Navy); unselected → chipBg
              color: selected ? _primary : _chipBg,
              border: Border.all(
                color: selected ? _primary : _border,
                width: 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _primary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              s,
              style: TextStyle(
                color: selected ? Colors.white : _onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── QUANTITY ─────────────────────────────────────────────────────────────
  Widget _quantityRow() {
    return Row(
      children: [
        Text(
          'Quantity',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _onSurface,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: _chipBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _qtyBtn(Icons.remove_rounded, () {
                if (quantity > 1) {
                  HapticFeedback.lightImpact();
                  setState(() => quantity--);
                }
              }, enabled: quantity > 1),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: SizedBox(
                  key: ValueKey(quantity),
                  width: 40,
                  child: Text(
                    quantity.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _onSurface,
                    ),
                  ),
                ),
              ),
              _qtyBtn(Icons.add_rounded, () {
                HapticFeedback.lightImpact();
                setState(() => quantity++);
              }, enabled: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, {required bool enabled}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: enabled ? _onSurface : _muted),
      ),
    );
  }

  // ─── DESCRIPTION ──────────────────────────────────────────────────────────
  Widget _descriptionSection(Product p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _onSurface,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedCrossFade(
          firstChild: Text(
            p.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: _muted, height: 1.6),
          ),
          secondChild: Text(
            p.description,
            style: TextStyle(fontSize: 14, color: _muted, height: 1.6),
          ),
          crossFadeState: showFullDescription
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        GestureDetector(
          onTap: () =>
              setState(() => showFullDescription = !showFullDescription),
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  showFullDescription ? 'Show less' : 'Read more',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _gold,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: showFullDescription ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: _gold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── FEATURE CHIPS ────────────────────────────────────────────────────────
  Widget _featureChips() {
    final features = [
      (Icons.verified_outlined, 'Authentic'),
      (Icons.local_shipping_outlined, 'Free Delivery'),
      (Icons.replay_outlined, '30-Day Return'),
    ];
    return Row(
      children: features
          .map(
            (f) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _chipBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(f.$1, size: 18, color: _gold),
                    const SizedBox(height: 5),
                    Text(
                      f.$2,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _onSurface,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ─── BOTTOM BAR ───────────────────────────────────────────────────────────
  Widget _bottomBar() {
    final p = widget.product;
    final product = widget.product;

    final wishlist = context.watch<WishlistProvider>();
    final isLiked = wishlist.isInWishlist(product);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      decoration: BoxDecoration(
        color: _surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // ── Wishlist ────────────────────────────────────────────────
            AnimatedBuilder(
              animation: _heartScale,
              builder: (_, child) =>
                  Transform.scale(scale: _heartScale.value, child: child),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();

                  final wasLiked = isLiked;

                  wishlist.toggle(product);

                  _snack(
                    wasLiked ? "Removed from wishlist" : "Added to wishlist",
                    icon: wasLiked
                        ? Icons.favorite_border_rounded
                        : Icons.favorite_rounded,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isLiked ? _accent.withOpacity(0.12) : _chipBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLiked ? _accent.withOpacity(0.40) : _border,
                    ),
                  ),
                  child: Icon(
                    isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isLiked ? _accent : _muted,
                    size: 22,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ── Add to Cart CTA ─────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: p.isInStock
                    ? () async {
                        if (p.sizes.isNotEmpty && selectedSize == null) {
                          _snack('Please select a size');
                          return;
                        }
                        if (p.colors.isNotEmpty && selectedColor == null) {
                          _snack('Please select a color');
                          return;
                        }

                        HapticFeedback.mediumImpact();

                        await CartService.addToCart(
                          p,
                          quantity: quantity,
                          size: selectedSize,
                          color: selectedColor,
                        );
                        if (mounted) {
                          _snack(
                            '$quantity item${quantity > 1 ? 's' : ''} added to cart',
                            icon: Icons.shopping_bag_rounded,
                          );
                        }
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    // CTA uses primaryColor; greyed-out when out of stock
                    color: p.isInStock
                        ? AppTheme.accentColor
                        : (isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade300),
                    boxShadow: p.isInStock
                        ? [
                            BoxShadow(
                              color: _primary.withOpacity(0.30),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 18,
                        color: p.isInStock ? Colors.white : _muted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        p.isInStock ? 'Add to Cart' : 'Out of Stock',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.3,
                          color: p.isInStock ? Colors.white : _muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────
  Color _parseColor(String value) {
    if (value.startsWith('#')) {
      return Color(int.parse(value.replaceFirst('#', '0xff')));
    }
    switch (value.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'pink':
        return Colors.pink;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'brown':
        return const Color(0xFF795548);
      default:
        return Colors.grey;
    }
  }

  void _snack(
    String msg, {
    bool isError = false,
    IconData icon = Icons.check_circle_rounded,
  }) {
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: isError ? Colors.red : Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
