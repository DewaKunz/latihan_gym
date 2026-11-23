import 'package:material_ui/material_ui.dart';
import '../models/latihan.dart';

// Halaman form untuk menambah latihan baru atau mengubah latihan yang sudah ada
class FormLatihanPage extends StatefulWidget {
  // Jika parameter latihan diisi, halaman berada dalam mode ubah (edit)
  // Jika null, halaman berada dalam mode tambah
  final Latihan? latihan;

  const FormLatihanPage({super.key, this.latihan});

  @override
  State<FormLatihanPage> createState() => _FormLatihanPageState();
}

class _FormLatihanPageState extends State<FormLatihanPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaController;
  late TextEditingController _bebanController;
  late TextEditingController _setController;
  late TextEditingController _repetisiController;
  late TextEditingController _tanggalController;

  late DateTime _selectedTanggal;

  // Format manual tanggal dd/mm/yyyy tanpa package intl
  String _formatTanggal(DateTime dt) {
    final hari = dt.day.toString().padLeft(2, '0');
    final bulan = dt.month.toString().padLeft(2, '0');
    final tahun = dt.year.toString();
    return '$hari/$bulan/$tahun';
  }

  @override
  void initState() {
    super.initState();

    final latihan = widget.latihan;
    if (latihan != null) {
      // Inisialisasi data untuk mode ubah
      _namaController = TextEditingController(text: latihan.namaLatihan);
      _bebanController = TextEditingController(
        text: latihan.beban % 1 == 0
            ? latihan.beban.toInt().toString()
            : latihan.beban.toString(),
      );
      _setController = TextEditingController(text: latihan.jumlahSet.toString());
      _repetisiController =
          TextEditingController(text: latihan.jumlahRepetisi.toString());
      _selectedTanggal = latihan.tanggal;
    } else {
      // Inisialisasi data untuk mode tambah (default hari ini)
      _namaController = TextEditingController();
      _bebanController = TextEditingController();
      _setController = TextEditingController();
      _repetisiController = TextEditingController();
      _selectedTanggal = DateTime.now();
    }

    _tanggalController =
        TextEditingController(text: _formatTanggal(_selectedTanggal));
  }

  @override
  void dispose() {
    _namaController.dispose();
    _bebanController.dispose();
    _setController.dispose();
    _repetisiController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  // Menampilkan dialog kalender bawaan Flutter
  Future<void> _pilihTanggal(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTanggal,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedTanggal) {
      setState(() {
        _selectedTanggal = picked;
        _tanggalController.text = _formatTanggal(picked);
      });
    }
  }

  // Memvalidasi form dan mengembalikan objek Latihan ke halaman sebelumnya
  void _simpan() {
    if (_formKey.currentState!.validate()) {
      // Mengubah koma menjadi titik agar dapat di-parse ke double
      final cleanBeban = _bebanController.text.trim().replaceAll(',', '.');
      final double beban = double.parse(cleanBeban);
      final int jumlahSet = int.parse(_setController.text.trim());
      final int jumlahRepetisi = int.parse(_repetisiController.text.trim());

      final Latihan dataHasil = Latihan(
        // Mode tambah menggunakan timestamp sebagai ID unik, mode ubah mempertahankan ID lama
        id: widget.latihan != null
            ? widget.latihan!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        namaLatihan: _namaController.text.trim(),
        beban: beban,
        jumlahSet: jumlahSet,
        jumlahRepetisi: jumlahRepetisi,
        tanggal: _selectedTanggal,
      );

      // Kembalikan objek Latihan lewat Navigator.pop
      Navigator.pop(context, dataHasil);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.latihan != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Ubah Latihan' : 'Tambah Latihan'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Field Nama Latihan
              TextFormField(
                controller: _namaController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Latihan *',
                  hintText: 'Misal: Bench Press, Squat',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama latihan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Field Beban (kg)
              TextFormField(
                controller: _bebanController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Beban (kg) *',
                  hintText: 'Contoh: 50 atau 52.5',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.scale),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Beban wajib diisi';
                  }
                  final cleanVal = value.trim().replaceAll(',', '.');
                  final parsed = double.tryParse(cleanVal);
                  if (parsed == null) {
                    return 'Masukkan angka beban yang valid';
                  }
                  if (parsed <= 0) {
                    return 'Beban harus lebih besar dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Field Jumlah Set
              TextFormField(
                controller: _setController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Set *',
                  hintText: 'Contoh: 3',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.repeat),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Jumlah set wajib diisi';
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null) {
                    return 'Masukkan bilangan bulat yang valid';
                  }
                  if (parsed <= 0) {
                    return 'Jumlah set harus lebih besar dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Field Jumlah Repetisi
              TextFormField(
                controller: _repetisiController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Repetisi *',
                  hintText: 'Contoh: 10',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Jumlah repetisi wajib diisi';
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null) {
                    return 'Masukkan bilangan bulat yang valid';
                  }
                  if (parsed <= 0) {
                    return 'Jumlah repetisi harus lebih besar dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Field Tanggal (readonly, dipilih lewat showDatePicker)
              TextFormField(
                controller: _tanggalController,
                readOnly: true,
                onTap: () => _pilihTanggal(context),
                decoration: const InputDecoration(
                  labelText: 'Tanggal Latihan *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Simpan
              ElevatedButton.icon(
                onPressed: _simpan,
                icon: const Icon(Icons.save),
                label: Text(
                  isEditMode ? 'Simpan Perubahan' : 'Simpan Latihan',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
