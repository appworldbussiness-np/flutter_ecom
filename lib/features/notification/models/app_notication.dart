class AppNotification {
  final String title;
  final String body;
  final DateTime time;

  final String type; // 👈 keep required
  bool read;

  AppNotification({
    required this.title,
    required this.body,
    required this.time,
    this.type = "general", // ✅ DEFAULT FIX
    this.read = false,
  });
}
