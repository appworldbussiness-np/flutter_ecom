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
    String? newName,
    String? newEmail,
    String? newPhone,
    String? newAddress,
  }) async {
    if (newName != null) name = newName;
    if (newEmail != null) email = newEmail;
    if (newPhone != null) phone = newPhone;
    if (newAddress != null) address = newAddress;

    /// 🔥 SAVE TO FIRESTORE (OPTIONAL)
    // await FirebaseFirestore.instance
    //   .collection('users')
    //   .doc(FirebaseAuth.instance.currentUser!.uid)
    //   .set({
    //     'name': name,
    //     'email': email,
    //     'phone': phone,
    //     'address': address,
    //   }, SetOptions(merge: true));

    notifyListeners();
  }

  /// 🔹 Change password
  Future<void> changePassword(String newPassword) async {
    await _service.changePassword(newPassword);
  }
}
