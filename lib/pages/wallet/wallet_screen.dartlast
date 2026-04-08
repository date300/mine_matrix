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
import 'package:lottie/lottie.dart'; // Lottie প্যাকেজ
import '../../providers/auth_provider.dart';

// --- Colors ------------------------------------------------------------------
class AppColors {
  static const Color background   = Color(0xFF0D0D12);
  static const Color accentGreen  = Color(0xFF14F195);
  static const Color accentPurple = Color(0xFF9945FF);
  static const Color blue         = Color(0xFF3B82F6);
  static const Color bgCard       = Color(0xFF1B1B22);
}

// Lottie Network URLs (কোনো লোকাল ফাইলের দরকার নেই)
class AppLottie {
  // ডেমো হিসেবে পাবলিক লিংক ব্যবহার করা হয়েছে, আপনি চাইলে এগুলো পরিবর্তন করতে পারেন
  static const String solCoin      = 'https://lottie.host/9c336dc4-9a3c-41c3-88bc-2f9ec67bc94e/sS9t5j2N7V.json'; 
  static const String rightArrow   = 'https://lottie.host/f0a4f5f5-8d5f-4a0b-8d0f-48d6b8b0e8b1/O7D1zXW0A6.json'; 
  static const String refresh      = 'https://lottie.host/7e008d7c-bb2c-4a34-bb67-6cdcc81f7cb8/JkUqX2B2aP.json';      
  static const String emptyHistory = 'https://lottie.host/5b11c9f3-4c91-4e4b-97e3-0d33e5c98260/7M8T8U9Qh3.json';
  static const String txPending    = 'https://lottie.host/7e008d7c-bb2c-4a34-bb67-6cdcc81f7cb8/JkUqX2B2aP.json';   
  static const String txSuccess    = 'https://lottie.host/1b5cb1de-17f1-4b72-8821-2e6ecaf8eb3b/M8p4zO9j9X.json';   
  static const String txFailed     = 'https://lottie.host/6a51d9e2-632b-4530-ab0f-155e8fb8c335/Y9L2R0a7k5.json';    
  static const String errorCloud   = 'https://lottie.host/2a3e6807-6b45-4228-874e-5e3e117498c8/7P3oX0c2V9.json';  
  static const String copy         = 'https://lottie.host/d1f99c0a-0c7f-43b6-96b4-2b6b5536e2f1/K0M7Z8L3B5.json';         
  static const String info         = 'https://lottie.host/c5c1655b-4b24-4f81-a3f1-45a828e833b7/R8T5V0D2X3.json';         
  static const String warning      = 'https://lottie.host/a4387d70-388a-45c1-8409-5c1a8db8c04d/Q6P4S9F1W2.json';      
  static const String secure       = 'https://lottie.host/e2d27453-9a3d-4226-8968-3c3b018510f2/E2X7C9Z0N4.json';       
  static const String question     = 'https://lottie.host/b7e45293-61a8-4251-8720-379e9eb10a18/Z5B2V8M1L7.json';     
  static const String verifyLoading= 'https://lottie.host/80e922b9-e160-44ec-b44c-db7d4ffab1be/B201b1Q6dK.json';
}

const String _baseUrl = 'https://web3.ltcminematrix.com';

