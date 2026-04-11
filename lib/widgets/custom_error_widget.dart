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

/// Compact Auto-Retry Error Widget
/// JWT থাকলে IMMEDIATE auto retry - user কিছু করতে হবে না
class CustomErrorWidget extends StatefulWidget {
  final VoidCallback onRetry;
  final String? title;
  final String? message;
  final bool hasToken;
  final int autoRetryDelaySeconds;

  const CustomErrorWidget({
    super.key,
    required this.onRetry,
    this.title,
    this.message,
    this.hasToken = false,
    this.autoRetryDelaySeconds = 3,
  });

  @override
  State<CustomErrorWidget> createState() => _CustomErrorWidgetState();
}

class _CustomErrorWidgetState extends State<CustomErrorWidget> {
  int _countdown = 0;
  bool _isAutoRetrying = false;

  @override
  void initState() {
    super.initState();
    
    // 🔥 JWT থাকলে IMMEDIATELY auto retry শুরু
    if (widget.hasToken) {
      _startAutoRetry();
    }
  }

  void _startAutoRetry() {
    setState(() {
      _isAutoRetrying = true;
      _countdown = widget.autoRetryDelaySeconds;
    });
    
    // Countdown শুরু
    _runCountdown();
  }

  void _runCountdown() {
    if (!mounted) return;
    
    if (_countdown > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() => _countdown--);
        _runCountdown();
      });
    } else {
      // 🔥 Countdown শেষ - AUTO RETRY (user ক্লিক করতে হবে না!)
      widget.onRetry();
    }
  }

  void _manualRetry() {
    widget.onRetry();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Compact Lottie - NO controller needed
            SizedBox(
              width: 100.w,
              height: 100.h,
              child: Lottie.network(
                AppLottie.errorCloud,
                fit: BoxFit.contain,
                repeat: true, // Auto repeat animation
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.cloud_off_rounded,
                  size: 60.w,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            
            // Title
            Text(
              widget.title ?? 'Connection Issue',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            
            // Message
            Text(
              widget.message ?? "Reconnecting...",
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            
            // 🔥 JWT থাকলে countdown দেখাবে, না থাকলে button
            _isAutoRetrying && widget.hasToken
                ? _buildAutoRetryIndicator()
                : _buildRetryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoRetryIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent background
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.accentGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16.w,
            height: 16.h,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            'Retrying in $_countdown...',
            style: GoogleFonts.inter(
              color: AppColors.accentGreen,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return InkWell(
      onTap: _manualRetry,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accentGreen, AppColors.accentBlue],
          ),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGreen.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16.w,
              height: 16.h,
              child: Lottie.network(
                AppLottie.refresh,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.refresh,
                  size: 16.w,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'Try Again',
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
