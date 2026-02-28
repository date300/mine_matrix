import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'features/home/home_screen.dart';
import 'features/home/mining_screen.dart';
import 'features/home/wallet_screen.dart';
import 'layout/widgets/bottom_nav.dart';
import 'layout/widgets/cosmic_background.dart';

// Conditional imports
import 'web3/web3_stub.dart'
    if (dart.library.js) 'web3/web3_web.dart';
import 'widgets/wallet_connect_stub.dart'
    if (dart.library.js) 'widgets/wallet_connect_web.dart';

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

  // Conditional Web3Service instance for Web
  late final web3Service = Web3Service();

  late final List<Widget> _pages = [
    const HomeScreen(),
    const MiningScreen(),
    WalletScreen(web3Service: web3Service),
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
