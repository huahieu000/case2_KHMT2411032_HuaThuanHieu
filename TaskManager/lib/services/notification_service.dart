
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  final FlutterSecureStorage storage =
  const FlutterSecureStorage();

  Future<Map<String, String>> _headers() async {
    final token = await storage.read(key: 'token');

    if (token == null || token.isEmpty) {
      throw Exception('Bạn chưa đăng nhập');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // D7 - Lấy danh sách thông báo
  Future<List<dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notifications'),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return List<dynamic>.from(data['notifications']);
    }

    throw Exception(data['message'] ?? 'Không thể tải thông báo');
  }

  // D7 - Đánh dấu thông báo đã đọc
  Future<void> markAsRead(String notificationId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Không thể đánh dấu đã đọc');
    }
  }
}
