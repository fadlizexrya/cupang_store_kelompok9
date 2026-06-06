import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti dengan domain server atau IP (10.0.2.2 jika pake emulator android)
  static const String baseUrl = 'https://bettaverse.my.id/api';

  // --- AUTH SERVICES ---

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      // Simpan token ke HP
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['access_token']);
      return data;
    } else {
      throw Exception('Login Gagal');
    }
  }

  // --- CONTENT SERVICES ---

  static Future<List<dynamic>> getMarketplace() async {
    final response = await http.get(Uri.parse('$baseUrl/marketplace'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Gagal ambil data marketplace');
    }
  }

  static Future<List<dynamic>> getArtikel() async {
    final response = await http.get(Uri.parse('$baseUrl/artikel'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Gagal ambil data artikel');
    }
  }
}