import 'package:material_ui/material_ui.dart';
import '../models/latihan.dart';
import '../services/latihan_storage.dart';

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
      List<Latihan> data = await _storage.loadLatihan();

      // // TODO hapus dummy: Menambahkan 3 data latihan contoh jika penyimpanan masih kosong
      if (data.isEmpty) {
        data = [
          Latihan(
            id: 'dummy-1',
            namaLatihan: 'Bench Press',
            beban: 60.0,
            jumlahSet: 4,
            jumlahRepetisi: 10,
            tanggal: DateTime.now(),
          ),
          Latihan(
            id: 'dummy-2',
            namaLatihan: 'Squat',
            beban: 80.0,
            jumlahSet: 3,
            jumlahRepetisi: 8,
            tanggal: DateTime.now().subtract(const Duration(days: 1)),
          ),
          Latihan(
            id: 'dummy-3',
            namaLatihan: 'Deadlift',
            beban: 100.0,
            jumlahSet: 3,
            jumlahRepetisi: 5,
            tanggal: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ];
        // Simpan data dummy ke storage
        await _storage.saveLatihan(data);
      }

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
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // // TODO: Placeholder untuk navigasi form tambah latihan di tahap selanjutnya
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Form tambah latihan akan dibuat di tahap berikutnya'),
              duration: Duration(seconds: 1),
            ),
          );
        },
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _daftarLatihan.length,
      itemBuilder: (context, index) {
        final latihan = _daftarLatihan[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris atas: nama latihan dan tanggal (dd/mm/yyyy)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        );
      },
    );
  }
}
