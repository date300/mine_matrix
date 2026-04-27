import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_error_widget.dart';

// --- Colors ------------------------------------------------------------------
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
  static const Color accentYellow = Color(0xFFF0B90B); // BNB Yellow
}

// Lottie Network URLs
class AppLottie {
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
  static const String wallet       = 'https://assets10.lottiefiles.com/packages/lf20_hu7birqV.json';
  static const String usdtCoin     = 'https://assets10.lottiefiles.com/packages/lf20_6wutsrox.json';
  static const String bnbCoin      = 'https://assets10.lottiefiles.com/packages/lf20_6wutsrox.json';
}

const String _baseUrl = 'https://web3.ltcminematrix.com';

// --- Models ------------------------------------------------------------------
class DepositInfo {
  final String platformWallet;
  final double minDeposit;
  final String network;
  final int requiredConfirmations;

  DepositInfo({
    required this.platformWallet,
    required this.minDeposit,
    required this.network,
    required this.requiredConfirmations,
  });

  factory DepositInfo.fromJson(Map<String, dynamic> json) {
    return DepositInfo(
      platformWallet: json['platformWallet'] ?? '',
      minDeposit: double.tryParse(json['minDeposit']?.toString() ?? '1') ?? 1.0,
      network: json['network'] ?? 'BEP20',
      requiredConfirmations: int.tryParse(json['requiredConfirmations']?.toString() ?? '12') ?? 12,
    );
  }
}

class MiningStatus {
  final double balance;
  final double withdrawable;

  MiningStatus({
    required this.balance,
    required this.withdrawable,
  });

  factory MiningStatus.fromJson(Map<String, dynamic> json) {
    return MiningStatus(
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0,
      withdrawable: double.tryParse(json['withdrawable']?.toString() ?? '0') ?? 0,
    );
  }
}

class TransactionItem {
  final String txHash;
  final double amount;
  final String network;
  final String status;
  final String? sender;
  final int? confirmations;
  final String? mode;
  final DateTime? date;
  final DateTime? approvedAt;
  final String? rejectedReason;

  TransactionItem({
    required this.txHash,
    required this.amount,
    required this.network,
    required this.status,
    this.sender,
    this.confirmations,
    this.mode,
    this.date,
    this.approvedAt,
    this.rejectedReason,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      txHash: json['txHash'] ?? json['tx_hash'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      network: json['network'] ?? 'BEP20',
      status: json['status'] ?? 'pending',
      sender: json['sender']?.toString(),
      confirmations: int.tryParse(json['confirmations']?.toString() ?? '0'),
      mode: json['mode'] ?? json['approval_mode'],
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      approvedAt: json['approvedAt'] != null ? DateTime.tryParse(json['approvedAt'].toString()) : null,
      rejectedReason: json['rejectedReason']?.toString(),
    );
  }
}

// --- Main Screen --------------------------------------------------------------
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with TickerProviderStateMixin {
  bool   _isLoading      = true;
  bool   _hasError       = false;
  bool   _isRefreshing   = false;

  DepositInfo? _depositInfo;
  MiningStatus? _miningStatus;
  double _displayBalance = 0;
  double _targetBalance  = 0;

  List<TransactionItem> _history = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;

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

    _balanceAnimation.addListener(() {
      if (mounted) {
        setState(() {
          _displayBalance = _targetBalance * _balanceAnimation.value;
        });
      }
    });

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
    _targetBalance = newValue;
    _balanceController.forward(from: 0);
  }

