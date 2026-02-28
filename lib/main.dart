import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Core files
import 'core/constants.dart';

// Screens
import 'features/home/home_screen.dart';
import 'features/home/mining_screen.dart';
import 'features/home/wallet_screen.dart';

// Layout widgets
import 'layout/widgets/bottom_nav.dart';
import 'layout/widgets/cosmic_background.dart';

// Web3 imports (Mobile uses real service, Web uses stubs)
import 'web3/web3_service.dart'
    if (dart.library.html) 'web3/web3_stub.dart';
import 'widgets/wallet_connect_button.dart'
    if (dart.library.html) 'widgets/wallet_connect_stub.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MiningApp());
}

class MiningApp extends StatelessWidget {
  const MiningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mining App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.emerald,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
      ),
      home: const MainWrapper(),
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const MiningScreen(),
    const WalletScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: CosmicBackground(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
