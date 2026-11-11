
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
      final data = await _taskService.getTaskStatistics();

      if (!mounted) return;

      setState(() {
        total = (data['total'] as num?)?.toInt() ?? 0;
        byStatus = Map<String, dynamic>.from(
          data['byStatus'] ?? {},
        );
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
          ],
        ),
      ),
    );
  }
}
