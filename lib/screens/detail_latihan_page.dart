import 'package:material_ui/material_ui.dart';
import '../models/latihan.dart';
import 'form_latihan_page.dart';

// Halaman detail untuk melihat informasi lengkap sebuah latihan
class DetailLatihanPage extends StatefulWidget {
  final Latihan latihan;

  const DetailLatihanPage({super.key, required this.latihan});

  @override
  State<DetailLatihanPage> createState() => _DetailLatihanPageState();
}

class _DetailLatihanPageState extends State<DetailLatihanPage> {
  late Latihan _latihan;
  bool _isUpdated = false;

  @override
  void initState() {
    super.initState();
    _latihan = widget.latihan;
  }

  // Format manual tanggal dd/mm/yyyy tanpa package intl
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

  // Membuka form dalam mode ubah
  Future<void> _bukaFormUbah() async {
    final Latihan? updated = await Navigator.push<Latihan>(
      context,
      MaterialPageRoute(
        builder: (context) => FormLatihanPage(latihan: _latihan),
      ),
    );

    if (updated != null) {
      setState(() {
        _latihan = updated;
        _isUpdated = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data latihan berhasil diperbarui'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  // Menampilkan dialog konfirmasi hapus sebelum menghapus data
  void _konfirmasiHapus() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus data latihan "${_latihan.namaLatihan}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Tutup dialog konfirmasi
              Navigator.pop(context, {
                'aksi': 'hapus',
                'id': _latihan.id,
              }); // Kembali ke halaman daftar dengan aksi hapus
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // Kembali ke halaman daftar dengan membawa data terupdate jika ada perubahan
  void _kembali() {
    if (_isUpdated) {
      Navigator.pop(context, {
        'aksi': 'ubah',
        'latihan': _latihan,
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _kembali();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detail Latihan'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Kembali',
            onPressed: _kembali,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Ubah Latihan',
              onPressed: _bukaFormUbah,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Hapus Latihan',
              onPressed: _konfirmasiHapus,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kartu informasi utama latihan
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama latihan
                      Row(
                        children: [
                          const Icon(Icons.fitness_center, size: 28, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _latihan.namaLatihan,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),

                      // Tanggal latihan
                      _buildInfoRow(
                        icon: Icons.calendar_today,
                        label: 'Tanggal',
                        value: _formatTanggal(_latihan.tanggal),
                      ),
                      const SizedBox(height: 12),

                      // Beban dalam kg
                      _buildInfoRow(
                        icon: Icons.scale,
                        label: 'Beban',
                        value: '${_formatBeban(_latihan.beban)} kg',
                      ),
                      const SizedBox(height: 12),

                      // Jumlah Set
                      _buildInfoRow(
                        icon: Icons.repeat,
                        label: 'Jumlah Set',
                        value: '${_latihan.jumlahSet} set',
                      ),
                      const SizedBox(height: 12),

                      // Jumlah Repetisi
                      _buildInfoRow(
                        icon: Icons.numbers,
                        label: 'Jumlah Repetisi',
                        value: '${_latihan.jumlahRepetisi} reps per set',
                      ),
                      const Divider(height: 28),

                      // Volume Latihan (beban x set x repetisi)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.insights, color: Colors.blue.shade800),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Volume Latihan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${_formatVolume(_latihan.volume)} kg',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol aksi di bawah: Ubah dan Hapus
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _bukaFormUbah,
                      icon: const Icon(Icons.edit),
                      label: const Text('Ubah Latihan'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _konfirmasiHapus,
                      icon: const Icon(Icons.delete),
                      label: const Text('Hapus Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget bantuan untuk baris informasi
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
