import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../layout/topbar.dart';

import '../../widgets/custom_error_widget.dart';

// --- Colors (WalletScreen থেকে একই) ----------------------------------------
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
  static const String refresh      = 'https://assets10.lottiefiles.com/packages/lf20_7fwvvesa.json';
  static const String emptyHistory = 'https://assets10.lottiefiles.com/packages/lf20_s8pbrcfw.json';
  static const String txPending    = 'https://assets10.lottiefiles.com/packages/lf20_b88nh30c.json';
  static const String txSuccess    = 'https://assets10.lottiefiles.com/packages/lf20_pqnfmkj9.json';
  static const String txFailed     = 'https://assets10.lottiefiles.com/packages/lf20_tl52xzvn.json';
  static const String errorCloud   = 'https://assets10.lottiefiles.com/packages/lf20_kcsr6fcp.json';
  static const String copy         = 'https://assets10.lottiefiles.com/packages/lf20_3s913D.json';
  static const String info         = 'https://assets10.lottiefiles.com/packages/lf20_b6cz19m8.json';
  static const String warning      = 'https://assets10.lottiefiles.com/packages/lf20_Tkwjw8.json';
  static const String secure       = 'https://assets10.lottiefiles.com/packages/lf20_5njp3vgg.json';
  static const String question     = 'https://assets10.lottiefiles.com/packages/lf20_w51pcehl.json';
  static const String verifyLoading= 'https://assets10.lottiefiles.com/packages/lf20_p8bfn5to.json';
  static const String arrowRight   = 'https://assets10.lottiefiles.com/packages/lf20_7z8wtyb0.json';
  static const String confetti     = 'https://assets10.lottiefiles.com/packages/lf20_u4yrau.json';
  static const String loadingSpinner='https://assets10.lottiefiles.com/packages/lf20_7fwvvesa.json';
  static const String coinSpin     = 'https://assets10.lottiefiles.com/packages/lf20_6wutsrox.json';
  static const String wallet       = 'https://assets10.lottiefiles.com/packages/lf20_hu7birqV.json';
  static const String send         = 'https://assets10.lottiefiles.com/packages/lf20_3rlc1l.json';
  static const String moneyOut     = 'https://assets10.lottiefiles.com/packages/lf20_qp1q7mct.json';
}

const String _baseUrl = 'https://web3.ltcminematrix.com';

// --- Withdraw Methods -------------------------------------------------------
class WithdrawMethod {
  final String name;
  final String symbol;
  final String iconUrl;
  final Color color;
  final double minAmount;
  final double fee;

  const WithdrawMethod({
    required this.name,
    required this.symbol,
    required this.iconUrl,
    required this.color,
    required this.minAmount,
    required this.fee,
  });
}

final List<WithdrawMethod> _withdrawMethods = [
  WithdrawMethod(
    name: 'Solana',
    symbol: 'SOL',
    iconUrl: AppLottie.solCoin,
    color: AppColors.accentPurple,
    minAmount: 0.01,
    fee: 0.001,
  ),
  WithdrawMethod(
    name: 'USDT',
    symbol: 'USDT',
    iconUrl: AppLottie.coinSpin,
    color: AppColors.accentGreen,
    minAmount: 10,
    fee: 1,
  ),
  WithdrawMethod(
    name: 'Bitcoin',
    symbol: 'BTC',
    iconUrl: AppLottie.coinSpin,
    color: Color(0xFFF7931A),
    minAmount: 0.001,
    fee: 0.0005,
  ),
];

// --- Main Screen --------------------------------------------------------------
class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> with TickerProviderStateMixin {
  bool   _isLoading      = true;
  bool   _hasError       = false;
  bool   _isRefreshing   = false;
  double _balance        = 0;
  double _displayBalance = 0;
  List<Map<String, dynamic>> _history = [];
  
  late AnimationController _balanceController;
  late Animation<double> _balanceAnimation;

  @override
  void initState() {
    super.initState();
    _balanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _balanceAnimation = CurvedAnimation(
      parent: _balanceController,
      curve: Curves.easeOutCubic,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  String? _getToken() =>
      Provider.of<AuthProvider>(context, listen: false).token;

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_getToken()}',
  };

  void _animateBalance(double newValue) {
    final double oldValue = _displayBalance;
    _balanceAnimation.addListener(() {
      if (mounted) {
        setState(() {
          _displayBalance = oldValue + (newValue - oldValue) * _balanceAnimation.value;
        });
      }
    });
    _balanceController.forward(from: 0);
  }

