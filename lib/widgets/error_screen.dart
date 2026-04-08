 import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppColors {
  static const Color background   = Color(0xFF0A0A0F);
  static const Color surface      = Color(0xFF12121A);
  static const Color accentGreen  = Color(0xFF00FFA3);
  static const Color accentBlue   = Color(0xFF00D4FF);
  static const Color accentPurple = Color(0xFFB829F7);
  static const Color textPrimary  = Color(0xFFFFFFFF);
  static const Color textSecondary= Color(0xFF8B8B9E);
  static const Color border       = Color(0xFF2A2A3A);
}

class ErrorScreen extends StatelessWidget {
  final String? lottieUrl;
  final String? title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onRetry;
  final bool showBackButton;
  final Widget? customAction;

  const ErrorScreen({
    super.key,
    this.lottieUrl,
    this.title,
    this.subtitle,
    this.buttonText,
    this.onRetry,
    this.showBackButton = false,
    this.customAction,
  });

  static const String _oopsError = 'https://assets10.lottiefiles.com/packages/lf20_tl52xzvn.json';
  static const String _networkError = 'https://assets10.lottiefiles.com/packages/lf20_7fwvvesa.json';
  static const String _emptyError = 'https://assets10.lottiefiles.com/packages/lf20_s8pbrcfw.json';

  factory ErrorScreen.oops({
    String? title,
    String? subtitle,
    VoidCallback? onRetry,
    bool showBackButton = false,
  }) {
    return ErrorScreen(
      lottieUrl: _oopsError,
      title: title ?? 'Oops!',
      subtitle: subtitle ?? 'Something went wrong',
      buttonText: 'Try Again',
      onRetry: onRetry,
      showBackButton: showBackButton,
    );
  }

  factory ErrorScreen.network({
    String? title,
    String? subtitle,
    VoidCallback? onRetry,
    bool showBackButton = false,
  }) {
    return ErrorScreen(
      lottieUrl: _networkError,
      title: title ?? 'Connection Lost',
      subtitle: subtitle ?? 'Please check your internet connection',
      buttonText: 'Retry',
      onRetry: onRetry,
      showBackButton: showBackButton,
    );
  }

  factory ErrorScreen.empty({
    String? title,
    String? subtitle,
    VoidCallback? onAction,
    String? buttonText,
    bool showBackButton = false,
  }) {
    return ErrorScreen(
      lottieUrl: _emptyError,
      title: title ?? 'Nothing Here',
      subtitle: subtitle ?? 'No data available at the moment',
      buttonText: buttonText,
      onRetry: onAction,
      showBackButton: showBackButton,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200.w,
                height: 200.h,
                child: Lottie.network(
                  lottieUrl ?? _oopsError,
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              SizedBox(height: 32.h),

              Text(
                title ?? 'Error',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 200.ms),

              SizedBox(height: 12.h),

              Text(
                subtitle ?? 'An unexpected error occurred',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 16.sp,
                ),
              ).animate().fadeIn(delay: 300.ms),

              SizedBox(height: 40.h),

              if (customAction != null)
                customAction!
              else if (onRetry != null && buttonText != null)
                _buildRetryButton(),

              SizedBox(height: 20.h),

              if (showBackButton)
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textSecondary,
                    size: 18.sp,
                  ),
                  label: Text(
                    'Go Back',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14.sp,
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetryButton() {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: onRetry,
          child: Container(
            width: double.infinity,
            height: 56.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentGreen, AppColors.accentBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
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
            child: Center(
              child: Text(
                buttonText!,
                style: GoogleFonts.inter(
                  color: AppColors.background,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0);
      },
    );
  }
}
