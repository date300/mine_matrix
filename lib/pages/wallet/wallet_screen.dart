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
import '../../widgets/error_screen.dart';

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
}

const String _baseUrl = 'https://web3.ltcminematrix.com';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with TickerProviderStateMixin {
  bool   _isLoading      = true;
  bool   _hasError       = false;
  bool   _isRefreshing   = false;
  String _platformWallet = '';
  double _solPrice       = 0;
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
        http.get(Uri.parse('$_baseUrl/api/deposit/info'), headers: _headers())
            .timeout(const Duration(seconds: 15)),
        http.get(Uri.parse('$_baseUrl/api/mining/status'), headers: _headers())
            .timeout(const Duration(seconds: 15)),
        http.get(Uri.parse('$_baseUrl/api/deposit/history'), headers: _headers())
            .timeout(const Duration(seconds: 15)),
      ]);

      if (!mounted) return;

      final infoRes = results[0];
      final statusRes = results[1];
      final histRes = results[2];

      if (infoRes.statusCode == 200) {
        final info = jsonDecode(infoRes.body);
        _platformWallet = info['platformWallet'] ?? '';
        _solPrice = double.tryParse(info['solPriceUSD']?.toString() ?? '0') ?? 0;
      }

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
        _history = List<Map<String, dynamic>>.from(h['deposits'] ?? []);
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
              ? ErrorScreen.oops(
                  subtitle: 'Failed to load wallet data',
                  onRetry: () => _loadAll(),
                )
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
              'Manage your SOL deposits',
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
            AppColors.accentPurple.withOpacity(0.3),
            AppColors.accentBlue.withOpacity(0.1),
            AppColors.surface,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(
          color: AppColors.accentPurple.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withOpacity(0.2),
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
                    Row(
                      children: [
                        SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: Lottie.network(AppLottie.solCoin),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '\$${_solPrice.toStringAsFixed(2)}',
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
                  '${(_displayBalance / (_solPrice > 0 ? _solPrice : 1)).toStringAsFixed(4)} SOL',
                  style: GoogleFonts.spaceMono(
                    color: AppColors.accentPurple,
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
            AppLottie.coinSpin,
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
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildHistoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Deposits',
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
              'See All',
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 40.h),
              SizedBox(
                width: 150.w,
                height: 150.h,
                child: Lottie.network(AppLottie.emptyHistory),
              ),
              SizedBox(height: 20.h),
              Text(
                'No deposits yet',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Your deposit history will appear here',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final tx = _history[index];
          return _buildHistoryItem(tx, index);
        },
        childCount: _history.length,
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> tx, int index) {
    final status = tx['status']?.toString().toLowerCase() ?? 'pending';
    final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
    final timestamp = tx['createdAt'] ?? DateTime.now().toIso8601String();
    
    Color statusColor;
    String statusText;
    String lottieAsset;

    switch (status) {
      case 'completed':
      case 'success':
        statusColor = AppColors.accentGreen;
        statusText = 'Completed';
        lottieAsset = AppLottie.txSuccess;
        break;
      case 'failed':
      case 'error':
        statusColor = AppColors.accentRed;
        statusText = 'Failed';
        lottieAsset = AppLottie.txFailed;
        break;
      case 'pending':
      default:
        statusColor = AppColors.accentOrange;
        statusText = 'Pending';
        lottieAsset = AppLottie.txPending;
        break;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: SizedBox(
                  width: 28.w,
                  height: 28.h,
                  child: Lottie.network(lottieAsset),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${amount.toStringAsFixed(4)} SOL',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatDate(timestamp),
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                statusText,
                style: GoogleFonts.inter(
                  color: statusColor,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 100).ms).slideX(begin: 0.2, end: 0);
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }

  void _showDepositSheet() {
    if (_platformWallet.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildDepositSheet(),
    );
  }

  Widget _buildDepositSheet() {
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                Text(
                  'Deposit SOL',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Send SOL to this address',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 24.h),
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: QrImageView(
                    data: _platformWallet,
                    version: QrVersions.auto,
                    size: 180.w,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _platformWallet,
                          style: GoogleFonts.spaceMono(
                            color: AppColors.textPrimary,
                            fontSize: 12.sp,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _platformWallet));
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
                                    style: GoogleFonts.inter(color: Colors.white),
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
                        },
                        child: Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.copy_rounded,
                            color: AppColors.accentGreen,
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(12.w),
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
                          'Only send SOL to this address. Other tokens will be lost.',
                          style: GoogleFonts.inter(
                            color: AppColors.accentOrange,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    height: 52.h,
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        'Close',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
