import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

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
  static const String refresh      = 'https://assets10.lottiefiles.com/packages/lf20_7fwvvesa.json';
  static const String emptyState   = 'https://assets10.lottiefiles.com/packages/lf20_s8pbrcfw.json';
  static const String coinSpin     = 'https://assets10.lottiefiles.com/packages/lf20_6wutsrox.json';
  static const String chartUp      = 'https://assets10.lottiefiles.com/packages/lf20_qp1q7mct.json';
  static const String notification = 'https://assets10.lottiefiles.com/packages/lf20_3rlc1l.json';
  static const String livePulse    = 'https://assets10.lottiefiles.com/packages/lf20_b88nh30c.json';
  static const String pinned       = 'https://assets10.lottiefiles.com/packages/lf20_5njp3vgg.json';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedTab = 0;
  bool _isLoading = true;
  bool _isRefreshing = false;

  final List<String> _tabs = [
    'Announcements',
    'Discover',
    'News',
    'Following',
  ];

  final List<Map<String, dynamic>> _coins = [
    {
      'name': 'Bitcoin',
      'symbol': 'BTC',
      'price': 69243.00,
      'change': 3.92,
      'color': Color(0xFFF7931A),
      'lottie': AppLottie.coinSpin,
    },
    {
      'name': 'Ethereum',
      'symbol': 'ETH',
      'price': 2134.62,
      'change': 5.21,
      'color': Color(0xFF627EEA),
      'lottie': AppLottie.coinSpin,
    },
    {
      'name': 'Voxel',
      'symbol': 'VXL',
      'price': 0.4821,
      'change': 2.14,
      'color': Color(0xFF00C896),
      'lottie': AppLottie.coinSpin,
    },
    {
      'name': 'Solana',
      'symbol': 'SOL',
      'price': 142.30,
      'change': -1.08,
      'color': Color(0xFF9945FF),
      'lottie': AppLottie.coinSpin,
    },
  ];

  final List<Map<String, dynamic>> _announcements = [
    {
      'user': '@511 BOITALO',
      'subtitle': '103 Users trading along',
      'message': 'Welcome to FXDig.com, If you want to change something, start today.',
      'date': '2026-01-23 08:17:09',
      'timeAgo': '2M, 14D, 4H',
      'pinned': true,
    },
    {
      'user': '@Admin',
      'subtitle': '512 Users reading',
      'message': 'Dear users, if you want, you can now purchase a package of any amount on New ID. We have provided a list of packages.',
      'date': '2026-03-27 03:29:21',
      'timeAgo': '10D, 8H',
      'pinned': false,
    },
    {
      'user': '@Support',
      'subtitle': '78 Users following',
      'message': 'System maintenance scheduled for April 10, 2026. Please ensure your funds are secured.',
      'date': '2026-04-01 10:00:00',
      'timeAgo': '6D, 2H',
      'pinned': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Simulate loading
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? _buildSkeletonLoading()
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
                          _buildTopCoinsCard(),
                          SizedBox(height: 24.h),
                          _buildTabSelector(),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
                  ),
                  _buildFeedContent(),
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
            // Header skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 150.w,
                  height: 32.h,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                Container(
                  width: 60.w,
                  height: 32.h,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            // Coins card skeleton
            Container(
              width: double.infinity,
              height: 180.h,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
            SizedBox(height: 24.h),
            // Tabs skeleton
            Row(
              children: List.generate(4, (index) => Container(
                width: 80.w,
                height: 36.h,
                margin: EdgeInsets.only(right: 10.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22.r),
                ),
              )),
            ),
            SizedBox(height: 16.h),
            // Announcements skeleton
            ...List.generate(3, (index) => Container(
              width: double.infinity,
              height: 120.h,
              margin: EdgeInsets.only(bottom: 14.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18.r),
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
              'Dashboard',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Track your crypto portfolio',
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
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildTopCoinsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentBlue.withOpacity(0.3),
            AppColors.accentPurple.withOpacity(0.1),
            AppColors.surface,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(
          color: AppColors.accentBlue.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentBlue.withOpacity(0.2),
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
            padding: EdgeInsets.all(20.w),
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
                            'LIVE MARKET',
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
                          child: Lottie.network(AppLottie.chartUp),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Top Gainers',
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
                SizedBox(
                  height: 100.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _coins.length,
                    separatorBuilder: (_, __) => SizedBox(width: 12.w),
                    itemBuilder: (context, index) {
                      final coin = _coins[index];
                      return _buildCoinCard(coin, index);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildCoinCard(Map<String, dynamic> coin, int index) {
    final isPositive = (coin['change'] as double) >= 0;
    final accentColor = coin['color'] as Color;
    final changeColor = isPositive ? AppColors.accentGreen : AppColors.accentRed;

    return Container(
      width: 140.w,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 18.w,
                    height: 18.h,
                    child: Lottie.network(coin['lottie'] as String),
                  ),
                ),
              ),
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: changeColor,
                size: 16.sp,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            coin['name'] as String,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            coin['symbol'] as String,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 10.sp,
            ),
          ),
          const Spacer(),
          Text(
            '\$${(coin['price'] as double).toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '${isPositive ? '+' : ''}${(coin['change'] as double).toStringAsFixed(2)}%',
            style: GoogleFonts.inter(
              color: changeColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 200 + index * 100)).slideX(begin: 0.2, end: 0);
  }

  Widget _buildTabSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(right: 10.w),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [AppColors.accentBlue, AppColors.accentPurple],
                      )
                    : null,
                color: isSelected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.border,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.accentBlue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                _tabs[index],
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.black : AppColors.textSecondary,
                  fontSize: 13.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildFeedContent() {
    if (_selectedTab == 0) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = _announcements[index];
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
              child: _buildAnnouncementItem(item, index),
            );
          },
          childCount: _announcements.length,
        ),
      );
    }

    // Empty state for other tabs
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 60.h),
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
                child: Lottie.network(AppLottie.emptyState),
              ),
              SizedBox(height: 16.h),
              Text(
                'Nothing here yet',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Content will appear here soon',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementItem(Map<String, dynamic> item, int index) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: AppColors.cardBg.withOpacity(0.5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.r),
                topRight: Radius.circular(18.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentBlue.withOpacity(0.6),
                        AppColors.accentGreen.withOpacity(0.4),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.textPrimary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['user'] as String,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        item['subtitle'] as String,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item['pinned'] == true)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.accentOrange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12.w,
                          height: 12.h,
                          child: Lottie.network(AppLottie.pinned),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Pinned',
                          style: GoogleFonts.inter(
                            color: AppColors.accentOrange,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['message'] as String,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                    height: 1.6,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: AppColors.textMuted,
                      size: 12.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '${item['date']} • ${item['timeAgo']}',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.2, end: 0);
  }
}
