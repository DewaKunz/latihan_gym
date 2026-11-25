import 'package:material_ui/material_ui.dart';
import '../data/panduan_gerakan.dart';
import '../models/kategori_otot.dart';
import '../models/latihan.dart';
import '../services/latihan_storage.dart';
import '../theme/app_theme.dart';

// Halaman form untuk menambah, mengubah, atau menduplikasi data latihan
class FormLatihanPage extends StatefulWidget {
  final Latihan? latihan; // Jika diisi, beroperasi dalam mode ubah (ID tetap)
  final Latihan? awal; // Jika diisi, mode tambah terisi awal untuk duplikat (ID baru)

  const FormLatihanPage({super.key, this.latihan, this.awal});

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
  late TextEditingController _catatanController;

  late String _selectedKategori;
  late DateTime _selectedTanggal;

  // Daftar riwayat latihan untuk saran autocomplete dan petunjuk beban terakhir
  List<Latihan> _riwayatLatihan = [];
  List<String> _opsiSaran = [];

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
    final awal = widget.awal;

    if (latihan != null) {
      // Inisialisasi data untuk mode ubah (mengisi nilai lama)
      _namaController = TextEditingController(text: latihan.namaLatihan);
      _bebanController = TextEditingController(
        text: latihan.beban % 1 == 0
            ? latihan.beban.toInt().toString()
            : latihan.beban.toString(),
      );
      _setController = TextEditingController(text: latihan.jumlahSet.toString());
      _repetisiController =
          TextEditingController(text: latihan.jumlahRepetisi.toString());
      _selectedKategori = latihan.kategori;
      _catatanController = TextEditingController(text: latihan.catatan);
      _selectedTanggal = latihan.tanggal;
    } else if (awal != null) {
      // Inisialisasi data untuk mode duplikat atau mode tambah dari panduan
      _namaController = TextEditingController(text: awal.namaLatihan);
      _bebanController = TextEditingController(
        text: awal.beban > 0
            ? (awal.beban % 1 == 0
                ? awal.beban.toInt().toString()
                : awal.beban.toString())
            : '',
      );
      _setController = TextEditingController(
        text: awal.jumlahSet > 0 ? awal.jumlahSet.toString() : '',
      );
      _repetisiController = TextEditingController(
        text: awal.jumlahRepetisi > 0 ? awal.jumlahRepetisi.toString() : '',
      );
      _selectedKategori = awal.kategori;
      _catatanController = TextEditingController(text: awal.catatan);
      _selectedTanggal = DateTime.now(); // Tanggal default hari ini
    } else {
      // Inisialisasi data untuk mode tambah biasa
      _namaController = TextEditingController();
      _bebanController = TextEditingController();
      _setController = TextEditingController();
      _repetisiController = TextEditingController();
      _selectedKategori = 'Dada';
      _catatanController = TextEditingController();
      _selectedTanggal = DateTime.now();
    }

    _tanggalController =
        TextEditingController(text: _formatTanggal(_selectedTanggal));

