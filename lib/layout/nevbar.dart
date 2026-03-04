import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingBottomNav({
    super.key, 
    required this.currentIndex, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.h,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 25.w),
      color: Colors.transparent, // মেইন ব্যাকগ্রাউন্ড স্বচ্ছ
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // নেভিগেশন বারের মূল বডি
          Container(
            width: double.infinity,
            height: 65.h,
            decoration: BoxDecoration(
              color: Colors.transparent, // বারটি এখন পুরোপুরি স্বচ্ছ
              borderRadius: BorderRadius.circular(30.r),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, CupertinoIcons.square_grid_2x2_fill, "Home"),
                SizedBox(width: 50.w), // মাঝখানের বাটনের জন্য ফাঁকা জায়গা
                _navItem(2, CupertinoIcons.briefcase_fill, "Wallet"),
              ],
            ),
          ),

          // মাঝখানের ভাসমান মাইনিং বাটন
          Positioned(
            bottom: 20.h,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onTap(1);
              },
              child: _miningBtn(currentIndex == 1),
            ),
          )
        ],
      ),
    );
  }

  // বাম ও ডান পাশের আইটেমগুলোর জন্য উইজেট
  Widget _navItem(int index, IconData icon, String label) {
    bool active = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            color: active ? const Color(0xFF14F195) : Colors.white.withOpacity(0.6), 
            size: 24.sp
          ),
          SizedBox(height: 4.h),
          Text(
            label, 
            style: GoogleFonts.inter(
              color: active ? Colors.white : Colors.white.withOpacity(0.6), 
              fontSize: 10.sp, 
              fontWeight: FontWeight.bold
            )
          ),
        ],
      ).animate(target: active ? 1 : 0).scale(end: const Offset(1.1, 1.1)),
    );
  }

  // মাঝখানের স্পেশাল মাইনিং বাটন
  Widget _miningBtn(bool isActive) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D12), // বাটনের চারপাশের বর্ডার লুক দিতে ডার্ক কালার
        shape: BoxShape.circle
      ),
      child: Container(
        padding: EdgeInsets.all(15.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isActive 
                ? [Colors.white, Colors.grey.shade300] 
                : [const Color(0xFF14F195), const Color(0xFF9945FF)]
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14F195).withOpacity(0.3), 
              blurRadius: 15, 
              spreadRadius: 2
            )
          ],
        ),
        child: Icon(
          CupertinoIcons.bolt_fill, 
          color: isActive ? const Color(0xFF14F195) : Colors.white, 
          size: 30.sp
        ),
      ),
    ).animate(target: isActive ? 1 : 0).shimmer(duration: 1500.ms);
  }
}