  Future<void> _loadAll({bool silent = false}) async {
    if (!silent) {
      setState(() { _isLoading = true; _hasError = false; });
    }
    
    try {
      final token = _getToken();
      if (token == null) { 
        setState(() { _isLoading = false; _hasError = true; }); 
        return; 
      }

      final results = await Future.wait([
        http.get(Uri.parse('$_baseUrl/api/mining/status'), headers: _headers())
            .timeout(const Duration(seconds: 15)),
        http.get(Uri.parse('$_baseUrl/api/withdraw/history'), headers: _headers())
            .timeout(const Duration(seconds: 15)),
      ]);

      if (!mounted) return;

      final statusRes = results[0];
      final histRes = results[1];

      if (statusRes.statusCode == 200) {
        final status = jsonDecode(statusRes.body);
        final newBalance = double.tryParse(status['withdrawableUSD']?.toString() ?? '0') ?? 0;
        if (_balance != newBalance) {
          _balance = newBalance;
          _animateBalance(newBalance);
        }
      }

      if (histRes.statusCode == 200) {
        final h = jsonDecode(histRes.body);
        _history = List<Map<String, dynamic>>.from(h['withdrawals'] ?? []);
      }

      setState(() => _isLoading = false);
    } on Exception catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _hasError = true; });
        String errorMsg = 'Connection error. Please retry.';
        if (e.toString().contains('timeout')) {
          errorMsg = 'Connection timeout. Please try again.';
        } else if (e.toString().contains('Socket') || e.toString().contains('Network')) {
          errorMsg = 'No internet connection.';
        }
        _showErrorSnackBar(errorMsg);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20.w,
              height: 20.h,
              child: Lottie.network(AppLottie.warning, repeat: false),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.accentRed.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadAll(silent: true);
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? _buildSkeletonLoading()
          : _hasError
              ? CustomErrorWidget(onRetry: _loadAll)
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
                              _buildHeader(),
                              SizedBox(height: 24.h),
                              _buildBalanceCard(),
                              SizedBox(height: 24.h),
                              _buildActionButtons(),
                              SizedBox(height: 32.h),
                              _buildHistoryHeader(),
                              SizedBox(height: 16.h),
                            ],
                          ),
                        ),
                      ),
                      _buildHistoryList(),
                      SliverToBoxAdapter(
                        child: SizedBox(height: 100.h),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.cardBg.withOpacity(0.5),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            SizedBox(height: 60.h),
            Container(
              width: double.infinity,
              height: 200.h,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 60.h,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Container(
                    height: 60.h,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),
            Container(
              width: 120.w,
              height: 24.h,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            SizedBox(height: 16.h),
            ...List.generate(3, (index) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Container(
                width: double.infinity,
                height: 80.h,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Withdraw',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Withdraw your earnings securely',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _isRefreshing ? null : _onRefresh,
          child: Container(
            width: 44.w,
            height: 44.h,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.border),
            ),
            child: _isRefreshing
                ? Center(
                    child: SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
                      ),
                    ),
                  )
                : Center(
                    child: SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: Lottie.network(
                        AppLottie.refresh,
                        repeat: false,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentRed.withOpacity(0.3),
            AppColors.accentOrange.withOpacity(0.1),
            AppColors.surface,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(
          color: AppColors.accentRed.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentRed.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.accentGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.w,
                            height: 6.h,
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'AVAILABLE',
                            style: GoogleFonts.inter(
                              color: AppColors.accentGreen,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: Lottie.network(AppLottie.wallet),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Withdrawable',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Text(
                  'Available Balance',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                AnimatedBuilder(
                  animation: _balanceAnimation,
                  builder: (context, child) {
                    return Text(
                      '\$${_displayBalance.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 40.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    );
                  },
                ),
                SizedBox(height: 8.h),
                Text(
                  'Ready to withdraw',
                  style: GoogleFonts.spaceMono(
                    color: AppColors.accentRed,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Withdraw Now',
            AppColors.accentRed,
            AppLottie.moneyOut,
            () => _showWithdrawSheet(),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildActionButton(
            'History',
            AppColors.accentBlue,
            AppLottie.wallet,
            () {},
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    Color color,
    String lottieUrl,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64.h,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28.w,
              height: 28.h,
              child: Lottie.network(lottieUrl),
            ),
            SizedBox(width: 10.w),
            Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: label == 'Withdraw Now' ? -0.2 : 0.2, end: 0);
  }

  Widget _buildHistoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Withdrawals',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_history.isNotEmpty)
          GestureDetector(
            onTap: () {},
            child: Text(
              'View All',
              style: GoogleFonts.inter(
                color: AppColors.accentGreen,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = _history[index];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
            child: _buildTransactionItem(item, index),
          );
        },
        childCount: _history.length,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 120.w,
            height: 120.h,
            child: Lottie.network(AppLottie.emptyHistory),
          ),
          SizedBox(height: 16.h),
          Text(
            'No withdrawals yet',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your withdrawal history will appear here',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 20.h),
          GestureDetector(
            onTap: () => _showWithdrawSheet(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.accentRed.withOpacity(0.3)),
              ),
              child: Text(
                'Make First Withdrawal',
                style: GoogleFonts.inter(
                  color: AppColors.accentRed,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> data, int index) {
    final amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0;
    final method = data['method']?.toString() ?? 'SOL';
    final status = data['status']?.toString() ?? 'pending';
    final address = data['address']?.toString() ?? '';
    final date = data['created_at']?.toString() ?? '';
    
    final bool isSuccess = status == 'completed';
    final bool isFailed = status == 'failed';
    final bool isPending = !isSuccess && !isFailed;

    Color statusColor;
    String statusLottie;
    String statusText;

    if (isSuccess) {
      statusColor = AppColors.accentGreen;
      statusLottie = AppLottie.txSuccess;
      statusText = 'Completed';
    } else if (isFailed) {
      statusColor = AppColors.accentRed;
      statusLottie = AppLottie.txFailed;
      statusText = 'Failed';
    } else {
      statusColor = AppColors.accentOrange;
      statusLottie = AppLottie.txPending;
      statusText = 'Processing';
    }

    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: address));
        _showCopiedSnackBar();
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: SizedBox(
                  width: 28.w,
                  height: 28.h,
                  child: Lottie.network(statusLottie, repeat: isPending),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$method Withdrawal',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatAddress(address),
                    style: GoogleFonts.spaceMono(
                      color: AppColors.textMuted,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatDate(date),
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-\$${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    color: AppColors.accentRed,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  method,
                  style: GoogleFonts.spaceMono(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.inter(
                      color: statusColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.2, end: 0);
  }

  String _formatAddress(String address) {
    if (address.length < 20) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 8)}';
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return '${dt.day}/${dt.month}/${dt.year} • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return date;
    }
  }

  void _showCopiedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20.w,
              height: 20.h,
              child: Lottie.network(AppLottie.copy, repeat: false),
            ),
            SizedBox(width: 10.w),
            Text(
              'Address copied!',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.accentGreen.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showWithdrawSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WithdrawSheet(
        balance: _balance,
        headers: _headers(),
        onSuccess: () {
          Navigator.pop(context);
          _loadAll(silent: true);
        },
      ),
    );
  }
}

// --- Withdraw Sheet Widget ---------------------------------------------------
class WithdrawSheet extends StatefulWidget {
  final double balance;
  final Map<String, String> headers;
  final VoidCallback onSuccess;

  const WithdrawSheet({
    super.key,
    required this.balance,
    required this.headers,
    required this.onSuccess,
  });

  @override
  State<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<WithdrawSheet> with TickerProviderStateMixin {
  int _step = 0;
  WithdrawMethod _selectedMethod = _withdrawMethods[0];
  final _amountController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isProcessing = false;
  String _errorMessage = '';
  
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
    _amountController.dispose();
    _addressController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _setMaxAmount() {
    final maxAmount = widget.balance - _selectedMethod.fee;
    if (maxAmount > 0) {
      _amountController.text = maxAmount.toStringAsFixed(4);
    }
  }

  void _validateAndProceed() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    
    if (amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }
    
    if (amount < _selectedMethod.minAmount) {
      setState(() => _errorMessage = 'Minimum withdrawal is ${_selectedMethod.minAmount} ${_selectedMethod.symbol}');
      return;
    }
    
    if (amount + _selectedMethod.fee > widget.balance) {
      setState(() => _errorMessage = 'Insufficient balance (including fee)');
      return;
    }
    
    if (_addressController.text.trim().length < 20) {
      setState(() => _errorMessage = 'Please enter a valid wallet address');
      return;
    }

    setState(() {
      _errorMessage = '';
      _step = 1;
    });
  }

  Future<void> _processWithdrawal() async {
    setState(() => _isProcessing = true);

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/withdraw/request'),
        headers: widget.headers,
        body: jsonEncode({
          'amount': double.parse(_amountController.text),
          'method': _selectedMethod.symbol,
          'address': _addressController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        setState(() => _isProcessing = false);
        _confettiController.forward();
        _showSuccessDialog(data);
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage = data['error'] ?? 'Withdrawal failed';
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = e.toString().contains('timeout') 
              ? 'Connection timeout. Try again.' 
              : 'Connection error. Try again.';
        });
      }
    }
  }

  void _showSuccessDialog(Map data) {
    final amount = data['amount']?.toString() ?? '0';
    final method = data['method']?.toString() ?? 'SOL';

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
                            'Withdrawal Submitted!',
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
                            '-\$$amount',
                            style: GoogleFonts.inter(
                              color: AppColors.accentRed,
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
                                '$method withdrawal processing',
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
                                'Got it!',
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
                    color: AppColors.accentRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 28.w,
                      height: 28.h,
                      child: Lottie.network(AppLottie.moneyOut),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Withdraw Funds',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Available: \$${widget.balance.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          color: AppColors.accentRed,
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
                _buildStepIndicator(0, 'Amount', Icons.account_balance_wallet),
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
                _buildStepIndicator(1, 'Confirm', Icons.check_circle),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Method',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        ..._withdrawMethods.map((method) => _buildMethodCard(method)),
        SizedBox(height: 24.h),
        Text(
          'Amount',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        _buildAmountInput(),
        SizedBox(height: 24.h),
        Text(
          'Wallet Address',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        _buildAddressInput(),
        if (_errorMessage.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _buildErrorMessage(),
        ],
        SizedBox(height: 32.h),
        GestureDetector(
          onTap: _validateAndProceed,
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
                  'Continue',
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

  Widget _buildMethodCard(WithdrawMethod method) {
    final bool isSelected = _selectedMethod.symbol == method.symbol;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? method.color.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? method.color.withOpacity(0.6) : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.h,
              decoration: BoxDecoration(
                color: method.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: Lottie.network(method.iconUrl),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Min: ${method.minAmount} ${method.symbol} • Fee: ${method.fee} ${method.symbol}',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24.w,
              height: 24.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? method.color : AppColors.textMuted,
                  width: 2,
                ),
                color: isSelected ? method.color : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.black, size: 14.sp)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _errorMessage.isNotEmpty && _amountController.text.isEmpty
              ? AppColors.accentRed
              : AppColors.border,
        ),
      ),
      child: TextField(
        controller: _amountController,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 16.sp,
        ),
        decoration: InputDecoration(
          hintText: '0.00',
          hintStyle: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 16.sp,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16.w),
          suffix: GestureDetector(
            onTap: _setMaxAmount,
            child: Container(
              margin: EdgeInsets.only(right: 16.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accentGreen, AppColors.accentBlue],
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'MAX',
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _errorMessage.isNotEmpty && _addressController.text.isEmpty
              ? AppColors.accentRed
              : AppColors.border,
        ),
      ),
      child: TextField(
        controller: _addressController,
        style: GoogleFonts.spaceMono(
          color: AppColors.textPrimary,
          fontSize: 13.sp,
        ),
        maxLines: 2,
        decoration: InputDecoration(
          hintText: 'Enter wallet address...',
          hintStyle: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 13.sp,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16.w),
          suffix: GestureDetector(
            onTap: () async {
              final data = await Clipboard.getData('text/plain');
              if (data?.text != null) {
                _addressController.text = data!.text!.trim();
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
    );
  }

  Widget _buildErrorMessage() {
    return Container(
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
            child: Lottie.network(AppLottie.warning, repeat: false),
          ),
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
    );
  }

  Widget _buildStep1() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final total = amount + _selectedMethod.fee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Withdrawal',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 24.h),
        _buildConfirmRow('Method', _selectedMethod.name),
        _buildConfirmRow('Amount', '\$${amount.toStringAsFixed(2)}'),
        _buildConfirmRow('Network Fee', '${_selectedMethod.fee} ${_selectedMethod.symbol}'),
        Divider(color: AppColors.border, height: 24.h),
        _buildConfirmRow('Total Deduction', '\$${total.toStringAsFixed(2)}', isTotal: true),
        SizedBox(height: 24.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.accentOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.accentOrange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20.w,
                height: 20.h,
                child: Lottie.network(AppLottie.warning),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Please verify the address. Transactions cannot be reversed.',
                  style: GoogleFonts.inter(
                    color: AppColors.accentOrange,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 32.h),
        GestureDetector(
          onTap: _isProcessing ? null : _processWithdrawal,
          child: Container(
            width: double.infinity,
            height: 56.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isProcessing
                    ? [AppColors.textMuted, AppColors.textMuted]
                    : [AppColors.accentRed, AppColors.accentOrange],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: _isProcessing
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.accentRed.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: _isProcessing
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
                        'Processing...',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Confirm Withdrawal',
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
            _errorMessage = '';
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

  Widget _buildConfirmRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14.sp,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: isTotal ? AppColors.accentRed : AppColors.textPrimary,
              fontSize: isTotal ? 16.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
