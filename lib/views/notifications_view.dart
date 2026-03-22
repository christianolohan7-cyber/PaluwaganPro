import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/notification.dart' as notif_model;
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/groups_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authVm = context.read<AuthViewModel>();
      final notifVm = context.read<NotificationViewModel>();
      final userId = authVm.currentUser?.id;

      if (userId != null) {
        await notifVm.loadUserNotifications(userId);
        await notifVm.startNotificationsStream(userId);
      }
    });
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    notif_model.Notification notification,
  ) async {
    final notifVm = context.read<NotificationViewModel>();
    final groupsVm = context.read<GroupsViewModel>();

    await notifVm.markAsRead(notification.id);

    if (!mounted || notification.groupId == null) {
      return;
    }

    await groupsVm.loadGroupDetails(notification.groupId!);

    if (!mounted) return;

    Navigator.of(
      context,
    ).pushNamed('/group-detail', arguments: notification.groupId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer<NotificationViewModel>(
            builder: (context, notifVm, _) {
              if (notifVm.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (notifVm.notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  final userId = context.read<AuthViewModel>().currentUser?.id;
                  if (userId != null) {
                    await notifVm.loadUserNotifications(userId);
                  }
                },
                child: ListView.builder(
                  itemCount: notifVm.notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifVm.notifications[index];
                    return _NotificationTile(
                      notification: notif,
                      onTap: () => _handleNotificationTap(context, notif),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final notif_model.Notification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final date = notification.createdAt;
    final formattedDate = '${date.month}/${date.day}/${date.year}';

    return Card(
      elevation: isUnread ? 2 : 0,
      color: isUnread ? Colors.blue.shade50 : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              )
            : const Icon(Icons.notifications, size: 24, color: Colors.grey),
        title: Text(
          notification.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        onTap: onTap,
        trailing: isUnread
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'New',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, required this.notification});

  final notif_model.Notification notification;

  @override
  Widget build(BuildContext context) {
    final date = notification.createdAt;
    final formattedDate = '${date.month}/${date.day}/${date.year}';
    final formattedTime =
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$formattedDate at $formattedTime',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Text(
                notification.message,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 16),
              if (notification.groupId != null)
                Text(
                  'Group ID: ${notification.groupId}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              const SizedBox(height: 16),
              Text(
                'Type: ${notification.type.replaceAll('_', ' ')}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
