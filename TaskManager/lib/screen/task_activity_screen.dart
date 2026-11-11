
import 'package:flutter/material.dart';
import '../services/task_service.dart';

// E4 - Màn hình lịch sử hoạt động công việc
class TaskActivityScreen extends StatefulWidget {
  final String taskId;

  const TaskActivityScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<TaskActivityScreen> createState() => _TaskActivityScreenState();
}

class _TaskActivityScreenState extends State<TaskActivityScreen> {
  final TaskService _taskService = TaskService();

  bool isLoading = true;
  String? errorMessage;
  List<dynamic> activities = [];

  @override
  void initState() {
    super.initState();
    loadActivities();
  }

  Future<void> loadActivities() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await _taskService.getTaskActivities(widget.taskId);

      if (!mounted) return;

      setState(() {
        activities = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  String actionLabel(String? action) {
    switch (action) {
      case 'created':
        return 'Tạo công việc';
      case 'updated':
        return 'Cập nhật công việc';
      case 'status_changed':
        return 'Thay đổi trạng thái';
      case 'assignee_changed':
        return 'Thay đổi người phụ trách';
      default:
        return 'Hoạt động';
    }
  }

  String formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'Không xác định';

    final local = date.toLocal();

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử hoạt động'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh),
            onPressed: loadActivities,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Text(
          errorMessage!,
          textAlign: TextAlign.center,
        ),
      )
          : RefreshIndicator(
        onRefresh: loadActivities,
        child: activities.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 150),
            Center(
              child: Text('Chưa có lịch sử hoạt động'),
            ),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            debugPrint('E4 ACTIVITY: $activity');
            final user = activity['userId'];

            final userName = user is Map
                ? (user['name']?.toString() ??
                'Người dùng')
                : 'Người dùng';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(
                  Icons.history,
                  color: Colors.indigo,
                ),
                title: Text(
                  actionLabel(
                    activity['action']?.toString(),
                  ),
                ),
                subtitle: Text(
                  '$userName\n'
                      '${activity['description'] ?? ''}\n'
                      '${formatDate(activity['createdAt'])}',
                ),
                isThreeLine: true,
              ),
            );
          },
        ),
      ),
    );
  }
}
