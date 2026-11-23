import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/latihan.dart';

// Layanan untuk mengelola penyimpanan data latihan menggunakan SharedPreferences
class LatihanStorage {
  static const String _keyLatihan = 'daftar_latihan';

  // Membaca seluruh data latihan dari SharedPreferences
  // Jika belum ada data atau terjadi error decoding, mengembalikan list kosong []
  Future<List<Latihan>> loadLatihan() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyLatihan);

    if (jsonString == null || jsonString.trim().isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decodedList = jsonDecode(jsonString) as List<dynamic>;
      return decodedList
          .map((item) => Latihan.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Jika data rusak atau format tidak sesuai, kembalikan list kosong
      return [];
    }
  }

  // Menyimpan seluruh list data latihan ke SharedPreferences sebagai JSON string
  Future<void> saveLatihan(List<Latihan> listLatihan) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList =
        listLatihan.map((latihan) => latihan.toJson()).toList();
    final String jsonString = jsonEncode(jsonList);
    await prefs.setString(_keyLatihan, jsonString);
  }
}
