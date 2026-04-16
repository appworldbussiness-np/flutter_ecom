class AppConstants {
  // 🔀 Routes
  static const String splashRoute = "/";
  static const String loginRoute = "/login";
  static const String registerRoute = "/register";
  static const String homeRoute = "/home";
  static const String productRoute = "/product";
  static const String cartRoute = "/cart";
  static const String checkoutRoute = "/checkout";
  static const String orderSuccessRoute = "/order-success";
  static const String forgotPasswordRoute = '/forgot-password';

  // 🔥 Firebase Collections
  static const String usersCollection = "users";
  static const String productsCollection = "products";
  static const String cartsCollection = "carts";
  static const String ordersCollection = "orders";

  // 💳 eSewa Config (Sandbox)
  static const String esewaClientId = "EPAYTEST";
  static const String esewaSecretKey = "8gBm/:&EnhH.1/q";
  static const String esewaSuccessUrl = "https://esewa.com.np/success";
  static const String esewaFailureUrl = "https://esewa.com.np/failure";

  // 📦 Order Status
  static const String orderPending = "PENDING";
  static const String orderConfirmed = "CONFIRMED";
  static const String orderShipped = "SHIPPED";
  static const String orderDelivered = "DELIVERED";
  static const String orderCancelled = "CANCELLED";
}
