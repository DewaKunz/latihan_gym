import 'package:material_ui/material_ui.dart';
import '../data/panduan_gerakan.dart';
import '../models/gerakan.dart';
import '../models/kategori_otot.dart';
import '../theme/app_theme.dart';
import 'gerakan_detail_page.dart';

// Halaman Panduan Gerakan Latihan Gym (Perpustakaan Gerakan)
class PanduanPage extends StatefulWidget {
  const PanduanPage({super.key});

  @override
  State<PanduanPage> createState() => _PanduanPageState();
}

class _PanduanPageState extends State<PanduanPage> {
  final TextEditingController _searchController = TextEditingController();
  String _keywordCari = '';
  String _kategoriTerpilih = 'Semua';

  // Daftar kategori yang memiliki panduan gerakan
  final List<String> _kategoriList = [
    'Semua',
    'Dada',
    'Punggung',
    'Kaki',
    'Bahu',
    'Lengan',
    'Core',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter daftar gerakan berdasarkan kategori dan kata kunci pencarian
  List<Gerakan> get _daftarTampil {
    return daftarPanduanGerakan.where((g) {
      final bool cocokKategori =
          _kategoriTerpilih == 'Semua' || g.kategori == _kategoriTerpilih;
      final bool cocokCari = _keywordCari.isEmpty ||
          g.nama.toLowerCase().contains(_keywordCari) ||
          g.ototUtama.toLowerCase().contains(_keywordCari);
      return cocokKategori && cocokCari;
    }).toList();
  }

  // Helper untuk warna badge tingkat kesulitan gerakan
  Color _getWarnaTingkat(String tingkat) {
    switch (tingkat.toLowerCase()) {
      case 'pemula':
        return const Color(0xFF69F0AE); // Hijau toska
      case 'menengah':
        return const Color(0xFFFFAB40); // Oranye amber
      case 'lanjut':
        return const Color(0xFFFF5252); // Merah cerah
      default:
        return AppTheme.textSecondary;
    }
  }

  // Reset pencarian dan filter kategori
  void _resetFilter() {
    setState(() {
      _searchController.clear();
      _keywordCari = '';
      _kategoriTerpilih = 'Semua';
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _daftarTampil;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panduan Gerakan'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Kolom Pencarian Gerakan
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (value) {
                setState(() {
                  _keywordCari = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari nama gerakan atau otot...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                suffixIcon: _keywordCari.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _keywordCari = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),

          // 2. Baris ChoiceChip Kategori Otot (Dapat digeser horizontal)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: _kategoriList.map((kategori) {
                final isSelected = _kategoriTerpilih == kategori;
                final warna = kategori == 'Semua'
                    ? AppTheme.primary
                    : getWarnaKategori(kategori);
                final ikon = kategori == 'Semua'
                    ? Icons.apps
                    : getIkonKategori(kategori);

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    avatar: Icon(
                      ikon,
                      size: 15,
                      color: isSelected ? warna : AppTheme.textSecondary,
                    ),
                    label: Text(kategori),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _kategoriTerpilih = selected ? kategori : 'Semua';
                      });
                    },
                    backgroundColor: AppTheme.surface,
                    selectedColor: warna.withValues(alpha: 0.25),
                    side: BorderSide(
                      color: isSelected ? warna : AppTheme.border,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? warna : AppTheme.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 3. Ringkasan Hasil & Daftar Gerakan
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 56,
                            color:
                                AppTheme.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Tidak ada gerakan yang cocok',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Coba ubah kata kunci pencarian atau pilih kategori lain',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _resetFilter,
                            icon: const Icon(
                              Icons.refresh,
                              color: AppTheme.primary,
                            ),
                            label: const Text(
                              'Reset Filter',
                              style: TextStyle(color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final gerakan = items[index];
                      final warnaKategori = getWarnaKategori(gerakan.kategori);
                      final ikonKategori = getIkonKategori(gerakan.kategori);
                      final warnaTingkat = _getWarnaTingkat(gerakan.tingkat);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            // Membuka halaman detail panduan gerakan
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    GerakanDetailPage(gerakan: gerakan),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Thumbnail dengan fallback errorBuilder
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 74,
                                    height: 74,
                                    color: AppTheme.surfaceLight,
                                    child: Image.asset(
                                      gerakan.gambar ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: warnaKategori.withValues(
                                            alpha: 0.15,
                                          ),
                                          child: Icon(
                                            ikonKategori,
                                            size: 32,
                                            color: warnaKategori,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Informasi Gerakan
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Baris Kategori & Tingkat Kesulitan
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Badge Kategori
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: warnaKategori.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: warnaKategori.withValues(
                                                  alpha: 0.4,
                                                ),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              gerakan.kategori,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: warnaKategori,
                                              ),
                                            ),
                                          ),
                                          // Badge Tingkat
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: warnaTingkat.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              gerakan.tingkat,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: warnaTingkat,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      // Nama Gerakan
                                      Text(
                                        gerakan.nama,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),

                                      // Otot Utama
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.accessibility_new,
                                            size: 13,
                                            color: AppTheme.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              gerakan.ototUtama,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: AppTheme.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
