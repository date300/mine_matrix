import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_error_widget.dart';

// Reuse exact same Colors, Lottie URLs as ReferScreen
class AppColors {
  static const Color background    = Color(0xFF0A0A0F);
  static const Color surface       = Color(0xFF12121A);
  static const Color accentGreen   = Color(0xFF00FFA3);
  static const Color accentPurple  = Color(0xFFB829F7);
  static const Color accentBlue    = Color(0xFF00D4FF);
  static const Color accentOrange  = Color(0xFFFF9500);
  static const Color accentRed     = Color(0xFFFF4D4D);
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B8B9E);
  static const Color textMuted     = Color(0xFF4A4A5A);
  static const Color border        = Color(0xFF2A2A3A);
  static const Color cardBg        = Color(0xFF161620);
}

class AppLottie {
  static const String refresh      = 'https://assets10.lottiefiles.com/packages/lf20_7fwvvesa.json';
  static const String successAnim  = 'https://assets10.lottiefiles.com/packages/lf20_touohxv0.json';
  static const String coinSpin     = 'https://assets10.lottiefiles.com/packages/lf20_6wutsrox.json';
  static const String emptyHistory = 'https://assets10.lottiefiles.com/packages/lf20_s8pbrcfw.json';
  static const String withdrawAnim = 'https://assets10.lottiefiles.com/packages/lf20_i2eyxukf.json';
}

