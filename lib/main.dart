import 'package:flutter/material.dart';
import 'package:get/get.dart'; // GetX যোগ করা হয়েছে
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ScreenUtil যোগ করা হয়েছে
import 'package:google_fonts/google_fonts.dart';

// আপনার প্রোজেক্টের পাথ অনুযায়ী এগুলো চেক করে নিন
import 'core/constants.dart';
import 'features/home/home_screen.dart';
import 'features/home/mining_screen.dart';
import 'features/home/wallet_screen.dart';
import 'layout/widgets/bottom_nav.dart';
// cosmic_background যদি গ্লাস ইফেক্টের সাথে ক্ল্যাশ করে তবে এটি অপশনাল রাখতে পারেন
// import 'layout/widgets/cosmic_background.dart'; 

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MiningApp());
}

class MiningApp extends StatelessWidget {
  const MiningApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ScreenUtilInit ব্যবহার করে পুরো অ্যাপকে রেস্পন্সিভ করা হলো
    return ScreenUtilInit(
      designSize: const Size(390, 844), // আইফোন স্ট্যান্ডার্ড সাইজ
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp( // MaterialApp এর বদলে GetMaterialApp
          title: 'Vexylon Pro Mining',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF14F195),
            scaffoldBackgroundColor: const Color(0xFF0D0D12),
            // গুগল ফন্টস ব্যবহার করে প্রিমিয়াম লুক দেওয়া হয়েছে
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
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
  int _currentIndex = 0;

  // পেজ লিস্ট
  final List<Widget> _pages = [
    const HomeScreen(),
    const MiningScreen(), // এটি আমরা আগে ডিজাইন করেছি
    const WalletScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody: true দিলে নিচের নেভিগেশন বারের পেছনে কন্টেন্ট দেখা যায় (Blur effect এর জন্য জরুরি)
      extendBody: true, 
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
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
