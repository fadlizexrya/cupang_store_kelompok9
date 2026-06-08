import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'https://bettaverse.my.id/api';

  // Tambahkan parameter role bray pas panggil fungsi login
  Future<bool> login(String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Accept': 'application/json', // 👈 WAJIB: Biar Laravel ngerespon berupa JSON, anti-419!
        },
        body: {
          'email': email, 
          'password': password,
          'role': role, // 👈 KIRIM ROLE NYA BRAY ('user' atau 'seller')
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String token = data['access_token'];

        // Simpan token ke memori HP pakai key 'token'
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        return true;
      } else {
        print("Login Gagal: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error login_service: $e");
      return false;
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}