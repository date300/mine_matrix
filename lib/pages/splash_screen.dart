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
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
    _loadingStatus.value = "SYNCING YOUR WALLET...";
    
    await Future.delayed(const Duration(milliseconds: 800));

    // ৩. এখন মেইন লেআউটে (AppLayout) পাঠিয়ে দিন
    Get.off(
      () => const AppLayout(), 
      transition: Transition.fadeIn, 
      duration: const Duration(milliseconds: 800)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12), // আপনার ব্যাকগ্রাউন্ড কালার
      body: SizedBox( // Container এর বদলে SizedBox ব্যবহার করা ভালো প্র্যাকটিস
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // লোগো - সাইজ ছোট করে প্রফেশনাল গ্লো ও শিমার ইফেক্ট দেওয়া হয়েছে
            Container(
              width: 85.w, // সাইজ ১৩০ থেকে ছোট করা হয়েছে
              height: 85.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF14F195).withOpacity(0.15),
                    blurRadius: 30,
                    spreadRadius: 8,
                  )
                ]
              ),
              child: Image.asset(
                'assets/icon/icon.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => Icon(
                  Icons.auto_awesome, 
                  size: 45.sp, // আইকন সাইজও কমানো হয়েছে
                  color: const Color(0xFF14F195)
                ),
              ),
            ).animate()
             .scale(duration: 1000.ms, curve: Curves.easeOutBack)
             .shimmer(delay: 1000.ms, duration: 1500.ms, color: Colors.white24),

            SizedBox(height: 24.h),

            // অ্যাপের নাম
            Text(
              "MINE MATRIX",
              style: GoogleFonts.inter(
                fontSize: 22.sp, // সাইজ ২৮ থেকে কমানো হয়েছে
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 5,
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0, duration: 600.ms),

            SizedBox(height: 35.h),

            // ডায়নামিক স্ট্যাটাস টেক্সট (ফেড ইন-আউট বা পালস ইফেক্ট সহ)
            Obx(() => Text(
              _loadingStatus.value,
              style: GoogleFonts.inter(
                fontSize: 10.sp, // সাইজ ছোট করা হয়েছে
                fontWeight: FontWeight.w500,
                color: const Color(0xFF14F195).withOpacity(0.7),
                letterSpacing: 1.5,
              ),
            )).animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.4, end: 1.0, duration: 800.ms), 

            SizedBox(height: 16.h),

            // প্রগ্রেস ইন্ডিকেটর - আরেকটু স্মার্ট ও চিকন করা হয়েছে
            SizedBox(
              width: 100.w, // একটু চওড়া কিন্তু চিকন
              height: 1.5.h,
              child: const LinearProgressIndicator(
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF14F195)),
              ),
            ).animate().fadeIn(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}
