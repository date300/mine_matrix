import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/mining_constants.dart';
import '../controllers/mining_controller.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// API Service (Inline - No extra files needed)
// ═══════════════════════════════════════════════════════════════════════════════
class MiningApiService {
  static const String _baseUrl = 'https://web3.ltcminematrix.com';
  
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, dynamic>> claim() async {
    final token = await _getToken();
    
    final response = await http.post(
      Uri.parse('$_baseUrl/api/mining/claim'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Claim failed. Please try again.');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Claim Confirm Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════
class ClaimConfirmSheet extends StatefulWidget {
  final MiningController c;
  final VoidCallback onConfirm;
  const ClaimConfirmSheet({super.key, required this.c, required this.onConfirm});

  @override
  State<ClaimConfirmSheet> createState() => _ClaimConfirmSheetState();
}

class _ClaimConfirmSheetState extends State<ClaimConfirmSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleClaim() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      final response = await MiningApiService.claim();
      
      if (!mounted) return;
      
      Navigator.pop(context);

      final double earnedUSD = (response['usd'] ?? 0.0).toDouble();
      final double earnedCoins = (response['coins'] ?? 0.0).toDouble();
      final double withdrawable = (response['withdrawable'] ?? 0.0).toDouble();
      final double withdrawableAdded = response['message']?.toString().contains('complete') == true 
          ? 100.0 
          : 0.0;
      final double totalWithdrawable = withdrawable;

      // FIXED: Use solPrice (not solPriceUSD) - matches MiningController field name
      final double solPrice = widget.c.solPrice > 0 ? widget.c.solPrice : 150.0;
      final double earnedSOL = earnedUSD / solPrice;

      showClaimSuccessDialog(
        context,
        widget.c,
        earnedUSD: earnedUSD,
        earnedSOL: earnedSOL,
        withdrawableAdded: withdrawableAdded,
        totalWithdrawable: totalWithdrawable,
      );

      // Notify parent to refresh state
      widget.onConfirm();

    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13.sp),
          ),
          backgroundColor: Colors.redAccent.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          margin: EdgeInsets.all(16.w),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double pct = (widget.c.cycleProgress * 100).clamp(0.0, 100.0);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080B12),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border(
          top: BorderSide(color: AppColors.accentGreen.withOpacity(0.3), width: 1.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 40.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Icon pulse
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Transform.scale(
              scale: _pulse.value,
              child: Container(
                width: 72.w,
                height: 72.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.accentGreen, Color(0xFF00CC88)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGreen.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  CupertinoIcons.arrow_down_circle_fill,
                  color: Colors.black,
                  size: 32.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          Text(
            "CLAIM REWARD",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            "Claim your earned USD & SOL.\nReach \$100 to complete a cycle.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 12.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 22.h),

          // Earnings card
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.accentGreen.withOpacity(0.25)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "\$${widget.c.liveUSD.toStringAsFixed(4)}",
                      style: GoogleFonts.spaceMono(
                        color: AppColors.accentGreen,
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Padding(
                      padding: EdgeInsets.only(bottom: 3.h),
                      child: Text(
                        "USD",
                        style: GoogleFonts.inter(
                          color: AppColors.accentGreen.withOpacity(0.7),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppColors.accentPurple.withOpacity(0.25)),
                  ),
                  child: Text(
                    "⛏ ${widget.c.formatSol(widget.c.liveSOL)} SOL",
                    style: GoogleFonts.spaceMono(
                      color: AppColors.accentPurple,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Current session earnings",
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 10.sp),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // Cycle progress
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Cycle Progress",
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 10.sp),
                    ),
                    Text(
                      "${pct.toStringAsFixed(1)}% of \$100",
                      style: GoogleFonts.inter(
                        color: AppColors.accentGreen,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                LinearPercentIndicator(
                  lineHeight: 6.h,
                  percent: widget.c.cycleProgress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white10,
                  linearGradient: const LinearGradient(
                    colors: [AppColors.accentGreen, AppColors.accentPurple],
                  ),
                  barRadius: const Radius.circular(10),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _isLoading ? null : () => Navigator.pop(context),
                  child: Container(
                    height: 52.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: Colors.white12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _isLoading ? null : _handleClaim,
                  child: Container(
                    height: 52.h,
                    decoration: BoxDecoration(
                      gradient: _isLoading 
                          ? LinearGradient(
                              colors: [AppColors.accentGreen.withOpacity(0.5), Color(0xFF00CC88).withOpacity(0.5)],
                            )
                          : const LinearGradient(
                              colors: [AppColors.accentGreen, Color(0xFF00CC88)],
                            ),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGreen.withOpacity(_isLoading ? 0.1 : 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.arrow_down_circle_fill,
                                  color: Colors.black, size: 18.sp),
                              SizedBox(width: 8.w),
                              Text(
                                "Claim Now",
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Claim Success Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════
class ClaimSuccessSheet extends StatefulWidget {
  final MiningController c;
  final double earnedUSD;
  final double earnedSOL;
  final double withdrawableAdded;
  final double totalWithdrawable;
  // FIXED: Added missing parameters that mining_screen.dart passes
  final double? savedCoinsUSD;
  final bool? cycleComplete;

  const ClaimSuccessSheet({
    super.key,
    required this.c,
    required this.earnedUSD,
    required this.earnedSOL,
    required this.withdrawableAdded,
    required this.totalWithdrawable,
    this.savedCoinsUSD,
    this.cycleComplete,
  });

  @override
  State<ClaimSuccessSheet> createState() => _ClaimSuccessSheetState();
}

class _ClaimSuccessSheetState extends State<ClaimSuccessSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    
    // Safe forward with post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FIXED: Use cycleComplete parameter if passed, otherwise fall back to withdrawable check
    final bool cycleComplete = widget.cycleComplete ?? widget.withdrawableAdded >= 100.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080B12),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border(
          top: BorderSide(color: AppColors.accentLeaf.withOpacity(0.35), width: 1.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 40.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 28.h),

          // Animated checkmark icon
          ScaleTransition(
            scale: _scaleAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.accentLeaf, Color(0xFF2ECC71)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentLeaf.withOpacity(0.45),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  color: Colors.white,
                  size: 38.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: 18.h),

          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                Text(
                  cycleComplete ? "Cycle Complete! 🎉" : "Claim Successful!",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  cycleComplete
                      ? "\$100 added to your withdrawable balance!"
                      : "Your earnings have been recorded.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: cycleComplete ? AppColors.accentLeaf : Colors.white54,
                    fontSize: 12.sp,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 22.h),

          // Stats row
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: AppColors.accentLeaf.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.accentLeaf.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem(
                  "Earned USD",
                  "\$${widget.earnedUSD.toStringAsFixed(4)}",
                  AppColors.accentLeaf,
                ),
                Container(width: 1.w, height: 36.h, color: Colors.white10),
                _statItem(
                  "Earned SOL",
                  widget.c.formatSol(widget.earnedSOL),
                  AppColors.accentPurple,
                ),
                Container(width: 1.w, height: 36.h, color: Colors.white10),
                _statItem(
                  "Withdrawable",
                  "\$${widget.totalWithdrawable.toStringAsFixed(2)}",
                  Colors.white70,
                ),
              ],
            ),
          ),

          if (widget.withdrawableAdded > 0) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.accentGreen.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.plus_circle_fill,
                      color: AppColors.accentGreen, size: 14.sp),
                  SizedBox(width: 6.w),
                  Text(
                    "\$${widget.withdrawableAdded.toStringAsFixed(2)} added to withdrawable",
                    style: GoogleFonts.inter(
                      color: AppColors.accentGreen,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 24.h),

          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: () {
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentLeaf, Color(0xFF2E8B00)],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Center(
                  child: Text(
                    "Awesome! 🎉",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.spaceMono(
            color: color,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Claim Not Ready Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════
class ClaimNotReadySheet extends StatelessWidget {
  final MiningController c;
  const ClaimNotReadySheet({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final double pct = (c.liveUSD / kUsdTarget * 100).clamp(0.0, 100.0);
    final double remaining = (kUsdTarget - c.liveUSD).clamp(0.0, kUsdTarget);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080B12),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border(
          top: BorderSide(color: Colors.orange.withOpacity(0.35), width: 1.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 40.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 28.h),

          // Warning icon
          Container(
            width: 72.w,
            height: 72.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withOpacity(0.12),
              border: Border.all(color: Colors.orange.withOpacity(0.4), width: 1.5),
            ),
            child: Icon(
              CupertinoIcons.lock_fill,
              color: Colors.orange,
              size: 32.sp,
            ),
          ),
          SizedBox(height: 18.h),

          Text(
            "Mining Not Active",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Start mining first by tapping the ORB.\nClaim is only available during an active session.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 12.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 24.h),

          // Progress section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Cycle Progress",
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 10.sp),
                    ),
                    Text(
                      "${pct.toStringAsFixed(1)}%",
                      style: GoogleFonts.inter(
                        color: Colors.orange,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                LinearPercentIndicator(
                  lineHeight: 7.h,
                  percent: pct / 100,
                  backgroundColor: Colors.white10,
                  linearGradient: const LinearGradient(
                    colors: [Colors.orange, Color(0xFFFFCC00)],
                  ),
                  barRadius: const Radius.circular(10),
                  padding: EdgeInsets.zero,
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "\$${c.liveUSD.toStringAsFixed(4)} earned",
                      style: GoogleFonts.spaceMono(
                          color: Colors.white54, fontSize: 10.sp),
                    ),
                    Text(
                      "\$${remaining.toStringAsFixed(2)} remaining",
                      style: GoogleFonts.spaceMono(
                          color: Colors.orange, fontSize: 10.sp),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Tips
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.lightbulb_fill,
                    color: Colors.orange, size: 16.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    "Tap the ORB on the mining screen to start your session, then come back to claim.",
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 11.sp,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: GestureDetector(
              onTap: () {
                if (context.mounted) Navigator.pop(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: Colors.white12),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Got it",
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Helper functions — mining_screen.dart থেকে call হবে
// ═══════════════════════════════════════════════════════════════════════════════
void showClaimDialog(
  BuildContext context,
  MiningController c,
  VoidCallback onConfirm,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ClaimConfirmSheet(c: c, onConfirm: onConfirm),
  );
}

// FIXED: Added missing parameters to match mining_screen.dart call
void showClaimSuccessDialog(
  BuildContext context,
  MiningController c, {
  required double earnedUSD,
  required double earnedSOL,
  required double withdrawableAdded,
  required double totalWithdrawable,
  double? savedCoinsUSD,
  bool? cycleComplete,
}) {
  if (!context.mounted) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ClaimSuccessSheet(
      c: c,
      earnedUSD: earnedUSD,
      earnedSOL: earnedSOL,
      withdrawableAdded: withdrawableAdded,
      totalWithdrawable: totalWithdrawable,
      savedCoinsUSD: savedCoinsUSD,
      cycleComplete: cycleComplete,
    ),
  );
}

void showClaimNotReadyDialog(BuildContext context, MiningController c) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ClaimNotReadySheet(c: c),
  );
}

