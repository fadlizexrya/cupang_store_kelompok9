import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Domain server VPS BettaVerse kamu bray bray
  static const String baseUrl = 'https://bettaverse.my.id/api';

  // --- AUTH SERVICES ---

  // 📢 FIX LOGIN: Tambahkan parameter role agar lolos validasi AuthController backend!
  static Future<Map<String, dynamic>> login(String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Accept': 'application/json', // 👈 WAJIB: Biar Laravel tahu ini API, bukan web browser
        },
        body: {
          'email': email, 
          'password': password,
          'role': role, // 👈 WAJIB: Mengirim 'user' atau 'seller' sesuai pilihan di UI
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        // Simpan token ke HP bray
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['access_token']);
        return data;
      } else {
        // Biar kalau role salah atau password salah, pesan error aslinya kelihatan di Flutter bray
        var errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Login Gagal');
      }
    } catch (e) {
      throw Exception('Gagal Login: $e');
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

  // --- 📢 FUNGSI BARU: POST ARTIKEL KHUSUS ANTI-419 (MULTIPART UNTUK GAMBAR) ---
  static Future<bool> storeArtikel({
    required String judul,
    required String ringkasan,
    required String isi,
    required String? imagePath, // Bisa bernilai null jika penjual gak upload foto bray
  }) async {
    try {
      // 1. Ambil token Sanctum yang tersimpan di memori HP
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token') ?? '';

      // 2. Gunakan MultipartRequest karena kita akan mengirim file gambar bray
      // Menembak ke rute khusus kita: /post-artikel-khusus-api
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/artikel'));

      // 3. Pasang Header Keamanan Token bray!
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json', // 👈 KUNCI EMAS: Menghancurkan error 419 CSRF!
      });

      // 4. Masukkan text fields sesuai validasi ContentApiController kelompokmu
      request.fields['judul'] = judul;
      request.fields['ringkasan'] = ringkasan;
      request.fields['isi'] = isi;

      // 5. Masukkan file gambar jika ada yang dipilih dari gallery HP bray
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('gambar', imagePath));
      }

      // 6. Kirim ke server VPS bray bray
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        print("Sukses Artikel berhasil disimpan di database BettaVerse via API.");
        return true;
      } else {
        print("Gagal menyimpan artikel. Status Code: ${response.statusCode}");
        print("Log Server: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Terjadi kesalahan koneksi saat storeArtikel: $e");
      return false;
    }
  }
  static Future<bool> updateArtikel({
    required int id,
    required String judul,
    required String ringkasan,
    required String isi,
    String? imagePath, // Bisa bernilai null jika user tidak mengubah gambar
  }) async {
    final String baseUrl = "https://bettaverse.my.id";
    final prefs = await SharedPreferences.getInstance();
    final String token = prefs.getString('token') ?? prefs.getString('auth_token') ?? '';

    try {
      // Karena endpoint backend kita menggunakan POST (/api/artikel/{id}/update)
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/artikel/$id/update'));
      
      // Pasang header keamanan Bearer Token Sanctum
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Tambahkan field data teks biasa
      request.fields['judul'] = judul;
      request.fields['ringkasan'] = ringkasan;
      request.fields['isi'] = isi;

      // Jika user memilih file gambar baru dari galeri HP, ikut sertakan dalam upload
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('gambar', imagePath));
      }

      // Kirim data multipart request ke server
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true; // Berhasil diubah bray!
      } else {
        print("Server error saat update artikel: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Koneksi error saat update artikel: $e");
      return false;
    }
  }
}