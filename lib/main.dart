import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// আপনার ডিরেক্টরি স্ট্রাকচার অনুযায়ী সঠিক ইমপোর্ট পাথ
import 'pages/home_screen.dart';
import 'pages/mining_screen.dart';
import 'pages/wallet_screen.dart';
import 'layout/layout.dart'; 
import 'layout/nevbar.dart'; 

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // MiningController এখানে একবার ইনজেক্ট করে দিলে সব পেজে কাজ করবে
  Get.put(MiningController()); 
  runApp(const MiningApp());
}

class MiningApp extends StatelessWidget {
  const MiningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Mine Matrix Pro',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF14F195),
            scaffoldBackgroundColor: const Color(0xFF0D0D12),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          // সরাসরি AppLayout ব্যবহার করা সবচেয়ে ভালো, তবে আপনি চাইলে MainWrapper-ও রাখতে পারেন
          home: const MainWrapper(),
        );
      },
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 1; // ডিফল্ট মাইনিং স্ক্রিন

  final List<Widget> _pages = [
    const HomeScreen(),
    const MiningScreen(),
    const WalletScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      // এখানে 'AppNavBar' এর পরিবর্তে 'FloatingBottomNav' ব্যবহার করা হয়েছে
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
