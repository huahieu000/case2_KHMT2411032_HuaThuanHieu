
import 'package:flutter/material.dart';
import '../services/task_service.dart';
import 'profile_screen.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';

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
  final TextEditingController searchController =
  TextEditingController();

  String searchKeyword = '';
  String selectedSort = 'createdAt';
  String? selectedStatus;
  String? selectedPriority;
  String? selectedAssigneeId;

  List<dynamic> users = [];

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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadTasks() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await taskService.getTaskGroups();

      List<dynamic> loadedUsers = [];

      try {
        loadedUsers = await taskService.getUsers();
      } catch (e) {
        debugPrint('Không thể tải danh sách người dùng: $e');
      }

      if (!mounted) return;

      setState(() {
        taskGroups = result;
        users = loadedUsers;
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

  String getUserId(dynamic user) {
    if (user == null) return '';

    if (user is Map) {
      return (user['_id'] ?? user['id'] ?? '').toString();
    }

    return user.toString();
  }

  Widget buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      color: background,
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: (value) {
              setState(() {
                searchKeyword = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm công việc...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchKeyword.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchController.clear();

                  setState(() {
                    searchKeyword = '';
                  });
                },
              )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 145,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedStatus ?? '',
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: '',
                      child: Text('Tất cả'),
                    ),
                    DropdownMenuItem(
                      value: 'todo',
                      child: Text('Chưa thực hiện'),
                    ),
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('Đang thực hiện'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Hoàn thành'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedStatus =
                      value == '' ? null : value;
                    });
                  },
                ),
              ),

              SizedBox(
                width: 145,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedPriority ?? '',
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Mức ưu tiên',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: '',
                      child: Text('Tất cả'),
                    ),
                    DropdownMenuItem(
                      value: 'low',
                      child: Text('Thấp'),
                    ),
                    DropdownMenuItem(
                      value: 'medium',
                      child: Text('Trung bình'),
                    ),
                    DropdownMenuItem(
                      value: 'high',
                      child: Text('Cao'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedPriority =
                      value == '' ? null : value;
                    });
                  },
                ),
              ),

              SizedBox(
                width: 145,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedAssigneeId ?? '',
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Người phụ trách',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Tất cả'),
                    ),
                    ...users.map((user) {
                      return DropdownMenuItem<String>(
                        value: getUserId(user),
                        child: Text(
                          user['name']?.toString() ??
                              user['email']?.toString() ??
                              'Người dùng',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedAssigneeId =
                      value == '' ? null : value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.sort,
                color: navy,
              ),
              const SizedBox(width: 8),

              const Text(
                'Sắp xếp:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedSort,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'dueDate',
                      child: Text('Hạn hoàn thành'),
                    ),
                    DropdownMenuItem(
                      value: 'priority',
                      child: Text('Mức độ ưu tiên'),
                    ),
                    DropdownMenuItem(
                      value: 'createdAt',
                      child: Text('Thời gian tạo'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedSort = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                searchController.clear();

                setState(() {
                  searchKeyword = '';
                  selectedStatus = null;
                  selectedPriority = null;
                  selectedAssigneeId = null;
                });
              },
              icon: const Icon(Icons.refresh, size: 17),
              label: const Text('Xóa bộ lọc'),
            ),
          ),
        ],
      ),
    );
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

  Widget buildProgressSummary(List<dynamic> tasks) {
    final total = tasks.length;

    final todo = tasks.where(
          (task) => task['status'] == 'todo',
    ).length;

    final inProgress = tasks.where(
          (task) => task['status'] == 'in_progress',
    ).length;

    final completed = tasks.where(
          (task) => task['status'] == 'completed',
    ).length;

    final percent = total == 0
        ? 0
        : (completed / total * 100).round();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiến độ công việc',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : completed / total,
                minHeight: 9,
                backgroundColor: const Color(0xFFE5E7EB),
                color: const Color(0xFF16A34A),
              ),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                buildInfoChip(
                  icon: Icons.assignment_outlined,
                  text: 'Tổng: $total',
                  color: navy,
                ),
                buildInfoChip(
                  icon: Icons.circle,
                  text: 'Chưa làm: $todo',
                  color: const Color(0xFF64748B),
                ),
                buildInfoChip(
                  icon: Icons.autorenew,
                  text: 'Đang làm: $inProgress',
                  color: const Color(0xFF2563EB),
                ),
                buildInfoChip(
                  icon: Icons.check_circle,
                  text: 'Hoàn thành: $completed',
                  color: const Color(0xFF16A34A),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTaskCard(dynamic task) {
    final title =
        task['title']?.toString() ?? 'Không có tiêu đề';
    final status = task['status']?.toString();
    final priority = task['priority']?.toString();
    final dueDate = formatDate(task['dueDate']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final taskId = task['_id']?.toString() ??
              task['id']?.toString();

          if (taskId == null || taskId.isEmpty) {
            return;
          }

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(
                taskId: taskId,
              ),
            ),
          );

          if (result == true && mounted) {
            await loadTasks();
          }
        },
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 35,
                ),
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

