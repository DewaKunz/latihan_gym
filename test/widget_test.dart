import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:latihan_gym/main.dart';

void main() {
  testWidgets('Menampilkan halaman utama Pencatat Latihan Gym', (WidgetTester tester) async {
    // Siapkan mock initial values untuk shared_preferences
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verifikasi judul AppBar muncul persis
    expect(find.text('Pencatat Latihan Gym'), findsWidgets);
  });
}
