import 'package:material_ui/material_ui.dart';
import '../models/kategori_otot.dart';
import '../models/latihan.dart';
import '../theme/app_theme.dart';
import '../widgets/dialog_konfirmasi_hapus.dart';
import 'form_latihan_page.dart';

// Halaman detail untuk melihat informasi lengkap sebuah latihan dengan tampilan modern
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
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Membuka form dalam mode duplikat (mengisi data latihan awal, tanggal hari ini)
  Future<void> _bukaFormDuplikat() async {
    final Latihan? duplikatBaru = await Navigator.push<Latihan>(
      context,
      MaterialPageRoute(
        builder: (context) => FormLatihanPage(awal: _latihan),
      ),
    );

    // Jika pengguna menyimpan latihan duplikat, kembalikan ke daftar
    if (duplikatBaru != null && mounted) {
      Navigator.pop(context, {
        'aksi': 'duplikat',
        'latihan': duplikatBaru,
      });
    }
  }

  // Menampilkan dialog konfirmasi hapus menggunakan fungsi bersama
  Future<void> _konfirmasiHapus() async {
    final bool setuju =
        await tampilkanDialogKonfirmasiHapus(context, _latihan.namaLatihan);

    if (setuju && mounted) {
      Navigator.pop(context, {
        'aksi': 'hapus',
        'id': _latihan.id,
      });
    }
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

  // Baris informasi rincian latihan
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor ?? AppTheme.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final warnaKategori = getWarnaKategori(_latihan.kategori);
    final ikonKategori = getIkonKategori(_latihan.kategori);

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
              icon: const Icon(Icons.copy_outlined),
              tooltip: 'Duplikat Latihan',
              onPressed: _bukaFormDuplikat,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Ubah Latihan',
              onPressed: _bukaFormUbah,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus Latihan',
              color: AppTheme.danger,
              onPressed: _konfirmasiHapus,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Besar: Nama Latihan, Kategori, dan Volume
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Icon(
                          ikonKategori,
                          size: 36,
                          color: warnaKategori,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Chip kategori di header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: warnaKategori.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
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
                              _latihan.kategori,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: warnaKategori,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _latihan.namaLatihan,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'TOTAL VOLUME',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatVolume(_latihan.volume)} kg',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Kartu Info untuk Beban, Set, Repetisi, Kategori, dan Tanggal
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        icon: ikonKategori,
                        iconColor: warnaKategori,
                        label: 'Kategori Otot',
                        value: _latihan.kategori,
                        valueColor: warnaKategori,
                      ),
                      const Divider(color: AppTheme.border, height: 26),
                      _buildDetailRow(
                        icon: Icons.scale_outlined,
                        label: 'Beban',
                        value: '${_formatBeban(_latihan.beban)} kg',
                      ),
                      const Divider(color: AppTheme.border, height: 26),
                      _buildDetailRow(
                        icon: Icons.repeat,
                        label: 'Jumlah Set',
                        value: '${_latihan.jumlahSet} set',
                      ),
                      const Divider(color: AppTheme.border, height: 26),
                      _buildDetailRow(
                        icon: Icons.numbers,
                        label: 'Jumlah Repetisi',
                        value: '${_latihan.jumlahRepetisi} reps / set',
                      ),
                      const Divider(color: AppTheme.border, height: 26),
                      _buildDetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Tanggal',
                        value: _formatTanggal(_latihan.tanggal),
                      ),
                    ],
                  ),
                ),
              ),

              // Bagian Catatan (Jika catatan kosong, sembunyikan bagian ini)
              if (_latihan.catatan.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notes, size: 20, color: AppTheme.primary),
                            SizedBox(width: 10),
                            Text(
                              'Catatan Latihan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _latihan.catatan,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Tombol Aksi: Ubah, Duplikat, dan Hapus
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _bukaFormUbah,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Ubah', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: AppTheme.primary,
                          width: 1.5,
                        ),
                        foregroundColor: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _bukaFormDuplikat,
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      label: const Text('Duplikat', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: Color(0xFF64B5F6),
                          width: 1.5,
                        ),
                        foregroundColor: const Color(0xFF64B5F6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _konfirmasiHapus,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Hapus', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
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
}
