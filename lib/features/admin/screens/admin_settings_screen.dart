import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  static const _bg = Color(0xFF0B0F1A);
  static const _card = Color(0xFF141B2D);
  static const _white = Colors.white;
  static const _white54 = Colors.white54;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      color: _bg,
      padding: EdgeInsets.all(width < 600 ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Settings",
            style: TextStyle(
              color: _white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          _tile("Dark Mode", Icons.dark_mode),
          _tile("Notifications", Icons.notifications),
          _tile("Security", Icons.lock),
        ],
      ),
    );
  }

  Widget _tile(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: _white54),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: _white)),
        ],
      ),
    );
  }
}
