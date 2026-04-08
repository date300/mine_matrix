import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../constants/mining_constants.dart';
import '../controllers/mining_controller.dart';

double _dw(BuildContext ctx,
        {double pct = 0.84, double min = 260, double max = 340}) =>
    (MediaQuery.of(ctx).size.width * pct).clamp(min, max);

double _dh(BuildContext ctx,
        {double pct = 0.45, double min = 240, double max = 360}) =>
    (MediaQuery.of(ctx).size.height * pct).clamp(min, max);

// ─── Claim Confirm Dialog ─────────────────────────────────────────────────────
void showClaimDialog(BuildContext context, MiningController c, VoidCallback onConfirm) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.75),
    builder: (ctx) {
      final dw = _dw(ctx, pct: 0.84, min: 260, max: 340);
      final dh = _dh(ctx, pct: 0.50, min: 280, max: 340);
      return Center(
        child: Material(
          color: Colors.transparent,
          child: GlassmorphicContainer(
            width: dw,
            height: dh,
            borderRadius: 22.r,
            blur: 22,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accentGreen.withOpacity(0.12),
                Colors.black.withOpacity(0.8),
              ],
            ),
            borderGradient: LinearGradient(colors: [
              AppColors.accentGreen.withOpacity(0.7),
              AppColors.accentPurple.withOpacity(0.3),
            ]),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.drop_fill,
                      color: AppColors.accentGreen, size: 36.sp),
                  SizedBox(height: 10.h),
                  Text("CLAIM REWARD",
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                  SizedBox(height: 6.h),
                  Text(
                    "Claim your earned USD.\nReach \$100 to complete a cycle.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: Colors.white60, fontSize: 11.sp),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                          color: AppColors.accentGreen.withOpacity(0.3)),
                    ),
                    child: Column(children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "\$${c.liveUSD.toStringAsFixed(4)} USD",
                          style: GoogleFonts.inter(
                              color: AppColors.accentGreen,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        "◎ ${c.formatSol(c.liveSOL)} SOL",
                        style: GoogleFonts.spaceMono(
                            color: AppColors.accentPurple,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2.h),
                      Text("Current session earnings",
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 10.sp)),
                    ]),
                  ),
                  SizedBox(height: 18.h),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          height: 46.h,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(13.r),
                            border: Border.all(color: Colors.white12),
                          ),
                          alignment: Alignment.center,
                          child: Text("Cancel",
                              style: GoogleFonts.inter(
                                  color: Colors.white60, fontSize: 13.sp)),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          onConfirm();
                        },
                        child: Container(
                          height: 46.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              AppColors.accentGreen,
                              AppColors.accentGreen.withOpacity(0.75),
                            ]),
                            borderRadius: BorderRadius.circular(13.r),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.drop_fill,
                                  color: Colors.black, size: 14.sp),
                              SizedBox(width: 6.w),
                              Text("Claim Now",
                                  style: GoogleFonts.inter(
                                      color: Colors.black,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

// ─── Claim Success Dialog ─────────────────────────────────────────────────────
void showClaimSuccessDialog(
  BuildContext context,
  MiningController c, {
  required double earnedUSD,
  required double earnedSOL,
  required double withdrawableAdded,
  required double totalWithdrawable,
}) {
  if (!context.mounted) return;
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.75),
    builder: (ctx) {
      final dw = _dw(ctx, pct: 0.78, min: 250, max: 310);
      final dh = _dh(ctx, pct: 0.48, min: 260, max: 320);
      return Center(
        child: Material(
          color: Colors.transparent,
          child: GlassmorphicContainer(
            width: dw,
            height: dh,
            borderRadius: 22.r,
            blur: 22,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accentLeaf.withOpacity(0.12),
                Colors.black.withOpacity(0.8),
              ],
            ),
            borderGradient: LinearGradient(colors: [
              AppColors.accentLeaf.withOpacity(0.7),
              Colors.transparent,
            ]),
            child: Padding(
              padding: EdgeInsets.all(22.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.checkmark_seal_fill,
                      color: AppColors.accentLeaf, size: 44.sp),
                  SizedBox(height: 12.h),
                  Text("Claim Successful!",
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900)),
                  SizedBox(height: 8.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Earned: \$${earnedUSD.toStringAsFixed(4)} USD",
                      style: GoogleFonts.inter(
                          color: AppColors.accentLeaf,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "◎ ${c.formatSol(earnedSOL)} SOL",
                    style: GoogleFonts.spaceMono(
                        color: AppColors.accentPurple,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold),
                  ),
                  if (withdrawableAdded > 0) ...[
                    SizedBox(height: 4.h),
                    Text(
                      "\$${withdrawableAdded.toStringAsFixed(2)} added to withdrawable!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: AppColors.accentGreen, fontSize: 11.sp),
                    ),
                  ],
                  SizedBox(height: 4.h),
                  Text(
                    "Total withdrawable: \$${totalWithdrawable.toStringAsFixed(2)}",
                    textAlign: TextAlign.center,
                    style:
                        GoogleFonts.inter(color: Colors.white54, fontSize: 10.sp),
                  ),
                  SizedBox(height: 18.h),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: double.infinity,
                      height: 44.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          AppColors.accentLeaf,
                          Color(0xFF2E8B00),
                        ]),
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                      alignment: Alignment.center,
                      child: Text("OK",
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

// ─── Claim Not Ready Dialog ───────────────────────────────────────────────────
void showClaimNotReadyDialog(BuildContext context, MiningController c) {
  final pct = (c.liveUSD / kUsdTarget * 100).clamp(0.0, 100.0);
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.75),
    builder: (ctx) {
      final dw = _dw(ctx, pct: 0.82, min: 250, max: 330);
      final dh = _dh(ctx, pct: 0.42, min: 250, max: 300);
      return Center(
        child: Material(
          color: Colors.transparent,
          child: GlassmorphicContainer(
            width: dw,
            height: dh,
            borderRadius: 22.r,
            blur: 22,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange.withOpacity(0.10),
                Colors.black.withOpacity(0.8),
              ],
            ),
            borderGradient: LinearGradient(colors: [
              Colors.orange.withOpacity(0.6),
              Colors.transparent,
            ]),
            child: Padding(
              padding: EdgeInsets.all(22.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.lock_fill,
                      color: Colors.orange, size: 38.sp),
                  SizedBox(height: 12.h),
                  Text("Mining Not Active",
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900)),
                  SizedBox(height: 8.h),
                  Text(
                    "Start mining first by tapping the ORB.\nClaim is only available during an active session.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: Colors.white60, fontSize: 11.sp),
                  ),
                  SizedBox(height: 14.h),
                  LinearPercentIndicator(
                    lineHeight: 7.h,
                    percent: pct / 100,
                    backgroundColor: Colors.white10,
                    linearGradient: const LinearGradient(
                        colors: [Colors.orange, Color(0xFFFFCC00)]),
                    barRadius: const Radius.circular(10),
                    padding: EdgeInsets.zero,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    "${pct.toStringAsFixed(1)}%  |  \$${(kUsdTarget - c.liveUSD).toStringAsFixed(2)} remaining",
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 9.sp),
                  ),
                  SizedBox(height: 16.h),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: double.infinity,
                      height: 44.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(13.r),
                        border: Border.all(color: Colors.white12),
                      ),
                      alignment: Alignment.center,
                      child: Text("OK",
                          style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
