import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:ecom_/features/products/models/product_model.dart';
import 'package:ecom_/services/storage_service.dart';
import 'package:ecom_/providers/admin_product_provider.dart';

class AdminProductForm extends StatefulWidget {
  final Product? product;

  const AdminProductForm({super.key, required this.product});

  @override
  State<AdminProductForm> createState() => _AdminProductFormState();
}

class _AdminProductFormState extends State<AdminProductForm> {
  // ── Constants ─────────────────────────────────────────────────────────────
  static const Color _bg = Color(0xFF0B0F1A);
  static const Color _surface = Color(0xFF0F1524);
  static const Color _card = Color(0xFF141B2D);
  static const Color _accent = Color(0xFF6C5CE7);
  static const Color _white = Colors.white;
  static const Color _white54 = Colors.white54;
  static const Color _white12 = Colors.white12;

  final _formKey = GlobalKey<FormState>();
  final _storage = StorageService();
  final _picker = ImagePicker();
  bool _loading = false;

  late TextEditingController _name;
  late TextEditingController _desc;
  late TextEditingController _price;
  late TextEditingController _discount;
  late TextEditingController _stock;
  late TextEditingController _sizes;
  late TextEditingController _colors;

  String _category = 'socks';
  bool _isFeatured = false;
  bool _isNew = false;

  // Existing URLs from Firestore (shown when editing)
  List<String> _oldImages = [];
  // Newly picked bytes (not yet uploaded)
  List<Uint8List> _newImages = [];

  final _categories = ['socks', 'underpants', 'innervest'];

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    _name = TextEditingController(text: p?.name ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p?.price.toString() ?? '');
    _discount = TextEditingController(text: p?.discountPrice?.toString() ?? '');
    _stock = TextEditingController(text: p?.stock.toString() ?? '');
    _sizes = TextEditingController(text: p?.sizes.join(', ') ?? '');
    _colors = TextEditingController(text: p?.colors.join(', ') ?? '');

    _category = p?.category ?? 'socks';
    _isFeatured = p?.isFeatured ?? false;
    _isNew = p?.isNew ?? false;

