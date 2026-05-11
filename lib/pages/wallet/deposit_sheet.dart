import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;

// ── Colors ───────────────────────────────────────────────────────────────────
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

// ── API Response Models ─────────────────────────────────────────────────────
class DepositVerifyResponse {
  final bool success;
  final String? mode;
  final String? amount;
  final String? message;
  final bool? pending;
  final int? confirmations;
  final int? required;
  final String? error;

  DepositVerifyResponse({
    this.success = false,
    this.mode,
    this.amount,
    this.message,
    this.pending,
    this.confirmations,
    this.required,
    this.error,
  });

  factory DepositVerifyResponse.fromJson(Map<String, dynamic> json) {
    return DepositVerifyResponse(
      success: json['success'] ?? false,
      mode: json['mode'],
      amount: json['amount'],
      message: json['message'],
      pending: json['pending'],
      confirmations: json['confirmations'],
      required: json['required'],
      error: json['error'],
    );
  }
}

// ── Deposit Sheet ────────────────────────────────────────────────────────────
class DepositSheet extends StatefulWidget {
  final String platformWallet;    // BEP20_WALLET from backend
  final double minDeposit;         // MIN_DEPOSIT (default 1.0)
  final int requiredConfirmations; // REQUIRED_CONFIRMATIONS (default 12)
  final Map<String, String> headers; // Auth headers with token
  final VoidCallback onSuccess;

  const DepositSheet({
    super.key,
    required this.platformWallet,
    required this.headers,
    required this.onSuccess,
    this.minDeposit = 1.0,
    this.requiredConfirmations = 12,
  });

