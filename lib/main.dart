import 'package:flutter/material.dart';
import 'package:get/get.dart'; 
import 'package:flutter_screenutil/flutter_screenutil.dart'; 
import 'package:google_fonts/google_fonts.dart';

// আপনার ডিরেক্টরি স্ট্রাকচার অনুযায়ী সঠিক ইমপোর্ট পাথ:
import 'pages/home_screen.dart';
import 'pages/mining_screen.dart';
import 'pages/wallet_screen.dart';
import 'layout/layout.dart'; // layout.dart ফাইলটি ব্যবহার করা হচ্ছে
import 'layout/nevbar.dart'; // আপনার ফাইলের নাম অনুযায়ী

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
          // সরাসরি MainWrapper বা AppLayout-কে কল করা হচ্ছে
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

  // আপনার pages ফোল্ডার থেকে সঠিক ফাইলগুলো এখানে লিস্ট করা হয়েছে
  final List<Widget> _pages = [
    const HomeScreen(),
    const MiningScreen(),
    const WalletScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      // IndexedStack ব্যবহার করলে পেজ সুইচ করলেও ডেটা হারিয়ে যায় না
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      // আপনার layout/nevbar.dart ফাইলের উইজেট এখানে কল করুন
      // মনে রাখবেন: আপনার nevbar.dart এর ভেতর উইজেটের নাম যেন 'AppNavBar' বা আপনার দেয়া নাম অনুযায়ী হয়
      bottomNavigationBar: AppNavBar( 
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
