// Model representasi panduan gerakan latihan gym
class Gerakan {
  final String id;
  final String nama;
  final String kategori; // Dada, Punggung, Kaki, Bahu, Lengan, Core
  final String ototUtama;
  final List<String> ototPendukung;
  final String peralatan;
  final String tingkat; // Pemula, Menengah, Lanjut
  final List<String> langkah;
  final List<String> tips;
  final List<String> kesalahanUmum;
  final String? gambar; // Path asset lokal, misal assets/images/gerakan/<id>.jpg

  const Gerakan({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.ototUtama,
    required this.ototPendukung,
    required this.peralatan,
    required this.tingkat,
    required this.langkah,
    required this.tips,
    required this.kesalahanUmum,
    this.gambar,
  });
}
