import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../widgets/custom_error_widget.dart' hide AppColors;
import 'constants/mining_constants.dart';
import 'controllers/mining_controller.dart';
import 'widgets/mining_widgets.dart';
import 'dialogs/mining_dialogs.dart';

class MiningScreen extends StatefulWidget {
  const MiningScreen({super.key});
  @override
  State<MiningScreen> createState() => _MiningScreenState();
}

class _MiningScreenState extends State<MiningScreen>
    with TickerProviderStateMixin {

  late final MiningController _c;

  @override
  void initState() {
    super.initState();
    _c = MiningController(context: context, setState: setState);
    WidgetsBinding.instance.addPostFrameCallback((_) => _c.fetchStatus());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _handleClaimTap() {
    if (_c.dayStarted && _c.isMining) {
      showClaimDialog(context, _c, _executeClaim);
    } else {
      showClaimNotReadyDialog(context, _c);
    }
  }

  Future<void> _executeClaim() async {
    try {
      final data          = await _c.doClaim();
      final double prevW  = _c.withdrawableUSD;
      final double newW   = double.tryParse(data['withdrawable']?.toString() ?? '0') ?? 0.0;
      final double earned = _c.liveUSD;
      final double added  = (newW - prevW).clamp(0.0, double.infinity);
      final bool complete = (data['message'] ?? '')
          .toString().toLowerCase().contains('complete');

      await _c.fetchStatus();

      if (mounted) {
        showClaimSuccessDialog(
          context, _c,
          earnedUSD: earned,
          earnedSOL: _c.liveSOL,
          withdrawableAdded: added,
          totalWithdrawable: newW,
        );
        if (complete) {
          _showSnack('Cycle Complete!',
              '\$100 added to withdrawable!', AppColors.accentGreen, Colors.black);
        }
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.toLowerCase().contains('wait')) {
        _showSnack('Too Soon',
            'Wait at least 60 seconds between claims', Colors.orange, Colors.white);
      } else {
        _showSnack('Claim Failed', msg, Colors.red, Colors.white);
      }
    }
  }

  void _showSnack(String title, String msg, Color bg, Color textColor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$title\n$msg',
          style: GoogleFonts.inter(
              color: textColor, fontWeight: FontWeight.bold)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _c.isLoading
          ? _buildSkeletonLoading()
          : _c.hasError
              ? CustomErrorWidget(onRetry: _c.fetchStatus)
              : RefreshIndicator(
                  color: AppColors.accentGreen,
                  backgroundColor: AppColors.bgCard,
                  strokeWidth: 3,
                  onRefresh: _c.fetchStatus,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 20.h),
                              _buildHeader(),
                              SizedBox(height: 20.h),
                              _buildMiningOrb(),
                              SizedBox(height: 20.h),
                              _buildActionButtons(),
                              SizedBox(height: 24.h),
                              _buildStatsSection(),
                              SizedBox(height: 16.h),
                              _buildLiveEarningsCard(),
                              SizedBox(height: 12.h),
                              _buildSolanaCard(),
                              SizedBox(height: 12.h),
                              _buildCycleProgress(),
                              SizedBox(height: 12.h),
                              _buildAutoMiningCard(),
                              SizedBox(height: 12.h),
                              _buildBoostCard(),
                              SizedBox(height: 30.h),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Shimmer.fromColors(
      baseColor: AppColors.bgCard,
      highlightColor: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            SizedBox(height: 20.h),
            Container(
              width: double.infinity,
              height: 60.h,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            SizedBox(height: 20.h),
            Container(
              width: 200.w,
              height: 200.h,
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Container(
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            ...List.generate(5, (index) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Container(
                width: double.infinity,
                height: 80.h,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
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
              'Mining',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Tap orb to start earning',
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _c.fetchStatus,
          child: Container(
            width: 44.w,
            height: 44.h,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white24),
            ),
            child: Center(
              child: Icon(
                CupertinoIcons.refresh,
                color: AppColors.accentGreen,
                size: 20.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiningOrb() {
    final isPaused = _c.dayStarted && !_c.isMining;

    String orbLabel, orbSub = '';
    Color orbAccent;
    List<Color> borderColors;
    IconData iconData;

    if (_c.isMining && _c.boostActive) {
      orbLabel = "BOOSTED";
      orbSub = "MINING";
      orbAccent = AppColors.accentPurple;
      borderColors = [AppColors.accentPurple, AppColors.accentGreen];
      iconData = CupertinoIcons.rocket_fill;
    } else if (_c.isMining) {
      orbLabel = "MINING";
      orbAccent = AppColors.accentGreen;
      borderColors = [AppColors.accentGreen, AppColors.accentPurple];
      iconData = CupertinoIcons.bolt_fill;
    } else if (isPaused) {
      orbLabel = "PAUSED";
      orbSub = "Tap to resume";
      orbAccent = Colors.orange;
      borderColors = [Colors.orange, Colors.white24];
      iconData = CupertinoIcons.pause_fill;
    } else {
      orbLabel = "START";
      orbSub = "Tap to mine";
      orbAccent = Colors.white70;
      borderColors = [Colors.white54, Colors.white24];
      iconData = CupertinoIcons.power;
    }

    return Animate(
      target: _c.isMining ? 1.0 : 0.0,
      effects: [
        ScaleEffect(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.0, 1.0),
          duration: 600.ms,
          curve: Curves.easeOut,
        ),
      ],
      child: Center(
        child: GestureDetector(
          onTap: () async {
            try {
              await _c.toggleMining();
              if (_c.isMining) {
                _showSnack('Mining Started',
                    'Earn \$100 to complete a cycle!',
                    AppColors.accentGreen, Colors.black);
              }
            } catch (e) {
              _showSnack('Error',
                  e.toString().replaceFirst('Exception: ', ''),
                  Colors.red, Colors.white);
            }
          },
          child: Container(
            width: 180.w,
            height: 180.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.4),
                ],
              ),
              border: Border.all(
                color: borderColors[0],
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: orbAccent.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      iconData,
                      color: orbAccent,
                      size: 40.sp,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      orbLabel,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (orbSub.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        orbSub,
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                    if (_c.isMining) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: orbAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: orbAccent.withOpacity(0.4)),
                        ),
                        child: Text(
                          "+\$${_c.usdPerSec.toStringAsFixed(6)}/s",
                          style: GoogleFonts.spaceMono(
                            color: orbAccent,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Claim',
            AppColors.accentGreen,
            CupertinoIcons.money_dollar_circle_fill,
            _handleClaimTap,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildActionButton(
            'Refresh',
            Colors.blue,
            CupertinoIcons.refresh,
            _c.fetchStatus,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56.h,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white24),
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
            Icon(icon, color: color, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Speed", "\$${kBaseUsdPerSec.toStringAsFixed(6)}/s"),
          Container(width: 1, height: 40.h, color: Colors.white12),
          _buildStatItem("Multiplier", "${_c.boostMultiplier.toStringAsFixed(2)}x"),
          Container(width: 1, height: 40.h, color: Colors.white12),
          _buildStatItem("AI Boost", "${_c.aiMultiplier.toStringAsFixed(2)}x"),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white38,
            fontSize: 10.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            color: Colors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveEarningsCard() {
    return Animate(
      effects: [
        FadeEffect(duration: 400.ms),
        SlideEffect(begin: const Offset(0, 0.1), end: Offset.zero, duration: 400.ms),
      ],
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentGreen.withOpacity(0.15),
              AppColors.bgCard,
            ],
          ),
          border: Border.all(
            color: AppColors.accentGreen.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGreen.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.h,
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              "LIVE EARNINGS",
                              style: GoogleFonts.inter(
                                color: AppColors.accentGreen,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          "\$${_c.liveUSD.toStringAsFixed(4)}",
                          style: GoogleFonts.spaceMono(
                            color: Colors.white,
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Withdrawable",
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 10.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        "\$${_c.withdrawableUSD.toStringAsFixed(2)}",
                        style: GoogleFonts.spaceMono(
                          color: Colors.white70,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSolanaCard() {
    final bool active = _c.isMining;

    return Animate(
      effects: [
        FadeEffect(duration: 400.ms),
        SlideEffect(begin: const Offset(0, 0.1), end: Offset.zero, duration: 400.ms),
      ],
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: LinearGradient(
            colors: [
              AppColors.accentPurple.withOpacity(active ? 0.15 : 0.05),
              AppColors.bgCard,
            ],
          ),
          border: Border.all(
            color: AppColors.accentPurple.withOpacity(active ? 0.3 : 0.15),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.accentPurple, AppColors.accentGreen],
                  ),
                ),
                child: Icon(
                  CupertinoIcons.circle_fill,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SOLANA MINING",
                      style: GoogleFonts.inter(
                        color: AppColors.accentPurple,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "1 SOL = \$${_c.solPrice.toStringAsFixed(2)}",
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _c.formatSol(_c.liveSOL),
                    style: GoogleFonts.spaceMono(
                      color: active ? AppColors.accentGreen : Colors.white54,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  if (active)
                    Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          "Active",
                          style: GoogleFonts.inter(
                            color: AppColors.accentGreen,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      "Paused",
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 10.sp,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCycleProgress() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (_c.isMining) {
      statusText = "Mining";
      statusColor = AppColors.accentGreen;
      statusIcon = CupertinoIcons.arrow_up_circle_fill;
    } else if (_c.dayStarted) {
      statusText = "Paused";
      statusColor = Colors.orange;
      statusIcon = CupertinoIcons.pause_circle_fill;
    } else {
      statusText = "Start";
      statusColor = AppColors.accentPurple;
      statusIcon = CupertinoIcons.power;
    }

    return Animate(
      effects: [
        FadeEffect(duration: 400.ms),
        SlideEffect(begin: const Offset(0, 0.1), end: Offset.zero, duration: 400.ms),
      ],
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white10),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "CYCLE PROGRESS",
                    style: GoogleFonts.inter(
                      color: AppColors.accentGreen,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12.sp),
                      SizedBox(width: 4.w),
                      Text(
                        statusText,
                        style: GoogleFonts.inter(
                          color: statusColor,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: LinearProgressIndicator(
                  value: _c.cycleProgress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
                  minHeight: 8.h,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "\$${_c.liveUSD.toStringAsFixed(2)} / \$100",
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 11.sp,
                    ),
                  ),
                  Text(
                    "${(_c.cycleProgress * 100).toStringAsFixed(1)}%",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutoMiningCard() {
    final bool active = _c.autoMining;

    return Animate(
      effects: [
        FadeEffect(duration: 400.ms),
        SlideEffect(begin: const Offset(0, 0.1), end: Offset.zero, duration: 400.ms),
      ],
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: active
                ? AppColors.accentGreen.withOpacity(0.4)
                : Colors.white10,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? AppColors.accentGreen.withOpacity(0.2)
                      : Colors.white10,
                ),
                child: Icon(
                  active
                      ? CupertinoIcons.checkmark_shield_fill
                      : CupertinoIcons.shield,
                  color: active ? AppColors.accentGreen : Colors.white54,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active ? "AUTO MINING ON" : "AUTO MINING",
                      style: GoogleFonts.inter(
                        color: active ? AppColors.accentGreen : Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      active
                          ? "Auto-restarts every cycle"
                          : "One-time \$10 unlock",
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              if (!active)
                GestureDetector(
                  onTap: () => showBuyAutoMiningSheet(context, _c, _c.purchaseAutoMining),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentGreen, Color(0xFF00CC88)],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      "BUY \$10",
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 8.w,
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoostCard() {
    final bool maxed = _c.boostAmount >= 50;

    return Animate(
      effects: [
        FadeEffect(duration: 400.ms),
        SlideEffect(begin: const Offset(0, 0.1), end: Offset.zero, duration: 400.ms),
      ],
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.accentPurple.withOpacity(0.3)),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.rocket_fill,
                        color: AppColors.accentPurple,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "SPEED BOOST",
                        style: GoogleFonts.inter(
                          color: AppColors.accentPurple,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      "${_c.boostMultiplier.toStringAsFixed(2)}x",
                      style: GoogleFonts.spaceMono(
                        color: AppColors.accentPurple,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Invested: \$${_c.boostAmount.toStringAsFixed(0)}",
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 11.sp,
                    ),
                  ),
                  GestureDetector(
                    onTap: maxed
                        ? null
                        : () => showBuyBoostSheet(context, _c, _c.purchaseBoost),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        gradient: maxed
                            ? null
                            : const LinearGradient(
                                colors: [AppColors.accentPurple, Color(0xFFCC44FF)],
                              ),
                        color: maxed ? Colors.white10 : null,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        maxed ? "MAXED" : "+ BUY",
                        style: GoogleFonts.inter(
                          color: maxed ? Colors.white38 : Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
