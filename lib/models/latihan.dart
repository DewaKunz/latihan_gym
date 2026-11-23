// Model data untuk mencatat satu aktivitas latihan gym
class Latihan {
  final String id;
  final String namaLatihan;
  final double beban; // dalam satuan kg
  final int jumlahSet;
  final int jumlahRepetisi;
  final DateTime tanggal;

  Latihan({
    required this.id,
    required this.namaLatihan,
    required this.beban,
    required this.jumlahSet,
    required this.jumlahRepetisi,
    required this.tanggal,
  });

  // Getter untuk menghitung total volume latihan (beban x set x repetisi)
  double get volume => beban * jumlahSet * jumlahRepetisi;

  // Mengubah objek Latihan menjadi Map (JSON)
  // Tanggal disimpan dalam format string ISO 8601
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'namaLatihan': namaLatihan,
      'beban': beban,
      'jumlahSet': jumlahSet,
      'jumlahRepetisi': jumlahRepetisi,
      'tanggal': tanggal.toIso8601String(),
    };
  }

  // Membuat objek Latihan dari Map (JSON)
  // Dilengkapi nilai default agar data lama tetap aman terbaca
  factory Latihan.fromJson(Map<String, dynamic> json) {
    return Latihan(
      id: json['id'] as String? ?? '',
      namaLatihan: json['namaLatihan'] as String? ?? '',
      beban: (json['beban'] as num?)?.toDouble() ?? 0.0,
      jumlahSet: (json['jumlahSet'] as num?)?.toInt() ?? 0,
      jumlahRepetisi: (json['jumlahRepetisi'] as num?)?.toInt() ?? 0,
      tanggal: json['tanggal'] != null
          ? DateTime.tryParse(json['tanggal'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // Membuat salinan objek Latihan dengan nilai baru yang diperbarui
  Latihan copyWith({
    String? id,
    String? namaLatihan,
    double? beban,
    int? jumlahSet,
    int? jumlahRepetisi,
    DateTime? tanggal,
  }) {
    return Latihan(
      id: id ?? this.id,
      namaLatihan: namaLatihan ?? this.namaLatihan,
      beban: beban ?? this.beban,
      jumlahSet: jumlahSet ?? this.jumlahSet,
      jumlahRepetisi: jumlahRepetisi ?? this.jumlahRepetisi,
      tanggal: tanggal ?? this.tanggal,
    );
  }
}
