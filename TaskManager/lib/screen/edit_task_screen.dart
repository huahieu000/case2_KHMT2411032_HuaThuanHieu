import 'package:flutter/material.dart';
import '../services/task_service.dart';

class EditTaskScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const EditTaskScreen({
    super.key,
    required this.task,
  });

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final TaskService taskService = TaskService();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  DateTime? startDate;
  DateTime? dueDate;

  String priority = 'medium';
  String status = 'todo';

  List<dynamic> users = [];
  List<String> selectedAssigneeIds = [];
  List<String> selectedSharedIds = [];

  String? primaryAssigneeId;

  bool isLoadingUsers = true;
  bool isSaving = false;
  String? userError;

  // Lấy ID dù dữ liệu là Object hay String.
  String? getId(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      final id = value['_id'] ?? value['id'];
      return id?.toString();
    }

    return value.toString();
  }

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  @override
  void initState() {
    super.initState();

    // Điền thông tin công việc hiện tại.
    final task = widget.task;

    titleController.text = task['title']?.toString() ?? '';
    descriptionController.text =
        task['description']?.toString() ?? '';

    startDate = parseDate(task['startDate']);
    dueDate = parseDate(task['dueDate']);

    priority = task['priority']?.toString() ?? 'medium';
    status = task['status']?.toString() ?? 'todo';

    // Lấy danh sách người được giao.
    final assignees = task['assigneeIds'];

    if (assignees is List) {
      selectedAssigneeIds = assignees
          .map((user) => getId(user))
          .whereType<String>()
          .toSet()
          .toList();
    }

    // Lấy người phụ trách chính.
    primaryAssigneeId = getId(task['primaryAssigneeId']);
    // Lấy danh sách người đang được chia sẻ
    final sharedUsers = task['sharedWithIds'];

    if (sharedUsers is List) {
      selectedSharedIds = sharedUsers
          .map((user) => getId(user))
          .whereType<String>()
          .toSet()
          .toList();
    }
    if (primaryAssigneeId != null &&
        !selectedAssigneeIds.contains(primaryAssigneeId)) {
      selectedAssigneeIds.add(primaryAssigneeId!);
    }

    loadUsers();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // Tải danh sách người dùng.
  Future<void> loadUsers() async {
    try {
      final result = await taskService.getUsers();

      if (!mounted) return;

      setState(() {
        users = result;

        // Nếu chưa có người phụ trách chính,
        // chọn người đầu tiên trong danh sách được giao.
        if (primaryAssigneeId == null &&
            selectedAssigneeIds.isNotEmpty) {
          primaryAssigneeId = selectedAssigneeIds.first;
        }

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

  // Chọn ngày.
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

  // Chọn hoặc bỏ chọn người được giao.
  void toggleAssignee(String userId, bool selected) {
    setState(() {
      if (selected) {
        if (!selectedAssigneeIds.contains(userId)) {
          selectedAssigneeIds.add(userId);
        }
      } else {
        selectedAssigneeIds.remove(userId);

        // Nếu bỏ chọn người phụ trách chính,
        // chuyển sang người còn lại.
        if (primaryAssigneeId == userId) {
          primaryAssigneeId = selectedAssigneeIds.isNotEmpty
              ? selectedAssigneeIds.first
              : null;
        }
      }
    });
  }

// Chọn hoặc bỏ chọn người được chia sẻ.
  void toggleSharedUser(String userId, bool selected) {
    setState(() {
      if (selected) {
        if (!selectedSharedIds.contains(userId)) {
          selectedSharedIds.add(userId);
        }
      } else {
        selectedSharedIds.remove(userId);
      }
    });
  }

  // Lấy tên người dùng.
  String userName(String id) {
    for (final user in users) {
      if (getId(user) == id) {
        return user['name']?.toString() ?? 'Không có tên';
      }
    }

    return 'Không tìm thấy tài khoản';
  }

  // Định dạng ngày.
  String formatDate(DateTime? date) {
    if (date == null) return 'Chưa chọn';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // Lưu thông tin chỉnh sửa.
  Future<void> saveTask() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên công việc'),
        ),
      );
      return;
    }

    if (startDate != null &&
        dueDate != null &&
        dueDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hạn hoàn thành không được trước ngày bắt đầu',
          ),
        ),
      );
      return;
    }

    if (primaryAssigneeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn người phụ trách chính'),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // Đảm bảo người phụ trách chính nằm trong danh sách
      // người được giao.
      final assigneeIds = List<String>.from(
        selectedAssigneeIds,
      );

      if (!assigneeIds.contains(primaryAssigneeId)) {
        assigneeIds.add(primaryAssigneeId!);
      }

      await taskService.updateTask(
        getId(widget.task['_id'] ?? widget.task['id'])!,
        {
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'startDate': startDate?.toIso8601String(),
          'dueDate': dueDate?.toIso8601String(),
          'priority': priority,
          'status': status,
          'assigneeIds': assigneeIds,
          'primaryAssigneeId': primaryAssigneeId,
          'sharedWithIds': selectedSharedIds,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật công việc thành công'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Danh sách người có thể được chọn làm phụ trách chính.
    final primaryOptions = selectedAssigneeIds.toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa công việc'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TÊN CÔNG VIỆC
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

            // MÔ TẢ
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

            // NGÀY BẮT ĐẦU
            const Text('Ngày bắt đầu'),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(formatDate(startDate)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () => selectDate(true),
            ),

            const Divider(),

            // HẠN HOÀN THÀNH
            const Text('Hạn hoàn thành'),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(formatDate(dueDate)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () => selectDate(false),
            ),

            const SizedBox(height: 16),

            // MỨC ĐỘ ƯU TIÊN
            const Text('Mức độ ưu tiên'),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: priority,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
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
                if (value != null) {
                  setState(() => priority = value);
                }
              },
            ),

            const SizedBox(height: 20),

            // TRẠNG THÁI
            const Text('Trạng thái'),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
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
                if (value != null) {
                  setState(() => status = value);
                }
              },
            ),

            const SizedBox(height: 24),

            // NGƯỜI ĐƯỢC GIAO
            const Text(
              'Người được giao',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            if (isLoadingUsers)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (userError != null)
              Text('Không tải được danh sách: $userError')
            else
              ...users.map((user) {
                final id = getId(user);

                if (id == null) {
                  return const SizedBox.shrink();
                }

                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    user['name']?.toString() ?? '',
                  ),
                  subtitle: Text(
                    user['email']?.toString() ?? '',
                  ),
                  value: selectedAssigneeIds.contains(id),
                  onChanged: (value) {
                    toggleAssignee(id, value ?? false);
                  },
                );
              }),

            const SizedBox(height: 20),

            // NGƯỜI PHỤ TRÁCH CHÍNH
            const Text(
              'Người phụ trách chính',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              key: ValueKey(primaryAssigneeId),
              initialValue: primaryOptions.contains(
                primaryAssigneeId,
              )
                  ? primaryAssigneeId
                  : null,

              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),

              items: primaryOptions.map((id) {
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(userName(id)),
                );
              }).toList(),

              onChanged: primaryOptions.isEmpty
                  ? null
                  : (value) {
                if (value != null) {
                  setState(() {
                    primaryAssigneeId = value;
                  });
                }
              },
            ),
// NGƯỜI ĐƯỢC CHIA SẺ
            const SizedBox(height: 24),

            const Text(
              'Chia sẻ công việc',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Chọn những người có thể xem công việc này',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 8),

            if (isLoadingUsers)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (userError != null)
              Text('Không tải được danh sách: $userError')
            else
              ...users.map((user) {
                final id = getId(user);

                if (id == null) {
                  return const SizedBox.shrink();
                }

                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    user['name']?.toString() ?? '',
                  ),
                  subtitle: Text(
                    user['email']?.toString() ?? '',
                  ),
                  secondary: const Icon(
                    Icons.visibility_outlined,
                    color: Colors.blue,
                  ),
                  value: selectedSharedIds.contains(id),
                  onChanged: (value) {
                      toggleSharedUser(id, value ?? false);
                  },
                );
              }),
            const SizedBox(height: 28),

            // NÚT LƯU
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isSaving ||
                    isLoadingUsers ||
                    userError != null
                    ? null
                    : saveTask,

                child: isSaving
                    ? const CircularProgressIndicator()
                    : const Text(
                  'Lưu thay đổi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}