// wallet_screen.dart
// Real Solana Deposit System — Reown auto transaction + manual verify

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
class AppColors {
  static const Color background   = Color(0xFF0D0D12);
  static const Color accentGreen  = Color(0xFF14F195);
  static const Color accentPurple = Color(0xFF9945FF);
  static const Color accentLeaf   = Color(0xFF76C442);
  static const Color blue         = Color(0xFF3B82F6);
  static const Color bgCard       = Color(0xFF1B1B22);
}

const String _baseUrl = 'https://web3.ltcminematrix.com';

// ─── Main Screen ──────────────────────────────────────────────────────────────
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {

  // State
  bool   _isLoading      = true;
  bool   _hasError       = false;
  String _platformWallet = '';
  double _solPrice       = 0;
  double _balance        = 0;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  String? _getToken() =>
      Provider.of<AuthProvider>(context, listen: false).token;

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_getToken()}',
  };

  // Load deposit info + history
  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final token = _getToken();
      if (token == null) { setState(() { _isLoading = false; _hasError = true; }); return; }

      // Deposit info
      final infoRes = await http.get(
        Uri.parse('$_baseUrl/api/deposit/info'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 15));

      // Mining status (balance এর জন্য)
      final statusRes = await http.get(
        Uri.parse('$_baseUrl/api/mining/status'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 15));

      // History
      final histRes = await http.get(
        Uri.parse('$_baseUrl/api/deposit/history'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (infoRes.statusCode == 200) {
        final info = jsonDecode(infoRes.body);
        _platformWallet = info['platformWallet'] ?? '';
        _solPrice       = double.tryParse(info['solPriceUSD']?.toString() ?? '0') ?? 0;
      }

      if (statusRes.statusCode == 200) {
        final status = jsonDecode(statusRes.body);
        _balance = double.tryParse(status['withdrawableUSD']?.toString() ?? '0') ?? 0;
      }

      if (histRes.statusCode == 200) {
        final h = jsonDecode(histRes.body);
        _history = List<Map<String, dynamic>>.from(h['deposits'] ?? []);
      }

      setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
          : _hasError
              ? _buildError()
              : RefreshIndicator(
                  color: AppColors.accentGreen,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: _loadAll,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      children: [
                        SizedBox(height: 20.h),
                        _buildBalanceCard(),
                        SizedBox(height: 20.h),
                        _buildDepositButton(),
                        SizedBox(height: 25.h),
                        _buildHistorySection(),
                        SizedBox(height: 100.h),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ─── Balance Card ────────────────────────────────────────────────────────────
  Widget _buildBalanceCard() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 180.h,
      borderRadius: 25.r,
      blur: 20,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.accentPurple.withOpacity(0.12),
          AppColors.accentGreen.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(colors: [
        AppColors.accentPurple.withOpacity(0.5),
        AppColors.accentGreen.withOpacity(0.2),
      ]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("WITHDRAWABLE BALANCE",
              style: GoogleFonts.inter(
                  color: Colors.white54, fontSize: 11.sp, letterSpacing: 1.5)),
          SizedBox(height: 10.h),
          Text("\$${_balance.toStringAsFixed(2)}",
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 34.sp,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 6.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.accentPurple.withOpacity(0.3)),
            ),
            child: Text(
              "1 SOL = \$${_solPrice.toStringAsFixed(2)}",
              style: GoogleFonts.inter(
                  color: AppColors.accentPurple,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  // ─── Deposit Button ──────────────────────────────────────────────────────────
  Widget _buildDepositButton() {
    return GestureDetector(
      onTap: () => _showDepositSheet(),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 62.h,
        borderRadius: 18.r,
        blur: 10,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(colors: [
          AppColors.accentGreen.withOpacity(0.18),
          AppColors.accentPurple.withOpacity(0.08),
        ]),
        borderGradient: LinearGradient(colors: [
          AppColors.accentGreen.withOpacity(0.6),
          AppColors.accentPurple.withOpacity(0.3),
        ]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [AppColors.accentPurple, AppColors.accentGreen]),
              ),
              child: Center(
                child: Text("◎",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(width: 10.w),
            Text("DEPOSIT SOL",
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
            SizedBox(width: 8.w),
            Icon(CupertinoIcons.chevron_right,
                color: AppColors.accentGreen, size: 16.sp),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  // ─── History Section ──────────────────────────────────────────────────────────
  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Deposit History",
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: _loadAll,
              child: Icon(CupertinoIcons.refresh,
                  color: AppColors.accentGreen, size: 18.sp),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        if (_history.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 30.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Column(children: [
              Icon(CupertinoIcons.tray,
                  color: Colors.white24, size: 32.sp),
              SizedBox(height: 8.h),
              Text("No deposits yet",
                  style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 13.sp)),
            ]),
          )
        else
          ...(_history.map((d) => _buildTxItem(d)).toList()),
      ],
    );
  }

  Widget _buildTxItem(Map<String, dynamic> d) {
    final sol    = double.tryParse(d['sol_amount']?.toString() ?? '0') ?? 0;
    final usd    = double.tryParse(d['usd_amount']?.toString() ?? '0') ?? 0;
    final status = d['status']?.toString() ?? 'pending';
    final sig    = d['tx_signature']?.toString() ?? '';
    final date   = d['created_at']?.toString().substring(0, 10) ?? '';

    Color statusColor;
    IconData statusIcon;
    if (status == 'confirmed') {
      statusColor = AppColors.accentGreen;
      statusIcon  = CupertinoIcons.checkmark_circle_fill;
    } else if (status == 'failed') {
      statusColor = Colors.redAccent;
      statusIcon  = CupertinoIcons.xmark_circle_fill;
    } else {
      statusColor = Colors.orange;
      statusIcon  = CupertinoIcons.clock_fill;
    }

    return GestureDetector(
      onTap: () {
        // Signature copy
        Clipboard.setData(ClipboardData(text: sig));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('TX hash copied!',
              style: GoogleFonts.inter(color: Colors.black)),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [AppColors.accentPurple, AppColors.accentGreen]),
              ),
              child: Center(
                child: Text("◎",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("SOL Deposit",
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp)),
                  SizedBox(height: 2.h),
                  Text(
                    "${sig.substring(0, 12)}...${sig.substring(sig.length - 6)}",
                    style: GoogleFonts.spaceMono(
                        color: Colors.white38, fontSize: 9.sp),
                  ),
                  SizedBox(height: 2.h),
                  Text(date,
                      style: GoogleFonts.inter(
                          color: Colors.white24, fontSize: 9.sp)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("+\$${usd.toStringAsFixed(2)}",
                    style: GoogleFonts.inter(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp)),
                SizedBox(height: 3.h),
                Text("${sol.toStringAsFixed(4)} SOL",
                    style: GoogleFonts.inter(
                        color: Colors.white54, fontSize: 10.sp)),
                SizedBox(height: 3.h),
                Row(children: [
                  Icon(statusIcon, color: statusColor, size: 10.sp),
                  SizedBox(width: 3.w),
                  Text(status,
                      style: GoogleFonts.inter(
                          color: statusColor, fontSize: 9.sp)),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error ────────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.cloud_off_rounded, color: Colors.white30, size: 48.sp),
        SizedBox(height: 12.h),
        Text("Could not load wallet data",
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14.sp)),
        SizedBox(height: 16.h),
        ElevatedButton.icon(
          onPressed: _loadAll,
          icon: const Icon(Icons.refresh_rounded, color: Colors.black),
          label: Text("Retry",
              style: GoogleFonts.inter(
                  color: Colors.black, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r)),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════ DEPOSIT BOTTOM SHEET ════════════════
  void _showDepositSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DepositSheet(
        platformWallet: _platformWallet,
        solPrice:       _solPrice,
        headers:        _headers(),
        onSuccess:      () {
          Navigator.pop(context);
          _loadAll();
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════ DEPOSIT SHEET ═══════════════════
class _DepositSheet extends StatefulWidget {
  final String platformWallet;
  final double solPrice;
  final Map<String, String> headers;
  final VoidCallback onSuccess;

  const _DepositSheet({
    required this.platformWallet,
    required this.solPrice,
    required this.headers,
    required this.onSuccess,
  });

  @override
  State<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<_DepositSheet> {
  // Steps: 0=address, 1=verify
  int _step = 0;

  final _sigController = TextEditingController();
  bool _verifying      = false;
  String _verifyError  = '';

  @override
  void dispose() {
    _sigController.dispose();
    super.dispose();
  }

  Future<void> _verifyDeposit() async {
    final sig = _sigController.text.trim();
    if (sig.length < 80) {
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
        _showSuccessDialog(data);
      } else {
        setState(() {
          _verifying   = false;
          _verifyError = data['error'] ?? 'Verification failed';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _verifying   = false;
          _verifyError = 'Connection error. Try again.';
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
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: GlassmorphicContainer(
            width: MediaQuery.of(ctx).size.width * 0.82,
            height: 300.h,
            borderRadius: 24.r,
            blur: 22,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(colors: [
              AppColors.accentGreen.withOpacity(0.12),
              Colors.black.withOpacity(0.8),
            ]),
            borderGradient: LinearGradient(colors: [
              AppColors.accentGreen.withOpacity(0.7),
              Colors.transparent,
            ]),
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.checkmark_seal_fill,
                      color: AppColors.accentGreen, size: 50.sp),
                  SizedBox(height: 14.h),
                  Text("Deposit Confirmed!",
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900)),
                  SizedBox(height: 10.h),
                  Text("+\$$usd USD",
                      style: GoogleFonts.inter(
                          color: AppColors.accentGreen,
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4.h),
                  Text("◎ $sol SOL deposited",
                      style: GoogleFonts.spaceMono(
                          color: AppColors.accentPurple, fontSize: 12.sp)),
                  SizedBox(height: 20.h),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onSuccess();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 46.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          AppColors.accentGreen,
                          AppColors.accentPurple,
                        ]),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      alignment: Alignment.center,
                      child: Text("Great!",
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F18),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border.all(color: AppColors.accentPurple.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Handle
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          SizedBox(height: 16.h),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [AppColors.accentPurple, AppColors.accentGreen]),
                  ),
                  child: Center(
                    child: Text("◎",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Deposit SOL",
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900)),
                    Text("1 SOL = \$${widget.solPrice.toStringAsFixed(2)}",
                        style: GoogleFonts.inter(
                            color: AppColors.accentPurple, fontSize: 10.sp)),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(CupertinoIcons.xmark_circle_fill,
                      color: Colors.white24, size: 24.sp),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Step indicator
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(children: [
              _stepDot(0, "Send SOL"),
              Expanded(child: Container(height: 1, color: Colors.white12)),
              _stepDot(1, "Verify"),
            ]),
          ),

          SizedBox(height: 20.h),

          // Content
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

  Widget _stepDot(int step, String label) {
    final active = _step >= step;
    return Column(children: [
      Container(
        width: 28.w,
        height: 28.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.accentGreen : Colors.white12,
        ),
        child: Center(
          child: Text("${step + 1}",
              style: GoogleFonts.inter(
                  color: active ? Colors.black : Colors.white38,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold)),
        ),
      ),
      SizedBox(height: 4.h),
      Text(label,
          style: GoogleFonts.inter(
              color: active ? AppColors.accentGreen : Colors.white38,
              fontSize: 9.sp)),
    ]);
  }

  // ── Step 0: Show Address + QR ─────────────────────────────────────────────
  Widget _buildStep0() {
    return Column(
      children: [
        // QR Code
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: QrImageView(
            data: widget.platformWallet,
            version: QrVersions.auto,
            size: 180.w,
            backgroundColor: Colors.white,
          ),
        ),

        SizedBox(height: 16.h),

        Text("Send SOL to this address",
            style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600)),

        SizedBox(height: 10.h),

        // Wallet address box
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: widget.platformWallet));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Address copied!',
                  style: GoogleFonts.inter(color: Colors.black)),
              backgroundColor: AppColors.accentGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ));
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.accentPurple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.platformWallet,
                    style: GoogleFonts.spaceMono(
                        color: Colors.white70, fontSize: 10.sp),
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(CupertinoIcons.doc_on_doc,
                    color: AppColors.accentPurple, size: 18.sp),
              ],
            ),
          ),
        ),

        SizedBox(height: 14.h),

        // Info boxes
        _infoBox(CupertinoIcons.info_circle,
            "Minimum deposit: 0.001 SOL", Colors.orange),
        SizedBox(height: 8.h),
        _infoBox(CupertinoIcons.exclamationmark_shield,
            "Only send SOL on Solana Mainnet", Colors.redAccent),
        SizedBox(height: 8.h),
        _infoBox(CupertinoIcons.clock,
            "Confirmation takes ~5–30 seconds", AppColors.accentGreen),

        SizedBox(height: 24.h),

        // Next button
        GestureDetector(
          onTap: () => setState(() => _step = 1),
          child: Container(
            width: double.infinity,
            height: 52.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.accentGreen, AppColors.accentPurple]),
              borderRadius: BorderRadius.circular(16.r),
            ),
            alignment: Alignment.center,
            child: Text("I've Sent SOL →",
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold)),
          ),
        ),

        SizedBox(height: 20.h),
      ],
    );
  }

  // ── Step 1: Enter TX Signature ────────────────────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Enter Transaction Signature",
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700)),
        SizedBox(height: 6.h),
        Text(
          "After sending SOL, copy the transaction hash from your wallet and paste below.",
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 11.sp),
        ),

        SizedBox(height: 16.h),

        // How to find TX hash
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.blue.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(CupertinoIcons.question_circle,
                    color: AppColors.blue, size: 14.sp),
                SizedBox(width: 6.w),
                Text("How to find TX hash?",
                    style: GoogleFonts.inter(
                        color: AppColors.blue,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700)),
              ]),
              SizedBox(height: 6.h),
              Text(
                "Phantom: Activity → tap transaction → Copy TX ID\nSolflare: History → tap transaction → Share icon",
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.sp),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // Input field
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: _verifyError.isNotEmpty
                  ? Colors.redAccent.withOpacity(0.5)
                  : AppColors.accentGreen.withOpacity(0.3),
            ),
          ),
          child: TextField(
            controller: _sigController,
            style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 11.sp),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Paste transaction signature here...',
              hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 11.sp),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14.w),
              suffixIcon: IconButton(
                icon: Icon(CupertinoIcons.doc_on_clipboard,
                    color: AppColors.accentGreen, size: 18.sp),
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    _sigController.text = data!.text!.trim();
                  }
                },
              ),
            ),
          ),
        ),

        if (_verifyError.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Row(children: [
            Icon(CupertinoIcons.xmark_circle,
                color: Colors.redAccent, size: 14.sp),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(_verifyError,
                  style: GoogleFonts.inter(
                      color: Colors.redAccent, fontSize: 11.sp)),
            ),
          ]),
        ],

        SizedBox(height: 20.h),

        // Verify button
        GestureDetector(
          onTap: _verifying ? null : _verifyDeposit,
          child: Container(
            width: double.infinity,
            height: 52.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.accentGreen.withOpacity(_verifying ? 0.5 : 1),
                AppColors.accentPurple.withOpacity(_verifying ? 0.5 : 1),
              ]),
              borderRadius: BorderRadius.circular(16.r),
            ),
            alignment: Alignment.center,
            child: _verifying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text("Verify & Credit Balance",
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold)),
          ),
        ),

        SizedBox(height: 12.h),

        // Back button
        GestureDetector(
          onTap: () => setState(() { _step = 0; _verifyError = ''; }),
          child: Container(
            width: double.infinity,
            height: 44.h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: Colors.white12),
            ),
            alignment: Alignment.center,
            child: Text("← Back",
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13.sp)),
          ),
        ),

        SizedBox(height: 30.h),
      ],
    );
  }

  Widget _infoBox(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 13.sp),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(text,
              style: GoogleFonts.inter(color: color, fontSize: 10.sp)),
        ),
      ]),
    );
  }
}
