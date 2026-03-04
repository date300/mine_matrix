import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      color: Colors.transparent, // পুরোপুরি স্বচ্ছ ব্যাকগ্রাউন্ড
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: const Color(0xFF14F195).withOpacity(0.15),
                child: Icon(
                  CupertinoIcons.person_solid,
                  color: const Color(0xFF14F195),
                  size: 24.sp
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, Miner 👋",
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "Mine Matrix",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  CupertinoIcons.bell,
                  color: Colors.white,
                  size: 24.sp
                ),
                Positioned(
                  right: 2.w,
                  top: 2.h,
                  child: Container(
                    height: 8.w,
                    width: 8.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D4D),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0D0D12), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
