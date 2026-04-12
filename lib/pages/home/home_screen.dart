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

// Lottie URLs - শুধু যেখানে animation দরকার
class AppLottie {
  static const String refresh      = 'https://assets10.lottiefiles.com/packages/lf20_7fwvvesa.json';
  static const String emptyState   = 'https://assets10.lottiefiles.com/packages/lf20_s8pbrcfw.json';
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

  // Extended coins list - অনেকগুলো মার্কেট
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
    return Scaffold(
      backgroundColor: Colors.transparent, // TRANSPARENT BACKGROUND
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.surface,
              AppColors.background,
            ],
          ),
        ),
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
                        padding: EdgeInsets.symmetric(horizontal: 16.w), // ছোট padding
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 50.h), // কম height
                            _buildHeader(),
                            SizedBox(height: 16.h),
                            _buildLiveMarketSection(), // নতুন Live Market
                            SizedBox(height: 20.h),
                            _buildTabSelector(),
                            SizedBox(height: 12.h),
                          ],
                        ),
                      ),
                    ),
                    _buildFeedContent(),
                    SliverToBoxAdapter(
                      child: SizedBox(height: 80.h),
                    ),
                  ],
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
            SizedBox(height: 50.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 120.w,
                  height: 28.h,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                Container(
                  width: 44.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            // Live market skeleton
            Container(
              width: double.infinity,
              height: 120.h,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: List.generate(4, (index) => Container(
                width: 80.w,
                height: 32.h,
                margin: EdgeInsets.only(right: 8.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.r),
                ),
              )),
            ),
            SizedBox(height: 12.h),
            ...List.generate(3, (index) => Container(
              width: double.infinity,
              height: 100.h,
              margin: EdgeInsets.only(bottom: 10.h),
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

  // iOS স্টাইলে Header - Dashboard টাইটেল নেই
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // iOS স্টাইলে টাইটেল
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning', // Dashboard নেই, পরিবর্তে greeting
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'FXDig',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        // iOS স্টাইলে Refresh Button
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isRefreshing ? null : _onRefresh,
          child: Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            child: _isRefreshing
                ? Center(
                    child: CupertinoActivityIndicator(
                      color: AppColors.accentGreen,
                      radius: 10,
                    ),
                  )
                : Center(
                    child: Icon(
                      CupertinoIcons.refresh,
                      color: AppColors.accentGreen,
                      size: 20.sp,
                    ),
                  ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  // নতুন Live Market Section - কার্ড থেকে বের করে আনা হয়েছে
  Widget _buildLiveMarketSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Market Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Lottie শুধু Live indicator এ
                SizedBox(
                  width: 16.w,
                  height: 16.h,
                  child: Lottie.network(
                    AppLottie.livePulse,
                    repeat: true,
                  ),
                ),
                SizedBox(width: 6.w),
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
            // iOS স্টাইলে View All
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {},
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: GoogleFonts.inter(
                      color: AppColors.accentBlue,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: AppColors.accentBlue,
                    size: 14.sp,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        // Horizontal scrolling coins - iOS স্টাইলে
        SizedBox(
          height: 90.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _coins.length,
            separatorBuilder: (_, __) => SizedBox(width: 10.w),
            itemBuilder: (context, index) {
              final coin = _coins[index];
              return _buildCoinCard(coin, index);
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  // iOS স্টাইলে Coin Card - ছোট এবং সুন্দর
  Widget _buildCoinCard(Map<String, dynamic> coin, int index) {
    final isPositive = (coin['change'] as double) >= 0;
    final accentColor = coin['color'] as Color;
    final changeColor = isPositive ? AppColors.accentGreen : AppColors.accentRed;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {},
      child: Container(
        width: 130.w,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: accentColor.withOpacity(0.2),
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
                // Icon ব্যবহার (Lottie না)
                Container(
                  width: 28.w,
                  height: 28.h,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: Icon(
                      coin['icon'] as IconData,
                      color: accentColor,
                      size: 16.sp,
                    ),
                  ),
                ),
                // iOS স্টাইলে Change indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: changeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${(coin['change'] as double).toStringAsFixed(2)}%',
                    style: GoogleFonts.inter(
                      color: changeColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              coin['symbol'] as String,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '\$${(coin['price'] as double).toStringAsFixed(coin['price'] < 1 ? 4 : 2)}',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 + index * 50)).slideX(begin: 0.2, end: 0);
  }

  // iOS স্টাইলে Tab Selector
  Widget _buildTabSelector() {
    return Container(
      height: 36.h,
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final isSelected = _selectedTab == index;
            return Expanded(
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _selectedTab = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentBlue.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: Text(
                      _tabs[index],
                      style: GoogleFonts.inter(
                        color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
                        fontSize: 12.sp,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
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
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
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
          padding: EdgeInsets.symmetric(vertical: 50.h),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              // Lottie শুধু Empty state এ
              SizedBox(
                width: 100.w,
                height: 100.h,
                child: Lottie.network(AppLottie.emptyState),
              ),
              SizedBox(height: 16.h),
              Text(
                'No content yet',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Check back later for updates',
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

  // iOS স্টাইলে Announcement Item
  Widget _buildAnnouncementItem(Map<String, dynamic> item, int index) {
    final isPinned = item['pinned'] as bool;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {},
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isPinned ? AppColors.accentOrange.withOpacity(0.3) : AppColors.border.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPinned 
                          ? [AppColors.accentOrange, AppColors.accentRed]
                          : [AppColors.accentBlue, AppColors.accentPurple],
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: Text(
                      (item['user'] as String).substring(1, 2).toUpperCase(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item['user'] as String,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isPinned) ...[
                            SizedBox(width: 6.w),
                            // Lottie শুধু Pinned এ
                            SizedBox(
                              width: 14.w,
                              height: 14.h,
                              child: Lottie.network(AppLottie.pinned),
                            ),
                          ],
                        ],
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
                Text(
                  item['timeAgo'] as String,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              item['message'] as String,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13.sp,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 400 + index * 100)).slideY(begin: 0.2, end: 0);
  }
}
