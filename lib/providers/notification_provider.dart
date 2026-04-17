import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/notification/models/app_notication.dart';

class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [];

  bool _isEnabled = true; // ✅ switch state

  List<AppNotification> get notifications => _notifications;
  bool get isEnabled => _isEnabled;

  void setEnabled(bool value) {
    _isEnabled = value;
    notifyListeners();
  }

  void addNotification(String title, String body, {String type = "general"}) {
    _notifications.insert(
      0,
      AppNotification(
        title: title,
        body: body,
        time: DateTime.now(),
        type: type,
        read: false,
      ),
    );

    _saveToStorage(); // ✅ IMPORTANT
    notifyListeners();
  }

  void removeNotification(AppNotification n) {
    _notifications.remove(n);
    _saveToStorage();
    notifyListeners();
  }

  void markAsRead(AppNotification n) {
    n.read = true;
    _saveToStorage();
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();

    final data = _notifications
        .map(
          (n) => {
            "title": n.title,
            "body": n.body,
            "time": n.time.toIso8601String(),
            "type": n.type,
            "read": n.read,
          },
        )
        .toList();

    prefs.setString("notifications", jsonEncode(data));
  }

  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("notifications");

    if (data != null) {
      final List decoded = jsonDecode(data);

      _notifications.clear();

      for (var item in decoded) {
        _notifications.add(
          AppNotification(
            title: item["title"],
            body: item["body"],
            time: DateTime.parse(item["time"]),
            type: item["type"],
            read: item["read"],
          ),
        );
      }

      notifyListeners();
    }
  }
}