  Future<void> _loadAll({bool silent = false, int page = 1}) async {
    if (!silent) {
      setState(() { _isLoading = true; _hasError = false; });
    }

    try {
      final token = _getToken();
      if (token == null) { 
        setState(() { _isLoading = false; _hasError = true; }); 
        return; 
      }

      // Fetch deposit info and mining status in parallel
      final results = await Future.wait([
        http.get(Uri.parse('\$_baseUrl/api/deposit/info'), headers: _headers())
            .timeout(const Duration(seconds: 15)),
        http.get(Uri.parse('\$_baseUrl/api/mining/status'), headers: _headers())
            .timeout(const Duration(seconds: 15)),
      ]);

      if (!mounted) return;

      final infoRes = results[0];
      final statusRes = results[1];

      // Parse deposit info
      if (infoRes.statusCode == 200) {
        final info = jsonDecode(infoRes.body);
        _depositInfo = DepositInfo.fromJson(info);
      }

      // Parse mining status
      if (statusRes.statusCode == 200) {
        final status = jsonDecode(statusRes.body);
        _miningStatus = MiningStatus.fromJson(status);
        final newBalance = _miningStatus!.balance;
        if (_displayBalance != newBalance) {
          _animateBalance(newBalance);
        }
      }

      // Fetch history
      await _loadHistory(page: page, silent: true);

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

  Future<void> _loadHistory({required int page, bool silent = false}) async {
    if (_isLoadingMore) return;

    if (!silent) {
      setState(() => _isLoadingMore = true);
    }

    try {
      final res = await http.get(
        Uri.parse('\$_baseUrl/api/deposit/history?page=\$page&limit=10'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> deposits = data['data'] ?? data['deposits'] ?? [];
        final pagination = data['pagination'];

        final items = deposits.map((d) => TransactionItem.fromJson(d)).toList();

        setState(() {
          if (page == 1) {
            _history = items;
          } else {
            _history.addAll(items);
          }
          _currentPage = page;
          _totalPages = pagination?['totalPages'] ?? 1;
          _isLoadingMore = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        if (!silent) {
          _showErrorSnackBar('Failed to load history');
        }
      }
    }
  }

  Future<void> _loadMore() async {
    if (_currentPage < _totalPages && !_isLoadingMore) {
      await _loadHistory(page: _currentPage + 1);
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
    await _loadAll(silent: true, page: 1);
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
              'My Wallet',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Manage your USDT deposits',
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
            AppColors.accentYellow.withOpacity(0.3),
            AppColors.accentPurple.withOpacity(0.1),
            AppColors.surface,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(
          color: AppColors.accentYellow.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentYellow.withOpacity(0.15),
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
                            'LIVE',
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
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentYellow.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.accentYellow.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.currency_bitcoin,
                            color: AppColors.accentYellow,
                            size: 14,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'BEP20',
                            style: GoogleFonts.inter(
                              color: AppColors.accentYellow,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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
                if (_miningStatus != null)
                  Text(
                    'Withdrawable: \$${_miningStatus!.withdrawable.toStringAsFixed(2)}',
                    style: GoogleFonts.spaceMono(
                      color: AppColors.accentYellow,
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
            'Deposit',
            AppColors.accentGreen,
            AppLottie.usdtCoin,
            () => _showDepositSheet(),
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
    ).animate().fadeIn(delay: 200.ms).slideX(begin: label == 'Deposit' ? -0.2 : 0.2, end: 0);
  }

  Widget _buildHistoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Transactions',
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
    if (_history.isEmpty && !_isLoadingMore) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == _history.length) {
            if (_isLoadingMore) {
              return Padding(
                padding: EdgeInsets.all(16.w),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentGreen,
                    strokeWidth: 2,
                  ),
                ),
              );
            }
            if (_currentPage < _totalPages) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: GestureDetector(
                  onTap: _loadMore,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Load More',
                      style: GoogleFonts.inter(
                        color: AppColors.accentGreen,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }
            return SizedBox.shrink();
          }

          final item = _history[index];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
            child: _buildTransactionItem(item, index),
          );
        },
        childCount: _history.length + 1,
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
            'No transactions yet',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your deposit history will appear here',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 20.h),
          GestureDetector(
            onTap: () => _showDepositSheet(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
              ),
              child: Text(
                'Make First Deposit',
                style: GoogleFonts.inter(
                  color: AppColors.accentGreen,
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

  Widget _buildTransactionItem(TransactionItem item, int index) {
    final bool isSuccess = item.status == 'confirmed';
    final bool isFailed = item.status == 'rejected' || item.status == 'failed';
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
      statusText = 'Pending';
    }

    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: item.txHash));
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
                    'USDT Deposit',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatTxHash(item.txHash),
                    style: GoogleFonts.spaceMono(
                      color: AppColors.textMuted,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  if (item.mode != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: item.mode == 'auto' 
                            ? AppColors.accentBlue.withOpacity(0.15)
                            : AppColors.accentPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        item.mode!.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: item.mode == 'auto' 
                              ? AppColors.accentBlue 
                              : AppColors.accentPurple,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatDate(item.date),
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
                  '+\$${item.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    color: AppColors.accentGreen,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                if (item.confirmations != null)
                  Text(
                    '${item.confirmations} confs',
                    style: GoogleFonts.spaceMono(
                      color: AppColors.textSecondary,
                      fontSize: 10.sp,
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

  String _formatTxHash(String hash) {
    if (hash.length < 20) return hash;
    return '\${hash.substring(0, 10)}...\${hash.substring(hash.length - 8)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '\${date.day}/\${date.month}/\${date.year} • \${date.hour.toString().padLeft(2, '0')}:\${date.minute.toString().padLeft(2, '0')}';
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
              'Transaction hash copied!',
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

  void _showDepositSheet() {
    if (_depositInfo == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DepositSheet(
        depositInfo: _depositInfo!,
        headers: _headers(),
        onSuccess: () {
          Navigator.pop(context);
          _loadAll(silent: true, page: 1);
        },
      ),
    );
  }
}

// --- Deposit Sheet Widget ------------------------------------------------------
class DepositSheet extends StatefulWidget {
  final DepositInfo depositInfo;
  final Map<String, String> headers;
  final VoidCallback onSuccess;

  const DepositSheet({
    super.key,
    required this.depositInfo,
    required this.headers,
    required this.onSuccess,
  });

  @override
  State<DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<DepositSheet> with TickerProviderStateMixin {
  int _step = 0;
  final _txHashController = TextEditingController();
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
    _txHashController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _verifyDeposit() async {
    final txHash = _txHashController.text.trim();

    // Validate txHash format (0x + 64 hex chars)
    final txHashRegex = RegExp(r'^0x[a-fA-F0-9]{64}\$');
    if (!txHashRegex.hasMatch(txHash)) {
      setState(() => _verifyError = 'Invalid transaction hash format. Must be 0x + 64 hex characters.');
      return;
    }

    setState(() { _verifying = true; _verifyError = ''; });

    try {
      final res = await http.post(
        Uri.parse('\$_baseUrl/api/deposit/verify'),
        headers: widget.headers,
        body: jsonEncode({'txHash': txHash}),
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        setState(() => _verifying = false);
        _confettiController.forward();
        _showSuccessDialog(data);
      } else if (res.statusCode == 202) {
        // Pending confirmations
        setState(() {
          _verifying = false;
          _verifyError = 'Transaction pending. Confirmations: \${data['confirmations'] ?? 0}/\${data['required'] ?? 12}. Please wait and try again.';
        });
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
    final amount = data['amount']?.toString() ?? '0';
    final mode = data['mode']?.toString() ?? 'auto';
    final isManual = mode == 'manual';

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
                  border: Border.all(color: isManual ? AppColors.accentPurple.withOpacity(0.5) : AppColors.accentGreen.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: isManual ? AppColors.accentPurple.withOpacity(0.2) : AppColors.accentGreen.withOpacity(0.2),
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
                            isManual ? AppColors.accentPurple.withOpacity(0.2) : AppColors.accentGreen.withOpacity(0.2),
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
                              isManual ? AppLottie.info : AppLottie.txSuccess,
                              repeat: false,
                              controller: _confettiController,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            isManual ? 'Deposit Submitted!' : 'Deposit Successful!',
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
                            '+\\$\$amount',
                            style: GoogleFonts.inter(
                              color: isManual ? AppColors.accentPurple : AppColors.accentGreen,
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
                                child: Lottie.network(AppLottie.usdtCoin),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                isManual ? 'Pending admin approval' : 'USDT deposited',
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
                                  colors: isManual 
                                      ? [AppColors.accentPurple, AppColors.accentBlue]
                                      : [AppColors.accentGreen, AppColors.accentBlue],
                                ),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isManual ? 'Got it!' : 'Awesome!',
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
                    color: AppColors.accentYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.currency_bitcoin,
                      color: AppColors.accentYellow,
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
                        'Deposit USDT',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\${widget.depositInfo.network} Network',
                        style: GoogleFonts.inter(
                          color: AppColors.accentYellow,
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
                    '\${step + 1}',
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
                color: AppColors.accentYellow.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: QrImageView(
            data: widget.depositInfo.platformWallet,
            version: QrVersions.auto,
            size: 180.w,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          'Send USDT to this address',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: widget.depositInfo.platformWallet));
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
                    widget.depositInfo.platformWallet,
                    style: GoogleFonts.spaceMono(
                      color: AppColors.textPrimary,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: _copied
                        ? AppColors.accentGreen.withOpacity(0.2)
                        : AppColors.accentYellow.withOpacity(0.15),
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
          '\${widget.depositInfo.minDeposit.toStringAsFixed(2)} USDT required',
          AppColors.accentOrange,
        ),
        SizedBox(height: 10.h),
        _buildInfoCard(
          AppLottie.warning,
          'Network',
          'Only \${widget.depositInfo.network} (BSC)',
          AppColors.accentRed,
        ),
        SizedBox(height: 10.h),
        _buildInfoCard(
          AppLottie.secure,
          'Confirmations',
          '\${widget.depositInfo.requiredConfirmations} confirmations required',
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
                  "I've Sent USDT",
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
          'Enter Transaction Hash',
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
                    'How to find your transaction hash?',
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
                'MetaMask/Trust Wallet: Activity → Tap transaction → Copy Transaction Hash',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'BscScan: Search your wallet → Find the TX → Copy Hash',
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
              fontSize: 11.sp,
            ),
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Paste transaction hash here (0x...)',
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
                    color: AppColors.accentYellow.withOpacity(0.15),
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
