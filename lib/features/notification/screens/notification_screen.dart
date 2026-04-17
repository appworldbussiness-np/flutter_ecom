import 'package:ecom_/features/home/screens/home_screen.dart';
import 'package:ecom_/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        centerTitle: true,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: theme.iconTheme.color,
          ),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          ),
        ),

        title: Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),

        actions: [
          if (notifications.any((n) => !n.read))
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${notifications.where((n) => !n.read).length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      body: notifications.isEmpty
          ? _buildEmptyState(theme)
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                return _tile(context, item, theme);
              },
            ),
    );
  }

  /// 🔔 Notification Tile
  Widget _tile(BuildContext context, dynamic item, ThemeData theme) {
    return Dismissible(
      key: Key(item.hashCode.toString()),
      onDismissed: (_) {
        context.read<NotificationProvider>().removeNotification(item);
      },

      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: item.read ? theme.cardColor : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),

        child: ListTile(
          onTap: () {
            context.read<NotificationProvider>().markAsRead(item);
          },

          /// ✅ FIXED ICON (VISIBLE IN DARK MODE)
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 22,

                backgroundColor: theme.colorScheme.secondary,
                child: Icon(
                  Icons.notifications,
                  //color: theme.colorScheme.primary,
                ),
              ),

              /// 🔵 UNREAD DOT (TOP RIGHT)
              if (!item.read)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          title: Text(
            item.title ?? "",
            style: TextStyle(
              fontWeight: item.read ? FontWeight.normal : FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),

          subtitle: Text(
            item.body ?? "",
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  /// 📭 Empty State
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 60, color: theme.disabledColor),
          const SizedBox(height: 10),
          Text(
            "No notifications yet",
            style: TextStyle(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}
