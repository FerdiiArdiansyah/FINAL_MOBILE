import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/notification_model.dart';
import '../../core/theme/app_theme.dart';

class NotificationListPage extends StatelessWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;
    final db = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Tandai Semua Dibaca',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: db.getNotifications(user.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snap.data ?? [];
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Tidak ada notifikasi',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, i) {
              return _NotificationCard(notification: notifications[i]);
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await db.markNotificationRead(notification.id);
      },
      child: Container(
        color: notification.isRead ? null : AppTheme.primaryColor.withOpacity(0.05),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _typeColor(notification.type).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _typeIcon(notification.type),
              color: _typeColor(notification.type),
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead
                  ? FontWeight.normal
                  : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.body),
              Text(
                _timeAgo(notification.createdAt),
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () => db.markNotificationRead(notification.id),
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'assignment': return Colors.orange;
      case 'alert': return AppTheme.warningColor;
      case 'violation': return AppTheme.errorColor;
      case 'announcement': return AppTheme.secondaryColor;
      case 'counseling': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'assignment': return Icons.assignment_outlined;
      case 'alert': return Icons.warning_amber_outlined;
      case 'violation': return Icons.gavel_outlined;
      case 'announcement': return Icons.announcement_outlined;
      case 'counseling': return Icons.psychology_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${time.day}/${time.month}/${time.year}';
  }
}
