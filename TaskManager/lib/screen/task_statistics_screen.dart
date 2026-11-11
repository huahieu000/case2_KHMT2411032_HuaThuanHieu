
import 'package:flutter/material.dart';
import '../services/task_service.dart';

class TaskStatisticsScreen extends StatefulWidget {
  const TaskStatisticsScreen({super.key});

  @override
  State<TaskStatisticsScreen> createState() =>
      _TaskStatisticsScreenState();
}

class _TaskStatisticsScreenState extends State<TaskStatisticsScreen> {
  final TaskService _taskService = TaskService();

  bool isLoading = true;
  String? errorMessage;
  int total = 0;
  Map<String, dynamic> byStatus = {};
  // E2 - Thống kê công việc được giao và đang phụ trách
  int assignedCount = 0;
  int responsibleCount = 0;
// E3 - Danh sách công việc sắp đến hạn và quá hạn
  List<dynamic> upcomingTasks = [];
  List<dynamic> overdueTasks = [];

  @override
  void initState() {
    super.initState();
    loadStatistics();
  }

  Future<void> loadStatistics() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // E1 - Thống kê công việc theo trạng thái
      final data = await _taskService.getTaskStatistics();

      // E2 - Thống kê theo vai trò
      final groups = await _taskService.getTaskGroups();
      final assigned = groups['assigned']?.length ?? 0;
      final responsible = groups['responsible']?.length ?? 0;

      // E3 - Lấy công việc để phân loại theo hạn
      final tasks = await _taskService.getTasks();

      final now = DateTime.now();
      final next24Hours = now.add(const Duration(hours: 24));

      final upcoming = <dynamic>[];
      final overdue = <dynamic>[];

      for (final task in tasks) {
        if (task is! Map) continue;
        if (task['status'] == 'completed') continue;

        final dueDateString = task['dueDate']?.toString();
        if (dueDateString == null || dueDateString.isEmpty) {
          continue;
        }

        final dueDate = DateTime.tryParse(dueDateString);
        if (dueDate == null) continue;

        if (dueDate.isBefore(now)) {
          overdue.add(task);
        } else if (!dueDate.isAfter(next24Hours)) {
          upcoming.add(task);
        }
      }

      // Sắp xếp theo hạn hoàn thành
      upcoming.sort(
            (a, b) => DateTime.parse(a['dueDate'].toString())
            .compareTo(DateTime.parse(b['dueDate'].toString())),
      );

      overdue.sort(
            (a, b) => DateTime.parse(a['dueDate'].toString())
            .compareTo(DateTime.parse(b['dueDate'].toString())),
      );

      if (!mounted) return;

      setState(() {
        // E1
        total = (data['total'] as num?)?.toInt() ?? 0;
        byStatus = Map<String, dynamic>.from(
          data['byStatus'] ?? {},
        );

        // E2
        assignedCount = assigned;
        responsibleCount = responsible;

        // E3
        upcomingTasks = upcoming;
        overdueTasks = overdue;

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

  Widget buildStatCard(
      String title,
      int count,
      IconData icon,
      Color color,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title),
        trailing: Text(
          '$count',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statuses = [
      ('todo', 'Chờ thực hiện', Icons.pending_actions, Colors.orange),
      ('in_progress', 'Đang thực hiện', Icons.autorenew, Colors.blue),
      ('completed', 'Hoàn thành', Icons.check_circle, Colors.green),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê công việc'),
        actions: [
          IconButton(
            tooltip: 'Tải lại thống kê',
            icon: const Icon(Icons.refresh),
            onPressed: loadStatistics,
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
        onRefresh: loadStatistics,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            buildStatCard(
              'Tổng số công việc',
              total,
              Icons.assignment,
              Colors.indigo,
            ),
            for (final item in statuses)
              buildStatCard(
                item.$2,
                (byStatus[item.$1] as num?)?.toInt() ?? 0,
                item.$3,
                item.$4,
              ),
            // E2 - Thống kê công việc được giao và đang phụ trách
            const SizedBox(height: 16),

            const Text(
              'Thống kê công việc theo vai trò',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            buildStatCard(
              'Công việc được giao',
              assignedCount,
              Icons.assignment_ind_outlined,
              Colors.orange,
            ),

            buildStatCard(
              'Công việc đang phụ trách',
              responsibleCount,
              Icons.supervisor_account_outlined,
              Colors.blue,
            ),

            // E3 - Hiển thị công việc sắp đến hạn và quá hạn
            const SizedBox(height: 20),

            const Text(
              'Công việc theo hạn hoàn thành',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Sắp đến hạn trong 24 giờ (${upcomingTasks.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),

            if (upcomingTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Không có công việc sắp đến hạn'),
              ),

            for (final task in upcomingTasks)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.orange),
                  title: Text(task['title']?.toString() ?? 'Không có tên'),
                  subtitle: Text(
                    'Hạn: ${DateTime.parse(task['dueDate'].toString()).toLocal().toString().substring(0, 16)}',
                  ),
                ),
              ),

            const SizedBox(height: 20),

            Text(
              'Đã quá hạn (${overdueTasks.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),

            if (overdueTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Không có công việc quá hạn'),
              ),

            for (final task in overdueTasks)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.warning_amber, color: Colors.red),
                  title: Text(task['title']?.toString() ?? 'Không có tên'),
                  subtitle: Text(
                    'Hạn: ${DateTime.parse(task['dueDate'].toString()).toLocal().toString().substring(0, 16)}',
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }
}
