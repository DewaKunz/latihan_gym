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

  testWidgets('Menampilkan tab Panduan Gerakan dan daftar latihan', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Buka tab Panduan
    await tester.tap(find.text('Panduan'));
    await tester.pumpAndSettle();

    // Verifikasi judul Panduan Gerakan dan elemen pencarian
    expect(find.text('Panduan Gerakan'), findsOneWidget);
    expect(find.text('Cari nama gerakan atau otot...'), findsOneWidget);

    // Verifikasi gerakan awal muncul (misal: Barbell Bench Press)
    expect(find.text('Barbell Bench Press'), findsOneWidget);
  });
}
