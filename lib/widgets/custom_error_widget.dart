import 'dart:async';
import 'package:flutter/material.dart';
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
    with SingleTickerProviderStateMixin {

  late final AnimationController _lottieController;
  Timer? _pollingTimer;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

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

  // ── Silent background polling ──────────────────────────────────────────────
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

  // ── Connect tap → same modal as TopBar ────────────────────────────────────
  void _onConnectTap() {
    if (_isConnecting) return;
    // TopBar এর মতো exactly same call — openModal is void, no await needed
    Provider.of<AuthProvider>(context, listen: false).openModal(context);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _lottieController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
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
              SizedBox(height: 32.h),
              _buildConnectButton(),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildConnectButton() {
    return GestureDetector(
      onTap: _isConnecting ? null : _onConnectTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 48.w, vertical: 16.h),
        decoration: BoxDecoration(
          gradient: _isConnecting
              ? null
              : const LinearGradient(
                  colors: [AppColors.accentGreen, AppColors.accentBlue],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: _isConnecting ? AppColors.surface : null,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: _isConnecting
                ? AppColors.accentBlue.withOpacity(0.3)
                : Colors.transparent,
            width: 1,
          ),
          boxShadow: _isConnecting
              ? []
              : [
                  BoxShadow(
                    color: AppColors.accentGreen.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isConnecting) ...[
              SizedBox(
                width: 16.w,
                height: 16.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                ),
              ),
              SizedBox(width: 10.w),
            ],
            Text(
              _isConnecting ? 'Connecting...' : 'Connect',
              style: GoogleFonts.inter(
                color: _isConnecting ? AppColors.accentBlue : Colors.black,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
