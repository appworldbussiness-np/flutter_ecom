import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  static const _bg = Color(0xFF0B0F1A);
  static const _card = Color(0xFF141B2D);
  static const _white = Colors.white;
  static const _white54 = Colors.white54;
  static const _accent = Color(0xFF6C5CE7);

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;

  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    nameController.text = user?.displayName ?? "Admin";
    emailController.text = user?.email ?? "";
  }

  void _addHistory(String action, bool success) {
    history.insert(0, {
      "action": action,
      "status": success ? "Success" : "Failed",
      "time": DateTime.now(),
    });
  }

  Future<void> _updateProfile() async {
    setState(() => isLoading = true);

    bool success = true;
    String actionSummary = "";

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (emailController.text.trim() != user.email) {
        await user.updateEmail(emailController.text.trim());
        actionSummary += "Email updated • ";
      }

      if (passwordController.text.trim().isNotEmpty) {
        await user.updatePassword(passwordController.text.trim());
        actionSummary += "Password updated • ";
      }

      await user.updateDisplayName(nameController.text.trim());
      actionSummary += "Name updated";

      await user.reload();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      success = false;
      actionSummary = "Update failed";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }

    _addHistory(actionSummary, success);
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 650;
    final cardWidth = isMobile ? double.infinity : 460.0;

    return Container(
      color: _bg,
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔝 HEADER
              const Text(
                "Admin Profile",
                style: TextStyle(
                  color: _white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              /// 👤 PROFILE CARD
              Container(
                width: cardWidth,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: _accent,
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: _white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        children: [
                          _input(nameController, "Full Name"),
                          const SizedBox(height: 8),
                          _input(emailController, "Email"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              /// 🔐 PASSWORD
              Container(
                width: cardWidth,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _input(
                  passwordController,
                  "New Password",
                  obscure: !showPassword,
                  suffix: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                      color: _white54,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() => showPassword = !showPassword);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              /// 💾 SAVE BUTTON
              SizedBox(
                width: cardWidth,
                height: 44,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text(
                          "Save Changes",
                          style: TextStyle(fontSize: 14),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              /// 🕘 HISTORY
              Container(
                width: cardWidth,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Activity Log",
                      style: TextStyle(
                        color: _white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (history.isEmpty)
                      const Text(
                        "No activity yet",
                        style: TextStyle(color: _white54),
                      )
                    else
                      Column(
                        children: history.take(5).map((item) {
                          final time = item["time"] as DateTime;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item["status"] == "Success"
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: item["status"] == "Success"
                                      ? Colors.green
                                      : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),

                                Expanded(
                                  child: Text(
                                    item["action"],
                                    style: const TextStyle(
                                      color: _white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),

                                Text(
                                  "${time.hour}:${time.minute.toString().padLeft(2, '0')}",
                                  style: const TextStyle(
                                    color: _white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 INPUT FIELD
  Widget _input(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: _white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _white54),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
