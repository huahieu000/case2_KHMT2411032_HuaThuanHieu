
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  final FlutterSecureStorage storage =
  const FlutterSecureStorage();

  // 1. ĐĂNG KÝ
  Future<Map<String, dynamic>> register(
      String name,
      String email,
      String password,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data;
    }

    throw Exception(data['message'] ?? 'Đăng ký thất bại');
  }

  // 2. ĐĂNG NHẬP
  Future<Map<String, dynamic>> login(
      String email,
      String password,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await storage.write(
        key: 'token',
        value: data['token'],
      );

      return data;
    }

    throw Exception(data['message'] ?? 'Đăng nhập thất bại');
  }

  // 3. LẤY TOKEN
  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  // 4. ĐĂNG XUẤT
  Future<void> logout() async {
    await storage.delete(key: 'token');
  }

  // 5. XEM THÔNG TIN CÁ NHÂN
  Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Bạn chưa đăng nhập');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Không thể lấy thông tin');
  }

  // 6. CẬP NHẬT THÔNG TIN
  Future<Map<String, dynamic>> updateProfile(
      String name,
      ) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/api/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Cập nhật thất bại');
  }

  // 7. ĐỔI MẬT KHẨU
  Future<Map<String, dynamic>> changePassword(
      String oldPassword,
      String newPassword,
      ) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/api/users/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Đổi mật khẩu thất bại');
  }
}
