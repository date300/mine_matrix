import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;

// --- Colors ------------------------------------------------------------------
class AppColors {
  static const Color background    = Color(0xFF0A0A0F);
  static const Color surface       = Color(0xFF12121A);
  static const Color accentGreen   = Color(0xFF00FFA3);
  static const Color accentPurple  = Color(0xFFB829F7);
  static const Color accentBlue    = Color(0xFF00D4FF);
  static const Color accentOrange  = Color(0xFFFF9500);
  static const Color accentRed     = Color(0xFFFF4D4D);
  static const Color accentYellow  = Color(0xFFFFD60A);
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B8B9E);
  static const Color textMuted     = Color(0xFF4A4A5A);
  static const Color border        = Color(0xFF2A2A3A);
  static const Color cardBg        = Color(0xFF161620);
}

// Lottie URLs
class AppLottie {
  static const String usdtCoin   = 'https://assets6.lottiefiles.com/packages/lf20_qmfs6c3i.json';
  static const String txSuccess  = 'https://assets10.lottiefiles.com/packages/lf20_pqnfmkj9.json';
  static const String txPending  = 'https://assets9.lottiefiles.com/packages/lf20_ysas9eas.json';
  static const String txFailed   = 'https://assets10.lottiefiles.com/packages/lf20_tl52xzvn.json';
  static const String confetti   = 'https://assets10.lottiefiles.com/packages/lf20_u4yrau.json';
  static const String loading    = 'https://assets4.lottiefiles.com/packages/lf20_usmfx6bp.json';
}

const String _baseUrl = 'https://web3.ltcminematrix.com';

// ── ENUMS ──────────────────────────────────────────────────────────────────
enum VerifyState { idle, loading, pending, success, failed }

// ── DEPOSIT SHEET WIDGET ───────────────────────────────────────────────────
class DepositSheet extends StatefulWidget {
  final String platformWallet; // BEP20 wallet address
  final Map<String, String> headers;
  final VoidCallback onSuccess;

  const DepositSheet({
    super.key,
    required this.platformWallet,
    required this.headers,
    required this.onSuccess,
  });

  @override
  State<DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<DepositSheet>
    with TickerProviderStateMixin {
  int _step = 0;
  final _txHashController = TextEditingController();
  VerifyState _verifyState = VerifyState.idle;
  String _errorMessage = '';
  bool _copied = false;

  // Pending confirmation tracking
  int _confirmations = 0;
  int _requiredConfirmations = 12;
  String _pendingMessage = '';
  Timer? _pendingPollingTimer;

  // Success data
  String _successAmount = '0.00';
  String _depositMode = 'auto';

  late AnimationController _confettiController;
  late AnimationController _pulseController;

  // TX hash validation regex
  static final _txHashRegex = RegExp(r'^0x([A-Fa-f0-9]{64})$');

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _txHashController.dispose();
    _confettiController.dispose();
    _pulseController.dispose();
    _pendingPollingTimer?.cancel();
    super.dispose();
  }

  // ── VALIDATION ──────────────────────────────────────────────────────────

  bool get _isTxHashValid =>
      _txHashRegex.hasMatch(_txHashController.text.trim());

  // ── API CALL ────────────────────────────────────────────────────────────

  Future<void> _verifyDeposit() async {
    final txHash = _txHashController.text.trim();

    if (!_isTxHashValid) {
      setState(() {
        _verifyState = VerifyState.failed;
        _errorMessage =
            'Invalid transaction hash. Must start with 0x followed by 64 hex characters.';
      });
      return;
    }

    setState(() {
      _verifyState = VerifyState.loading;
      _errorMessage = '';
    });

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/deposit/verify'),
        headers: {
          ...widget.headers,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'txHash': txHash}),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      // ── 202 Pending (not enough confirmations) ──
      if (res.statusCode == 202 && data['pending'] == true) {
        setState(() {
          _verifyState = VerifyState.pending;
          _confirmations = data['confirmations'] ?? 0;
          _requiredConfirmations = data['required'] ?? 12;
          _pendingMessage = data['message'] ?? 'Transaction is pending...';
        });
        _startPendingPolling(txHash);
        return;
      }

      // ── 200 Success ──
      if (res.statusCode == 200 && data['success'] == true) {
        setState(() {
          _verifyState = VerifyState.success;
          _successAmount = data['amount']?.toString() ?? '0.00';
          _depositMode = data['mode'] ?? 'auto';
        });
        _confettiController.forward();
        _showSuccessDialog(data);
        return;
      }

