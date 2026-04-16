import 'package:ecom_/features/products/models/product_model.dart';
import 'package:ecom_/features/products/screens/product_details_screen.dart';
import 'package:ecom_/providers/wishlist_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        title: const Text("Wishlist"),
        centerTitle: true,
      ),
      body: wishlist.items.isEmpty
          ? _emptyState(cs)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: wishlist.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _WishlistTile(product: wishlist.items[i]),
            ),
    );
  }

  Widget _emptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 60,
            color: cs.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 10),
          Text(
            "Your wishlist is empty",
            style: TextStyle(
              fontSize: 15,
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistTile extends StatelessWidget {
  final Product product;

  const _WishlistTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wishlist = context.read<WishlistProvider>();

    final image = product.images.isNotEmpty ? product.images.first : '';

    return Dismissible(
      key: ValueKey(product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => wishlist.remove(product),

      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),

      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product),
            ),
          );
        },

        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),

          child: Row(
            children: [
              /// 🖼 IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: image.isNotEmpty
                    ? Image.network(
                        image,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: cs.surfaceContainerHighest,
                        child: Icon(
                          Icons.image,
                          color: cs.onSurface.withOpacity(0.3),
                        ),
                      ),
              ),

              const SizedBox(width: 12),

              /// 📄 INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// NAME
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),

                    const SizedBox(height: 4),

                    /// CATEGORY
                    Text(
                      product.category,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// PRICE
                    Row(
                      children: [
                        Text(
                          "NPR ${product.finalPrice.toStringAsFixed(0)}",
                          style: TextStyle(
                            color: cs.secondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),

                        if (product.discountPrice != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            "NPR ${product.price.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                              color: cs.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 6),

                    /// STOCK STATUS
                    Text(
                      product.isInStock ? "In Stock" : "Out of Stock",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: product.isInStock ? Colors.green : cs.error,
                      ),
                    ),
                  ],
                ),
              ),

              /// ❌ REMOVE BUTTON
              GestureDetector(
                onTap: () => wishlist.remove(product),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: cs.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 16, color: cs.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
