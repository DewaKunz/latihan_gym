import 'package:material_ui/material_ui.dart';

// Daftar kategori otot yang tersedia dalam aplikasi
const List<String> daftarKategoriOtot = [
  'Dada',
  'Punggung',
  'Kaki',
  'Bahu',
  'Lengan',
  'Core',
  'Lainnya',
];

// Mengambil warna tema visual yang sesuai untuk setiap kategori otot
Color getWarnaKategori(String kategori) {
  switch (kategori) {
    case 'Dada':
      return const Color(0xFFFF5252); // Merah cerah
    case 'Punggung':
      return const Color(0xFF448AFF); // Biru cerah
    case 'Kaki':
      return const Color(0xFF69F0AE); // Hijau toska
    case 'Bahu':
      return const Color(0xFFFFAB40); // Oranye amber
    case 'Lengan':
      return const Color(0xFFE040FB); // Ungu magenta
    case 'Core':
      return const Color(0xFF18FFFF); // Cyan cerah
    case 'Lainnya':
    default:
      return const Color(0xFFB0BEC5); // Abu-abu
  }
}

// Mengambil ikon yang sesuai untuk setiap kategori otot
IconData getIkonKategori(String kategori) {
  switch (kategori) {
    case 'Dada':
      return Icons.fitness_center;
    case 'Punggung':
      return Icons.accessibility_new;
    case 'Kaki':
      return Icons.directions_run;
    case 'Bahu':
      return Icons.sports_gymnastics;
    case 'Lengan':
      return Icons.sports_kabaddi;
    case 'Core':
      return Icons.self_improvement;
    case 'Lainnya':
    default:
      return Icons.category_outlined;
  }
}
