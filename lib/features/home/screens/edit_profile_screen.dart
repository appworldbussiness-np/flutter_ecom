import 'package:ecom_/core/theme/app_theme.dart';
import 'package:ecom_/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  final currentPasswordCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();

  bool isGoogleUser = false;
  bool isLoading = false;

  bool showCurrentPass = false;
  bool showNewPass = false;

  @override
  void initState() {
    super.initState();

    final profile = context.read<ProfileProvider>();
    final user = FirebaseAuth.instance.currentUser;

    nameCtrl.text = user?.displayName ?? profile.name;
    emailCtrl.text = user?.email ?? profile.email;
    phoneCtrl.text = profile.phone;
    addressCtrl.text = profile.address;

    isGoogleUser =
        user?.providerData.any((p) => p.providerId == "google.com") ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 👤 PROFILE HEADER
            Center(
              child: Column(
                children: [
                  _profileAvatar(user),
                  const SizedBox(height: 10),
                  Text(
                    nameCtrl.text,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    emailCtrl.text,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _sectionTitle("Profile Info"),
            _card(
              isDark,
              cs,
              children: [
                _input("Full Name", nameCtrl),
                _input(
                  "Email",
                  emailCtrl,
                  enabled: !isGoogleUser,
                  helper: isGoogleUser ? "Managed by Google account" : null,
                ),
              ],
            ),

            const SizedBox(height: 14),

            _sectionTitle("Contact Details"),
            _card(
              isDark,
              cs,
              children: [
                _input("Phone Number", phoneCtrl),
                _input("Shipping Address", addressCtrl),
              ],
            ),

            const SizedBox(height: 14),

            _sectionTitle("Security"),
            _card(
              isDark,
              cs,
              children: [
                if (!isGoogleUser) ...[
                  _passwordInput(
                    "Current Password",
                    currentPasswordCtrl,
                    showCurrentPass,
                    () => setState(() => showCurrentPass = !showCurrentPass),
                  ),
                  _passwordInput(
                    "New Password",
                    newPasswordCtrl,
                    showNewPass,
                    () => setState(() => showNewPass = !showNewPass),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      "Password is managed by your Google account",
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            /// 💾 SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 👤 PROFILE IMAGE (Google + fallback)
  Widget _profileAvatar(User? user) {
    final photoUrl = user?.photoURL;

    return Stack(
      children: [
        CircleAvatar(
          radius: 42,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? const Icon(Icons.person, size: 40, color: Colors.grey)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.edit, size: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }

  /// 🔹 UPDATE LOGIC
  Future<void> _handleUpdate() async {
    setState(() => isLoading = true);

    final provider = context.read<ProfileProvider>();
    final user = FirebaseAuth.instance.currentUser;

    try {
      if (!isGoogleUser && newPasswordCtrl.text.isNotEmpty) {
        final cred = EmailAuthProvider.credential(
          email: user!.email!,
          password: currentPasswordCtrl.text,
        );

        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(newPasswordCtrl.text);
      }

      if (user != null) {
        await user.updateDisplayName(nameCtrl.text);

        if (!isGoogleUser &&
            emailCtrl.text.isNotEmpty &&
            emailCtrl.text != user.email) {
          await user.updateEmail(emailCtrl.text);
        }
      }

      await provider.updateProfile(
        newName: nameCtrl.text,
        newEmail: isGoogleUser ? null : emailCtrl.text,
        newPhone: phoneCtrl.text,
        newAddress: addressCtrl.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          backgroundColor: Colors.green,
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "Profile updated successfully",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),

          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }

    setState(() => isLoading = false);
  }

  /// 🔤 SECTION TITLE
  Widget _sectionTitle(String title) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  /// 🧊 CARD
  Widget _card(bool isDark, ColorScheme cs, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  /// ✨ INPUT
  Widget _input(
    String label,
    TextEditingController ctrl, {
    bool enabled = true,
    String? helper,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        style: TextStyle(fontSize: 14, color: cs.onSurface),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          filled: true,
          fillColor: isDark
              ? Colors.white.withOpacity(0.04)
              : cs.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// 🔐 PASSWORD INPUT
  Widget _passwordInput(
    String label,
    TextEditingController ctrl,
    bool visible,
    VoidCallback toggle,
  ) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        obscureText: !visible,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: cs.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              visible ? Icons.visibility : Icons.visibility_off,
              size: 18,
            ),
            onPressed: toggle,
          ),
        ),
      ),
    );
  }
}
