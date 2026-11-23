import 'package:material_ui/material_ui.dart';
import 'beranda_page.dart';
import 'daftar_latihan_page.dart';
import 'panduan_page.dart';
import 'profil_page.dart';
import 'statistik_page.dart';

// Shell utama aplikasi dengan NavigationBar (Material 3) dan IndexedStack
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Tab awal adalah Beranda (index 0)
  int _selectedIndex = 0;

  // Key unik untuk memicu pemuatan ulang data latihan saat tab Latihan dipilih
  Key _latihanKey = UniqueKey();

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
      // Sinkronisasi data: jika tab Latihan dipilih, segarkan dengan memperbarui key
      if (index == 1) {
        _latihanKey = UniqueKey();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const BerandaPage(),
          DaftarLatihanPage(key: _latihanKey),
          const PanduanPage(),
          const StatistikPage(),
          const ProfilPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Latihan',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Panduan',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