// SẮP XẾP DANH SÁCH CÔNG VIỆC
  List<dynamic> sortTasks(List<dynamic> tasks) {
    final sortedTasks = List<dynamic>.from(tasks);

    sortedTasks.sort((a, b) {
      switch (selectedSort) {
        case 'dueDate':
          final dateA = DateTime.tryParse(
            a['dueDate']?.toString() ?? '',
          );

          final dateB = DateTime.tryParse(
            b['dueDate']?.toString() ?? '',
          );

          if (dateA == null) return 1;
          if (dateB == null) return -1;

          return dateA.compareTo(dateB);

        case 'priority':
          const priorityOrder = {
            'high': 1,
            'medium': 2,
            'low': 3,
          };

          final priorityA =
              priorityOrder[a['priority']] ?? 4;

          final priorityB =
              priorityOrder[b['priority']] ?? 4;

          return priorityA.compareTo(priorityB);

        case 'createdAt':
        default:
          final dateA = DateTime.tryParse(
            a['createdAt']?.toString() ?? '',
          );

          final dateB = DateTime.tryParse(
            b['createdAt']?.toString() ?? '',
          );

          if (dateA == null) return 1;
          if (dateB == null) return -1;

          return dateB.compareTo(dateA);
      }
    });

    return sortedTasks;
  }

  List<dynamic> getFilteredTasks(String groupKey) {
    final tasks = taskGroups[groupKey] ?? [];
    final filteredTasks = tasks.where((task) {
      final title = (task['title'] ?? '')
          .toString()
          .toLowerCase();

      final keyword = searchKeyword.trim().toLowerCase();

      if (keyword.isNotEmpty && !title.contains(keyword)) {
        return false;
      }

      if (selectedStatus != null &&
          task['status'] != selectedStatus) {
        return false;
      }

      if (selectedPriority != null &&
          task['priority'] != selectedPriority) {
        return false;
      }

      if (selectedAssigneeId != null) {
        final primaryId = getUserId(
          task['primaryAssigneeId'],
        );

        if (primaryId != selectedAssigneeId) {
          return false;
        }
      }

      return true;
    }).toList();

    return sortTasks(filteredTasks);
  }

  Widget buildTaskList(
      String groupKey,
      String emptyMessage,
      ) {
    final allTasks = taskGroups[groupKey] ?? [];
    final tasks = getFilteredTasks(groupKey);

    final hasFilter = searchKeyword.isNotEmpty ||
        selectedStatus != null ||
        selectedPriority != null ||
        selectedAssigneeId != null;

    return RefreshIndicator(
      color: primary,
      onRefresh: loadTasks,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          90,
        ),
        children: [
          // Thống kê tiến độ của nhóm đang xem
          buildProgressSummary(allTasks),

          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 35,
                horizontal: 15,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 55,
                    color: primary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hasFilter
                        ? 'Không tìm thấy công việc phù hợp.'
                        : emptyMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF8791A8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            ...tasks.map((task) => buildTaskCard(task)),
        ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
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
            : Column(
          children: [
            buildSearchAndFilters(),

            Expanded(
              child: TabBarView(
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
              await loadTasks();
            }
          },

          icon: const Icon(Icons.add),

          label: const Text(
            'Thêm công việc',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
