import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ইউজার ইনফো
          Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: const Color(0xFF14F195).withOpacity(0.2),
                child: Icon(CupertinoIcons.person_fill, color: const Color(0xFF14F195), size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("HELLO, MINER!", style: GoogleFonts.inter(color: Colors.white60, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  Text("VEXYLON PRO", style: GoogleFonts.inter(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
          
          // নোটিফিকেশন বাটন
          GlassmorphicContainer(
            width: 45.w,
            height: 45.w,
            borderRadius: 15.r,
            blur: 15,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]),
            borderGradient: LinearGradient(colors: [const Color(0xFF14F195).withOpacity(0.5), Colors.transparent]),
            child: Icon(CupertinoIcons.bell_fill, color: const Color(0xFF14F195), size: 20.sp),
          ),
        ],
      ),
    );
  }
}

