import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service = ProfileService();

  String name = '';
  String email = '';
  String phone = '';
  String address = '';

  bool isLoading = false;

  /// 🔹 Load from Firebase
  void loadUser() {
    final user = _service.user;

    name = user?.displayName ?? '';
    email = user?.email ?? '';

    notifyListeners();
  }

  /// 🔹 Update profile
  Future<void> updateProfile({
    required String newName,
    String? newEmail,
    required String newPhone,
    required String newAddress,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      await _service.updateName(newName);

      if (newEmail != null) {
        await _service.updateEmail(newEmail);
        email = newEmail;
      }

      name = newName;
      phone = newPhone;
      address = newAddress;
    } catch (e) {
      rethrow;
    }

    isLoading = false;
    notifyListeners();
  }

  /// 🔹 Change password
  Future<void> changePassword(String newPassword) async {
    await _service.changePassword(newPassword);
  }
}