  @override
  State<DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<DepositSheet> {
  int _step = 0;
  final _txHashController = TextEditingController();
  bool _verifying = false;
  String _errorMessage = '';
  bool _copied = false;
  bool _isPending = false;
  int? _currentConfirmations;
  
  static const String _baseUrl = 'https://web3.ltcminematrix.com';

  @override
  void dispose() {
    _txHashController.dispose();
    super.dispose();
  }

  // ── Validate txHash format: 0x + 64 hex characters ─────────────────────
  bool _isValidTxHash(String txHash) {
    return RegExp(r'^0x([A-Fa-f0-9]{64})$').hasMatch(txHash);
  }

  // ── API: Verify Deposit ──────────────────────────────────────────────────
  Future<void> _verifyDeposit() async {
    final txHash = _txHashController.text.trim();

    // Validation
    if (!_isValidTxHash(txHash)) {
      setState(() => _errorMessage = 'Invalid transaction hash format. Must be 0x + 64 hex characters.');
      return;
    }

    setState(() {
      _verifying = true;
      _errorMessage = '';
      _isPending = false;
      _currentConfirmations = null;
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

      final data = jsonDecode(res.body);
      final response = DepositVerifyResponse.fromJson(data);

      // Handle 202 Pending (insufficient confirmations)
      if (res.statusCode == 202 && response.pending == true) {
        setState(() {
          _verifying = false;
          _isPending = true;
          _currentConfirmations = response.confirmations;
          _errorMessage = 'Transaction pending. Confirmations: ${response.confirmations}/${response.required}. Please wait and verify again.';
        });
        return;
      }

      // Handle 400/500 errors
      if (res.statusCode != 200 || response.success != true) {
        setState(() {
          _verifying = false;
          _errorMessage = response.error ?? 'Verification failed. Please try again.';
        });
        return;
      }

      // Success: Auto mode or Manual mode
      setState(() => _verifying = false);
      _showSuccessDialog(response);

    } on TimeoutException {
      if (mounted) {
        setState(() {
          _verifying = false;
          _errorMessage = 'Connection timeout. Blockchain network is busy. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _verifying = false;
          _errorMessage = 'Connection error. Please check your internet and try again.';
        });
      }
    }
  }

  // ── Success Dialog ───────────────────────────────────────────────────────
  void _showSuccessDialog(DepositVerifyResponse response) {
    final isAuto = response.mode == 'auto';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(ctx).size.width * 0.85,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isAuto ? AppColors.accentGreen.withOpacity(0.5) : AppColors.accentOrange.withOpacity(0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isAuto ? AppColors.accentGreen.withOpacity(0.2) : AppColors.accentOrange.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                ),
                child: Column(
                  children: [
                    Icon(
                      isAuto ? Icons.check_circle : Icons.pending_actions,
                      color: isAuto ? AppColors.accentGreen : AppColors.accentOrange,
                      size: 64,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      isAuto ? 'Deposit Successful!' : 'Deposit Submitted',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Body
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    if (response.amount != null) ...[
                      Text(
                        '+\$${response.amount}',
                        style: GoogleFonts.inter(
                          color: isAuto ? AppColors.accentGreen : AppColors.accentOrange,
                          fontSize: 36.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                    ],
                    Text(
                      response.message ?? (isAuto 
                          ? 'Deposit successful and balance updated.' 
                          : 'Deposit submitted for admin approval.'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    
                    // Action Button
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
                            colors: isAuto 
                                ? [AppColors.accentGreen, AppColors.accentBlue]
                                : [AppColors.accentOrange, AppColors.accentPurple],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isAuto ? 'Awesome!' : 'Got it',
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
          // Handle bar
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
          
          // Header
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
                  child: const Center(
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.accentPurple,
                      size: 24,
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deposit USDT (BEP20)',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Min: \$${widget.minDeposit.toStringAsFixed(2)} | Confirmations: ${widget.requiredConfirmations}',
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
                    child: const Icon(
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
          
          // Step Indicator
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Send USDT', Icons.send),
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
          
          // Content
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
                ? const LinearGradient(
                    colors: [AppColors.accentGreen, AppColors.accentBlue],
                  )
                : null,
            color: isActive ? null : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.transparent : AppColors.border,
              width: 2,
            ),
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

  // ── Step 0: Show QR & Wallet Address ─────────────────────────────────────
  Widget _buildStep0() {
    return Column(
      children: [
        // QR Code
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
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
          'Send USDT (BEP20) to this address',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        
        // Wallet Address with Copy
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
                      ? const Icon(Icons.check, color: AppColors.accentGreen, size: 18)
                      : const Icon(Icons.copy, color: AppColors.accentPurple, size: 18),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h),
        
        // Info Cards
        _buildInfoCard(
          Icons.info_outline,
          'Minimum Deposit',
          '\$${widget.minDeposit.toStringAsFixed(2)} USDT required',
          AppColors.accentOrange,
        ),
        SizedBox(height: 10.h),
        _buildInfoCard(
          Icons.network_check,
          'Network',
          'Only BSC (BEP20) supported',
          AppColors.accentRed,
        ),
        SizedBox(height: 10.h),
        _buildInfoCard(
          Icons.access_time,
          'Confirmations',
          '${widget.requiredConfirmations} blocks required',
          AppColors.accentGreen,
        ),
        SizedBox(height: 32.h),
        
        // Next Button
        GestureDetector(
          onTap: () => setState(() => _step = 1),
          child: Container(
            width: double.infinity,
            height: 56.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentGreen, AppColors.accentBlue],
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            alignment: Alignment.center,
            child: Text(
              "I've Sent USDT",
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  // ── Step 1: Enter TxHash & Verify ──────────────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Transaction Hash',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Paste the BEP20 transaction hash from your wallet to verify and credit your deposit.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13.sp,
            height: 1.5,
          ),
        ),
        SizedBox(height: 20.h),
        
        // How to find guide
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
                  const Icon(Icons.help_outline, color: AppColors.accentBlue, size: 20),
                  SizedBox(width: 8.w),
                  Text(
                    'How to find your txHash?',
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
                'Trust Wallet/Metamask: Activity → Tap transaction → Copy Transaction Hash',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        
        // TxHash Input Field
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: _errorMessage.isNotEmpty
                  ? AppColors.accentRed
                  : _txHashController.text.isNotEmpty
                      ? AppColors.accentGreen
                      : AppColors.border,
              width: _txHashController.text.isNotEmpty ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: _txHashController,
            style: GoogleFonts.spaceMono(
              color: AppColors.textPrimary,
              fontSize: 12.sp,
            ),
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '0x... (64 characters)',
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
                    _txHashController.text = data!.text!.trim();
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
                  child: const Icon(Icons.paste, color: AppColors.accentPurple, size: 20),
                ),
              ),
            ),
          ),
        ),
        
        // Pending Status
        if (_isPending && _currentConfirmations != null) ...[
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.accentOrange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.pending, color: AppColors.accentOrange, size: 18),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Pending: $_currentConfirmations/${widget.requiredConfirmations} confirmations. Please wait and verify again.',
                    style: GoogleFonts.inter(
                      color: AppColors.accentOrange,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Error Message
        if (_errorMessage.isNotEmpty) ...[
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
                const Icon(Icons.error_outline, color: AppColors.accentRed, size: 18),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    _errorMessage,
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
        
        // Verify Button
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
            ),
            alignment: Alignment.center,
            child: _verifying
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24.w,
                        height: 24.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Verifying on Blockchain...',
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
        
        // Back Button
        GestureDetector(
          onTap: () => setState(() {
            _step = 0;
            _errorMessage = '';
            _isPending = false;
            _currentConfirmations = null;
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

  Widget _buildInfoCard(IconData icon, String title, String subtitle, Color color) {
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
              child: Icon(icon, color: color, size: 20),
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
