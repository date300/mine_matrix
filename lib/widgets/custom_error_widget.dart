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

  // Gold palette
  static const Color goldLight  = Color(0xFFFFD700);
  static const Color goldMid    = Color(0xFFFFA500);
  static const Color goldDark   = Color(0xFFB8860B);
  static const Color goldGlow   = Color(0xFFFFD70040);
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

    // Gold glow pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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
              _buildGoldConnectButton(),
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

  // ── Gold Professional Connect Button ──────────────────────────────────────
  Widget _buildGoldConnectButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        // Pulse: glow spreads in and out
        final double glowSpread = 2 + (_pulseController.value * 6);
        final double glowBlur   = 12 + (_pulseController.value * 16);

        return GestureDetector(
          onTap: _onConnectTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50.r), // pill/rounded
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 32.w, vertical: 14.h),
                constraints: BoxConstraints(minWidth: 160.w),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50.r),
                  // Gold shimmer gradient — matches TopBar glass style
                  gradient: LinearGradient(
                    colors: [
                      AppColors.goldLight.withOpacity(0.18),
                      AppColors.goldMid.withOpacity(0.10),
                      AppColors.goldDark.withOpacity(0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppColors.goldLight.withOpacity(0.55),
                    width: 1.4,
                  ),
                  boxShadow: [
                    // Outer gold glow — pulses
                    BoxShadow(
                      color: AppColors.goldLight
                          .withOpacity(0.20 + _pulseController.value * 0.15),
                      blurRadius: glowBlur,
                      spreadRadius: glowSpread,
                    ),
                    // Inner subtle shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Chain-link icon — same pattern as TopBar
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          AppColors.goldLight,
                          AppColors.goldMid,
                        ],
                      ).createShader(bounds),
                      child: Icon(
                        CupertinoIcons.link,
                        color: Colors.white, // ShaderMask overrides this
                        size: 15.sp,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          AppColors.goldLight,
                          AppColors.goldMid,
                          AppColors.goldDark,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'Connect',
                        style: GoogleFonts.inter(
                          color: Colors.white, // ShaderMask overrides
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
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
