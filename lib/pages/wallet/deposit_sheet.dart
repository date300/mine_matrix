import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;

// --- Colors (শেয়ার করা) ------------------------------------------------------
class AppColors {
  static const Color background   = Color(0xFF0A0A0F);
  static const Color surface      = Color(0xFF12121A);
  static const Color accentGreen  = Color(0xFF00FFA3);
  static const Color accentPurple = Color(0xFFB829F7);
  static const Color accentBlue   = Color(0xFF00D4FF);
  static const Color accentOrange = Color(0xFFFF9500);
  static const Color accentRed    = Color(0xFFFF4D4D);
  static const Color textPrimary  = Color(0xFFFFFFFF);
  static const Color textSecondary= Color(0xFF8B8B9E);
  static const Color textMuted    = Color(0xFF4A4A5A);
  static const Color border       = Color(0xFF2A2A3A);
  static const Color cardBg       = Color(0xFF161620);
}

// Lottie URLs
class AppLottie {
  static const String solCoin      = 'https://assets10.lottiefiles.com/packages/lf20_6wutsrox.json';
  static const String txSuccess    = 'https://assets10.lottiefiles.com/packages/lf20_pqnfmkj9.json';
  static const String txFailed     = 'https://assets10.lottiefiles.com/packages/lf20_tl52xzvn.json';
  static const String copy         = 'https://assets10.lottiefiles.com/packages/lf20_3s913D.json';
  static const String info         = 'https://assets10.lottiefiles.com/packages/lf20_b6cz19m8.json';
  static const String warning      = 'https://assets10.lottiefiles.com/packages/lf20_Tkwjw8.json';
  static const String secure       = 'https://assets10.lottiefiles.com/packages/lf20_5njp3vgg.json';
  static const String question     = 'https://assets10.lottiefiles.com/packages/lf20_w51pcehl.json';
  static const String arrowRight   = 'https://assets10.lottiefiles.com/packages/lf20_7z8wtyb0.json';
  static const String confetti     = 'https://assets10.lottiefiles.com/packages/lf20_u4yrau.json';
}

const String _baseUrl = 'https://web3.ltcminematrix.com';

// --- Deposit Sheet Widget ------------------------------------------------------
class DepositSheet extends StatefulWidget {
  final String platformWallet;
  final double solPrice;
  final Map<String, String> headers;
  final VoidCallback onSuccess;

  const DepositSheet({
    super.key,
    required this.platformWallet,
    required this.solPrice,
    required this.headers,
    required this.onSuccess,
  });