      // ── Error ──
      setState(() {
        _verifyState = VerifyState.failed;
        _errorMessage = data['error'] ?? 'Verification failed. Please try again.';
      });

    } on TimeoutException {
      if (mounted) {
        setState(() {
          _verifyState = VerifyState.failed;
          _errorMessage = 'Connection timed out. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _verifyState = VerifyState.failed;
          _errorMessage = 'Network error. Check your connection and try again.';
        });
      }
    }
  }

  // ── PENDING AUTO-POLLING ─────────────────────────────────────────────────

  void _startPendingPolling(String txHash) {
    _pendingPollingTimer?.cancel();
    _pendingPollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && _verifyState == VerifyState.pending) {
        _pollPendingStatus(txHash);
      } else {
        _pendingPollingTimer?.cancel();
      }
    });
  }

  Future<void> _pollPendingStatus(String txHash) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/deposit/verify'),
        headers: {
          ...widget.headers,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'txHash': txHash}),
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 202 && data['pending'] == true) {
        setState(() {
          _confirmations = data['confirmations'] ?? _confirmations;
          _requiredConfirmations = data['required'] ?? 12;
          _pendingMessage = data['message'] ?? _pendingMessage;
        });
      } else if (res.statusCode == 200 && data['success'] == true) {
        _pendingPollingTimer?.cancel();
        setState(() {
          _verifyState = VerifyState.success;
          _successAmount = data['amount']?.toString() ?? '0.00';
          _depositMode = data['mode'] ?? 'auto';
        });
        _confettiController.forward();
        _showSuccessDialog(data);
      } else {
        _pendingPollingTimer?.cancel();
        setState(() {
          _verifyState = VerifyState.failed;
          _errorMessage = data['error'] ?? 'Verification failed.';
        });
      }
    } catch (_) {
      // Silent — retry on next tick
    }
  }

  // ── SUCCESS DIALOG ──────────────────────────────────────────────────────

  void _showSuccessDialog(Map<String, dynamic> data) {
    final isManual = _depositMode == 'manual';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Stack(
        children: [
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(ctx).size.width * 0.88,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: isManual
                        ? AppColors.accentOrange.withOpacity(0.5)
                        : AppColors.accentGreen.withOpacity(0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isManual
                              ? AppColors.accentOrange
                              : AppColors.accentGreen)
                          .withOpacity(0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ──
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          vertical: 24.h, horizontal: 20.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            (isManual
                                    ? AppColors.accentOrange
                                    : AppColors.accentGreen)
                                .withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24.r)),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 80.w,
                            height: 80.h,
                            child: Lottie.network(
                              isManual
                                  ? AppLottie.txPending
                                  : AppLottie.txSuccess,
                              repeat: false,
                              controller: isManual ? null : _confettiController,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            isManual ? 'Submitted!' : 'Deposit Confirmed!',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            isManual
                                ? 'Awaiting admin approval'
                                : 'Balance updated instantly',
                            style: GoogleFonts.inter(
                              color: isManual
                                  ? AppColors.accentOrange
                                  : AppColors.accentGreen,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Amount ──
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 16.h, horizontal: 20.w),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _usdtBadge(size: 24),
                                SizedBox(width: 10.w),
                                Text(
                                  '\$$_successAmount USDT',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontSize: 26.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isManual) ...[
                            SizedBox(height: 12.h),
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: AppColors.accentOrange.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                    color:
                                        AppColors.accentOrange.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.schedule,
                                      color: AppColors.accentOrange, size: 16.sp),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      'Your deposit is under review. Balance will be credited after admin approval.',
                                      style: GoogleFonts.inter(
                                        color: AppColors.accentOrange,
                                        fontSize: 11.sp,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          SizedBox(height: 20.h),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                              widget.onSuccess();
                            },
                            child: Container(
                              width: double.infinity,
                              height: 48.h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isManual
                                      ? [
                                          AppColors.accentOrange,
                                          const Color(0xFFFFD60A)
                                        ]
                                      : [
                                          AppColors.accentGreen,
                                          AppColors.accentBlue
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(14.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isManual
                                            ? AppColors.accentOrange
                                            : AppColors.accentGreen)
                                        .withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isManual ? 'Got it!' : 'Awesome!',
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Confetti overlay (auto mode only)
          if (!isManual)
            Positioned.fill(
              child: IgnorePointer(
                child: Lottie.network(
                  AppLottie.confetti,
                  controller: _confettiController,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // ── Drag handle ──
          SizedBox(height: 10.h),
          Container(
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          SizedBox(height: 16.h),

          // ── Header ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                _networkBadgeIcon(),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Funds',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0B90B).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'BEP20 · BSC',
                              style: GoogleFonts.spaceMono(
                                color: const Color(0xFFF0B90B),
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          _usdtBadge(size: 12),
                          SizedBox(width: 4.w),
                          Text(
                            'USDT',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 18.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // ── Step Indicator ──
          _buildStepIndicator(),
          SizedBox(height: 24.h),

          // ── Body ──
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: _step == 0 ? _buildStep0() : _buildStep1(),
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP INDICATOR ──────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          _stepDot(0, 'Send', Icons.send_rounded),
          Expanded(
            child: Container(
              height: 2,
              margin: EdgeInsets.symmetric(horizontal: 8.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _step >= 1
                      ? [AppColors.accentGreen, AppColors.accentBlue]
                      : [AppColors.border, AppColors.border],
                ),
              ),
            ),
          ),
          _stepDot(1, 'Verify', Icons.verified_rounded),
        ],
      ),
    );
  }

  Widget _stepDot(int step, String label, IconData icon) {
    final bool active = _step >= step;
    final bool current = _step == step;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 38.w,
          height: 38.h,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [AppColors.accentGreen, AppColors.accentBlue])
                : null,
            color: active ? null : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? Colors.transparent : AppColors.border,
              width: 2,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.accentGreen.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: active
                ? Icon(icon, color: Colors.black, size: 18.sp)
                : Text(
                    '${step + 1}',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: GoogleFonts.inter(
            color: active ? AppColors.accentGreen : AppColors.textMuted,
            fontSize: 11.sp,
            fontWeight: current ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ── STEP 0: SEND ────────────────────────────────────────────────────────

  Widget _buildStep0() {
    return Column(
      children: [
        // QR Code
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF0B90B).withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: QrImageView(
            data: widget.platformWallet,
            version: QrVersions.auto,
            size: 160.w,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _usdtBadge(size: 16),
            SizedBox(width: 6.w),
            Text(
              'Send USDT (BEP20) only',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Wallet Address
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: widget.platformWallet));
            setState(() => _copied = true);
            Future.delayed(
                const Duration(seconds: 2),
                () {
                  if (mounted) setState(() => _copied = false);
                });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color:
                    _copied ? AppColors.accentGreen : AppColors.border,
                width: _copied ? 1.5 : 1,
              ),
              boxShadow: _copied
                  ? [
                      BoxShadow(
                        color: AppColors.accentGreen.withOpacity(0.1),
                        blurRadius: 12,
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.platformWallet,
                    style: GoogleFonts.spaceMono(
                      color: AppColors.textPrimary,
                      fontSize: 10.sp,
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: _copied
                        ? AppColors.accentGreen.withOpacity(0.15)
                        : const Color(0xFFF0B90B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    color: _copied
                        ? AppColors.accentGreen
                        : const Color(0xFFF0B90B),
                    size: 16.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_copied) ...[
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.accentGreen, size: 14.sp),
              SizedBox(width: 4.w),
              Text(
                'Address copied!',
                style: GoogleFonts.inter(
                  color: AppColors.accentGreen,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: 16.h),

        // Info Cards
        _buildInfoCard(Icons.attach_money_rounded, 'Minimum Deposit',
            'Min \$1.00 USDT required', AppColors.accentOrange),
        SizedBox(height: 8.h),
        _buildInfoCard(Icons.link_rounded, 'Network Warning',
            'Only Binance Smart Chain (BEP20)', AppColors.accentRed),
        SizedBox(height: 8.h),
        _buildInfoCard(Icons.verified_outlined, 'Confirmations Required',
            '12 network confirmations needed', AppColors.accentBlue),
        SizedBox(height: 8.h),
        _buildInfoCard(Icons.timer_outlined, 'Processing Time',
            'Usually 30 seconds – 2 minutes', AppColors.accentGreen),
        SizedBox(height: 28.h),

        // CTA Button
        GestureDetector(
          onTap: () => setState(() => _step = 1),
          child: Container(
            width: double.infinity,
            height: 52.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentGreen, AppColors.accentBlue],
              ),
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGreen.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "I've Sent USDT",
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.arrow_forward_rounded,
                    color: Colors.black, size: 18.sp),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  // ── STEP 1: VERIFY ──────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Transaction Hash',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Paste the BSC transaction hash (TxHash) from your wallet to verify and credit your deposit.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12.sp,
            height: 1.5,
          ),
        ),
        SizedBox(height: 14.h),

        // How to find guide
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.accentBlue.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.help_outline_rounded,
                      color: AppColors.accentBlue, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'How to find TxHash?',
                    style: GoogleFonts.inter(
                      color: AppColors.accentBlue,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              _guideStep('1', 'Open your wallet (Trust Wallet / Metamask)'),
              _guideStep('2', 'Go to Activity / Transaction History'),
              _guideStep('3', 'Tap the USDT transfer transaction'),
              _guideStep('4', 'Copy the TxHash / Transaction ID'),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // TxHash format hint
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.textMuted, size: 14.sp),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'Format: 0x followed by 64 hex characters',
                  style: GoogleFonts.spaceMono(
                    color: AppColors.textMuted,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // TxHash Input
        _buildTxHashInput(),

        // Error message
        if (_verifyState == VerifyState.failed && _errorMessage.isNotEmpty) ...[
          SizedBox(height: 10.h),
          _buildErrorBox(_errorMessage),
        ],

        // Pending state
        if (_verifyState == VerifyState.pending) ...[
          SizedBox(height: 14.h),
          _buildPendingBox(),
        ],

        SizedBox(height: 24.h),

        // Verify Button
        _buildVerifyButton(),

        SizedBox(height: 12.h),

        // Back Button
        GestureDetector(
          onTap: () {
            _pendingPollingTimer?.cancel();
            setState(() {
              _step = 0;
              _verifyState = VerifyState.idle;
              _errorMessage = '';
            });
          },
          child: Container(
            width: double.infinity,
            height: 46.h,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              'Back',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 28.h),
      ],
    );
  }

  Widget _buildTxHashInput() {
    final isError = _verifyState == VerifyState.failed;
    final isValid = _isTxHashValid;

    Color borderColor = AppColors.border;
    if (isError) borderColor = AppColors.accentRed;
    else if (isValid) borderColor = AppColors.accentGreen;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: borderColor,
          width: (isError || isValid) ? 1.5 : 1,
        ),
        boxShadow: isValid && !isError
            ? [
                BoxShadow(
                  color: AppColors.accentGreen.withOpacity(0.08),
                  blurRadius: 12,
                )
              ]
            : null,
      ),
      child: TextField(
        controller: _txHashController,
        style: GoogleFonts.spaceMono(
          color: AppColors.textPrimary,
          fontSize: 11.sp,
          height: 1.5,
        ),
        maxLines: 3,
        enabled: _verifyState != VerifyState.loading,
        onChanged: (_) => setState(() {
          _verifyState = VerifyState.idle;
          _errorMessage = '';
        }),
        decoration: InputDecoration(
          hintText: '0x... (paste transaction hash here)',
          hintStyle: GoogleFonts.spaceMono(
            color: AppColors.textMuted,
            fontSize: 11.sp,
          ),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.fromLTRB(14.w, 14.h, 50.w, 14.h),
          suffixIcon: GestureDetector(
            onTap: _verifyState == VerifyState.loading
                ? null
                : () async {
                    final data =
                        await Clipboard.getData('text/plain');
                    if (data?.text != null && mounted) {
                      _txHashController.text =
                          data!.text!.trim();
                      setState(() {
                        _verifyState = VerifyState.idle;
                        _errorMessage = '';
                      });
                    }
                  },
            child: Container(
              margin: EdgeInsets.all(10.w),
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.content_paste_rounded,
                  color: AppColors.accentPurple, size: 18.sp),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    final bool isLoading = _verifyState == VerifyState.loading;
    final bool isPending = _verifyState == VerifyState.pending;
    final bool disabled = isLoading || isPending;

    return GestureDetector(
      onTap: disabled ? null : _verifyDeposit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: 52.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: disabled
                ? [AppColors.textMuted, AppColors.textMuted]
                : [AppColors.accentGreen, AppColors.accentBlue],
          ),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.accentGreen.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Verifying on BSC...',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : isPending
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16.w,
                        height: 16.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white54),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Auto-checking confirmations...',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Verify & Credit Balance',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
      ),
    );
  }

  Widget _buildPendingBox() {
    final double progress =
        _confirmations / _requiredConfirmations.toDouble();

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.accentOrange.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14.r),
        border:
            Border.all(color: AppColors.accentOrange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 10.w,
                  height: 10.h,
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withOpacity(
                        0.5 + 0.5 * _pulseController.value),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentOrange.withOpacity(0.4),
                        blurRadius: 6,
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Transaction Pending',
                style: GoogleFonts.inter(
                  color: AppColors.accentOrange,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$_confirmations / $_requiredConfirmations',
                style: GoogleFonts.spaceMono(
                  color: AppColors.accentOrange,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.accentOrange),
              minHeight: 6.h,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _pendingMessage,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 11.sp,
              height: 1.4,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '⟳ Auto-checking every 15 seconds...',
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.accentRed.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.accentRed, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: AppColors.accentRed,
                fontSize: 11.sp,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SHARED HELPERS ──────────────────────────────────────────────────────

  Widget _buildInfoCard(
      IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 34.w,
            height: 34.h,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(child: Icon(icon, color: color, size: 18.sp)),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guideStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18.w,
            height: 18.h,
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: GoogleFonts.inter(
                color: AppColors.accentBlue,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 11.sp,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkBadgeIcon() {
    return Container(
      width: 42.w,
      height: 42.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF0B90B).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
            color: const Color(0xFFF0B90B).withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          'BNB',
          style: GoogleFonts.spaceMono(
            color: const Color(0xFFF0B90B),
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _usdtBadge({required double size}) {
    return Container(
      width: size.w,
      height: size.w,
      decoration: const BoxDecoration(
        color: Color(0xFF26A17B),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '₮',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: (size * 0.6).sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