    // ← Load existing images from Firestore when editing
    _oldImages = List.from(p?.images ?? []);
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _discount.dispose();
    _stock.dispose();
    _sizes.dispose();
    _colors.dispose();
    super.dispose();
  }

  // ── Image picking ─────────────────────────────────────────────────────────
  Future<void> _pickImages() async {
    if (kIsWeb) {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() => _newImages.add(bytes));
      }
    } else {
      final files = await _picker.pickMultiImage(imageQuality: 75);
      for (final f in files) {
        _newImages.add(await f.readAsBytes());
      }
      setState(() {});
    }
  }

  Future<List<String>> _uploadNewImages() async {
    final urls = <String>[];
    for (final img in _newImages) {
      final url = await _storage.uploadImage(img);
      if (url.isNotEmpty) urls.add(url);
    }
    return urls;
  }

  List<String> _split(String text) =>
      text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_oldImages.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final uploaded = await _uploadNewImages();
      final allImages = [..._oldImages, ...uploaded];

      final stockQty = int.parse(_stock.text.trim());

      final product = Product(
        isInStock: stockQty > 0, // ✅ auto-derive from stock
        id: widget.product?.id ?? '',
        name: _name.text.trim(),
        description: _desc.text.trim(),
        price: double.parse(_price.text.trim()),
        discountPrice: _discount.text.trim().isEmpty
            ? null
            : double.tryParse(_discount.text.trim()),
        category: _category,
        images: allImages,
        sizes: _split(_sizes.text),
        colors: _split(_colors.text),
        stock: stockQty, // ✅ reuse parsed value
        isFeatured: _isFeatured,
        isNew: _isNew,
        rating: widget.product?.rating ?? 0,
        reviewCount: widget.product?.reviewCount ?? 0,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
      );

      final provider = context.read<AdminProductProvider>();

      widget.product == null
          ? await provider.addProduct(product)
          : await provider.updateProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null ? 'Product added!' : 'Product updated!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w > 800;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        title: Text(
          widget.product == null ? 'Add Product' : 'Edit Product',
          style: const TextStyle(color: _white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: _white),
        // actions: [
        //   if (!_loading)
        //     Padding(
        //       padding: const EdgeInsets.only(right: 12),
        //       child: TextButton(
        //         onPressed: _submit,
        //         child: const Text(
        //           'Save',
        //           style: TextStyle(
        //             color: _accent,
        //             fontWeight: FontWeight.w700,
        //             fontSize: 15,
        //           ),
        //         ),
        //       ),
        //     ),
        // ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 860 : double.infinity),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(isWide ? 24 : 16),
              children: [
                // ── Images ─────────────────────────────────────────────
                _section(title: 'Product Images', child: _imageSection()),

                // ── Basic Info ─────────────────────────────────────────
                _section(
                  title: 'Basic Info',
                  child: Column(
                    children: [
                      _field(_name, 'Product Name'),
                      const SizedBox(height: 12),
                      _field(_desc, 'Description', maxLines: 3),
                    ],
                  ),
                ),

                // ── Category & Stock ───────────────────────────────────
                _section(
                  title: 'Category & Stock',
                  child: isWide
                      ? Row(
                          children: [
                            Expanded(child: _dropdown()),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                _stock,
                                'Stock Quantity',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _dropdown(),
                            const SizedBox(height: 12),
                            _field(
                              _stock,
                              'Stock Quantity',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                ),

                // ── Pricing ────────────────────────────────────────────
                _section(
                  title: 'Pricing',
                  child: isWide
                      ? Row(
                          children: [
                            Expanded(
                              child: _field(
                                _price,
                                'Price (NPR)',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                _discount,
                                'Discount Price (optional)',
                                keyboardType: TextInputType.number,
                                required: false,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _field(
                              _price,
                              'Price (NPR)',
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            _field(
                              _discount,
                              'Discount Price (optional)',
                              keyboardType: TextInputType.number,
                              required: false,
                            ),
                          ],
                        ),
                ),

                // ── Variants ───────────────────────────────────────────
                _section(
                  title: 'Variants',
                  child: isWide
                      ? Row(
                          children: [
                            Expanded(
                              child: _field(
                                _sizes,
                                'Sizes',
                                hint: 'S, M, L, XL',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                _colors,
                                'Colors',
                                hint: 'Black, White, Navy',
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _field(_sizes, 'Sizes', hint: 'S, M, L, XL'),
                            const SizedBox(height: 12),
                            _field(
                              _colors,
                              'Colors',
                              hint: 'Black, White, Navy',
                            ),
                          ],
                        ),
                ),

                // ── Flags ──────────────────────────────────────────────
                _section(
                  title: 'Flags',
                  child: Column(
                    children: [
                      _switch(
                        label: 'Featured Product',
                        subtitle: 'Shows in featured section',
                        value: _isFeatured,
                        onChanged: (v) => setState(() => _isFeatured = v),
                      ),
                      _switch(
                        label: 'Mark as New',
                        subtitle: 'Shows NEW badge on card',
                        value: _isNew,
                        onChanged: (v) => setState(() => _isNew = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Submit button ──────────────────────────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: _white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _white,
                            ),
                          )
                        : Text(
                            widget.product == null
                                ? 'Add Product'
                                : 'Update Product',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Image section ─────────────────────────────────────────────────────────
  Widget _imageSection() {
    final hasImages = _oldImages.isNotEmpty || _newImages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image previews
        if (hasImages)
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // ← Existing images loaded from Firestore
                ..._oldImages.asMap().entries.map(
                  (e) => _imageThumb(
                    child: Image.network(
                      e.value,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(
                              color: _card,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _accent,
                                  ),
                                ),
                              ),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        color: _card,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: _white54,
                        ),
                      ),
                    ),
                    onRemove: () => setState(() => _oldImages.removeAt(e.key)),
                  ),
                ),

                // Newly picked images (not yet uploaded)
                ..._newImages.asMap().entries.map(
                  (e) => _imageThumb(
                    child: Image.memory(e.value, fit: BoxFit.cover),
                    onRemove: () => setState(() => _newImages.removeAt(e.key)),
                    isNew: true,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Pick button
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
          label: Text(hasImages ? 'Add More Images' : 'Pick Images'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _white,
            side: const BorderSide(color: _white12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  // ── Image thumbnail ────────────────────────────────────────────────────────
  Widget _imageThumb({
    required Widget child,
    required VoidCallback onRemove,
    bool isNew = false,
  }) {
    return Stack(
      children: [
        Container(
          width: 88,
          height: 88,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _card,
            border: Border.all(
              color: isNew ? _accent.withOpacity(0.5) : _white12,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
        // NEW label on newly picked images
        if (isNew)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: _white,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        // Remove button
        Positioned(
          top: 2,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: _white),
            ),
          ),
        ),
      ],
    );
  }

  // ── Section card ──────────────────────────────────────────────────────────
  Widget _section({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ── Text field ────────────────────────────────────────────────────────────
  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
  }) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: _white),
      cursorColor: _accent,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _white54),
        hintStyle: const TextStyle(color: _white54, fontSize: 13),
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: required
          ? (v) => v == null || v.isEmpty ? 'Required' : null
          : null,
    );
  }

  // ── Dropdown ──────────────────────────────────────────────────────────────
  Widget _dropdown() {
    return DropdownButtonFormField<String>(
      value: _category,
      dropdownColor: _surface,
      iconEnabledColor: _white54,
      style: const TextStyle(color: _white, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Category',
        labelStyle: const TextStyle(color: _white54),
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      ),
      items: _categories
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                e[0].toUpperCase() + e.substring(1),
                style: const TextStyle(color: _white),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _category = v!),
    );
  }

  // ── Switch tile ───────────────────────────────────────────────────────────
  Widget _switch({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      activeColor: _accent,
      title: Text(label, style: const TextStyle(color: _white, fontSize: 14)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: _white54, fontSize: 12),
      ),
    );
  }
}
