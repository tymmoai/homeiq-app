// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/api_client.dart';
import '../../../utils/responsive_utils.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  // Notification data – loaded from backend.
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  int get _unreadCount =>
      _notifications.where((n) => n['isRead'] == false).length;

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  /// Fetches notifications from `GET /api/v1/notifications` and populates
  /// the list.
  Future<void> _loadFromBackend() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient().get('/notifications');
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List? ?? [];

      final mapped = data.map((rawItem) {
        final item = rawItem as Map<String, dynamic>;
        final type = item['type'] as String? ?? '';
        IconData icon;
        if (type.contains('booking') || type.contains('service')) {
          icon = Icons.build_circle_outlined;
        } else if (type.contains('maintenance') || type.contains('reminder')) {
          icon = Icons.home_repair_service_outlined;
        } else if (type.contains('payment')) {
          icon = Icons.payment_outlined;
        } else if (type.contains('asset')) {
          icon = Icons.inventory_2_outlined;
        } else if (type.contains('warning') || type.contains('alert')) {
          icon = Icons.warning_amber_outlined;
        } else {
          icon = Icons.notifications_none;
        }
        return {
          'id': item['id'] ?? '',
          'title': item['title'] ?? '',
          'message': item['body'] ?? '',
          'timestamp': item['createdAt'] != null
              ? DateTime.tryParse(item['createdAt'] as String) ?? DateTime.now()
              : DateTime.now(),
          'icon': icon,
          'isRead': item['isRead'] as bool? ?? false,
          'type': type,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(mapped);
          _isLoading = false;
        });
      }
    } on Object catch (e) {
      debugPrint('[NotificationScreen] Failed to load notifications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks weeks ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months months ago';
    }
  }

  String _getSectionForTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );
    final daysDiff = today.difference(notificationDate).inDays;

    if (daysDiff == 0) {
      return 'Today';
    } else if (daysDiff <= 7) {
      return 'This Week';
    } else {
      return 'Last Month';
    }
  }

  Future<void> _markAllAsRead() async {
    // Optimistic update
    setState(() {
      for (final n in _notifications) {
        n['isRead'] = true;
      }
    });
    // Persist to backend
    try {
      await ApiClient().put('/notifications/read-all');
    } on Object catch (e) {
      debugPrint('[NotificationScreen] markAllRead failed: $e');
    }
  }

  Future<void> _markAsRead(String id) async {
    setState(() {
      final notification = _notifications.firstWhere(
        (n) => n['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (notification.isNotEmpty) {
        notification['isRead'] = true;
      }
    });
    // Persist to backend
    try {
      await ApiClient().put('/notifications/$id/read');
    } on Object catch (e) {
      debugPrint('[NotificationScreen] markRead failed: $e');
    }
  }

  Future<void> _deleteNotification(String id) async {
    setState(() {
      _notifications.removeWhere((n) => n['id'] == id);
    });
    // Persist to backend
    try {
      await ApiClient().delete('/notifications/$id');
    } on Object catch (e) {
      debugPrint('[NotificationScreen] deleteNotification failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group notifications by section
    const sectionOrder = ['Today', 'This Week', 'Last Month'];
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final s in sectionOrder) {
      grouped[s] = [];
    }
    for (final n in _notifications) {
      final timestamp = n['timestamp'] as DateTime?;
      if (timestamp != null) {
        final sec = _getSectionForTimestamp(timestamp);
        grouped[sec]!.add(n);
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.headerBackground,
        elevation: 2,
        systemOverlayStyle: AppColors.headerBackground.computeLuminance() > 0.5
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.headerForeground, size: responsive.iconSize(20)),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                color: AppColors.headerForeground,
                fontSize: responsive.fontSize(18),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_unreadCount > 0)
              Text(
                '$_unreadCount unread',
                style: TextStyle(
                  color: AppColors.headerForeground.withValues(alpha: 0.7),
                  fontSize: responsive.fontSize(12),
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        centerTitle: false,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark All as Read',
                style: TextStyle(
                  color: AppColors.headerForeground.withValues(alpha: 0.9),
                  fontSize: responsive.fontSize(13),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (!_isLoading)
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.headerForeground, size: responsive.iconSize(20)),
              onPressed: _loadFromBackend,
              tooltip: 'Refresh',
            ),
          SizedBox(width: responsive.spacing(8)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: responsive.spacing(16), vertical: responsive.spacing(12)),
              itemCount: sectionOrder.length,
              itemBuilder: (context, sectionIndex) {
                final section = sectionOrder[sectionIndex];
                final items = grouped[section] ?? [];

                if (items.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    Padding(
                      padding: EdgeInsets.only(
                        top: sectionIndex == 0 ? 0 : 16,
                        bottom: 12,
                      ),
                      child: Text(
                        section,
                        style: TextStyle(
                          fontSize: responsive.fontSize(13),
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary.withValues(alpha: 0.75),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // Notification Items
                    ...items.map((notification) {
                      return _buildNotificationItem(notification);
                    }),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: responsive.iconSize(64),
            color: Colors.grey.shade300,
          ),
          SizedBox(height: responsive.spacing(16)),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: responsive.fontSize(18),
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: responsive.spacing(8)),
          Text(
            'You\'re all caught up!',
            style: TextStyle(fontSize: responsive.fontSize(14), color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final notificationId = notification['id'] as String? ?? '';
    final isRead = notification['isRead'] as bool? ?? false;
    final title = notification['title'] as String? ?? '';
    final message = notification['message'] as String? ?? '';
    final timestamp = notification['timestamp'] as DateTime?;
    final timeAgo = timestamp != null ? _formatTimeAgo(timestamp) : '';
    final icon = notification['icon'] as IconData? ?? Icons.notifications_none;

    return Dismissible(
      key: Key(notificationId),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: const Color.fromARGB(255, 181, 181, 181),
        child: const Icon(
          Icons.delete_outline,
          color: Color.fromARGB(255, 22, 33, 58),
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color.fromARGB(255, 181, 181, 181),
        child: const Icon(
          Icons.delete_outline,
          color: Color.fromARGB(255, 22, 33, 58),
        ),
      ),
      onDismissed: (direction) {
        _deleteNotification(notificationId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          _markAsRead(notificationId);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: responsive.spacing(12)),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with unread dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: isRead
                          ? Colors.grey.shade200
                          : AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: responsive.iconSize(25),
                      color: isRead
                          ? Colors.grey.shade600
                          : AppColors.primary,
                    ),
                  ),
                  // Unread dot on top right of icon
                  if (!isRead)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        height: 10,
                        width: 10,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 22, 33, 58),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: responsive.spacing(12)),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: responsive.fontSize(15),
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              color: isRead
                                  ? Colors.grey.shade800
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: responsive.spacing(8)),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.spacing(4)),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: responsive.fontSize(13),
                        color: isRead
                            ? Colors.grey.shade600
                            : Colors.grey.shade700,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}
