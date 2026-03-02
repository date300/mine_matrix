import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import '../../core/constants.dart'; // আপনার প্রোজেক্টের কালার কনস্ট্যান্ট

class FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingBottomNav({Key? key, required this.currentIndex, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.h,
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // ১. ফ্রস্টেড গ্লাস নেভিগেশন বেস
          GlassmorphicContainer(
            width: double.infinity,
            height: 70.h,
            borderRadius: 35.r,
            blur: 25,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.02)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderGradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.2), Colors.transparent],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, CupertinoIcons.square_grid_2x2_fill, "Home"),
                SizedBox(width: 60.w), // মাঝখানের মাইনিং বাটনের জন্য জায়গা
                _navItem(2, CupertinoIcons.briefcase_fill, "Wallet"), // আইকন একটু মডার্ন করা হলো
              ],
            ),
          ).animate().slideY(begin: 1.0, duration: 600.ms, curve: Curves.easeOutBack), // স্ক্রিনে আসার সময় সুন্দর বাউন্স

          // ২. ফ্লোটিং মাইনিং অ্যাকশন বাটন
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.heavyImpact();
                onTap(1);
              },
              child: _miningActionBtn(currentIndex == 1),
            ),
          )
        ],
      ),
    );
  }

  // নেভিগেশন আইটেম (অ্যানিমেটেড)
  Widget _navItem(int index, IconData icon, String label) {
    bool active = currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(index);
      },
      child: Container(
        color: Colors.transparent, // ট্যাপ এরিয়া বড় করার জন্য
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              // AppColors.emeraldLight এর বদলে সরাসরি নিয়ন গ্রিন দিলাম, আপনি চাইলে AppColors ব্যবহার করতে পারেন
              color: active ? const Color(0xFF14F195) : Colors.white54, 
              size: active ? 26.sp : 22.sp,
            ).animate(target: active ? 1 : 0).scale(duration: 200.ms),
            SizedBox(height: 4.h),
            Text(
              label,
              style: GoogleFonts.inter(
                color: active ? Colors.white : Colors.white54,
                fontSize: 10.sp,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
              ),
            ).animate(target: active ? 1 : 0).fadeIn(duration: 200.ms),
          ],
        ),
      ),
    );
  }

  // সেন্টার মাইনিং বাটন (Shimmer + Pulse Animation)
  Widget _miningActionBtn(bool isActive) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF0D0D12), // অ্যাপের ব্যাকগ্রাউন্ড কালার, যাতে একটি Cutout ইফেক্ট তৈরি হয়
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(isActive ? 16.w : 18.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isActive 
                ? [Colors.white, const Color(0xFFE0E0E0)] 
                : [const Color(0xFF14F195), const Color(0xFF0C945B)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14F195).withOpacity(isActive ? 0.6 : 0.3),
              blurRadius: isActive ? 30 : 15,
              spreadRadius: isActive ? 5 : 2,
            )
          ],
        ),
        child: Icon(
          CupertinoIcons.bolt_fill,
          color: isActive ? const Color(0xFF14F195) : Colors.black,
          size: 28.sp,
        )
        // কন্টিনিউয়াস শিমার ইফেক্ট (যেহেতু এটি কোর ফিচার)
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 2000.ms, color: Colors.white54),
      ),
    ).animate(target: isActive ? 1 : 0).scale(
      begin: const Offset(1, 1), 
      end: const Offset(1.05, 1.05), 
      duration: 200.ms
    ); // অ্যাক্টিভ থাকলে বাটন হালকা বড় হবে
  }
}
