import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';

// আপনার অ্যাপের মেইন ফাইল বা কালার ক্লাস যেখানে আছে
import '../main.dart'; 
import 'mining_screen.dart'; // লোডিং শেষে যেখানে যাবে

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // ডায়নামিক লোডিং টেক্সট দেখানোর জন্য GetX এর RxString
  final RxString _loadingText = "INITIALIZING CORE...".obs;

  @override
  void initState() {
    super.initState();
    _startLoadingProcess();
  }

  // প্রফেশনাল লোডিং লজিক (Simulated)
  void _startLoadingProcess() async {
    await Future.delayed(const Duration(seconds: 1));
    
    // মনে হবে যেন সার্ভারের সাথে কানেক্ট হচ্ছে
    _loadingText.value = "CONNECTING TO SECURE SERVER...";
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // ইউজারের ডেটা ফেচ করার সিমুলেশন
    _loadingText.value = "SYNCING MATRIX DATA...";
    await Future.delayed(const Duration(milliseconds: 1500));

    // লোডিং শেষে মেইন স্ক্রিনে নিয়ে যাওয়া
    Get.off(
      () => const MiningScreen(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // লোগো উইথ গ্লোয়িং ইফেক্ট
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGreen.withOpacity(0.15),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60.w),
                child: Image.asset(
                  'assets/icon/icon.png',
                  fit: BoxFit.cover,
                  // যদি কোনো কারণে ছবি না পায়, তাহলে একটি আইকন দেখাবে (Crash রোধ করার জন্য)
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.token, size: 60.sp, color: AppColors.accentGreen);
                  },
                ),
              ),
            ).animate()
             .scale(duration: 800.ms, curve: Curves.easeOutBack)
             .shimmer(delay: 1000.ms, duration: 2000.ms),

            SizedBox(height: 30.h),

            // অ্যাপের নতুন নাম
            Text(
              "MINE MATRIX",
              style: GoogleFonts.inter(
                fontSize: 26.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 5,
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

            SizedBox(height: 12.h),

            // ডায়নামিক লোডিং টেক্সট (GetX Obx)
            Obx(() => Text(
              _loadingText.value,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.accentGreen,
                letterSpacing: 1.5,
              ),
            ).animate(key: ValueKey(_loadingText.value)) // টেক্সট চেঞ্জ হলে এনিমেশন হবে
             .fadeIn(duration: 400.ms)),
            
            SizedBox(height: 50.h),
            
            // প্রফেশনাল স্লিম লোডিং বার
            Container(
              width: 180.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(2.h),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2.h),
                child: const LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
                ),
              ),
            ).animate().fadeIn(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}
