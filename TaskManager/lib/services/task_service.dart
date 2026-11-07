
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TaskService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  final FlutterSecureStorage storage =
  const FlutterSecureStorage();

  Future<String> _getToken() async {
    final token = await storage.read(key: 'token');

    if (token == null || token.isEmpty) {
      throw Exception('Bạn chưa đăng nhập');
    }

    return token;
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Xử lý phản hồi từ Backend
  dynamic _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['message'] ?? 'Có lỗi xảy ra từ máy chủ',
    );
  }

  Future<List<dynamic>> getTasks({
    String? search,
    String? status,
    String? priority,
    String? assigneeId,
    String sortBy = 'createdAt',
  }) async {
    final query = <String, String>{
      'sortBy': sortBy,
    };

    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    if (status != null) {
      query['status'] = status;
    }

    if (priority != null) {
      query['priority'] = priority;
    }

    if (assigneeId != null) {
      query['assigneeId'] = assigneeId;
    }

    final uri = Uri.parse('$baseUrl/api/tasks')
        .replace(queryParameters: query);

    final response = await http.get(
      uri,
      headers: await _headers(),
    );

    final data = _handleResponse(response);

    if (data is List) {
      return data;
    }

    throw Exception('Dữ liệu danh sách công việc không hợp lệ');
  }

  Future<Map<String, dynamic>> getTaskById(
      String id,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tasks/$id'),
      headers: await _headers(),
    );

    final data = _handleResponse(response);

    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> createTask({
    required String title,
    String description = '',
    String? startDate,
    String? dueDate,
    String priority = 'medium',
    String status = 'todo',
    List<String> assigneeIds = const [],
    String? primaryAssigneeId,
    List<String> sharedWithIds = const [],
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tasks'),
      headers: await _headers(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'startDate': startDate,
        'dueDate': dueDate,
        'priority': priority,
        'status': status,
        'assigneeIds': assigneeIds,
        'primaryAssigneeId': primaryAssigneeId,
        'sharedWithIds': sharedWithIds,
      }),
    );

    final data = _handleResponse(response);

    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> updateTask(
      String id,
      Map<String, dynamic> updateData,
      ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/tasks/$id'),
      headers: await _headers(),
      body: jsonEncode(updateData),
    );

    final data = _handleResponse(response);

    return Map<String, dynamic>.from(data);
  }

  // 5. XÓA CÔNG VIỆC
  Future<Map<String, dynamic>> deleteTask(
      String id,
      ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/tasks/$id'),
      headers: await _headers(),
    );

    final data = _handleResponse(response);

    return Map<String, dynamic>.from(data);
  }
  // LẤY DANH SÁCH NGƯỜI DÙNG
  Future<List<dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users'),
      headers: await _headers(),
    );

    final data = _handleResponse(response);

    if (data is List) {
      return data;
    }

    throw Exception('Dữ liệu danh sách người dùng không hợp lệ');
  }
  Future<Map<String, List<dynamic>>> getTaskGroups() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tasks/groups'),
      headers: await _headers(),
    );

    final data = _handleResponse(response);

    return {
      'created': List<dynamic>.from(data['created'] ?? []),
      'assigned': List<dynamic>.from(data['assigned'] ?? []),
      'responsible': List<dynamic>.from(data['responsible'] ?? []),
      'shared': List<dynamic>.from(data['shared'] ?? []),
    };
  }
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/me'),
      headers: await _headers(),
    );

    final data = _handleResponse(response);

    return Map<String, dynamic>.from(data);
  }
}
