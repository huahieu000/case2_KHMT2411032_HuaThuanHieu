
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'task_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService notificationService = NotificationService();

  List<dynamic> notifications = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await notificationService.getNotifications();
      if (!mounted) return;

      setState(() {
        notifications = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> openNotification(Map<String, dynamic> notification) async {
    final notificationId = notification['_id']?.toString();
    final taskId = notification['taskId']?.toString();

    if (notificationId == null || taskId == null) return;

    try {
      if (notification['isRead'] != true) {
        await notificationService.markAsRead(notificationId);
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TaskDetailScreen(taskId: taskId),
        ),
      );

      if (!mounted) return;
      await loadNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở thông báo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            tooltip: 'Thông báo',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadNotifications,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : notifications.isEmpty
          ? const Center(
        child: Text('Bạn chưa có thông báo nào'),
      )
          : RefreshIndicator(
        onRefresh: loadNotifications,
        child: ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final item = Map<String, dynamic>.from(
              notifications[index],
            );

            final isRead = item['isRead'] == true;

            return ListTile(
              leading: Icon(
                isRead
                    ? Icons.notifications_none
                    : Icons.notifications_active,
                color: isRead ? Colors.grey : Colors.blue,
              ),
              title: Text(
                item['title']?.toString() ?? 'Thông báo',
                style: TextStyle(
                  fontWeight: isRead
                      ? FontWeight.normal
                      : FontWeight.bold,
                ),
              ),
              subtitle: Text(
                item['message']?.toString() ?? '',
              ),
              trailing: isRead
                  ? null
                  : const Icon(
                Icons.circle,
                size: 10,
                color: Colors.blue,
              ),
              onTap: () => openNotification(item),
            );
          },
        ),
      ),
    );
  }
}
