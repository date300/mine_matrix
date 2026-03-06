import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';

// আপনার প্রোজেক্ট স্ট্রাকচার অনুযায়ী সঠিক ইমপোর্ট
import '../layout/layout.dart'; 
import '../main.dart'; // AppColors পাওয়ার জন্য

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final RxString _loadingStatus = "INITIALIZING MATRIX...".obs;

  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  void _handleNavigation() async {
    // ১. একটু অপেক্ষা করুন (সিস্টেম লোড হওয়ার জন্য)
    await Future.delayed(const Duration(seconds: 1));
    _loadingStatus.value = "CONNECTING TO NODES...";

    // ২. আরও কিছু সময় লোডিং এনিমেশন দেখান
    await Future.delayed(const Duration(seconds: 2));
    _loadingStatus.value = "SYNCING YOUR WALLET...";
    
    await Future.delayed(const Duration(milliseconds: 800));

    // ৩. এখন মেইন লেআউটে (AppLayout) পাঠিয়ে দিন
    // Get.off ব্যবহার করলে ইউজার ব্যাক বাটন টিপলে আর লোডিং স্ক্রিনে ফিরবে না
    Get.off(
      () => const AppLayout(), 
      transition: Transition.fadeIn, 
      duration: const Duration(milliseconds: 800)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12), // আপনার AppColors.background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // লোগো
            Container(
              width: 130.w,
              height: 130.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF14F195).withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 10,
                  )
                ]
              ),
              child: Image.asset(
                'assets/icon/icon.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => const Icon(Icons.auto_awesome, size: 80, color: Color(0xFF14F195)),
              ),
            ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),

            SizedBox(height: 30.h),

            // নাম
            Text(
              "MINE MATRIX",
              style: GoogleFonts.inter(
                fontSize: 28.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 6,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),

            SizedBox(height: 40.h),

            // ডায়নামিক স্ট্যাটাস টেক্সট
            Obx(() => Text(
              _loadingStatus.value,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: const Color(0xFF14F195).withOpacity(0.8),
                letterSpacing: 2,
              ),
            )),

            SizedBox(height: 20.h),

            // একটি ছোট প্রগ্রেস ইন্ডিকেটর
            SizedBox(
              width: 40.w,
              height: 2.h,
              child: const LinearProgressIndicator(
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF14F195)),
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
