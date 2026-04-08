import 'package:flutter/material.dart';
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

  // ─── Claim flow ───────────────────────────────────────────────────────────
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
          _showSnack('🎉 Cycle Complete!',
              '\$100 added to withdrawable!', AppColors.accentGreen, Colors.black);
        }
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.toLowerCase().contains('wait')) {
        _showSnack('⏳ Too Soon',
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

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
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
                          padding: EdgeInsets.symmetric(horizontal: 18.w),
                          child: Column(
                            children: [
                              SizedBox(height: 15.h),
                              LiveEarningsCard(c: _c),
                              SizedBox(height: 8.h),
                              SolanaLiveCard(c: _c),
                              SizedBox(height: 8.h),
                              CycleProgressSection(c: _c),
                              SizedBox(height: 8.h),
                              if (_c.boostActive) ...[
                                BoostInfoSection(c: _c),
                                SizedBox(height: 8.h),
                              ],
                              if (_c.withdrawableUSD > 0) ...[
                                WithdrawableSection(c: _c),
                                SizedBox(height: 8.h),
                              ],
                              SizedBox(height: 16.h),
                              MiningOrb(
                                c: _c,
                                onTap: () async {
                                  try {
                                    await _c.toggleMining();
                                    if (_c.isMining) {
                                      _showSnack('⛏ Mining Started',
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
                              SizedBox(height: 20.h),
                              CycleProgressBar(c: _c),
                              SizedBox(height: 25.h),
                              ActionButtons(
                                c: _c,
                                onClaim: _handleClaimTap,
                                onRefresh: _c.fetchStatus,
                              ),
                              SizedBox(height: 12.h),
                              StatsGrid(c: _c),
                              SizedBox(height: 30.h),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
