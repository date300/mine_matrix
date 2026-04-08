import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../layout/layout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

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
      'price': '\$69,243.00',
      'change': '+3.92%',
      'isPositive': true,
      'icon': '₿',
      'color': Color(0xFFF7931A),
    },
    {
      'name': 'Ethereum',
      'symbol': 'ETH',
      'price': '\$2,134.62',
      'change': '+5.21%',
      'isPositive': true,
      'icon': 'Ξ',
      'color': Color(0xFF627EEA),
    },
    {
      'name': 'Voxel',
      'symbol': 'VXL',
      'price': '\$0.4821',
      'change': '+2.14%',
      'isPositive': true,
      'icon': 'V',
      'color': Color(0xFF00C896),
    },
    {
      'name': 'Solana',
      'symbol': 'SOL',
      'price': '\$142.30',
      'change': '-1.08%',
      'isPositive': false,
      'icon': 'S',
      'color': Color(0xFF9945FF),
    },
  ];

  final List<Map<String, dynamic>> _announcements = [
    {
      'user': '@511 BOITALO',
      'subtitle': '103 Users trading along',
      'message':
          'Welcome to FXDig.com, If you want to change something, start today.',
      'date': '2026-01-23 08:17:09',
      'timeAgo': '2M, 14D, 4H',
      'pinned': true,
    },
    {
      'user': '@Admin',
      'subtitle': '512 Users reading',
      'message':
          'Dear users, if you want, you can now purchase a package of any amount on New ID. We have provided a list of packages.',
      'date': '2026-03-27 03:29:21',
      'timeAgo': '10D, 8H',
      'pinned': false,
    },
    {
      'user': '@Support',
      'subtitle': '78 Users following',
      'message':
          'System maintenance scheduled for April 10, 2026. Please ensure your funds are secured.',
      'date': '2026-04-01 10:00:00',
      'timeAgo': '6D, 2H',
      'pinned': false,
    },
  ];

  // Simple sparkline path data
  List<Offset> _getSparklinePoints(bool isPositive, double width, double height) {
    if (isPositive) {
      return [
        Offset(0, height * 0.7),
        Offset(width * 0.2, height * 0.8),
        Offset(width * 0.4, height * 0.4),
        Offset(width * 0.6, height * 0.6),
        Offset(width * 0.8, height * 0.3),
        Offset(width, height * 0.1),
      ];
    } else {
      return [
        Offset(0, height * 0.2),
        Offset(width * 0.2, height * 0.3),
        Offset(width * 0.4, height * 0.5),
        Offset(width * 0.6, height * 0.4),
        Offset(width * 0.8, height * 0.7),
        Offset(width, height * 0.9),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),

            // ── Header ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dashboard',
                  style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn().slideX(),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                        color: AppColors.blue.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle,
                          color: AppColors.accentGreen, size: 8.sp),
                      SizedBox(width: 6.w),
                      Text(
                        'LIVE',
                        style: GoogleFonts.rajdhani(
                          color: AppColors.accentGreen,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),
              ],
            ),

            SizedBox(height: 24.h),

            // ── Top Coins ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Coins',
                  style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'View All',
                  style: GoogleFonts.rajdhani(
                    color: AppColors.blue,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 150.ms),

            SizedBox(height: 14.h),

            // Horizontal scrollable coin cards
            SizedBox(
              height: 148.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _coins.length,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (context, index) {
                  final coin = _coins[index];
                  return _buildCoinCard(coin, index)
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 200 + index * 100))
                      .slideX(begin: 0.2);
                },
              ),
            ),

            SizedBox(height: 28.h),

            // ── Feed Tabs ────────────────────────────────
            SingleChildScrollView(
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
                      padding: EdgeInsets.symmetric(
                          horizontal: 18.w, vertical: 9.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.blue.withOpacity(0.25)
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(22.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.blue.withOpacity(0.7)
                              : Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _tabs[index],
                        style: GoogleFonts.rajdhani(
                          color:
                              isSelected ? Colors.white : Colors.white54,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ).animate().fadeIn(delay: 350.ms),

            SizedBox(height: 16.h),

            // ── Announcement Feed ────────────────────────
            ..._buildFeedContent(),

            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }

  // ── Coin Card ──────────────────────────────────────────────────────────────
  Widget _buildCoinCard(Map<String, dynamic> coin, int index) {
    final isPositive = coin['isPositive'] as bool;
    final accentColor = coin['color'] as Color;
    final changeColor =
        isPositive ? AppColors.accentGreen : const Color(0xFFFF5252);

    return GlassmorphicContainer(
      width: 155.w,
      height: 148.h,
      borderRadius: 20.r,
      blur: 12,
      alignment: Alignment.topLeft,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentColor.withOpacity(0.10),
          Colors.white.withOpacity(0.03),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentColor.withOpacity(0.45),
          Colors.transparent,
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coin icon + arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: accentColor.withOpacity(0.4), width: 1),
                  ),
                  child: Center(
                    child: Text(
                      coin['icon'] as String,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Icon(
                  isPositive
                      ? Icons.north_east_rounded
                      : Icons.south_east_rounded,
                  color: changeColor,
                  size: 16.sp,
                ),
              ],
            ),

            SizedBox(height: 6.h),

            Text(
              coin['name'] as String,
              style: GoogleFonts.rajdhani(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              coin['symbol'] as String,
              style: GoogleFonts.rajdhani(
                color: Colors.white38,
                fontSize: 10.sp,
              ),
            ),

            const Spacer(),

            // Price
            Text(
              coin['price'] as String,
              style: GoogleFonts.rajdhani(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
              ),
            ),

            SizedBox(height: 4.h),

            // Change % + sparkline
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  coin['change'] as String,
                  style: GoogleFonts.rajdhani(
                    color: changeColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(
                  width: 50.w,
                  height: 22.h,
                  child: CustomPaint(
                    painter: _SparklinePainter(
                      points: _getSparklinePoints(isPositive, 50.w, 22.h),
                      color: changeColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Feed Content (tab-dependent) ──────────────────────────────────────────
  List<Widget> _buildFeedContent() {
    if (_selectedTab == 0) {
      // Announcements
      return _announcements.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return _buildAnnouncementItem(item, i)
            .animate()
            .fadeIn(delay: Duration(milliseconds: 100 * i))
            .slideY(begin: 0.1);
      }).toList();
    }

    // Placeholder for other tabs
    return [
      SizedBox(height: 40.h),
      Center(
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, color: Colors.white24, size: 48.sp),
            SizedBox(height: 12.h),
            Text(
              'Nothing here yet',
              style: GoogleFonts.rajdhani(
                color: Colors.white38,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(),
    ];
  }

  // ── Announcement Item ─────────────────────────────────────────────────────
  Widget _buildAnnouncementItem(Map<String, dynamic> item, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.r),
                topRight: Radius.circular(18.r),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.blue.withOpacity(0.6),
                        AppColors.accentGreen.withOpacity(0.4),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_rounded,
                      color: Colors.white70, size: 20.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['user'] as String,
                        style: GoogleFonts.rajdhani(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        item['subtitle'] as String,
                        style: GoogleFonts.rajdhani(
                          color: Colors.white38,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item['pinned'] == true)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                          color: AppColors.blue.withOpacity(0.4)),
                    ),
                    child: Text(
                      'Pinned',
                      style: GoogleFonts.rajdhani(
                        color: AppColors.blue,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Message body ──
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['message']}  – ${item['date']}',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12.sp,
                    height: 1.6,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  item['timeAgo'] as String,
                  style: GoogleFonts.rajdhani(
                    color: Colors.white30,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
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

// ── Sparkline Painter ─────────────────────────────────────────────────────────
class _SparklinePainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  _SparklinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpx = (prev.dx + curr.dx) / 2;
      path.cubicTo(cpx, prev.dy, cpx, curr.dy, curr.dx, curr.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.points != points || old.color != color;
}