const String _baseUrl = 'https://web3.ltcminematrix.com';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen>
    with TickerProviderStateMixin {
  bool _isLoading    = true;
  bool _hasError     = false;
  bool _isRefreshing = false;
  bool _isSubmitting = false;

  // Balance & stats
  double _withdrawable = 0.0;
  double _totalWithdrawn = 0.0;
  int _pendingCount = 0;

  // Form
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _walletCtrl = TextEditingController();

  // History
  List<Map<String, dynamic>> _history = [];
  int _currentPage = 1;
  bool _hasMoreHistory = true;
  bool _loadingHistory = false;

  // Anim controller for balance digit roll
  late AnimationController _balanceCtrl;
  late Animation<double>   _balanceAnim;
  double _displayBalance = 0;

  @override
  void initState() {
    super.initState();
    _balanceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _balanceAnim = CurvedAnimation(
        parent: _balanceCtrl, curve: Curves.easeOutCubic);
    _balanceAnim.addListener(() {
      if (mounted) {
        setState(() => _displayBalance = _withdrawable * _balanceAnim.value);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _balanceCtrl.dispose();
    _amountCtrl.dispose();
    _walletCtrl.dispose();
    super.dispose();
  }

  String? _token() =>
      Provider.of<AuthProvider>(context, listen: false).token;

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_token()}',
      };

  // ─── DATA FETCH ────────────────────────
  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() { _isLoading = true; _hasError = false; });
    try {
      final statsRes = await http
          .get(Uri.parse('$_baseUrl/api/mining/stats'), headers: _headers())
          .timeout(const Duration(seconds: 15));
      final histRes = await http
          .get(Uri.parse('$_baseUrl/api/withdraw/history?page=1&limit=10'),
               headers: _headers())
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;
      if (statsRes.statusCode == 200 && histRes.statusCode == 200) {
        final statsData = jsonDecode(statsRes.body);
        final histData = jsonDecode(histRes.body);

        final newBalance = double.tryParse(
            statsData['withdrawable']?.toString() ?? '0') ?? 0.0;
        final newTotalWithdrawn = double.tryParse(
            statsData['totalWithdrawn']?.toString() ?? '0') ?? 0.0;
        final pending = int.tryParse(
            statsData['pendingCount']?.toString() ?? '0') ?? 0;

        // ✅ Fixed type casting
        final List<Map<String, dynamic>> rawHistory =
          (histData['data'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ?? [];

        setState(() {
          _withdrawable = newBalance;
          _totalWithdrawn = newTotalWithdrawn;
          _pendingCount = pending;
          _history = rawHistory;
          _isLoading = false;
          _currentPage = 1;
          _hasMoreHistory = rawHistory.length >= 10;
        });

        _balanceCtrl.forward(from: 0);
      } else {
        setState(() { _isLoading = false; _hasError = true; });
      }
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  Future<void> _loadMoreHistory() async {
    if (_loadingHistory || !_hasMoreHistory) return;
    setState(() => _loadingHistory = true);
    try {
      final nextPage = _currentPage + 1;
      final res = await http.get(
          Uri.parse('$_baseUrl/api/withdraw/history?page=$nextPage&limit=10'),
          headers: _headers());
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // ✅ Fixed type casting
        final List<Map<String, dynamic>> newItems =
          (data['data'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ?? [];

        setState(() {
          _history.addAll(newItems);
          _currentPage = nextPage;
          _hasMoreHistory = newItems.length >= 10;
        });
      }
    } catch (_) {}
    setState(() => _loadingHistory = false);
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await _load(silent: true);
    setState(() => _isRefreshing = false);
  }

  // ─── WITHDRAW REQUEST ─────────────────
  Future<void> _submitWithdraw() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text.trim());
    final wallet = _walletCtrl.text.trim();

    if (amount == null || amount <= 0) return;

    setState(() => _isSubmitting = true);

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/withdraw'),
        headers: _headers(),
        body: jsonEncode({'amount': amount, 'wallet': wallet}),
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;
      final body = jsonDecode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            SizedBox(width: 20.w, height: 20.h,
                child: Lottie.network(AppLottie.successAnim, repeat: false)),
            SizedBox(width: 10.w),
            Text('Withdraw request submitted!',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13.sp)),
          ]),
          backgroundColor: AppColors.accentGreen.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          margin: EdgeInsets.all(16.w),
          duration: const Duration(seconds: 2),
        ));
        _amountCtrl.clear();
        _walletCtrl.clear();
        await _load(silent: true);
      } else {
        final err = body['error'] ?? 'Withdraw failed';
        _showError(err);
      }
    } catch (e) {
      _showError('Network error. Please try again.');
    }
    setState(() => _isSubmitting = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(Icons.error_outline, color: Colors.white, size: 18.sp),
        SizedBox(width: 8.w),
        Expanded(child: Text(message,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13.sp))),
      ]),
      backgroundColor: AppColors.accentRed.withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      margin: EdgeInsets.all(16.w),
      duration: const Duration(seconds: 3),
    ));
  }

  // ─── BUILD ─────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? _skeleton()
          : _hasError
              ? CustomErrorWidget(onRetry: _load)
              : RefreshIndicator(
                  color: AppColors.accentGreen,
                  backgroundColor: AppColors.surface,
                  strokeWidth: 3,
                  onRefresh: _onRefresh,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 60.h),
                              _header(),
                              SizedBox(height: 24.h),
                              _balanceCard()
                                  .animate()
                                  .fadeIn(duration: 600.ms)
                                  .slideY(begin: 0.2, end: 0),
                              SizedBox(height: 24.h),
                              _sec('📤 Withdraw Funds'),
                              SizedBox(height: 12.h),
                              _withdrawFormCard()
                                  .animate().fadeIn(delay: 100.ms),
                              SizedBox(height: 24.h),
                              _sec('📋 Withdraw History'),
                              SizedBox(height: 12.h),
                              if (_history.isEmpty)
                                _emptyHistory()
                                    .animate().fadeIn(delay: 300.ms)
                              else ...[
                                ..._history.asMap().entries.map((e) =>
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 10.h),
                                      child: _historyItem(e.value)
                                          .animate()
                                          .fadeIn(delay: Duration(
                                              milliseconds: 300 + e.key * 60)),
                                    )),
                                if (_hasMoreHistory)
                                  Center(
                                    child: TextButton(
                                      onPressed: _loadingHistory ? null : _loadMoreHistory,
                                      child: _loadingHistory
                                          ? SizedBox(
                                              width: 20.w, height: 20.h,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation(
                                                      AppColors.accentGreen)))
                                          : Text('Load more',
                                              style: GoogleFonts.inter(
                                                  color: AppColors.accentGreen)),
                                    ),
                                  ).animate().fadeIn(),
                                SizedBox(height: 100.h),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // ─── SKELETON ─────────────────────────
  Widget _skeleton() => Shimmer.fromColors(
        baseColor: AppColors.surface,
        highlightColor: AppColors.cardBg.withOpacity(0.5),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(children: [
            SizedBox(height: 60.h),
            _skel(180.h),
            SizedBox(height: 20.h),
            _skel(220.h),
            SizedBox(height: 20.h),
            _skel(72.h),
            SizedBox(height: 12.h),
            _skel(72.h),
            SizedBox(height: 12.h),
            _skel(72.h),
          ]),
        ),
      );

  Widget _skel(double h) => Container(
      width: double.infinity, height: h,
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r)));

  // ─── HEADER ───────────────────────────
  Widget _header() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Withdraw',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 4.h),
            Text('Transfer your earnings',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 14.sp)),
          ]),
          GestureDetector(
            onTap: _isRefreshing ? null : _onRefresh,
            child: Container(
              width: 44.w, height: 44.h,
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.border)),
              child: Center(
                child: _isRefreshing
                    ? SizedBox(
                        width: 20.w, height: 20.h,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                                AppColors.accentGreen)))
                    : SizedBox(
                        width: 24.w, height: 24.h,
                        child: Lottie.network(AppLottie.refresh,
                            repeat: false)),
              ),
            ),
          ),
        ],
      );

  // ─── BALANCE CARD (glass) ────────────
  Widget _balanceCard() => AnimatedBuilder(
        animation: _balanceAnim,
        builder: (_, __) => Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accentBlue.withOpacity(0.2),
                AppColors.accentPurple.withOpacity(0.1),
                AppColors.surface,
              ],
            ),
            border: Border.all(color: AppColors.accentBlue.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                  color: AppColors.accentBlue.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text('WITHDRAWABLE',
                            style: GoogleFonts.inter(
                                color: AppColors.accentBlue,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                      ),
                      Spacer(),
                      Lottie.network(AppLottie.coinSpin,
                          width: 28.w, height: 28.h),
                    ]),
                    SizedBox(height: 16.h),
                    Text('Available Balance',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 14.sp)),
                    SizedBox(height: 8.h),
                    Text('\$${_displayBalance.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 38.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1)),
                    SizedBox(height: 8.h),
                    Row(children: [
                      _statChip('Withdrawn', '\$${_totalWithdrawn.toStringAsFixed(2)}',
                          AppColors.accentOrange),
                      SizedBox(width: 12.w),
                      _statChip('Pending', '$_pendingCount',
                          AppColors.accentPurple),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _statChip(String label, String value, Color color) => Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('$label: ',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 11.sp)),
          Text(value,
              style: GoogleFonts.inter(
                  color: color, fontSize: 12.sp, fontWeight: FontWeight.w600)),
        ]),
      );

  // ─── WITHDRAW FORM CARD ─────────────
  Widget _withdrawFormCard() => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Form(
          key: _formKey,
          child: Column(children: [
            // Amount field
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16.sp),
              decoration: InputDecoration(
                labelText: 'Amount (USD)',
                labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.monetization_on_rounded,
                    color: AppColors.accentGreen),
                filled: true,
                fillColor: AppColors.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.accentGreen, width: 1.5),
                ),
                hintText: 'Min \$5 | Max \$10,000',
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12.sp),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter amount';
                final amt = double.tryParse(v.trim());
                if (amt == null || amt <= 0) return 'Invalid amount';
                if (amt < 5) return 'Minimum \$5';
                if (amt > 10000) return 'Maximum \$10,000';
                if (amt > _withdrawable) return 'Insufficient balance';
                return null;
              },
            ),
            SizedBox(height: 16.h),
            // Wallet address field
            TextFormField(
              controller: _walletCtrl,
              style: GoogleFonts.spaceMono(color: AppColors.textPrimary, fontSize: 14.sp),
              decoration: InputDecoration(
                labelText: 'BEP20 Wallet Address',
                labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.account_balance_wallet_rounded,
                    color: AppColors.accentBlue),
                filled: true,
                fillColor: AppColors.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.accentBlue, width: 1.5),
                ),
                hintText: '0x... (40 hex chars)',
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12.sp),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter wallet address';
                if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(v.trim()))
                  return 'Invalid wallet format';
                return null;
              },
            ),
            SizedBox(height: 20.h),
            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitWithdraw,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 22.w, height: 22.h,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.network(AppLottie.withdrawAnim,
                              width: 24.w, height: 24.h),
                          SizedBox(width: 8.w),
                          Text('Withdraw Now',
                              style: GoogleFonts.inter(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold)),
                        ]),
              ),
            ),
          ]),
        ),
      );

  // ─── HISTORY ITEM ────────────────────
  Widget _historyItem(Map<String, dynamic> item) {
    final status = item['status'] ?? 'pending';
    final Color statusColor = status == 'approved'
        ? AppColors.accentGreen
        : status == 'rejected'
            ? AppColors.accentRed
            : AppColors.accentOrange;
    final String date = (item['created_at']?.toString() ?? '').length >= 16
        ? item['created_at'].toString().substring(0, 16)
        : (item['created_at']?.toString() ?? '');

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 44.w, height: 44.h,
          decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12.r)),
          alignment: Alignment.center,
          child: Icon(
            status == 'approved'
                ? Icons.check_circle_rounded
                : status == 'rejected'
                    ? Icons.cancel_rounded
                    : Icons.hourglass_bottom_rounded,
            color: statusColor,
            size: 22.sp,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('\$${item['amount'] ?? 0}',
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 3.h),
              Text(date,
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 11.sp)),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Text(status.toUpperCase(),
              style: GoogleFonts.inter(
                  color: statusColor,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _emptyHistory() => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30.h),
          child: Column(children: [
            Lottie.network(AppLottie.emptyHistory, width: 80.w, height: 80.h),
            SizedBox(height: 12.h),
            Text('No withdraw history yet',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 14.sp)),
          ]),
        ),
      );

  Widget _sec(String text) => Text(text,
      style: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 16.sp,
          fontWeight: FontWeight.bold));
}
