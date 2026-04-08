import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

// --- Colors ---
class AppColors {
  static const Color background   = Color(0xFF0A0A0F);
  static const Color surface      = Color(0xFF12121A);
  static const Color accentGreen  = Color(0xFF00FFA3);
  static const Color accentBlue   = Color(0xFF00D4FF);
  static const Color textPrimary  = Color(0xFFFFFFFF);
  static const Color textSecondary= Color(0xFF8B8B9E);
}

// Lottie URLs
class AppLottie {
  static const String errorCloud   = 'https://assets10.lottiefiles.com/packages/lf20_kcsr6fcp.json';
  static const String refresh      = 'https://assets10.lottiefiles.com/packages/lf20_7fwvvesa.json';
}

/// Reusable Error Widget - Wallet Screen থেকে বের করা
/// নাম পরিবর্তন: ErrorWidget → CustomErrorWidget (Flutter SDK conflict এড়াতে)
class CustomErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const CustomErrorWidget({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150.w,
              height: 150.h,
              child: Lottie.network(AppLottie.errorCloud),
            ),
            SizedBox(height: 24.h),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              "We couldn't load your wallet data. Please check your connection and try again.",
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                width: double.infinity,
                height: 56.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accentGreen, AppColors.accentBlue],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGreen.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: Lottie.network(AppLottie.refresh),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Try Again',
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
