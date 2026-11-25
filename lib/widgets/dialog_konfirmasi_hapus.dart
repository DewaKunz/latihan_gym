import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';

// Fungsi pembantu dialog konfirmasi hapus yang dipakai ulang di seluruh aplikasi
Future<bool> tampilkanDialogKonfirmasiHapus(
  BuildContext context,
  String namaLatihan,
) async {
  final bool? setuju = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      title: const Text(
        'Konfirmasi Hapus',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      content: Text(
        'Apakah Anda yakin ingin menghapus data latihan "$namaLatihan"?',
        style: const TextStyle(color: AppTheme.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text(
            'Batal',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.danger,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );

  return setuju ?? false;
}
