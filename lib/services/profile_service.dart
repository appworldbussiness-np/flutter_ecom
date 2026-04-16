import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final _auth = FirebaseAuth.instance;

  /// 🔹 Get current user
  User? get user => _auth.currentUser;

  /// 🔹 Update name
  Future<void> updateName(String name) async {
    await user?.updateDisplayName(name);
  }

  /// 🔹 Update email (non-google)
  Future<void> updateEmail(String email) async {
    if (user != null && email != user!.email) {
      await user!.updateEmail(email);
    }
  }

  /// 🔹 Change password
  Future<void> changePassword(String newPassword) async {
    await user?.updatePassword(newPassword);
  }
}