// --- Main Screen --------------------------------------------------------------
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

      // API Calls
      final infoRes = await http.get(Uri.parse('$_baseUrl/api/deposit/info'), headers: _headers()).timeout(const Duration(seconds: 15));
      final statusRes = await http.get(Uri.parse('$_baseUrl/api/mining/status'), headers: _headers()).timeout(const Duration(seconds: 15));
      final histRes = await http.get(Uri.parse('$_baseUrl/api/deposit/history'), headers: _headers()).timeout(const Duration(seconds: 15));

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
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? Center(child: Lottie.network(AppLottie.verifyLoading, width: 60.w)) // Lottie Network
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

  // --- Balance Card -------------------------------------------------------------
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

  // --- Deposit Button -----------------------------------------------------------
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
            SizedBox(
              width: 32.w,
              height: 32.w,
              child: Lottie.network(AppLottie.solCoin, repeat: true), // Lottie Network
            ),
            SizedBox(width: 10.w),
            Text("DEPOSIT SOL",
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
            SizedBox(width: 8.w),
            SizedBox(
              width: 18.w,
              height: 18.w,
              child: Lottie.network(AppLottie.rightArrow), // Lottie Network
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  // --- History Section -----------------------------------------------------------
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
              child: SizedBox(
                width: 20.w,
                height: 20.w,
                child: Lottie.network(AppLottie.refresh, repeat: false), // Lottie Network
              ),
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
              Lottie.network(AppLottie.emptyHistory, width: 80.w, height: 80.h), // Lottie Network
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

    String statusLottie;
    Color statusColor;
    
    if (status == 'confirmed') {
      statusColor = AppColors.accentGreen;
      statusLottie = AppLottie.txSuccess;
    } else if (status == 'failed') {
      statusColor = Colors.redAccent;
      statusLottie = AppLottie.txFailed;
    } else {
      statusColor = Colors.orange;
      statusLottie = AppLottie.txPending;
    }

    return GestureDetector(
      onTap: () {
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
            SizedBox(
              width: 40.w,
              height: 40.w,
              child: Lottie.network(AppLottie.solCoin), // Lottie Network
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
                    sig.length > 20 ? "${sig.substring(0, 12)}...${sig.substring(sig.length - 6)}" : sig,
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
                  SizedBox(
                    width: 12.w,
                    height: 12.w,
                    child: Lottie.network(statusLottie), // Lottie Network
                  ),
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

  // --- Error Widget -------------------------------------------------------------
  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Lottie.network(AppLottie.errorCloud, width: 100.w), // Lottie Network
        SizedBox(height: 12.h),
        Text("Could not load wallet data",
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14.sp)),
        SizedBox(height: 16.h),
        ElevatedButton.icon(
          onPressed: _loadAll,
          icon: SizedBox(width: 16.w, height: 16.w, child: Lottie.network(AppLottie.refresh)), // Lottie Network
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

  // --------------------------------------- DEPOSIT BOTTOM SHEET ----------------
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

// ------------------------------------------- DEPOSIT SHEET -------------------
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
  int _step = 0; // Steps: 0=address, 1=verify

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
            height: 320.h,
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
                  Lottie.network(AppLottie.txSuccess, width: 80.w, height: 80.h, repeat: false), // Lottie Network
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
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(width: 14.w, height: 14.w, child: Lottie.network(AppLottie.solCoin)), // Lottie Network
                    SizedBox(width: 4.w),
                    Text("$sol SOL deposited",
                      style: GoogleFonts.spaceMono(
                          color: AppColors.accentPurple, fontSize: 12.sp)),
                  ]),
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
        color: const Color(0xCC0F0F18), 
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
                SizedBox(
                  width: 36.w,
                  height: 36.w,
                  child: Lottie.network(AppLottie.solCoin), // Lottie Network
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
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white12),
                    child: const Icon(Icons.close, color: Colors.white54, size: 16),
                  ),
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

  // -- Step 0: Show Address + QR ------------------------------------------------
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
                SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: Lottie.network(AppLottie.copy), // Lottie Network
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 14.h),

        // Info boxes with Lottie
        _infoBox(AppLottie.info, "Minimum deposit: 0.001 SOL", Colors.orange),
        SizedBox(height: 8.h),
        _infoBox(AppLottie.warning, "Only send SOL on Solana Mainnet", Colors.redAccent),
        SizedBox(height: 8.h),
        _infoBox(AppLottie.secure, "Confirmation takes ~5-30 seconds", AppColors.accentGreen),

        SizedBox(height: 24.h),

        // Next button with arrow
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("I've Sent SOL",
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold)),
                SizedBox(width: 8.w),
                SizedBox(width: 16.w, height: 16.w, child: Lottie.network(AppLottie.rightArrow)), // Lottie Network
              ],
            ),
          ),
        ),

        SizedBox(height: 20.h),
      ],
    );
  }

  // -- Step 1: Enter TX Signature -----------------------------------------------
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
          "After sending SOL, copy the transaction hash (signature) from your wallet and paste below.",
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
                SizedBox(width: 14.w, height: 14.w, child: Lottie.network(AppLottie.question)), // Lottie Network
                SizedBox(width: 6.w),
                Text("How to find TX hash?",
                    style: GoogleFonts.inter(
                        color: AppColors.blue,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700)),
              ]),
              SizedBox(height: 6.h),
              Text(
                "Phantom/Solflare: Activity/History -> Tap transaction -> Copy Signature/ID",
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
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Paste transaction signature here...',
              hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 11.sp),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14.w),
              suffixIcon: GestureDetector(
                onTap: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    _sigController.text = data!.text!.trim();
                  }
                },
                child: UnconstrainedBox(
                  child: SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: Lottie.network(AppLottie.copy), // Lottie Network
                  ),
                ),
              ),
            ),
          ),
        ),

        if (_verifyError.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Row(children: [
            SizedBox(width: 14.w, height: 14.w, child: Lottie.network(AppLottie.txFailed)), // Lottie Network
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
                ? SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: Lottie.network(AppLottie.verifyLoading)) // Lottie Network
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.rotate(angle: 3.14159, 
                 child: SizedBox(width: 14.w, height: 14.w, child: Lottie.network(AppLottie.rightArrow, delegates: LottieDelegates(values: [ValueDelegate.colorFilter(['**'], value: const ColorFilter.mode(Colors.white54, BlendMode.srcIn))])))), // Lottie Network
                SizedBox(width: 6.w),
                Text("Back",
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 13.sp)),
              ],
            ),
          ),
        ),

        SizedBox(height: 30.h),
      ],
    );
  }

  Widget _infoBox(String lottieAsset, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        SizedBox(
          width: 14.w,
          height: 14.w,
          child: Lottie.network(lottieAsset), // Lottie Network
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(text,
              style: GoogleFonts.inter(color: color, fontSize: 10.sp)),
        ),
      ]),
    );
  }
}

