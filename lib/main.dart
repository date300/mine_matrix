import 'package:flutter/material.dart';
// আপনার প্রজেক্টের ফাইলগুলো ইম্পোর্ট করা হচ্ছে
import 'core/constants.dart';
import 'features/home/home_screen.dart';
import 'features/home/mining_screen.dart';
import 'features/home/wallet_screen.dart';
import 'layout/widgets/bottom_nav.dart';
import 'layout/widgets/cosmic_background.dart'; // ব্যাকগ্রাউন্ড উইজেট
// Web3 ফাইলগুলো import
import 'features/web3/web3_service.dart';
import 'features/web3/widgets/wallet_connect_button.dart';
void main() {
  // স্ট্যাটাস বার স্বচ্ছ করার জন্য (ঐচ্ছিক)
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
      // থিম সেটআপ
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.emerald,
        scaffoldBackgroundColor: AppColors.background, // আপনার দেওয়া 0xFF020617
        fontFamily: 'Roboto', // আপনার যদি নির্দিষ্ট ফন্ট থাকে তবে এখানে দিন
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

  // অ্যাপের প্রধান পেজগুলো
  final List<Widget> _pages = [
    const HomeScreen(),
    const MiningScreen(),
    const WalletScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody true থাকলে বটম নেভিগেশনের পেছনেও ব্যাকগ্রাউন্ড দেখা যাবে
      extendBody: true, 
      
      // CosmicBackground আপনার পুরো অ্যাপের পেছনে এনিমেটেড আকাশ ও গ্রহ দেখাবে
      body: CosmicBackground(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),

      // আপনার কাস্টম বটম নেভিগেশন বার
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
