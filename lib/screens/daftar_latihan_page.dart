import 'package:material_ui/material_ui.dart';
import '../models/latihan.dart';
import '../services/latihan_storage.dart';
import '../theme/app_theme.dart';
import 'detail_latihan_page.dart';
import 'form_latihan_page.dart';

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

  // Tanggal yang sedang aktif sebagai filter (null jika menampilkan semua)
  DateTime? _filterTanggal;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  // Memuat data dari SharedPreferences dan mengurutkan berdasarkan tanggal terbaru
  Future<void> _muatData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<Latihan> data = await _storage.loadLatihan();

      // Mengurutkan latihan dari tanggal terbaru
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

  // Mengambil daftar latihan yang tampil (disaring jika filter aktif)
  List<Latihan> get _daftarTampil {
    if (_filterTanggal == null) {
      return _daftarLatihan;
    }
    return _daftarLatihan
        .where((item) => _apakahTanggalSama(item.tanggal, _filterTanggal!))
        .toList();
  }

  // Membuka dialog kalender untuk memilih tanggal filter
  Future<void> _pilihFilterTanggal() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _filterTanggal ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _filterTanggal = picked;
      });
    }
  }

  // Menghapus filter dan kembali menampilkan semua data latihan
  void _hapusFilter() {
    setState(() {
      _filterTanggal = null;
    });
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

    // Tangani aksi dari halaman detail (ubah atau hapus) pada data asli
    if (hasil != null) {
      final aksi = hasil['aksi'] as String?;

      if (aksi == 'hapus') {
        final String id = hasil['id'] as String;
        setState(() {
          _daftarLatihan.removeWhere((item) => item.id == id);
        });
        await _storage.saveLatihan(_daftarLatihan);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Latihan berhasil dihapus'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencatat Latihan Gym'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _filterTanggal != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: _filterTanggal != null ? AppTheme.primary : null,
            ),
            tooltip: 'Filter Tanggal',
            onPressed: _pilihFilterTanggal,
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

    // Tampilan kosong jika data penyimpanan belum ada
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indikator filter tanggal aktif ditampilkan rapi di atas daftar
        if (_filterTanggal != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  const Icon(Icons.filter_alt, size: 15, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Tanggal: ${_formatTanggal(_filterTanggal!)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _hapusFilter,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Daftar latihan atau pesan jika tidak ada data pada tanggal filter
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 56,
                        color: AppTheme.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Tidak ada latihan pada tanggal ini',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _hapusFilter,
                        icon: const Icon(Icons.clear, color: AppTheme.primary),
                        label: const Text(
                          'Tampilkan Semua Latihan',
                          style: TextStyle(color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final latihan = items[index];
                    return Card(
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
                              // Baris Atas: Nama Latihan (kiri) & Volume Menonjol (kanan)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      latihan.namaLatihan,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
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
                    );
                  },
                ),
        ),
      ],
    );
  }
}
