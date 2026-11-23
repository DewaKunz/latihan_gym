import 'package:material_ui/material_ui.dart';
import '../models/latihan.dart';
import '../services/latihan_storage.dart';
import 'detail_latihan_page.dart';
import 'form_latihan_page.dart';

// Halaman utama untuk menampilkan daftar riwayat latihan gym
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
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _muatData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    // Jika data penyimpanan sama sekali belum ada
    if (_daftarLatihan.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada data',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    final items = _daftarTampil;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indikator filter aktif (Chip dengan tombol hapus filter)
        if (_filterTanggal != null)
          Padding(
            padding: const EdgeInsets.only(
                left: 16.0, right: 16.0, top: 12.0, bottom: 4.0),
            child: Chip(
              avatar: const Icon(Icons.calendar_today, size: 16),
              label: Text('Tanggal: ${_formatTanggal(_filterTanggal!)}'),
              onDeleted: _hapusFilter,
              deleteIcon: const Icon(Icons.close, size: 18),
              deleteButtonTooltipMessage: 'Hapus filter',
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
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tidak ada latihan pada tanggal ini',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _hapusFilter,
                        icon: const Icon(Icons.clear),
                        label: const Text('Tampilkan Semua Latihan'),
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
                          horizontal: 16, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _bukaDetail(latihan),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Baris atas: nama latihan dan tanggal (dd/mm/yyyy)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      latihan.namaLatihan,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatTanggal(latihan.tanggal),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Informasi beban dan set x repetisi
                              Row(
                                children: [
                                  Text(
                                    'Beban: ${_formatBeban(latihan.beban)} kg',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${latihan.jumlahSet} set x ${latihan.jumlahRepetisi} reps',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Informasi volume latihan (beban x set x repetisi)
                              Text(
                                'Volume: ${_formatVolume(latihan.volume)} kg',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade800,
                                ),
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
