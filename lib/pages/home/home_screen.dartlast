import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

// --- Colors ----------------------------------------
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
  static const String livePulse    = 'https://assets10.lottiefiles.com/packages/lf20_b88nh30c.json';
  static const String pinned       = 'https://assets10.lottiefiles.com/packages/lf20_5njp3vgg.json';
}

// MAIN APP - ScreenUtilInit ????? wrap ???
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ScreenUtilInit ????? responsive ???
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'FXDig',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.transparent, // TRANSPARENT
            fontFamily: 'Inter',
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
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
    'News',
  ];

  final List<Map<String, dynamic>> _coins = [
    {
      'name': 'Bitcoin',
      'symbol': 'BTC',
      'price': 69243.00,
      'change': 3.92,
      'color': Color(0xFFF7931A),
      'icon': Icons.currency_bitcoin,
    },
    {
      'name': 'Ethereum',
      'symbol': 'ETH',
      'price': 2134.62,
      'change': 5.21,
      'color': Color(0xFF627EEA),
      'icon': Icons.token,
    },
    {
      'name': 'Voxel',
      'symbol': 'VXL',
      'price': 0.4821,
      'change': 2.14,
      'color': Color(0xFF00C896),
      'icon': Icons.view_in_ar,
    },
    {
      'name': 'Solana',
      'symbol': 'SOL',
      'price': 142.30,
      'change': -1.08,
      'color': Color(0xFF9945FF),
      'icon': Icons.flash_on,
    },
    {
      'name': 'Cardano',
      'symbol': 'ADA',
      'price': 0.5842,
      'change': 1.45,
      'color': Color(0xFF0033AD),
      'icon': Icons.waves,
    },
    {
      'name': 'Polkadot',
      'symbol': 'DOT',
      'price': 7.23,
      'change': -0.82,
      'color': Color(0xFFE6007A),
      'icon': Icons.circle,
    },
    {
      'name': 'Chainlink',
      'symbol': 'LINK',
      'price': 18.45,
      'change': 4.12,
      'color': Color(0xFF2A5ADA),
      'icon': Icons.link,
    },
    {
      'name': 'Avalanche',
      'symbol': 'AVAX',
      'price': 35.67,
      'change': 2.89,
      'color': Color(0xFFE84142),
      'icon': Icons.ac_unit,
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
    // TRULY TRANSPARENT BACKGROUND
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent, // FULL TRANSPARENT
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // SCAFFOLD TRANSPARENT
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Container(
          // Gradient background ??? ???
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.background,
                AppColors.surface,
                AppColors.background.withOpacity(0.95),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: _isLoading
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
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 12.h),
                                _buildHeader(),
                                SizedBox(height: 20.h),
                                _buildLiveMarketSection(),
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
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.cardBg.withOpacity(0.5),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Container(
              width: double.infinity,
              height: 100.h,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            SizedBox(height: 24.h),
            Container(
              height: 36.h,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            SizedBox(height: 16.h),
            ...List.generate(3, (index) => Container(
              width: double.infinity,
              height: 110.h,
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.r),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isRefreshing ? null : _onRefresh,
          child: Container(
            width: 44.w,
            height: 44.h,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: AppColors.border.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: _isRefreshing
                ? Center(
                    child: CupertinoActivityIndicator(
                      color: AppColors.accentGreen,
                      radius: 12.w,
                    ),
                  )
                : Center(
                    child: Icon(
                      CupertinoIcons.refresh,
                      color: AppColors.accentGreen,
                      size: 22.sp,
                    ),
                  ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildLiveMarketSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 18.w,
                  height: 18.h,
                  child: Lottie.network(
                    AppLottie.livePulse,
                    repeat: true,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Live Market',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: GoogleFonts.inter(
                      color: AppColors.accentBlue,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    color: AppColors.accentBlue,
                    size: 14.sp,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        SizedBox(
          height: 96.h,
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
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildCoinCard(Map<String, dynamic> coin, int index) {
    final isPositive = (coin['change'] as double) >= 0;
    final accentColor = coin['color'] as Color;
    final changeColor = isPositive ? AppColors.accentGreen : AppColors.accentRed;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {},
      child: Container(
        width: 140.w,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: accentColor.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32.w,
                  height: 32.h,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: Icon(
                      coin['icon'] as IconData,
                      color: accentColor,
                      size: 18.sp,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: changeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${(coin['change'] as double).toStringAsFixed(2)}%',
                    style: GoogleFonts.inter(
                      color: changeColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              coin['symbol'] as String,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '\$${(coin['price'] as double).toStringAsFixed(coin['price'] < 1 ? 4 : 2)}',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 + index * 60)).slideX(begin: 0.3, end: 0);
  }

  Widget _buildTabSelector() {
    return Container(
      height: 40.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.border.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentBlue.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                  border: isSelected ? Border.all(
                    color: AppColors.accentBlue.withOpacity(0.3),
                    width: 1,
                  ) : null,
                ),
                child: Center(
                  child: Text(
                    _tabs[index],
                    style: GoogleFonts.inter(
                      color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
                      fontSize: 12.sp,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
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
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              child: _buildAnnouncementItem(item, index),
            );
          },
          childCount: _announcements.length,
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 20.h),
          padding: EdgeInsets.symmetric(vertical: 60.h),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppColors.border.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120.w,
                height: 120.h,
                child: Lottie.network(AppLottie.emptyState),
              ),
              SizedBox(height: 20.h),
              Text(
                'No content yet',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Check back later for updates',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementItem(Map<String, dynamic> item, int index) {
    final isPinned = item['pinned'] as bool;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {},
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isPinned ? AppColors.accentOrange.withOpacity(0.25) : AppColors.border.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isPinned 
                          ? [AppColors.accentOrange, AppColors.accentRed]
                          : [AppColors.accentBlue, AppColors.accentPurple],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      (item['user'] as String).substring(1, 2).toUpperCase(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item['user'] as String,
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPinned) ...[
                            SizedBox(width: 8.w),
                            SizedBox(
                              width: 16.w,
                              height: 16.h,
                              child: Lottie.network(AppLottie.pinned),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        item['subtitle'] as String,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  item['timeAgo'] as String,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              item['message'] as String,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 400 + index * 100)).slideY(begin: 0.2, end: 0);
  }
}
