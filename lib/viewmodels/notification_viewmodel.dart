import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/notification.dart' as notif_model;
import '../services/local_notification_service.dart';
import '../services/supabase_service.dart';

class NotificationViewModel extends ChangeNotifier {
  NotificationViewModel(this._supabaseService);

  final SupabaseService _supabaseService;

  List<notif_model.Notification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _unreadCount = 0;
  String? _activeUserId;
  StreamSubscription<List<Map<String, dynamic>>>? _notificationsSubscription;
  final Set<int> _knownNotificationIds = <int>{};

  List<notif_model.Notification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;
  String? get activeUserId => _activeUserId;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  void _updateNotifications(List<Map<String, dynamic>> rows) {
    _notifications =
        rows.map((row) => notif_model.Notification.fromMap(row)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  Future<void> _showSystemNotificationsForNew(Set<int> previousIds) async {
    for (final notification in _notifications) {
      if (!previousIds.contains(notification.id) && !notification.isRead) {
        await LocalNotificationService.instance.showNotification(
          id: notification.id,
          title: notification.title,
          body: notification.message,
        );
      }
    }
  }

  Future<void> loadUserNotifications(String userId) async {
    _activeUserId = userId;
    _setLoading(true);
    try {
      final rows = await _supabaseService.getNotifications(userId);
      _updateNotifications(rows);
      _knownNotificationIds
        ..clear()
        ..addAll(_notifications.map((n) => n.id));
      _setError(null);
    } catch (e) {
      _setError('Failed to load notifications');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> startNotificationsStream(String userId) async {
    if (_activeUserId == userId && _notificationsSubscription != null) {
      return;
    }

    await stopNotificationsStream();
    _activeUserId = userId;

    _notificationsSubscription = _supabaseService
        .streamNotifications(userId)
        .listen(
          (rows) {
            final previousIds = Set<int>.from(_knownNotificationIds);
            _updateNotifications(rows);
            unawaited(_showSystemNotificationsForNew(previousIds));
            _knownNotificationIds
              ..clear()
              ..addAll(_notifications.map((n) => n.id));
            _errorMessage = null;
            notifyListeners();
          },
          onError: (_) {
            _setError('Failed to subscribe to notifications');
          },
        );
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      await _supabaseService.markNotificationAsRead(notificationId);
      final readAt = DateTime.now();
      _notifications = _notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true, readAt: readAt);
        }
        return n;
      }).toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to mark notification as read');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    final userId = _activeUserId;
    if (userId == null) return false;

    try {
      await _supabaseService.markAllNotificationsAsRead(userId);
      final readAt = DateTime.now();
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true, readAt: readAt))
          .toList();
      _unreadCount = 0;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to mark all notifications as read');
      return false;
    }
  }

  Future<void> stopNotificationsStream() async {
    await _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
    _knownNotificationIds.clear();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}