  @override
  State<DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<DepositSheet> with TickerProviderStateMixin {
  int _step = 0;
  final _sigController = TextEditingController();
  bool _verifying = false;
  String _verifyError = '';
  bool _copied = false;
  
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _sigController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _verifyDeposit() async {
    final sig = _sigController.text.trim();
    if (sig.length < 50) {
      setState(() => _verifyError = 'Invalid transaction signature');
      return;
    }

    setState(() { _verifying = true; _verifyError = ''; });

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/deposit/verify'),
        headers: widget.headers,
        body: jsonEncode({'signature': sig}),
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        setState(() => _verifying = false);
        _confettiController.forward();
        _showSuccessDialog(data);
      } else {
        setState(() {
          _verifying = false;
          _verifyError = data['error'] ?? 'Verification failed';
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _verifying = false;
          _verifyError = e.toString().contains('timeout') 
              ? 'Connection timeout. Try again.' 
              : 'Connection error. Try again.';
        });
      }
    }
  }

  void _showSuccessDialog(Map data) {
    final usd = data['usdAmount']?.toString() ?? '0';
    final sol = data['solAmount']?.toString() ?? '0';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Stack(
        children: [
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(ctx).size.width * 0.85,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: AppColors.accentGreen.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGreen.withOpacity(0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accentGreen.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 80.w,
                            height: 80.h,
                            child: Lottie.network(
                              AppLottie.txSuccess,
                              repeat: false,
                              controller: _confettiController,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Deposit Successful!',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        children: [
                          Text(
                            '+\$$usd',
                            style: GoogleFonts.inter(
                              color: AppColors.accentGreen,
                              fontSize: 36.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16.w,
                                height: 16.h,
                                child: Lottie.network(AppLottie.solCoin),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                '$sol SOL deposited',
                                style: GoogleFonts.spaceMono(
                                  color: AppColors.textSecondary,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              widget.onSuccess();
                            },
                            child: Container(
                              width: double.infinity,
                              height: 52.h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.accentGreen, AppColors.accentBlue],
                                ),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Awesome!',
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontSize: 16.sp,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 28.w,
                      height: 28.h,
                      child: Lottie.network(AppLottie.solCoin),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deposit SOL',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '1 SOL = \$${widget.solPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          color: AppColors.accentPurple,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Send SOL', Icons.send),
                Expanded(
                  child: Container(
                    height: 2,
                    margin: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _step >= 1
                            ? [AppColors.accentGreen, AppColors.accentBlue]
                            : [AppColors.border, AppColors.border],
                      ),
                    ),
                  ),
                ),
                _buildStepIndicator(1, 'Verify', Icons.verified),
              ],
            ),
          ),
          SizedBox(height: 32.h),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: _step == 0 ? _buildStep0() : _buildStep1(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final bool isActive = _step >= step;
    final bool isCurrent = _step == step;

    return Column(
      children: [
        Container(
          width: 44.w,
          height: 44.h,
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [AppColors.accentGreen, AppColors.accentBlue],
                  )
                : null,
            color: isActive ? null : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.transparent : AppColors.border,
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.accentGreen.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isActive
                ? Icon(icon, color: Colors.black, size: 20)
                : Text(
                    '${step + 1}',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: GoogleFonts.inter(
            color: isActive ? AppColors.accentGreen : AppColors.textMuted,
            fontSize: 12.sp,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStep0() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPurple.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: QrImageView(
            data: widget.platformWallet,
            version: QrVersions.auto,
            size: 180.w,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          'Send SOL to this address',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: widget.platformWallet));
            setState(() => _copied = true);
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) setState(() => _copied = false);
            });
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: _copied ? AppColors.accentGreen : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.platformWallet,
                    style: GoogleFonts.spaceMono(
                      color: AppColors.textPrimary,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: _copied
                        ? AppColors.accentGreen.withOpacity(0.2)
                        : AppColors.accentPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: _copied
                      ? Icon(Icons.check, color: AppColors.accentGreen, size: 18)
                      : SizedBox(
                          width: 18.w,
                          height: 18.h,
                          child: Lottie.network(AppLottie.copy),
                        ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h),
        _buildInfoCard(
          AppLottie.info,
          'Minimum Deposit',
          '0.001 SOL required',
          AppColors.accentOrange,
        ),
        SizedBox(height: 10.h),
        _buildInfoCard(
          AppLottie.warning,
          'Network',
          'Only Solana Mainnet',
          AppColors.accentRed,
        ),
        SizedBox(height: 10.h),
        _buildInfoCard(
          AppLottie.secure,
          'Confirmation',
          'Usually takes 5-30 seconds',
          AppColors.accentGreen,
        ),
        SizedBox(height: 32.h),
        GestureDetector(
          onTap: () => setState(() => _step = 1),
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
                Text(
                  "I've Sent SOL",
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 10.w),
                SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: Lottie.network(AppLottie.arrowRight),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Transaction Signature',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Paste the transaction hash from your wallet to verify and credit your deposit.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13.sp,
            height: 1.5,
          ),
        ),
        SizedBox(height: 20.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: Lottie.network(AppLottie.question),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'How to find your signature?',
                    style: GoogleFonts.inter(
                      color: AppColors.accentBlue,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'Phantom/Solflare: Activity → Tap transaction → Copy Signature',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: _verifyError.isNotEmpty
                  ? AppColors.accentRed
                  : _sigController.text.isNotEmpty
                      ? AppColors.accentGreen
                      : AppColors.border,
              width: _sigController.text.isNotEmpty ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: _sigController,
            style: GoogleFonts.spaceMono(
              color: AppColors.textPrimary,
              fontSize: 12.sp,
            ),
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Paste transaction signature here...',
              hintStyle: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 13.sp,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16.w),
              suffixIcon: GestureDetector(
                onTap: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    _sigController.text = data!.text!.trim();
                    setState(() {});
                  }
                },
                child: Container(
                  margin: EdgeInsets.all(12.w),
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: Lottie.network(AppLottie.copy),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_verifyError.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.accentRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.accentRed.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 18.w,
                  height: 18.h,
                  child: Lottie.network(AppLottie.txFailed, repeat: false),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    _verifyError,
                    style: GoogleFonts.inter(
                      color: AppColors.accentRed,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 32.h),
        GestureDetector(
          onTap: _verifying ? null : _verifyDeposit,
          child: Container(
            width: double.infinity,
            height: 56.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _verifying
                    ? [AppColors.textMuted, AppColors.textMuted]
                    : [AppColors.accentGreen, AppColors.accentBlue],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: _verifying
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.accentGreen.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: _verifying
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24.w,
                        height: 24.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Verifying...',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Verify & Credit',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 16.h),
        GestureDetector(
          onTap: () => setState(() {
            _step = 0;
            _verifyError = '';
          }),
          child: Container(
            width: double.infinity,
            height: 48.h,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              'Back',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 32.h),
      ],
    );
  }

  Widget _buildInfoCard(String lottieUrl, String title, String subtitle, Color color) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.h,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: SizedBox(
                width: 20.w,
                height: 20.h,
                child: Lottie.network(lottieUrl),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 11.sp,
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
}

