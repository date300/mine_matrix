import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../layout/layout.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 20.h),
          
          // মেইন ব্যালেন্স কার্ড
          GlassmorphicContainer(
            width: double.infinity,
            height: 180.h,
            borderRadius: 25.r,
            blur: 20,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.blue.withOpacity(0.1), Colors.white.withOpacity(0.03)],
            ),
            borderGradient: LinearGradient(colors: [AppColors.blue, Colors.transparent]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("TOTAL ASSETS", style: GoogleFonts.inter(color: Colors.white54, fontSize: 12.sp, letterSpacing: 2)),
                SizedBox(height: 10.h),
                Text("\$12,450.80", style: GoogleFonts.inter(color: Colors.white, fontSize: 32.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 5.h),
                Text("+ 15.4% last month", style: GoogleFonts.inter(color: AppColors.accentGreen, fontSize: 12.sp)),
              ],
            ),
          ).animate().fadeIn().scale(),

          SizedBox(height: 25.h),

          // অ্যাকশন বাটনসমূহ
          Row(
            children: [
              Expanded(child: _walletAction("Send", CupertinoIcons.up_arrow, AppColors.blue)),
              SizedBox(width: 15.w),
              Expanded(child: _walletAction("Receive", CupertinoIcons.down_arrow, AppColors.accentGreen)),
            ],
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

          SizedBox(height: 30.h),

          // ট্রানজেকশন লিস্ট হেডার
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Transactions", style: GoogleFonts.inter(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
              Text("See All", style: GoogleFonts.inter(color: AppColors.blue, fontSize: 13.sp)),
            ],
          ),

          SizedBox(height: 15.h),

          _buildTxItem("Withdrawal", "- 50.0 VXL", "Success", Colors.redAccent),
          _buildTxItem("Mining Reward", "+ 12.5 VXL", "Success", AppColors.accentGreen),
          _buildTxItem("External Deposit", "+ 100.0 VXL", "Success", AppColors.accentGreen),
          
          SizedBox(height: 100.h),
        ],
      ),
    );
  }

  Widget _walletAction(String label, IconData icon, Color color) {
    return Container(
      height: 55.h,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 8.w),
          Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTxItem(String title, String amount, String status, Color amountColor) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white10,
            child: Icon(CupertinoIcons.money_dollar, color: Colors.white70),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(status, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11.sp)),
              ],
            ),
          ),
          Text(amount, style: GoogleFonts.inter(color: amountColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
