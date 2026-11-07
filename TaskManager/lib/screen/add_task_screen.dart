
import 'package:flutter/material.dart';
import '../services/task_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TaskService taskService = TaskService();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final searchUserController = TextEditingController();

  DateTime? startDate;
  DateTime? dueDate;

  String priority = 'medium';
  String status = 'todo';

  List<dynamic> users = [];
  List<String> selectedAssigneeIds = [];
  String? currentUserId;
  String? primaryAssigneeId;

  bool isLoadingUsers = true;
  bool isSaving = false;
  String? userError;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    searchUserController.dispose();
    super.dispose();
  }

  Future<void> loadUsers() async {
    try {
      final results = await Future.wait([
        taskService.getUsers(),
        taskService.getCurrentUser(),
      ]);

      final userList = results[0] as List<dynamic>;
      final currentUser = results[1] as Map<String, dynamic>;

      if (!mounted) return;

      setState(() {
        users = userList;
        currentUserId = currentUser['id'].toString();

        // Mặc định người tạo là người phụ trách chính.
        primaryAssigneeId = currentUserId;
        isLoadingUsers = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        userError = e.toString();
        isLoadingUsers = false;
      });
    }
  }

  Future<void> selectDate(bool isStartDate) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (startDate ?? DateTime.now())
          : (dueDate ?? startDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) return;

    setState(() {
      if (isStartDate) {
        startDate = selectedDate;
      } else {
        dueDate = selectedDate;
      }
    });
  }

  void toggleAssignee(String userId, bool selected) {
    setState(() {
      if (selected) {
        if (!selectedAssigneeIds.contains(userId)) {
          selectedAssigneeIds.add(userId);
        }
      } else {
        selectedAssigneeIds.remove(userId);

        // Nếu bỏ chọn người đang phụ trách chính,
        // chuyển người phụ trách về người tạo.
        if (primaryAssigneeId == userId) {
          primaryAssigneeId = currentUserId;
        }
      }
    });
  }

  Future<void> saveTask() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên công việc')),
      );
      return;
    }

    if (startDate != null &&
        dueDate != null &&
        dueDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hạn hoàn thành không được trước ngày bắt đầu'),
        ),
      );
      return;
    }

    if (primaryAssigneeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn người phụ trách chính')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      // Backend yêu cầu người phụ trách chính phải có trong assigneeIds.
      final assigneeIds = List<String>.from(selectedAssigneeIds);

      if (!assigneeIds.contains(primaryAssigneeId)) {
        assigneeIds.add(primaryAssigneeId!);
      }

      await taskService.createTask(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        startDate: startDate?.toIso8601String(),
        dueDate: dueDate?.toIso8601String(),
        priority: priority,
        status: status,
        assigneeIds: assigneeIds,
        primaryAssigneeId: primaryAssigneeId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm công việc thành công')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Chưa chọn';
    return '${date.day}/${date.month}/${date.year}';
  }

  String userName(String id) {
    final user = users.firstWhere(
          (u) => u['_id'].toString() == id,
      orElse: () => null,
    );

    return user == null ? 'Không tìm thấy tài khoản' : user['name'].toString();
  }

  @override
  Widget build(BuildContext context) {
    final primaryOptions = <String>[
      ?currentUserId,
      ...selectedAssigneeIds.where((id) => id != currentUserId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm công việc'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tên công việc'),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Nhập tên công việc',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),
            const Text('Mô tả'),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Nhập mô tả công việc',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),
            const Text('Ngày bắt đầu'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(formatDate(startDate)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () => selectDate(true),
            ),

            const Divider(),
            const Text('Hạn hoàn thành'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(formatDate(dueDate)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () => selectDate(false),
            ),

            const SizedBox(height: 16),
            const Text('Mức độ ưu tiên'),
            DropdownButtonFormField<String>(
              initialValue: priority,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Thấp')),
                DropdownMenuItem(value: 'medium', child: Text('Trung bình')),
                DropdownMenuItem(value: 'high', child: Text('Cao')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => priority = value);
              },
            ),

            const SizedBox(height: 8),

            if (!isLoadingUsers && userError == null)
              TextField(
                controller: searchUserController,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm bằng tên hoặc email...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),

            const SizedBox(height: 12),

            if (isLoadingUsers)
              const Center(child: CircularProgressIndicator())
            else if (userError != null)
              Text('Không tải được danh sách: $userError')
            else
              ...users.where((user) {
                final id = user['_id'].toString();
                final name = (user['name'] ?? '').toString().toLowerCase();
                final email = (user['email'] ?? '').toString().toLowerCase();

                final keyword = searchUserController.text.trim().toLowerCase();

                return id != currentUserId &&
                    (name.contains(keyword) || email.contains(keyword));
              }).map((user) {
                final id = user['_id'].toString();

                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(user['name'].toString()),
                  subtitle: Text(user['email'].toString()),
                  value: selectedAssigneeIds.contains(id),
                  onChanged: (value) {
                    toggleAssignee(id, value ?? false);
                  },
                );
              }),

            const SizedBox(height: 20),
            const Text(
              'Người phụ trách chính',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: primaryOptions.contains(primaryAssigneeId)
                  ? primaryAssigneeId
                  : null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: primaryOptions.map((id) {
                final label = id == currentUserId
                    ? '${userName(id)} (Người tạo)'
                    : userName(id);

                return DropdownMenuItem(
                  value: id,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => primaryAssigneeId = value);
                }
              },
            ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving || isLoadingUsers || userError != null
                    ? null
                    : saveTask,
                child: isSaving
                    ? const CircularProgressIndicator()
                    : const Text('Lưu công việc'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
