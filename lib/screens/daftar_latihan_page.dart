import 'package:material_ui/material_ui.dart';
import '../models/kategori_otot.dart';
import '../models/latihan.dart';
import '../services/latihan_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/dialog_konfirmasi_hapus.dart';
import 'detail_latihan_page.dart';
import 'form_latihan_page.dart';

// Kelas abstrak untuk item dalam daftar tampilan (header tanggal atau data latihan)
abstract class ItemDaftarLatihan {}

// Item header tanggal yang menampilkan tanggal dan total volume pada tanggal tersebut
class HeaderTanggalItem extends ItemDaftarLatihan {
  final DateTime tanggal;
  final String labelTanggal;
  final double totalVolume;

  HeaderTanggalItem({
    required this.tanggal,
    required this.labelTanggal,
    required this.totalVolume,
  });
}

// Item data latihan
class DataLatihanItem extends ItemDaftarLatihan {
  final Latihan latihan;

  DataLatihanItem(this.latihan);
}

// Halaman utama untuk menampilkan daftar riwayat latihan gym dengan tema modern
class DaftarLatihanPage extends StatefulWidget {
  const DaftarLatihanPage({super.key});

  @override
  State<DaftarLatihanPage> createState() => _DaftarLatihanPageState();
}

class _DaftarLatihanPageState extends State<DaftarLatihanPage> {
  final LatihanStorage _storage = LatihanStorage();
  List<Latihan> _daftarLatihan = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter Kategori Otot (default: 'Semua')
  String _filterKategori = 'Semua';

  // Filter Tanggal (satu tanggal atau rentang tanggal)
  DateTime? _filterTanggal;
  DateTimeRange? _filterRentang;

  // Kontrol dan kata kunci pencarian nama latihan
  final TextEditingController _searchController = TextEditingController();
  String _keywordCari = '';

  // Opsi pengurutan daftar (default: 'terbaru')
  // Pilihan: 'terbaru', 'terlama', 'volume', 'nama'
  String _opsiUrutan = 'terbaru';

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Memuat data dari SharedPreferences
  Future<void> _muatData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<Latihan> data = await _storage.loadLatihan();

      // Urutkan data awal berdasarkan tanggal terbaru
      data.sort((a, b) => b.tanggal.compareTo(a.tanggal));

