import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_background/animated_background.dart';
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
          _showSnack('✅ Cycle Complete!',
              '\$100 added to withdrawable!', AppColors.accentGreen, Colors.black);
        }
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.toLowerCase().contains('wait')) {
        _showSnack('⏱️ Too Soon',
            'Wait at least 60 seconds between claims', Colors.orange, Colors.white);
      } else {
        _showSnack('❌ Claim Failed', msg, Colors.red, Colors.white);
      }
    }
  }

  void _showSnack(String title, String msg, Color bg, Color textColor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$title  $msg',
          style: GoogleFonts.inter(
              color: textColor, fontWeight: FontWeight.bold)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // ✅ স্ক্রিন সাইজ ক্যালকুলেশন
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    
    // SafeArea padding
    final EdgeInsets safeArea = MediaQuery.of(context).padding;
    final double topSafe = safeArea.top;
    final double bottomSafe = safeArea.bottom;
    
    // ✅ Fixed heights (আপনার AppLayout অনুযায়ী)
    const double topBarHeight = 56.0;      // TopBar height
    const double bottomNavHeight = 80.0;   // FloatingBottomNav height
    
    // ✅ পেজের নেট উপলব্ধ সাইজ
    final double pageWidth = screenWidth;
    final double pageHeight = screenHeight - topBarHeight - bottomNavHeight - topSafe;
    
    // ✅ Responsive breakpoints
    final bool isSmallScreen = screenHeight < 700;
    final bool isLargeScreen = screenHeight > 850;
    
    // ✅ Dynamic spacing
    final double orbSize = isSmallScreen ? 180.w : (isLargeScreen ? 220.w : 200.w);
    final double sectionSpacing = isSmallScreen ? 8.h : (isLargeScreen ? 16.h : 12.h);
    final double cardPadding = isSmallScreen ? 12.w : 16.w;

    return Scaffold(
      backgroundColor: Colors.transparent, // ✅ AppLayout background দেখাবে
      body: SizedBox(
        width: pageWidth,
        height: pageHeight,
        child: Stack(
          children: [
            // Particle background
            AnimatedBackground(
              vsync: this,
              behaviour: RandomParticleBehaviour(
                options: const ParticleOptions(
                  baseColor: AppColors.accentGreen,
                  spawnOpacity: 0.1,
                  particleCount: 15,
                ),
              ),
              child: Container(),
            ),

            SafeArea(
              top: false, // ✅ TopBar already has SafeArea
              bottom: false, // ✅ BottomNav থাকায় bottom SafeArea লাগবে না
              child: SizedBox(
                width: pageWidth,
                height: pageHeight,
                child: _c.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accentGreen))
                    : _c.hasError
                        ? MiningErrorWidget(onRetry: _c.fetchStatus)
                        : RefreshIndicator(
                            color: AppColors.accentGreen,
                            backgroundColor: AppColors.bgCard,
                            onRefresh: _c.fetchStatus,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: pageHeight - 20.h, // ✅ Full page coverage
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: isSmallScreen ? 8.h : 12.h),

                                    // ✅ 1. Withdrawable Balance
                                    if (_c.withdrawableUSD > 0) ...[
                                      SizedBox(
                                        width: double.infinity,
                                        child: WithdrawableSection(c: _c),
                                      ),
                                      SizedBox(height: sectionSpacing),
                                    ],

                                    // ✅ 2. Mining Orb (Responsive Size)
                                    SizedBox(
                                      width: orbSize,
                                      height: orbSize,
                                      child: MiningOrb(
                                        c: _c,
                                        size: orbSize,
                                        onTap: () async {
                                          try {
                                            await _c.toggleMining();
                                            if (_c.isMining) {
                                              _showSnack('⛏️ Mining Started',
                                                  'Earn \$100 to complete a cycle!',
                                                  AppColors.accentGreen, Colors.black);
                                            }
                                          } catch (e) {
                                            _showSnack('❌ Error',
                                                e.toString().replaceFirst('Exception: ', ''),
                                                Colors.red, Colors.white);
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(height: sectionSpacing + 4.h),

                                    // ✅ 3. Action Buttons
                                    SizedBox(
                                      width: double.infinity,
                                      child: ActionButtons(
                                        c: _c,
                                        onClaim: _handleClaimTap,
                                        onRefresh: _c.fetchStatus,
                                      ),
                                    ),
                                    SizedBox(height: sectionSpacing),

                                    // ✅ 4. Stats Grid
                                    SizedBox(
                                      width: double.infinity,
                                      child: StatsGrid(
                                        c: _c,
                                        padding: cardPadding,
                                      ),
                                    ),
                                    SizedBox(height: sectionSpacing),

                                    // ✅ 5. Live Earnings Card
                                    SizedBox(
                                      width: double.infinity,
                                      child: LiveEarningsCard(
                                        c: _c,
                                        padding: cardPadding,
                                      ),
                                    ),
                                    SizedBox(height: sectionSpacing - 4.h),

                                    // ✅ 6. Solana Live Card
                                    SizedBox(
                                      width: double.infinity,
                                      child: SolanaLiveCard(
                                        c: _c,
                                        padding: cardPadding,
                                      ),
                                    ),
                                    SizedBox(height: sectionSpacing - 4.h),

                                    // ✅ 7. Cycle Progress
                                    SizedBox(
                                      width: double.infinity,
                                      child: CycleProgressSection(
                                        c: _c,
                                        padding: cardPadding,
                                      ),
                                    ),
                                    SizedBox(height: sectionSpacing - 4.h),

                                    // ✅ 8. Auto Mining Card
                                    SizedBox(
                                      width: double.infinity,
                                      child: AutoMiningCard(
                                        c: _c,
                                        padding: cardPadding,
                                        onBuyAuto: () => showBuyAutoMiningSheet(context, _c, _c.purchaseAutoMining),
                                      ),
                                    ),
                                    SizedBox(height: sectionSpacing - 4.h),

                                    // ✅ 9. Boost Info
                                    SizedBox(
                                      width: double.infinity,
                                      child: BoostInfoSection(
                                        c: _c,
                                        padding: cardPadding,
                                        onBuyBoost: () => showBuyBoostSheet(context, _c, _c.purchaseBoost),
                                      ),
                                    ),
                                    SizedBox(height: 20.h), // Bottom padding
                                  ],
                                ),
                              ),
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Updated Supporting Widgets with Responsive Parameters
// ============================================================================

class MiningErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const MiningErrorWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.redAccent, size: 40.sp),
          SizedBox(height: 10.h),
          Text("Failed to load mining data", style: GoogleFonts.inter(color: Colors.white70, fontSize: 12.sp)),
          SizedBox(height: 15.h),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen),
            child: Text("Retry", style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}

class ActionButtons extends StatelessWidget {
  final MiningController c;
  final VoidCallback onClaim;
  final VoidCallback onRefresh;
  const ActionButtons({super.key, required this.c, required this.onClaim, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: OutlinedButton.icon(
            onPressed: onRefresh,
            icon: Icon(CupertinoIcons.refresh, size: 14.sp, color: Colors.white70),
            label: Text("Refresh", style: GoogleFonts.inter(color: Colors.white70, fontSize: 11.sp)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
          ),
        ),
        SizedBox(width: 12.w),
        Flexible(
          child: ElevatedButton.icon(
            onPressed: onClaim,
            icon: Icon(CupertinoIcons.money_dollar_circle_fill, size: 16.sp, color: Colors.black),
            label: Text("Claim", style: GoogleFonts.inter(color: Colors.black, fontSize: 11.sp, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen),
          ),
        ),
      ],
    );
  }
}

class StatsGrid extends StatelessWidget {
  final MiningController c;
  final double padding;
  const StatsGrid({super.key, required this.c, this.padding = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: padding, horizontal: padding),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _statItem("Base Speed", "\$${kBaseUsdPerSec.toStringAsFixed(6)}/s")),
          Container(width: 1, height: 30.h, color: Colors.white12),
          Expanded(child: _statItem("Multiplier", "${c.boostMultiplier.toStringAsFixed(2)}x")),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp)),
        SizedBox(height: 4.h),
        Text(value, style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
