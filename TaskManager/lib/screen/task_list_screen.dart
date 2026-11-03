
import 'package:flutter/material.dart';
import '../services/task_service.dart';
import 'profile_screen.dart';
import 'add_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const TaskListScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService taskService = TaskService();

  static const Color navy = Color(0xFF202B50);
  static const Color primary = Color(0xFF536DFE);
  static const Color background = Color(0xFFF4F6FC);

  Map<String, List<dynamic>> taskGroups = {
    'created': [],
    'assigned': [],
    'responsible': [],
    'shared': [],
  };

  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await taskService.getTaskGroups();

      if (!mounted) return;

      setState(() {
        taskGroups = result;
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

  Color statusColor(String? status) {
    switch (status) {
      case 'todo':
        return const Color(0xFF64748B);
      case 'in_progress':
        return const Color(0xFF2563EB);
      case 'completed':
        return const Color(0xFF16A34A);
      default:
        return Colors.grey;
    }
  }

  String priorityText(String? priority) {
    switch (priority) {
      case 'high':
        return 'Cao';
      case 'medium':
        return 'Trung bình';
      case 'low':
        return 'Thấp';
      default:
        return 'Không xác định';
    }
  }

  Color priorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'medium':
        return const Color(0xFFD97706);
      case 'low':
        return const Color(0xFF16A34A);
      default:
        return Colors.grey;
    }
  }

  String formatDate(dynamic date) {
    if (date == null) return '';

    final parsedDate = DateTime.tryParse(date.toString());

    if (parsedDate == null) return '';

    return '${parsedDate.day.toString().padLeft(2, '0')}/'
        '${parsedDate.month.toString().padLeft(2, '0')}/'
        '${parsedDate.year}';
  }

  Widget buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTaskCard(dynamic task) {
    final title = task['title']?.toString() ?? 'Không có tiêu đề';
    final status = task['status']?.toString();
    final priority = task['priority']?.toString();
    final dueDate = formatDate(task['dueDate']);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8ECF4),
        ),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: primary,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: navy,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                buildInfoChip(
                  icon: Icons.circle,
                  text: statusText(status),
                  color: statusColor(status),
                ),
                buildInfoChip(
                  icon: Icons.flag_outlined,
                  text: 'Ưu tiên ${priorityText(priority)}',
                  color: priorityColor(priority),
                ),
              ],
            ),

            if (dueDate.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(
                height: 1,
                color: Color(0xFFEDF0F5),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 17,
                    color: Color(0xFF8791A8),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Hạn hoàn thành',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8791A8),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dueDate,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: navy,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildEmptyState(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 110),
        Center(
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inbox_outlined,
                  size: 42,
                  color: primary,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Chưa có công việc',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 7),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF8791A8),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildTaskList(String groupKey, String emptyMessage) {
    final tasks = taskGroups[groupKey] ?? [];

    return RefreshIndicator(
      color: primary,
      onRefresh: loadTasks,
      child: tasks.isEmpty
          ? buildEmptyState(emptyMessage)
          : ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return buildTaskCard(tasks[index]);
        },
      ),
    );
  }

  Widget buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 55,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 15),
            const Text(
              'Không thể tải công việc',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: loadTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupNames = [
      'Tôi tạo',
      'Được giao',
      'Tôi phụ trách',
      'Được chia sẻ',
    ];

    final groupKeys = [
      'created',
      'assigned',
      'responsible',
      'shared',
    ];

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 20,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TaskManager',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Quản lý công việc nhóm',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFB8C4E5),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Tải lại',
              onPressed: isLoading ? null : loadTasks,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'Tài khoản',
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(
                      onLogout: widget.onLogout,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: Container(
              color: navy,
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFFB8C4E5),
                indicatorColor: const Color(0xFF8EA1FF),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                tabs: List.generate(4, (index) {
                  final count =
                      taskGroups[groupKeys[index]]?.length ?? 0;

                  return Tab(
                    text: '${groupNames[index]} ($count)',
                  );
                }),
              ),
            ),
          ),
        ),
        body: isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: primary,
          ),
        )
            : error != null
            ? buildErrorState()
            : TabBarView(
          children: [
            buildTaskList(
              'created',
              'Bạn chưa tạo công việc nào.',
            ),
            buildTaskList(
              'assigned',
              'Bạn chưa được giao công việc nào.',
            ),
            buildTaskList(
              'responsible',
              'Bạn chưa phụ trách công việc nào.',
            ),
            buildTaskList(
              'shared',
              'Chưa có công việc nào được chia sẻ với bạn.',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 5,
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddTaskScreen(),
              ),
            );

            if (result == true && mounted) {
              loadTasks();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text(
            'Thêm công việc',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