      setState(() {
        _daftarLatihan = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Gagal memuat data latihan';
        _isLoading = false;
      });
    }
  }

  // Mengecek kesamaan tanggal (tahun, bulan, hari)
  bool _apakahTanggalSama(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  // Mengambil daftar latihan yang tampil setelah disaring (kategori, tanggal, pencarian)
  // serta diurutkan sesuai opsi yang dipilih
  List<Latihan> get _daftarTampil {
    // 1. Salin list master agar tidak mengubah data asli
    List<Latihan> hasil = List.from(_daftarLatihan);

    // 2. Filter Kategori Otot
    if (_filterKategori != 'Semua') {
      hasil = hasil.where((item) => item.kategori == _filterKategori).toList();
    }

    // 3. Filter Tanggal (Satu Tanggal atau Rentang Tanggal)
    if (_filterTanggal != null) {
      hasil = hasil
          .where((item) => _apakahTanggalSama(item.tanggal, _filterTanggal!))
          .toList();
    } else if (_filterRentang != null) {
      final start = DateTime(
        _filterRentang!.start.year,
        _filterRentang!.start.month,
        _filterRentang!.start.day,
      );
      final end = DateTime(
        _filterRentang!.end.year,
        _filterRentang!.end.month,
        _filterRentang!.end.day,
        23,
        59,
        59,
        999,
      );
      hasil = hasil
          .where((item) =>
              !item.tanggal.isBefore(start) && !item.tanggal.isAfter(end))
          .toList();
    }

    // 4. Filter Pencarian Nama Latihan (tidak peka huruf besar-kecil)
    if (_keywordCari.isNotEmpty) {
      hasil = hasil
          .where((item) =>
              item.namaLatihan.toLowerCase().contains(_keywordCari))
          .toList();
    }

    // 5. Pengurutan Tampilan
    switch (_opsiUrutan) {
      case 'terlama':
        hasil.sort((a, b) => a.tanggal.compareTo(b.tanggal));
        break;
      case 'volume':
        hasil.sort((a, b) => b.volume.compareTo(a.volume));
        break;
      case 'nama':
        hasil.sort((a, b) =>
            a.namaLatihan.toLowerCase().compareTo(b.namaLatihan.toLowerCase()));
        break;
      case 'terbaru':
      default:
        hasil.sort((a, b) => b.tanggal.compareTo(a.tanggal));
        break;
    }

    return hasil;
  }

  // Menghasilkan label tanggal: "Hari ini", "Kemarin", atau format dd/mm/yyyy
  String _getLabelTanggal(DateTime dt) {
    final now = DateTime.now();
    if (_apakahTanggalSama(dt, now)) {
      return 'Hari ini';
    }
    final kemarin = DateTime(now.year, now.month, now.day - 1);
    if (_apakahTanggalSama(dt, kemarin)) {
      return 'Kemarin';
    }
    return _formatTanggal(dt);
  }

  // Menghasilkan daftar campuran (header tanggal + data latihan) untuk ListView
  List<ItemDaftarLatihan> get _daftarCampuran {
    final List<Latihan> items = _daftarTampil;
    if (items.isEmpty) return [];

    // Saat urutan = Volume tertinggi atau Nama A-Z, header tidak ditampilkan
    if (_opsiUrutan != 'terbaru' && _opsiUrutan != 'terlama') {
      return items.map((l) => DataLatihanItem(l)).toList();
    }

    // Saat urutan = Terbaru atau Terlama, kelompokkan per tanggal dengan header
    final List<ItemDaftarLatihan> campuran = [];
    DateTime? tanggalGrup;
    List<Latihan> grup = [];

    void flushGrup() {
      if (grup.isEmpty || tanggalGrup == null) return;
      final double totalVolume = grup.fold(
        0.0,
        (sum, item) => sum + item.volume,
      );
      campuran.add(
        HeaderTanggalItem(
          tanggal: tanggalGrup,
          labelTanggal: _getLabelTanggal(tanggalGrup),
          totalVolume: totalVolume,
        ),
      );
      for (final l in grup) {
        campuran.add(DataLatihanItem(l));
      }
      grup = [];
    }

    for (final lat in items) {
      if (tanggalGrup == null || !_apakahTanggalSama(tanggalGrup, lat.tanggal)) {
        flushGrup();
        tanggalGrup = lat.tanggal;
      }
      grup.add(lat);
    }
    flushGrup();

    return campuran;
  }

  // Mengecek apakah ada filter yang sedang aktif
  bool get _adaFilterAktif =>
      _filterKategori != 'Semua' ||
      _filterTanggal != null ||
      _filterRentang != null ||
      _keywordCari.isNotEmpty;

  // Membuka dialog kalender untuk memilih satu tanggal
  Future<void> _pilihSatuTanggal() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _filterTanggal ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _filterTanggal = picked;
        _filterRentang = null; // Menghapus filter rentang jika ada
      });
    }
  }

  // Membuka dialog kalender untuk memilih rentang tanggal
  Future<void> _pilihRentangTanggal() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _filterRentang ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );

    if (picked != null) {
      setState(() {
        _filterRentang = picked;
        _filterTanggal = null; // Menghapus filter satu tanggal jika ada
      });
    }
  }

  // Mereset seluruh filter dan kata kunci pencarian
  void _hapusSemuaFilter() {
    setState(() {
      _filterKategori = 'Semua';
      _filterTanggal = null;
      _filterRentang = null;
      _searchController.clear();
      _keywordCari = '';
    });
  }

  // Menghapus latihan dari daftar dengan opsi Urungkan (Undo) lewat SnackBar
  Future<void> _hapusLatihanDenganUndo(Latihan latihan) async {
    final int indexAsli =
        _daftarLatihan.indexWhere((item) => item.id == latihan.id);
    if (indexAsli == -1) return;

    // Hapus dari data lokal dan simpan ke SharedPreferences
    setState(() {
      _daftarLatihan.removeAt(indexAsli);
    });
    await _storage.saveLatihan(_daftarLatihan);

    if (!mounted) return;

    // Tampilkan SnackBar dengan tombol aksi "Urungkan"
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Latihan "${latihan.namaLatihan}" dihapus'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Urungkan',
          textColor: AppTheme.primary,
          onPressed: () async {
            // Mengembalikan item ke posisi semula
            setState(() {
              if (indexAsli <= _daftarLatihan.length) {
                _daftarLatihan.insert(indexAsli, latihan);
              } else {
                _daftarLatihan.add(latihan);
              }
            });
            await _storage.saveLatihan(_daftarLatihan);
          },
        ),
      ),
    );
  }

  // Membuka form tambah latihan lewat Navigator.push
  Future<void> _bukaFormTambah() async {
    final Latihan? hasil = await Navigator.push<Latihan>(
      context,
      MaterialPageRoute(
        builder: (context) => const FormLatihanPage(),
      ),
    );

    // Jika pengguna menyimpan data, tambahkan ke list asli dan simpan ke SharedPreferences
    if (hasil != null) {
      setState(() {
        _daftarLatihan.add(hasil);
        _daftarLatihan.sort((a, b) => b.tanggal.compareTo(a.tanggal));
      });

      await _storage.saveLatihan(_daftarLatihan);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Latihan berhasil ditambahkan'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Membuka halaman detail latihan lewat Navigator.push
  Future<void> _bukaDetail(Latihan latihan) async {
    final Map<String, dynamic>? hasil =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => DetailLatihanPage(latihan: latihan),
      ),
    );

    // Tangani aksi dari halaman detail (ubah, hapus, atau duplikat)
    if (hasil != null) {
      final aksi = hasil['aksi'] as String?;

      if (aksi == 'hapus') {
        final String id = hasil['id'] as String;
        final itemDihapus = _daftarLatihan.firstWhere(
          (item) => item.id == id,
          orElse: () => latihan,
        );
        await _hapusLatihanDenganUndo(itemDihapus);
      } else if (aksi == 'duplikat') {
        final Latihan latihanBaru = hasil['latihan'] as Latihan;
        setState(() {
          _daftarLatihan.add(latihanBaru);
          _daftarLatihan.sort((a, b) => b.tanggal.compareTo(a.tanggal));
        });
        await _storage.saveLatihan(_daftarLatihan);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Latihan berhasil diduplikasi'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (aksi == 'ubah') {
        final Latihan latihanBaru = hasil['latihan'] as Latihan;
        setState(() {
          final index =
              _daftarLatihan.indexWhere((item) => item.id == latihanBaru.id);
          if (index != -1) {
            _daftarLatihan[index] = latihanBaru;
          }
          _daftarLatihan.sort((a, b) => b.tanggal.compareTo(a.tanggal));
        });
        await _storage.saveLatihan(_daftarLatihan);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perubahan latihan berhasil disimpan'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  // Format tanggal manual tanpa package intl (dd/mm/yyyy)
  String _formatTanggal(DateTime dt) {
    final hari = dt.day.toString().padLeft(2, '0');
    final bulan = dt.month.toString().padLeft(2, '0');
    final tahun = dt.year.toString();
    return '$hari/$bulan/$tahun';
  }

  // Format angka volume dengan pemisah ribuan titik (contoh: 3000 -> 3.000)
  String _formatVolume(double vol) {
    if (vol == vol.roundToDouble()) {
      final intVal = vol.toInt().toString();
      final buffer = StringBuffer();
      final chars = intVal.split('').reversed.toList();
      for (int i = 0; i < chars.length; i++) {
        if (i > 0 && i % 3 == 0) {
          buffer.write('.');
        }
        buffer.write(chars[i]);
      }
      return buffer.toString().split('').reversed.join('');
    } else {
      final parts = vol.toStringAsFixed(1).split('.');
      final intPart = parts[0];
      final decPart = parts[1];
      final buffer = StringBuffer();
      final chars = intPart.split('').reversed.toList();
      for (int i = 0; i < chars.length; i++) {
        if (i > 0 && i % 3 == 0) {
          buffer.write('.');
        }
        buffer.write(chars[i]);
      }
      final formattedInt = buffer.toString().split('').reversed.join('');
      return '$formattedInt,$decPart';
    }
  }

  // Format beban kg (jika bulat tampil tanpa desimal)
  String _formatBeban(double beban) {
    if (beban == beban.roundToDouble()) {
      return beban.toInt().toString();
    }
    return beban.toString();
  }

  // Widget chip kecil untuk informasi beban, set x repetisi, dan tanggal
  Widget _buildMiniChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Widget header tanggal untuk memisahkan kelompok latihan per tanggal
  Widget _buildHeaderTanggal(HeaderTanggalItem header) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sisi Kiri: Ikon kalender dan label tanggal ("Hari ini", "Kemarin", atau dd/mm/yyyy)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  size: 13,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                header.labelTanggal,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          // Sisi Kanan: Total volume latihan hari itu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.border,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total: ',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatVolume(header.totalVolume),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 3),
                const Text(
                  'kg',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget chip filter aktif dengan tombol silang (hapus)
  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_alt, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onDeleted,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(2.0),
              child: Icon(
                Icons.close,
                size: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Item menu pada popup pilihan urutan
  PopupMenuItem<String> _buildPopupMenuItem({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = _opsiUrutan == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppTheme.primary : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool dateFilterActive =
        _filterTanggal != null || _filterRentang != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencatat Latihan Gym'),
        centerTitle: true,
        actions: [
          // Menu Filter Tanggal dengan Pilihan "Satu Tanggal" dan "Rentang Tanggal"
          PopupMenuButton<String>(
            icon: Icon(
              dateFilterActive
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: dateFilterActive ? AppTheme.primary : null,
            ),
            tooltip: 'Filter Tanggal',
            color: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.border),
            ),
            onSelected: (String value) {
              if (value == 'satu') {
                _pilihSatuTanggal();
              } else if (value == 'rentang') {
                _pilihRentangTanggal();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'satu',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: _filterTanggal != null
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Satu tanggal',
                      style: TextStyle(
                        fontWeight: _filterTanggal != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _filterTanggal != null
                            ? AppTheme.primary
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'rentang',
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 18,
                      color: _filterRentang != null
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Rentang tanggal',
                      style: TextStyle(
                        fontWeight: _filterRentang != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _filterRentang != null
                            ? AppTheme.primary
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _bukaFormTambah,
        tooltip: 'Tambah Latihan',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppTheme.danger, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _muatData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    // Tampilan jika data penyimpanan master memang belum ada sama sekali
    if (_daftarLatihan.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border, width: 1.5),
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 52,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tekan tombol + di bawah untuk mencatat latihan baru',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final items = _daftarTampil;
    final campuran = _daftarCampuran;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Bar Kontrol: Kolom Cari + Tombol Pengurutan (Sort)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              // Kolom Cari (TextField)
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (value) {
                    setState(() {
                      _keywordCari = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari nama latihan...',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 20),
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
              const SizedBox(width: 10),

              // Pilihan Urutan (PopupMenuButton)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.sort, color: AppTheme.primary),
                  tooltip: 'Urutkan Daftar',
                  color: AppTheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  onSelected: (String value) {
                    setState(() {
                      _opsiUrutan = value;
                    });
                  },
                  itemBuilder: (context) => [
                    _buildPopupMenuItem(
                      value: 'terbaru',
                      label: 'Terbaru',
                      icon: Icons.schedule,
                    ),
                    _buildPopupMenuItem(
                      value: 'terlama',
                      label: 'Terlama',
                      icon: Icons.history,
                    ),
                    _buildPopupMenuItem(
                      value: 'volume',
                      label: 'Volume tertinggi',
                      icon: Icons.trending_up,
                    ),
                    _buildPopupMenuItem(
                      value: 'nama',
                      label: 'Nama A-Z',
                      icon: Icons.sort_by_alpha,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. Baris ChoiceChip Horizontal untuk Filter Kategori Otot
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              // Chip "Semua"
              ChoiceChip(
                label: const Text('Semua'),
                selected: _filterKategori == 'Semua',
                onSelected: (selected) {
                  setState(() {
                    _filterKategori = 'Semua';
                  });
                },
                backgroundColor: AppTheme.surface,
                selectedColor: AppTheme.primary.withValues(alpha: 0.25),
                side: BorderSide(
                  color: _filterKategori == 'Semua'
                      ? AppTheme.primary
                      : AppTheme.border,
                ),
                labelStyle: TextStyle(
                  color: _filterKategori == 'Semua'
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                  fontWeight: _filterKategori == 'Semua'
                      ? FontWeight.bold
                      : FontWeight.w500,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 8),

              // Chip untuk Setiap Kategori Otot
              ...daftarKategoriOtot.map((kategori) {
                final isSelected = _filterKategori == kategori;
                final warna = getWarnaKategori(kategori);
                final ikon = getIkonKategori(kategori);

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
                        _filterKategori = selected ? kategori : 'Semua';
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
              }),
            ],
          ),
        ),

        // 3. Chip Filter Aktif dan Tombol "Hapus semua filter"
        if (_adaFilterAktif)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (_filterKategori != 'Semua')
                  _buildActiveFilterChip(
                    label: 'Kategori: $_filterKategori',
                    onDeleted: () => setState(() => _filterKategori = 'Semua'),
                  ),
                if (_filterTanggal != null)
                  _buildActiveFilterChip(
                    label: 'Tanggal: ${_formatTanggal(_filterTanggal!)}',
                    onDeleted: () => setState(() => _filterTanggal = null),
                  ),
                if (_filterRentang != null)
                  _buildActiveFilterChip(
                    label:
                        'Tanggal: ${_formatTanggal(_filterRentang!.start)} - ${_formatTanggal(_filterRentang!.end)}',
                    onDeleted: () => setState(() => _filterRentang = null),
                  ),
                if (_keywordCari.isNotEmpty)
                  _buildActiveFilterChip(
                    label: 'Cari: "$_keywordCari"',
                    onDeleted: () {
                      _searchController.clear();
                      setState(() => _keywordCari = '');
                    },
                  ),
                // Tombol "Hapus semua filter"
                InkWell(
                  onTap: _hapusSemuaFilter,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.danger.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.clear_all, size: 14, color: AppTheme.danger),
                        SizedBox(width: 4),
                        Text(
                          'Hapus semua filter',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 4. Daftar Latihan atau Pesan "Tidak ada hasil" jika filter tidak cocok
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 56,
                        color: AppTheme.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Tidak ada hasil',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tidak ada latihan yang cocok dengan filter atau pencarian saat ini',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton.icon(
                        onPressed: _hapusSemuaFilter,
                        icon:
                            const Icon(Icons.refresh, color: AppTheme.primary),
                        label: const Text(
                          'Hapus Semua Filter',
                          style: TextStyle(color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: campuran.length,
                  itemBuilder: (context, index) {
                    final item = campuran[index];

                    // Tampilkan widget Header Tanggal
                    if (item is HeaderTanggalItem) {
                      return _buildHeaderTanggal(item);
                    }

                    // Tampilkan widget Data Latihan
                    final latihan = (item as DataLatihanItem).latihan;
                    final warnaKategori = getWarnaKategori(latihan.kategori);
                    final ikonKategori = getIkonKategori(latihan.kategori);

                    // Setiap item dibungkus Dismissible (geser ke kiri untuk hapus)
                    return Dismissible(
                      key: Key(latihan.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        // Memakai ulang dialog konfirmasi hapus yang sama
                        return await tampilkanDialogKonfirmasiHapus(
                          context,
                          latihan.namaLatihan,
                        );
                      },
                      onDismissed: (direction) {
                        _hapusLatihanDenganUndo(latihan);
                      },
                      background: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.danger,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline,
                                color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Hapus',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _bukaDetail(latihan),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Baris Atas: Chip Kategori, Nama Latihan & Volume Menonjol
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Chip kategori berwarna
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: warnaKategori.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: warnaKategori.withValues(
                                                  alpha: 0.5,
                                                ),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  ikonKategori,
                                                  size: 12,
                                                  color: warnaKategori,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  latihan.kategori,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: warnaKategori,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            latihan.namaLatihan,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'VOLUME',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Text(
                                              _formatVolume(latihan.volume),
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 3),
                                            const Text(
                                              'kg',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                // Baris Bawah: Chip kecil untuk beban, set x repetisi, dan tanggal
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _buildMiniChip(
                                      icon: Icons.scale_outlined,
                                      label: '${_formatBeban(latihan.beban)} kg',
                                    ),
                                    _buildMiniChip(
                                      icon: Icons.repeat,
                                      label:
                                          '${latihan.jumlahSet} set x ${latihan.jumlahRepetisi} reps',
                                    ),
                                    _buildMiniChip(
                                      icon: Icons.calendar_today_outlined,
                                      label: _formatTanggal(latihan.tanggal),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
