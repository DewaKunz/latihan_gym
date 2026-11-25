import 'package:material_ui/material_ui.dart';
import '../models/gerakan.dart';
import '../models/kategori_otot.dart';
import '../models/latihan.dart';
import '../services/latihan_storage.dart';
import '../theme/app_theme.dart';
import 'form_latihan_page.dart';

// Halaman detail untuk panduan gerakan latihan gym
class GerakanDetailPage extends StatefulWidget {
  final Gerakan gerakan;

  const GerakanDetailPage({super.key, required this.gerakan});

  @override
  State<GerakanDetailPage> createState() => _GerakanDetailPageState();
}

class _GerakanDetailPageState extends State<GerakanDetailPage> {
  final LatihanStorage _storage = LatihanStorage();

  // Helper untuk warna badge tingkat kesulitan
  Color _getWarnaTingkat(String tingkat) {
    switch (tingkat.toLowerCase()) {
      case 'pemula':
        return const Color(0xFF69F0AE); // Hijau cerah
      case 'menengah':
        return const Color(0xFFFFAB40); // Oranye amber
      case 'lanjut':
        return const Color(0xFFFF5252); // Merah cerah
      default:
        return AppTheme.textSecondary;
    }
  }

  // Membuka form tambah latihan dengan nama dan kategori gerakan terisi awal
  Future<void> _catatLatihanIni() async {
    final Latihan? hasil = await Navigator.push<Latihan>(
      context,
      MaterialPageRoute(
        builder: (context) => FormLatihanPage(
          awal: Latihan(
            id: '', // ID kosong menandakan mode tambah dari panduan
            namaLatihan: widget.gerakan.nama,
            beban: 0,
            jumlahSet: 3,
            jumlahRepetisi: 10,
            tanggal: DateTime.now(),
            kategori: widget.gerakan.kategori,
            catatan: 'Panduan: ${widget.gerakan.nama}',
          ),
        ),
      ),
    );

    // Jika pengguna menyimpan latihan baru, simpan ke SharedPreferences
    if (hasil != null && mounted) {
      try {
        final List<Latihan> dataLama = await _storage.loadLatihan();
        dataLama.add(hasil);
        dataLama.sort((a, b) => b.tanggal.compareTo(a.tanggal));
        await _storage.saveLatihan(dataLama);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Latihan "${hasil.namaLatihan}" berhasil dicatat'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppTheme.surfaceLight,
          ),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan latihan'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gerakan = widget.gerakan;
    final warnaKategori = getWarnaKategori(gerakan.kategori);
    final ikonKategori = getIkonKategori(gerakan.kategori);
    final warnaTingkat = _getWarnaTingkat(gerakan.tingkat);

    return Scaffold(
      appBar: AppBar(
        title: Text(gerakan.nama),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Foto / Thumbnail Besar dengan fallback errorBuilder
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Image.asset(
                  gerakan.gambar ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback visual jika file gambar lokal belum dimasukkan
                    return Container(
                      color: AppTheme.surface,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: warnaKategori.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: warnaKategori.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Icon(
                              ikonKategori,
                              size: 48,
                              color: warnaKategori,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            gerakan.nama,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kategori: ${gerakan.kategori}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Chip Info: Kategori, Peralatan, dan Tingkat
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Chip Kategori
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: warnaKategori.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: warnaKategori.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(ikonKategori, size: 14, color: warnaKategori),
                      const SizedBox(width: 6),
                      Text(
                        gerakan.kategori,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: warnaKategori,
                        ),
                      ),
                    ],
                  ),
                ),
                // Chip Peralatan
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        gerakan.peralatan,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Chip Tingkat Kesulitan
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: warnaTingkat.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: warnaTingkat.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 14, color: warnaTingkat),
                      const SizedBox(width: 4),
                      Text(
                        gerakan.tingkat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: warnaTingkat,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Card Otot yang Dilatih (Otot Utama & Otot Pendukung)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.accessibility_new,
                          size: 20,
                          color: AppTheme.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Otot yang Dilatih',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Otot Utama
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Otot Utama: ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            gerakan.ototUtama,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Otot Pendukung
                    const Text(
                      'Otot Pendukung: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: gerakan.ototPendukung.map((otot) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            otot,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Card Langkah-langkah Pelaksanaan (Bernomor)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.format_list_numbered,
                          size: 20,
                          color: AppTheme.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Langkah-langkah Pelaksanaan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...gerakan.langkah.asMap().entries.map((entry) {
                      final nomor = entry.key + 1;
                      final deskripsi = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primary,
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$nomor',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                deskripsi,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 5. Card Tips Latihan
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: Color(0xFFFFAB40), // Amber
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Tips Latihan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...gerakan.tips.map((tip) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: Color(0xFF69F0AE),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 6. Card Kesalahan Umum
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 20,
                          color: AppTheme.danger,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Kesalahan Umum',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...gerakan.kesalahanUmum.map((kesalahan) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.cancel_outlined,
                              size: 16,
                              color: AppTheme.danger,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                kesalahan,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 7. Tombol "Catat Latihan Ini"
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _catatLatihanIni,
                icon: const Icon(Icons.edit_calendar, size: 20),
                label: const Text(
                  'Catat Latihan Ini',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