    // Siapkan saran awal dari panduan gerakan lalu muat riwayat tersimpan
    _bangunOpsiSaran();
    _muatRiwayatLatihan();
  }

  // Memuat riwayat latihan dari SharedPreferences untuk saran & petunjuk terakhir
  Future<void> _muatRiwayatLatihan() async {
    try {
      final data = await LatihanStorage().loadLatihan();
      if (!mounted) return;
      _riwayatLatihan = data;
      _bangunOpsiSaran();
    } catch (_) {
      // Abaikan jika gagal memuat riwayat; saran panduan tetap tersedia
    }
  }

  // Menggabungkan nama unik dari riwayat dan panduan (tidak peka huruf besar-kecil)
  void _bangunOpsiSaran() {
    final Map<String, String> unikMap = {};

    // Prioritaskan penulisan dari catatan riwayat terbaru
    final riwayatTerurut = List<Latihan>.from(_riwayatLatihan)
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
    for (final item in riwayatTerurut) {
      final key = item.namaLatihan.trim().toLowerCase();
      if (key.isNotEmpty && !unikMap.containsKey(key)) {
        unikMap[key] = item.namaLatihan.trim();
      }
    }

    // Tambahkan nama gerakan dari panduan gerakan
    for (final gerakan in daftarPanduanGerakan) {
      final key = gerakan.nama.trim().toLowerCase();
      if (key.isNotEmpty && !unikMap.containsKey(key)) {
        unikMap[key] = gerakan.nama.trim();
      }
    }

    final hasil = unikMap.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (mounted) {
      setState(() {
        _opsiSaran = hasil;
      });
    } else {
      _opsiSaran = hasil;
    }
  }

  // Mengisi kategori otomatis saat saran dipilih dari panduan atau riwayat
  void _saatNamaDipilih(String namaDipilih) {
    final key = namaDipilih.trim().toLowerCase();
    String? kategoriBaru;

    // Cek di panduan gerakan terlebih dahulu
    final indeksPanduan = daftarPanduanGerakan.indexWhere(
      (g) => g.nama.trim().toLowerCase() == key,
    );
    if (indeksPanduan != -1) {
      kategoriBaru = daftarPanduanGerakan[indeksPanduan].kategori;
    } else {
      // Jika dari riwayat, ambil kategori dari catatan terakhir dengan nama tersebut
      final riwayatCocok = _riwayatLatihan
          .where((item) => item.namaLatihan.trim().toLowerCase() == key)
          .toList()
        ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
      if (riwayatCocok.isNotEmpty) {
        kategoriBaru = riwayatCocok.first.kategori;
      }
    }

    setState(() {
      _namaController.text = namaDipilih;
      if (kategoriBaru != null && daftarKategoriOtot.contains(kategoriBaru)) {
        _selectedKategori = kategoriBaru;
      }
    });
  }

  // Mencari catatan latihan terakhir berdasarkan nama latihan saat ini
  Latihan? get _latihanTerakhir {
    final key = _namaController.text.trim().toLowerCase();
    if (key.isEmpty) return null;

    final cocok = _riwayatLatihan
        .where((item) => item.namaLatihan.trim().toLowerCase() == key)
        .toList();
    if (cocok.isEmpty) return null;

    cocok.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return cocok.first;
  }

  // Format angka beban agar rapi (50 bukan 50.0, sedangkan 52.5 tetap 52.5)
  String _formatBeban(double beban) {
    if (beban == beban.roundToDouble()) {
      return beban.toInt().toString();
    }
    return beban.toString();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _bebanController.dispose();
    _setController.dispose();
    _repetisiController.dispose();
    _tanggalController.dispose();
    _catatanController.dispose();
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
        // Mode tambah dan mode duplikat menggunakan timestamp sebagai ID baru
        id: widget.latihan != null
            ? widget.latihan!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        namaLatihan: _namaController.text.trim(),
        beban: beban,
        jumlahSet: jumlahSet,
        jumlahRepetisi: jumlahRepetisi,
        tanggal: _selectedTanggal,
        kategori: _selectedKategori,
        catatan: _catatanController.text.trim(),
      );

      // Kembalikan objek Latihan lewat Navigator.pop
      Navigator.pop(context, dataHasil);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.latihan != null;
    final isDuplicateMode = widget.awal != null && widget.awal!.id.isNotEmpty;
    final latihanTerakhir = _latihanTerakhir;

    final String judulAppBar = isEditMode
        ? 'Ubah Latihan'
        : (isDuplicateMode ? 'Duplikat Latihan' : 'Tambah Latihan');

    return Scaffold(
      appBar: AppBar(
        title: Text(judulAppBar),
        centerTitle: true,
      ),
      // SingleChildScrollView mencegah overflow saat keyboard virtual muncul
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Field Nama Latihan dengan Autocomplete bawaan Flutter
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _namaController.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final query = textEditingValue.text.trim().toLowerCase();
                  if (query.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return _opsiSaran.where(
                    (opsi) => opsi.toLowerCase().contains(query),
                  );
                },
                onSelected: _saatNamaDipilih,
                fieldViewBuilder: (
                  BuildContext context,
                  TextEditingController fieldTextEditingController,
                  FocusNode fieldFocusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  return TextFormField(
                    controller: fieldTextEditingController,
                    focusNode: fieldFocusNode,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nama Latihan *',
                      hintText: 'Misal: Bench Press, Barbell Squat',
                      prefixIcon: Icon(Icons.fitness_center),
                    ),
                    onChanged: (value) {
                      _namaController.text = value;
                      setState(() {});
                    },
                    onFieldSubmitted: (value) => onFieldSubmitted(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama latihan wajib diisi';
                      }
                      return null;
                    },
                  );
                },
                optionsViewBuilder: (
                  BuildContext context,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options,
                ) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 6,
                      color: AppTheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.border),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 220,
                          maxWidth: MediaQuery.of(context).size.width - 40,
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return InkWell(
                              onTap: () => onSelected(option),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.fitness_center,
                                      size: 16,
                                      color: AppTheme.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Petunjuk kecil catatan terakhir bila nama pernah dicatat
              if (latihanTerakhir != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.history,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Terakhir: ${_formatBeban(latihanTerakhir.beban)} kg x ${latihanTerakhir.jumlahSet} x ${latihanTerakhir.jumlahRepetisi}',
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
                ),
              const SizedBox(height: 20),

              // Dropdown Kategori Otot (Wajib Terpilih)
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedKategori),
                initialValue: _selectedKategori,
                dropdownColor: const Color(0xFF1B1B1E),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  labelText: 'Kategori Otot *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: daftarKategoriOtot.map((kategori) {
                  final warna = getWarnaKategori(kategori);
                  final ikon = getIkonKategori(kategori);
                  return DropdownMenuItem<String>(
                    value: kategori,
                    child: Row(
                      children: [
                        Icon(ikon, size: 18, color: warna),
                        const SizedBox(width: 10),
                        Text(kategori, style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedKategori = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kategori otot wajib dipilih';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Field Beban (kg)
              TextFormField(
                controller: _bebanController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Beban (kg) *',
                  hintText: 'Contoh: 50 atau 52.5',
                  prefixIcon: Icon(Icons.scale_outlined),
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
              const SizedBox(height: 20),

              // Field Jumlah Set
              TextFormField(
                controller: _setController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Jumlah Set *',
                  hintText: 'Contoh: 3 atau 4',
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
              const SizedBox(height: 20),

              // Field Jumlah Repetisi
              TextFormField(
                controller: _repetisiController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Jumlah Repetisi *',
                  hintText: 'Contoh: 8, 10, atau 12',
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
              const SizedBox(height: 20),

              // Field Tanggal (readonly, dipilih lewat showDatePicker)
              TextFormField(
                controller: _tanggalController,
                readOnly: true,
                style: const TextStyle(color: Colors.white),
                onTap: () => _pilihTanggal(context),
                decoration: const InputDecoration(
                  labelText: 'Tanggal Latihan *',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
              ),
              const SizedBox(height: 20),

              // Field Catatan (Opsional, Maks. 200 karakter, boleh beberapa baris)
              TextFormField(
                controller: _catatanController,
                maxLines: 3,
                minLines: 1,
                maxLength: 200,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  hintText: 'Misal: Terasa ringan, tambah beban minggu depan',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 32),

              // Tombol Simpan
              ElevatedButton.icon(
                onPressed: _simpan,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  isEditMode ? 'Simpan Perubahan' : 'Simpan Latihan',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
