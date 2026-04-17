// 🔹 UI POLISHED (LOGIC UNCHANGED)

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom_/core/store/address_store.dart';
import 'package:ecom_/core/theme/app_theme.dart';
import 'package:ecom_/providers/profile_provider.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';
import 'package:flutter/material.dart';
import 'package:ecom_/services/order_service.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final double total;

  const CheckoutScreen({super.key, required this.items, required this.total});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  String? selectedCity;

  bool isLoading = false;
  String selectedPayment = "cod";

  static const _clientId =
      "JB0BBQ4aD0UqIThFJwAKBgAXEUkEGQUBBAwdOgABHD4DChwUAB0R";
  static const _secretKey = "BhwIWQQADhIYSxILExMcAgFXFhcOBwAKBgAXEQ==";

  ColorScheme get _cs => Theme.of(context).colorScheme;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  double get subtotal => widget.items.fold(
    0,
    (sum, item) => sum + (item['price'] * item['quantity']),
  );

  double get deliveryFee => subtotal > 1000 ? 0 : 100;
  double get discount => subtotal > 2000 ? 100 : 0;
  double get finalTotal => subtotal + deliveryFee - discount;
  //forsavingaddress
  // 🔹 Load saved address

  bool _isInitialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isInitialized) return;

    final profile = context.read<ProfileProvider>();

    nameCtrl.text = profile.name;
    phoneCtrl.text = profile.phone;
    addressCtrl.text = profile.address;

    _isInitialized = true;
  }

  void _autoFillFromProfile() {
    final profile = context.read<ProfileProvider>();

    setState(() {
      nameCtrl.text = profile.name;
      phoneCtrl.text = profile.phone;
      addressCtrl.text = profile.address;
    });
  }

  void _autoFill() {
    if (!AddressStore.hasData) return;

    setState(() {
      nameCtrl.text = AddressStore.name ?? '';
      phoneCtrl.text = AddressStore.phone ?? '';
      addressCtrl.text = AddressStore.address ?? '';
      selectedCity = AddressStore.city;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        title: const Text("Checkout"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Shipping Details"),
            _addressCard(),

            const SizedBox(height: 24),

            _sectionTitle("Payment Method"),
            _paymentSection(),

            const SizedBox(height: 24),

            _sectionTitle("Order Summary"),
            _orderSummary(),
          ],
        ),
      ),

      bottomNavigationBar: _bottomBar(),
    );
  }

  // 🔤 TITLE
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: _cs.onSurface,
        ),
      ),
    );
  }

  // 📍 ADDRESS CARD
  Widget _addressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.25 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔥 Saved Address Header
            const SizedBox(height: 10),

            _input("Full Name", nameCtrl, Icons.person),
            _input("Phone Number", phoneCtrl, Icons.phone),
            _input("Full Address", addressCtrl, Icons.location_on),
            _cityDropdown(),
            if (AddressStore.hasData)
              Center(
                child: InkWell(
                  onTap: _autoFill,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          "Use Saved Address",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _autoFillFromProfile,
                  icon: Icon(Icons.auto_fix_high, size: 18),
                  label: const Text("Use Profile"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController ctrl, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
        style: TextStyle(
          color: _cs.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: _cs.onSurface.withOpacity(0.6),
            fontSize: 13,
          ),

          prefixIcon: Icon(icon, size: 20),

          filled: true,
          fillColor: _isDark
              ? Colors.white.withOpacity(0.04)
              : _cs.surfaceContainerHighest,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),

          // 👇 Clean rounded look
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          // 👇 Focus glow effect
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _cs.primary, width: 1.4),
          ),

          // 👇 Subtle error style
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _cs.error, width: 1.2),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _cs.error, width: 1.4),
          ),
        ),
      ),
    );
  }

  // 🏙 CITY
  Widget _cityDropdown() {
    final cities = ["Kathmandu", "Bhaktapur", "Lalitpur"];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: selectedCity,
        isExpanded: true,

        dropdownColor: _cs.surface,

        style: TextStyle(
          color: _cs.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),

        items: cities
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),

        onChanged: (v) => setState(() => selectedCity = v),

        validator: (v) => v == null ? "Select city" : null,

        icon: Icon(Icons.keyboard_arrow_down, color: _cs.primary),

        decoration: InputDecoration(
          labelText: "City",
          labelStyle: TextStyle(
            color: _cs.onSurface.withOpacity(0.6),
            fontSize: 13,
          ),

          prefixIcon: Icon(Icons.location_city, size: 20),

          filled: true,
          fillColor: _isDark
              ? Colors.white.withOpacity(0.04)
              : _cs.surfaceContainerHighest,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _cs.primary, width: 1.4),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _cs.error, width: 1.2),
          ),
        ),
      ),
    );
  }

  // 💳 PAYMENT
  Widget _paymentSection() {
    return Column(
      children: [
        _paymentTile("Cash on Delivery", "cod", Icons.money),
        _paymentTile("eSewa", "esewa", null, image: "assets/images/esewa.png"),
      ],
    );
  }

  Widget _paymentTile(
    String title,
    String value,
    IconData? icon, {
    String? image,
  }) {
    final selected = selectedPayment == value;

    return GestureDetector(
      onTap: () => setState(() => selectedPayment = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentColor.withOpacity(0.12)
              : _cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppTheme.accentColor
                : _cs.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            image != null
                ? Image.asset(image, width: 34)
                : Icon(icon, size: 20),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

            if (selected) const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }

  // 🧾 SUMMARY
  Widget _orderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cs.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          ...widget.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['name'],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text("x${item['quantity']}"),
                ],
              ),
            ),
          ),
          const Divider(height: 24),
          _row("Subtotal", subtotal),
          _row("Delivery", deliveryFee),
          if (discount > 0) _row("Discount", -discount),
          const Divider(height: 24),
          _row("Total", finalTotal, bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            "NPR ${value.toStringAsFixed(0)}",
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : null,
              color: bold ? AppTheme.accentColor : null,
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 BOTTOM CTA
  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: _cs.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    "Place Order • NPR ${finalTotal.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // 🚀 LOGIC UNCHANGED (same as yours)
  // 🔹 ONLY IMPORTANT PART SHOWN (UPDATED _placeOrder)

  void _placeOrder() async {
    AddressStore.save(
      name: nameCtrl.text,
      phone: phoneCtrl.text,
      address: addressCtrl.text,
      city: selectedCity ?? '',
    );

    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    /// ✅ 🔥 FIX: FORCE CLEAN + CONSISTENT DATA
    final enrichedItems = widget.items.map((item) {
      final size =
          item["size"] ??
          item["selectedSize"] ??
          item["variant"]?["size"] ??
          "";

      final color =
          item["color"] ??
          item["selectedColor"] ??
          item["variant"]?["color"] ??
          "";

      final colorHex =
          item["colorHex"] ??
          item["selectedColorHex"] ??
          item["variant"]?["colorHex"] ??
          "";

      return {
        ...item,

        /// ✅ ALWAYS SAVE THESE KEYS
        "size": size.toString(),
        "color": color.toString(),
        "colorHex": colorHex.toString(),
      };
    }).toList();

    /// 🔍 DEBUG PRINT (VERY IMPORTANT)
    for (var i in enrichedItems) {
      print("🧾 ITEM => ${i['name']}");
      print("   size: ${i['size']}");
      print("   color: ${i['color']}");
      print("   hex: ${i['colorHex']}");
    }

    try {
      /// =========================
      /// COD ORDER
      /// =========================
      if (selectedPayment == "cod") {
        await OrderService.placeOrder(
          enrichedItems, // ✅ FIXED
          finalTotal,
          {
            'name': nameCtrl.text,
            'phone': phoneCtrl.text,
            'address': addressCtrl.text,
            'city': selectedCity,
          },
          paymentMethod: "cod",
          isPaid: false,
        );

        await _deductStock(enrichedItems);

        _success();
        return;
      }

      /// =========================
      /// ESEWA PAYMENT
      /// =========================
      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(
          environment: Environment.test,
          clientId: _clientId,
          secretId: _secretKey,
        ),
        esewaPayment: EsewaPayment(
          productId: DateTime.now().millisecondsSinceEpoch.toString(),
          productName: "Order Payment",
          productPrice: finalTotal.toInt().toString(),
        ),
        onPaymentSuccess: (data) async {
          final verified = await _verifyTransaction(data);

          if (!verified) {
            setState(() => isLoading = false);
            _showError("Payment verification failed");
            return;
          }

          await OrderService.placeOrder(
            enrichedItems, // ✅ FIXED
            finalTotal,
            {
              'name': nameCtrl.text,
              'phone': phoneCtrl.text,
              'address': addressCtrl.text,
              'city': selectedCity,
            },
            paymentMethod: "esewa",
            isPaid: true,
          );

          await _deductStock(enrichedItems);

          _success();
        },
        onPaymentFailure: (_) {
          setState(() => isLoading = false);
          _showError("Payment Failed");
        },
        onPaymentCancellation: (_) {
          setState(() => isLoading = false);
          _showError("Payment Cancelled");
        },
      );
    } catch (e) {
      setState(() => isLoading = false);
      _showError(e.toString());
    }
  }

  Future<bool> _verifyTransaction(EsewaPaymentSuccessResult result) async {
    try {
      final url =
          "https://rc.esewa.com.np/mobile/transaction?txnRefId=${result.refId}";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "merchantId": _clientId,
          "merchantSecret": _secretKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        /// 🔥 SAFE PARSING (avoid crashes)
        final status = data[0]?['transactionDetails']?['status'] ?? "FAILED";

        return status == "COMPLETE";
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  void _success() {
    if (!mounted) return;

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Order placed successfully",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    /// ✅ Navigate back to home (clears checkout stack)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
    });
  }

  void _showError(String msg) {
    if (!mounted) return;

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        backgroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _deductStock(List items) async {
    final firestore = FirebaseFirestore.instance;

    for (var item in items) {
      final productId = item['productId']?.toString().trim();

      // 🔍 Debug: print entire item to see what's coming in
      print("🛒 ITEM DATA: $item");

      if (productId == null || productId.isEmpty) {
        print("❌ Skipping — productId is null/empty");
        continue;
      }

      final int quantity = (item['quantity'] as num?)?.toInt() ?? 1;
      print("➡️ Deducting $quantity from product: $productId");

      final productRef = firestore.collection('products').doc(productId);

      try {
        await firestore.runTransaction((tx) async {
          final snapshot = await tx.get(productRef);

          if (!snapshot.exists) {
            print("❌ Product doc not found in Firestore: $productId");
            return;
          }

          final currentStock = (snapshot['stock'] ?? 0) as num;
          final newStock = (currentStock.toInt() - quantity).clamp(0, 999999);

          tx.update(productRef, {'stock': newStock, 'isInStock': newStock > 0});

          print("✅ $productId: $currentStock → $newStock");
        });
      } catch (e) {
        print("🔥 Transaction failed for $productId: $e");
      }
    }
  }
}
