import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

// --- Colors ---
class AppColors {
  static const Color background    = Color(0xFF0A0A0F);
  static const Color surface       = Color(0xFF12121A);
  static const Color accentGreen   = Color(0xFF00FFA3);
  static const Color accentBlue    = Color(0xFF00D4FF);
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B8B9E);
}

// Lottie URLs
class AppLottie {
  static const String errorCloud = 'https://assets10.lottiefiles.com/packages/lf20_kcsr6fcp.json';
  static const String refresh    = 'https://assets10.lottiefiles.com/packages/lf20_7fwvvesa.json';
}

class CustomErrorWidget extends StatefulWidget {
  final VoidCallback onRetry;
  final String? title;
  final String? message;
  final bool hasToken;
  final int pollingIntervalSeconds;

  const CustomErrorWidget({
    super.key,
    required this.onRetry,
    this.title,
    this.message,
    this.hasToken = false,
    this.pollingIntervalSeconds = 3,
  });

  @override
  State<CustomErrorWidget> createState() => _CustomErrorWidgetState();
}

class _CustomErrorWidgetState extends State<CustomErrorWidget>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  Timer? _pollingTimer;
  bool _isPolling = false;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    if (!widget.hasToken) {
      _startPolling();
    }
  }

  @override
  void didUpdateWidget(CustomErrorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasToken && _isPolling) {
      _stopPolling();
    }
    if (!widget.hasToken && !oldWidget.hasToken && !_isPolling) {
      _startPolling();
    }
  }

  void _startPolling() {
    setState(() => _isPolling = true);
    _retry();
    _pollingTimer = Timer.periodic(
      Duration(seconds: widget.pollingIntervalSeconds),
      (_) => _retry(),
    );
  }

  void _retry() {
    if (!mounted) return;
    setState(() => _retryCount++);
    widget.onRetry();
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    if (mounted) {
      setState(() => _isPolling = false);
    }
  }

  void _manualRetry() {
    _retryCount = 0;
    _stopPolling();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent, // ✅ TRANSPARENT
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie
              SizedBox(
                width: 100.w,
                height: 100.h,
                child: Lottie.network(
                  AppLottie.errorCloud,
                  fit: BoxFit.contain,
                  controller: _controller,
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
                widget.message ?? "Couldn't load wallet data",
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),

              // Polling indicator
              _buildPollingIndicator(),

              if (_retryCount > 0) ...[
                SizedBox(height: 8.h),
                Text(
                  'Attempt $_retryCount',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPollingIndicator() {
    return InkWell(
      onTap: _manualRetry,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppColors.accentBlue.withOpacity(0.3),
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
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'Connecting...',
              style: GoogleFonts.inter(
                color: AppColors.accentBlue,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.refresh,
              size: 14.w,
              color: AppColors.accentBlue.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}
