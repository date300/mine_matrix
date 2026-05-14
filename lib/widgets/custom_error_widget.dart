import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:mine_matrix/providers/auth_provider.dart';

// --- Colors ---
class AppColors {
  static const Color background    = Color(0xFF0A0A0F);
  static const Color surface       = Color(0xFF12121A);
  static const Color accentGreen   = Color(0xFF00FFA3);
  static const Color accentBlue    = Color(0xFF00D4FF);
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B8B9E);

  // iOS System Colors
  static const Color iosBlue      = Color(0xFF007AFF);
  static const Color iosBlueDark  = Color(0xFF0055D4);
  static const Color iosBlueLight = Color(0xFF4DA3FF);
  static const Color iosBlueMid   = Color(0xFF0A84FF); // iOS dark mode blue
}

class AppLottie {
  static const String errorCloud =
      'https://assets10.lottiefiles.com/packages/lf20_kcsr6fcp.json';
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
    with TickerProviderStateMixin {

  late final AnimationController _lottieController;
  late final AnimationController _pulseController;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();

    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    if (!widget.hasToken) _startSilentPolling();
  }

  @override
  void didUpdateWidget(CustomErrorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasToken) {
      _stopSilentPolling();
    } else if (!oldWidget.hasToken) {
      _startSilentPolling();
    }
  }

  void _startSilentPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      Duration(seconds: widget.pollingIntervalSeconds),
      (_) { if (mounted) widget.onRetry(); },
    );
  }

  void _stopSilentPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _onConnectTap() {
    Provider.of<AuthProvider>(context, listen: false).openModal(context);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _lottieController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTopIcon(),
              SizedBox(height: 40.h),
              _buildIOSConnectButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Lottie icon ────────────────────────────────────────────────────────
  Widget _buildTopIcon() {
    return SizedBox(
      width: 100.w,
      height: 100.h,
      child: Lottie.network(
        AppLottie.errorCloud,
        fit: BoxFit.contain,
        controller: _lottieController,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.cloud_off_rounded,
          size: 60.w,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  // ── iOS-style Connect Button ───────────────────────────────────────────────
  Widget _buildIOSConnectButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final double glowOpacity = 0.18 + (_pulseController.value * 0.14);

        return GestureDetector(
          onTap: _onConnectTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 36.w, vertical: 15.h),
                constraints: BoxConstraints(minWidth: 160.w),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50.r),

                  // iOS translucent blue — like iOS modal / action sheet
                  gradient: LinearGradient(
                    colors: [
                      AppColors.iosBlueMid.withOpacity(0.85),
                      AppColors.iosBlue.withOpacity(0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  border: Border.all(
                    color: AppColors.iosBlueLight.withOpacity(0.45),
                    width: 1.2,
                  ),

                  boxShadow: [
                    // iOS blue soft glow — pulses gently
                    BoxShadow(
                      color: AppColors.iosBlue.withOpacity(glowOpacity),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.20),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.link,
                      color: Colors.white,
                      size: 15.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Connect',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
