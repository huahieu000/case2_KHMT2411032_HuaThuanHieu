
import 'package:flutter/material.dart';
import '../services/task_service.dart';
import 'edit_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService taskService = TaskService();

  Map<String, dynamic>? task;
  bool hasChanged = false;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadTaskDetail();
  }
  Future<void> editTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTaskScreen(
          task: task!,
        ),
      ),
    );

    if (result == true && mounted) {
      hasChanged = true;
      await loadTaskDetail();
    }
  }

  Future<void> loadTaskDetail() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await taskService.getTaskById(widget.taskId);

      if (!mounted) return;

      setState(() {

        task = result['task'] is Map
            ? Map<String, dynamic>.from(result['task'])
            : result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String formatDate(dynamic date) {
    if (date == null) return 'Chưa thiết lập';

    final parsedDate = DateTime.tryParse(date.toString());

    if (parsedDate == null) return 'Không hợp lệ';

    return '${parsedDate.day.toString().padLeft(2, '0')}/'
        '${parsedDate.month.toString().padLeft(2, '0')}/'
        '${parsedDate.year}';
  }

  String statusText(String? status) {
    switch (status) {
      case 'todo':
        return 'Chưa thực hiện';
      case 'in_progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Hoàn thành';
      default:
        return 'Không xác định';
    }
  }

  String priorityText(String? priority) {
    switch (priority) {
      case 'low':
        return 'Thấp';
      case 'medium':
        return 'Trung bình';
      case 'high':
        return 'Cao';
      default:
        return 'Không xác định';
    }
  }

  Widget buildInfo(String label, String value,
      {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.blueGrey),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa công việc'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa công việc này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await taskService.deleteTask(widget.taskId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xóa công việc thành công'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Widget buildDetail() {
    if (task == null) {
      return const Center(
        child: Text('Không tìm thấy công việc'),
      );
    }

    final title = task!['title']?.toString() ?? '';
    final description =
        task!['description']?.toString() ?? 'Không có mô tả';

    final status = task!['status']?.toString();
    final priority = task!['priority']?.toString();

    return RefreshIndicator(
      onRefresh: loadTaskDetail,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'THÔNG TIN CÔNG VIỆC',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: editTask,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Chỉnh sửa công việc'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Divider(),
                  buildInfo(
                    'Mô tả',
                    description,
                    icon: Icons.description_outlined,
                  ),
                  buildInfo(
                    'Ngày bắt đầu',
                    formatDate(task!['startDate']),
                    icon: Icons.calendar_today,
                  ),
                  buildInfo(
                    'Hạn hoàn thành',
                    formatDate(task!['dueDate']),
                    icon: Icons.event,
                  ),
                  buildInfo(
                    'Trạng thái',
                    statusText(status),
                    icon: Icons.flag_outlined,
                  ),
                  buildInfo(
                    'Ưu tiên',
                    priorityText(priority),
                    icon: Icons.priority_high,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PHÂN CÔNG CÔNG VIỆC',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),

                  buildInfo(
                    'Người phụ trách chính',
                    getUserName(task!['primaryAssigneeId']),
                  ),

                  const Divider(),

                  const Text(
                    'Danh sách người được giao',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ...getAssigneeNames(task!['assigneeIds'])
                      .map(
                        (name) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(name),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: deleteTask,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Xóa công việc'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String getUserName(dynamic user) {
    if (user == null) return 'Chưa xác định';

    if (user is Map) {
      return user['name']?.toString() ?? 'Chưa xác định';
    }

    return user.toString();
  }

  List<String> getAssigneeNames(dynamic assignees) {
    if (assignees is! List) return [];

    return assignees.map((user) {
      return getUserName(user);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, hasChanged);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết công việc'),
        ),
        body: isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : error != null
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: loadTaskDetail,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        )
            : buildDetail(),
      ),
    );
  }
}
