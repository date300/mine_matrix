import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReferPage extends StatelessWidget {
  const ReferPage({super.key});

  @override
  Widget build(BuildContext context) {
    String referCode = "MINER786"; // আপনার ডাইনামিক কোড এখানে বসবে

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40.h),
              
              // উপরের আইকন বা ইমেজ
              Container(
                height: 150.h,
                width: 150.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [const Color(0xFF14F195).withOpacity(0.2), Colors.transparent],
                  ),
                ),
                child: Icon(Icons.people_alt_rounded, size: 80.sp, color: const Color(0xFF14F195)),
              ).animate().scale(duration: 600.ms, curve: Curves.backOut),

              SizedBox(height: 30.h),

              // টাইটেল
              Text(
                "Refer & Earn",
                style: GoogleFonts.inter(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                "Invite your friends and get 10% of their \nmining rewards instantly!",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),

              SizedBox(height: 40.h),

              // রেফারেল কোড বক্স
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B22),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Text(
                      "Your Referral Code",
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 12.sp),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          referCode,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF14F195),
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(width: 15.w),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: referCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Code Copied!")),
                            );
                          },
                          child: Icon(Icons.copy, color: Colors.white, size: 20.sp),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

              SizedBox(height: 30.h),

              // শেয়ার বাটন
              SizedBox(
                width: double.infinity,
                height: 55.h,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // শেয়ার লজিক এখানে হবে
                  },
                  icon: const Icon(Icons.share, color: Colors.black),
                  label: Text(
                    "Share with Friends",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14F195),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                  ),
                ),
              ),

              SizedBox(height: 40.h),

              // পরিসংখ্যান (Stats)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard("Total Refers", "24"),
                  _buildStatCard("Earnings", "120.50 SOL"),
                ],
              ),
              
              SizedBox(height: 120.h), // নেভবার এর জন্য নিচের ফাঁকা জায়গা
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      width: 150.w,
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B22),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12.sp)),
          SizedBox(height: 5.h),
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp)),
        ],
      ),
    );
  }
}
