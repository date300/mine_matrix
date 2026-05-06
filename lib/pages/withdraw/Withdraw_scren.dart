import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_error_widget.dart';

// ─── Colors (same as WalletScreen) ─────────────────────────────────────────
class AppColors {
  static const Color background    = Color(0xFF0A0A0F);
  static const Color surface       = Color(0xFF12121A);
  static const Color accentGreen   = Color(0xFF00FFA3);
  static const Color accentPurple  = Color(0xFFB829F7);
  static const Color accentBlue    = Color(0xFF00D4FF);
  static const Color accentOrange  = Color(0xFFFF9500);
  static const Color accentRed     = Color(0xFFFF4D4D);
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B8B9E);
  static const Color textMuted     = Color(0xFF4A4A5A);
  static const Color border        = Color(0xFF2A2A3A);
  static const Color cardBg        = Color(0xFF161620);
}

class AppLottie {
  static const String refresh      = 'https://assets10.lottiefiles.com/packages/lf20_7fwvvesa.json';
  static const String copy         = 'https://assets10.lottiefiles.com/packages/lf20_3s913D.json';
  static const String coinSpin     = 'https://assets10.lottiefiles.com/packages/lf20_6wutsrox.json';
  static const String emptyHistory = 'https://assets10.lottiefiles.com/packages/lf20_s8pbrcfw.json';
}

const String _baseUrl = 'https://web3.ltcminematrix.com';

// ─── Main Screen ─────────────────────────────────────────────────────────────
class ReferScreen extends StatefulWidget {
  const ReferScreen({super.key});

  @override
  State<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends State<ReferScreen>
    with TickerProviderStateMixin {
  bool _isLoading    = true;
  bool _hasError     = false;
  bool _isRefreshing = false;

  // API fields
  String _referralCode  = '';
  String _referralLink  = '';
  Map<String, dynamic>? _referredBy;
  Map<String, dynamic>  _network    = {};
  List<dynamic> _levelProgress      = [];
  Map<String, dynamic>  _commission = {};
  List<dynamic> _commissionHistory  = [];
  List<dynamic> _referralTree       = [];
  Map<String, dynamic>? _guide;

  // Animated earned counter
  late AnimationController _earnedCtrl;
  late Animation<double>   _earnedAnim;
  double _displayEarned = 0;
  double _targetEarned  = 0;

  @override
  void initState() {
    super.initState();
    _earnedCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _earnedAnim = CurvedAnimation(
        parent: _earnedCtrl, curve: Curves.easeOutCubic);
    _earnedAnim.addListener(() {
      if (mounted) {
        setState(() => _displayEarned = _targetEarned * _earnedAnim.value);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _earnedCtrl.dispose();
    super.dispose();
  }

  String? _token() =>
      Provider.of<AuthProvider>(context, listen: false).token;

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_token()}',
      };

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() { _isLoading = true; _hasError = false; });
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/api/referral/stats'), headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        final newEarned = double.tryParse(
                d['commission']?['totalEarned']?.toString() ?? '0') ??
            0;
        setState(() {
          _referralCode      = d['myReferralCode']  ?? '';
          _referralLink      = d['referralLink']     ?? '';
          _referredBy        = d['referredBy'];
          _network           = Map<String, dynamic>.from(d['network']     ?? {});
          _levelProgress     = List<dynamic>.from(d['levelProgress']      ?? []);
          _commission        = Map<String, dynamic>.from(d['commission']   ?? {});
          _commissionHistory = List<dynamic>.from(d['commissionHistory']   ?? []);
          _referralTree      = List<dynamic>.from(d['referralTree']        ?? []);
          _guide             = d['guide'];
          _isLoading         = false;
          _targetEarned      = newEarned;
        });
        _earnedCtrl.forward(from: 0);
      } else {
        setState(() { _isLoading = false; _hasError = true; });
      }
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await _load(silent: true);
    setState(() => _isRefreshing = false);
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        SizedBox(
            width: 20.w, height: 20.h,
            child: Lottie.network(AppLottie.copy, repeat: false)),
        SizedBox(width: 10.w),
        Text('$label copied!',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13.sp)),
      ]),
      backgroundColor: AppColors.accentGreen.withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      margin: EdgeInsets.all(16.w),
      duration: const Duration(seconds: 2),
    ));
  }

  // ════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? _skeleton()
          : _hasError
              ? CustomErrorWidget(onRetry: _load)
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
                              _header(),
                              SizedBox(height: 24.h),
                              _heroCard()
                                  .animate()
                                  .fadeIn(duration: 600.ms)
                                  .slideY(begin: 0.2, end: 0),
                              SizedBox(height: 20.h),
                              _linkCard()
                                  .animate()
                                  .fadeIn(delay: 100.ms)
                                  .slideY(begin: 0.1),
                              SizedBox(height: 24.h),
                              _sec('🌐 Network Overview'),
                              SizedBox(height: 12.h),
                              _networkRow()
                                  .animate().fadeIn(delay: 200.ms),
                              SizedBox(height: 24.h),
                              _sec('🏆 Level Progress'),
                              SizedBox(height: 12.h),
                              ..._levelProgress.asMap().entries.map((e) =>
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 12.h),
                                    child: _levelCard(e.value)
                                        .animate()
                                        .fadeIn(delay: Duration(
                                            milliseconds: 280 + e.key * 80))
                                        .slideX(begin: 0.15, end: 0),
                                  )),
                              SizedBox(height: 12.h),
                              _sec('💰 Commission Breakdown'),
                              SizedBox(height: 12.h),
                              _commBreakdown()
                                  .animate().fadeIn(delay: 500.ms),
                              SizedBox(height: 24.h),
                              if (_referralTree.isNotEmpty) ...[
                                _sec('🌳 Referral Tree'),
                                SizedBox(height: 12.h),
                                _tree().animate().fadeIn(delay: 540.ms),
                                SizedBox(height: 24.h),
                              ],
                              _sec('📋 Commission History'),
                              SizedBox(height: 12.h),
                              if (_commissionHistory.isEmpty)
                                _emptyHistory().animate().fadeIn(delay: 580.ms)
                              else
                                ..._commissionHistory.asMap().entries.map((e) =>
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 10.h),
                                      child: _histItem(e.value)
                                          .animate()
                                          .fadeIn(delay: Duration(
                                              milliseconds: 580 + e.key * 60)),
                                    )),
                              SizedBox(height: 24.h),
                              _sec('📖 How It Works'),
                              SizedBox(height: 12.h),
                              _guide2().animate().fadeIn(delay: 660.ms),
                              SizedBox(height: 20.h),
                              if (_referredBy != null) ...[
                                _sec('👤 Referred By'),
                                SizedBox(height: 12.h),
                                _referredByCard()
                                    .animate().fadeIn(delay: 700.ms),
                                SizedBox(height: 20.h),
                              ],
                              _shareBtn().animate().scale(delay: 740.ms),
                              SizedBox(height: 100.h),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // SKELETON
  // ════════════════════════════════════════════════════════════
  Widget _skeleton() => Shimmer.fromColors(
        baseColor: AppColors.surface,
        highlightColor: AppColors.cardBg.withOpacity(0.5),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(children: [
            SizedBox(height: 60.h),
            _skel(200.h),
            SizedBox(height: 20.h),
            _skel(110.h),
            SizedBox(height: 20.h),
            Row(children: [
              Expanded(child: _skel(72.h)),
              SizedBox(width: 10.w),
              Expanded(child: _skel(72.h)),
              SizedBox(width: 10.w),
              Expanded(child: _skel(72.h)),
            ]),
            SizedBox(height: 20.h),
            ...List.generate(3,
                (_) => Padding(padding: EdgeInsets.only(bottom: 12.h), child: _skel(90.h))),
          ]),
        ),
      );

  Widget _skel(double h) => Container(
      width: double.infinity, height: h,
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r)));

  // ════════════════════════════════════════════════════════════
  // HEADER
  // ════════════════════════════════════════════════════════════
  Widget _header() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Referral',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 4.h),
            Text('Earn by growing your network',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 14.sp)),
          ]),
          GestureDetector(
            onTap: _isRefreshing ? null : _onRefresh,
            child: Container(
              width: 44.w, height: 44.h,
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.border)),
              child: Center(
                child: _isRefreshing
                    ? SizedBox(
                        width: 20.w, height: 20.h,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                                AppColors.accentGreen)))
                    : SizedBox(
                        width: 24.w, height: 24.h,
                        child: Lottie.network(AppLottie.refresh,
                            repeat: false)),
              ),
            ),
          ),
        ],
      );

  // ════════════════════════════════════════════════════════════
  // HERO — Commission total (glassmorphism, like WalletScreen balance card)
  // ════════════════════════════════════════════════════════════
  Widget _heroCard() {
    final pays = _commission['totalPayouts'] ?? 0;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentGreen.withOpacity(0.25),
            AppColors.accentBlue.withOpacity(0.1),
            AppColors.surface,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
              color: AppColors.accentGreen.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                // badge
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                        color: AppColors.accentGreen.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 6.w, height: 6.h,
                        decoration: BoxDecoration(
                            color: AppColors.accentGreen,
                            shape: BoxShape.circle)),
                    SizedBox(width: 6.w),
                    Text('REFERRAL',
                        style: GoogleFonts.inter(
                            color: AppColors.accentGreen,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ]),
                ),
                SizedBox(
                    width: 28.w, height: 28.h,
                    child: Lottie.network(AppLottie.coinSpin)),
              ]),
              SizedBox(height: 20.h),
              Text('Total Commission Earned',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 14.sp)),
              SizedBox(height: 8.h),
              AnimatedBuilder(
                animation: _earnedAnim,
                builder: (_, __) => Text(
                  '\$${_displayEarned.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 42.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                  '$pays payout${pays != 1 ? "s" : ""} received',
                  style: GoogleFonts.spaceMono(
                      color: AppColors.accentPurple,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // REFERRAL LINK CARD
  // ════════════════════════════════════════════════════════════
  Widget _linkCard() => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border:
              Border.all(color: AppColors.accentPurple.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
                color: AppColors.accentPurple.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(children: [
          // Code
          Row(children: [
            _iconBox(Icons.tag_rounded, AppColors.accentPurple),
            SizedBox(width: 14.w),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Referral Code',
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 11.sp)),
                  SizedBox(height: 3.h),
                  Text(_referralCode,
                      style: GoogleFonts.spaceMono(
                          color: AppColors.accentGreen,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3)),
                ])),
            _copyBtn(AppColors.accentGreen,
                () => _copy(_referralCode, 'Referral code')),
          ]),
          SizedBox(height: 14.h),
          Divider(color: AppColors.border),
          SizedBox(height: 14.h),
          // Link
          Row(children: [
            _iconBox(Icons.link_rounded, AppColors.accentBlue),
            SizedBox(width: 14.w),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Invite Link',
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 11.sp)),
                  SizedBox(height: 3.h),
                  Text(_referralLink,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          color: AppColors.accentBlue, fontSize: 12.sp)),
                ])),
            SizedBox(width: 8.w),
            _copyBtn(AppColors.accentBlue,
                () => _copy(_referralLink, 'Referral link')),
          ]),
        ]),
      );

  // ════════════════════════════════════════════════════════════
  // NETWORK ROW
  // ════════════════════════════════════════════════════════════
  Widget _networkRow() => Row(children: [
        Expanded(child: _netCard('Total',
            (_network['totalReferred'] ?? 0).toString(),
            AppColors.textSecondary, Icons.people_rounded)),
        SizedBox(width: 10.w),
        Expanded(child: _netCard('Active',
            (_network['totalActive'] ?? 0).toString(),
            AppColors.accentGreen, Icons.check_circle_rounded)),
        SizedBox(width: 10.w),
        Expanded(child: _netCard('Inactive',
            (_network['totalInactive'] ?? 0).toString(),
            AppColors.accentRed, Icons.cancel_rounded)),
      ]);

  Widget _netCard(String label, String val, Color color, IconData icon) =>
      Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22.sp),
          SizedBox(height: 8.h),
          Text(val,
              style: GoogleFonts.inter(
                  color: color,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 4.h),
          Text(label,
              style: GoogleFonts.inter(
                  color: AppColors.textMuted, fontSize: 10.sp)),
        ]),
      );

  // ════════════════════════════════════════════════════════════
  // LEVEL CARD
  // ════════════════════════════════════════════════════════════
  Widget _levelCard(Map<String, dynamic> lv) {
    final lvNum    = (lv['level'] as int? ?? 1).clamp(1, 3);
    final colors   = [AppColors.accentGreen, AppColors.accentOrange, AppColors.accentBlue];
    final color    = colors[lvNum - 1];
    final unlocked = lv['unlocked'] as bool? ?? false;
    final pct      = (lv['progressPct'] as num?)?.toDouble() ?? 0.0;
    final active   = lv['activeReferred'] ?? 0;
    final required = lv['minReferrals']   ?? 0;
    final reward   = lv['reward']         ?? 0;
    final status   = lv['status']         ?? '';
    final hint     = lv['hint']           ?? '';

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
            color: unlocked ? color.withOpacity(0.4) : AppColors.border,
            width: unlocked ? 1.5 : 1),
        boxShadow: unlocked
            ? [BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 6))]
            : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44.w, height: 44.h,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12.r)),
            child: Icon(
                unlocked
                    ? Icons.lock_open_rounded
                    : Icons.lock_rounded,
                color: color, size: 22.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Level $lvNum',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 3.h),
            Text(status,
                style: GoogleFonts.inter(
                    color: unlocked
                        ? AppColors.accentGreen
                        : AppColors.textSecondary,
                    fontSize: 11.sp)),
          ])),
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                color.withOpacity(0.25),
                color.withOpacity(0.1)
              ]),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text('\$$reward',
                style: GoogleFonts.inter(
                    color: color,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
        SizedBox(height: 16.h),
        // Progress bar
        Row(children: [
          Expanded(
            child: Stack(children: [
              Container(
                  height: 8.h,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4.r))),
              FractionallySizedBox(
                widthFactor: (pct / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 8.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.6)]),
                    borderRadius: BorderRadius.circular(4.r),
                    boxShadow: [
                      BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ],
                  ),
                ),
              ),
            ]),
          ),
          SizedBox(width: 12.w),
          Text('$active / $required',
              style: GoogleFonts.spaceMono(
                  color: color,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold)),
        ]),
        SizedBox(height: 10.h),
        Text(hint,
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 11.sp)),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════
  // COMMISSION BREAKDOWN
  // ════════════════════════════════════════════════════════════
  Widget _commBreakdown() => Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Expanded(child: _commCell(
              'Level 1', '\$${_commission["level1Earned"] ?? 0}',
              AppColors.accentGreen)),
          _vDivider(),
          Expanded(child: _commCell(
              'Level 2', '\$${_commission["level2Earned"] ?? 0}',
              AppColors.accentOrange)),
          _vDivider(),
          Expanded(child: _commCell(
              'Level 3', '\$${_commission["level3Earned"] ?? 0}',
              AppColors.accentBlue)),
        ]),
      );

  Widget _commCell(String label, String val, Color color) =>
      Column(children: [
        Text(val,
            style: GoogleFonts.inter(
                color: color,
                fontSize: 17.sp,
                fontWeight: FontWeight.bold)),
        SizedBox(height: 4.h),
        Text(label,
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 11.sp)),
      ]);

  Widget _vDivider() => Container(
      width: 1, height: 40.h,
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      color: AppColors.border);

  // ════════════════════════════════════════════════════════════
  // REFERRAL TREE
  // ════════════════════════════════════════════════════════════
  Widget _tree() => Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _referralTree.map<Widget>((l1) {
            final l2s = l1['children'] as List<dynamic>? ?? [];
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              _treeNode(l1['wallet'] ?? '', l1['active'] ?? false,
                  AppColors.accentGreen, 'L1', 0),
              ...l2s.map<Widget>((l2) {
                final l3s = l2['children'] as List<dynamic>? ?? [];
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _treeNode(l2['wallet'] ?? '', l2['active'] ?? false,
                      AppColors.accentOrange, 'L2', 20),
                  ...l3s.map<Widget>((l3) => _treeNode(
                        l3['wallet'] ?? '',
                        l3['active'] ?? false,
                        AppColors.accentBlue, 'L3', 40,
                      )),
                ]);
              }),
              SizedBox(height: 4.h),
            ]);
          }).toList(),
        ),
      );

  Widget _treeNode(String wallet, bool active, Color color,
      String tag, double indent) {
    return Padding(
      padding: EdgeInsets.only(left: indent.w, bottom: 8.h),
      child: Row(children: [
        if (indent > 0)
          Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: Icon(Icons.subdirectory_arrow_right_rounded,
                color: AppColors.textMuted, size: 14.sp),
          ),
        Container(
          padding:
              EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6.r)),
          child: Text(tag,
              style: GoogleFonts.inter(
                  color: color,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold)),
        ),
        SizedBox(width: 8.w),
        Expanded(
            child: Text(wallet,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary, fontSize: 12.sp))),
        Container(
          padding:
              EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: active
                ? AppColors.accentGreen.withOpacity(0.12)
                : AppColors.accentRed.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
              color: active
                  ? AppColors.accentGreen.withOpacity(0.3)
                  : AppColors.accentRed.withOpacity(0.3),
            ),
          ),
          child: Text(active ? 'Active' : 'Inactive',
              style: GoogleFonts.inter(
                  color: active
                      ? AppColors.accentGreen
                      : AppColors.accentRed,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════
  // COMMISSION HISTORY ITEM
  // ════════════════════════════════════════════════════════════
  Widget _histItem(Map<String, dynamic> h) {
    final lvl    = (h['level'] as int? ?? 1).clamp(1, 3);
    final colors = [AppColors.accentGreen, AppColors.accentOrange, AppColors.accentBlue];
    final color  = colors[lvl - 1];
    final reward = h['reward'] ?? 0.0;
    final from   = h['from']   ?? '';
    final date   = (h['earnedAt']?.toString() ?? '').length >= 16
        ? h['earnedAt'].toString().substring(0, 16)
        : h['earnedAt']?.toString() ?? '';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 44.w, height: 44.h,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12.r)),
          alignment: Alignment.center,
          child: Text('L$lvl',
              style: GoogleFonts.inter(
                  color: color,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold)),
        ),
        SizedBox(width: 14.w),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Text('From: $from',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 3.h),
          Text(date,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 11.sp)),
        ])),
        Text('+\$$reward',
            style: GoogleFonts.inter(
                color: color,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _emptyHistory() => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(children: [
            SizedBox(
                width: 80.w, height: 80.h,
                child: Lottie.network(AppLottie.emptyHistory)),
            SizedBox(height: 12.h),
            Text('No commission yet',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 14.sp)),
            SizedBox(height: 4.h),
            Text('Invite friends to start earning',
                style: GoogleFonts.inter(
                    color: AppColors.textMuted, fontSize: 12.sp)),
          ]),
        ),
      );

  // ════════════════════════════════════════════════════════════
  // GUIDE
  // ════════════════════════════════════════════════════════════
  Widget _guide2() {
    final steps = [
      _guide?['step1'] ?? 'Share your referral link with friends',
      _guide?['step2'] ?? 'They register using your link',
      _guide?['step3'] ?? 'They pay \$18 entry to start mining',
      _guide?['step4'] ?? 'You earn commission automatically',
    ];
    final rewards = (_guide?['rewards'] as List<dynamic>?) ?? [];

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        ...steps.asMap().entries.map((e) => Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Container(
                  width: 26.w, height: 26.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      AppColors.accentGreen,
                      AppColors.accentBlue
                    ]),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('${e.key + 1}',
                      style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: 12.w),
                Expanded(
                    child: Text(e.value,
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13.sp,
                            height: 1.4))),
              ]),
            )),
        if (rewards.isNotEmpty) ...[
          Divider(color: AppColors.border),
          SizedBox(height: 10.h),
          Text('Reward Structure',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 10.h),
          ...rewards.map<Widget>((r) => Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(children: [
                  Icon(Icons.monetization_on_rounded,
                      color: AppColors.accentGreen, size: 14.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                      child: Text(r.toString(),
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 12.sp))),
                ]),
              )),
        ],
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════
  // REFERRED BY
  // ════════════════════════════════════════════════════════════
  Widget _referredByCard() => Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
              color: AppColors.accentPurple.withOpacity(0.2)),
        ),
        child: Row(children: [
          _iconBox(Icons.person_pin_rounded, AppColors.accentPurple),
          SizedBox(width: 14.w),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Text('Referred By',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 11.sp)),
            SizedBox(height: 3.h),
            Text(_referredBy?['wallet'] ?? '',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600)),
          ])),
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                  color: AppColors.accentPurple.withOpacity(0.3)),
            ),
            child: Text(_referredBy?['referralCode'] ?? '',
                style: GoogleFonts.inter(
                    color: AppColors.accentPurple,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
      );

  // ════════════════════════════════════════════════════════════
  // SHARE BUTTON
  // ════════════════════════════════════════════════════════════
  Widget _shareBtn() => GestureDetector(
        onTap: () => Share.share(
            'Join LTC Mine Matrix and start earning!\nUse my referral link: $_referralLink'),
        child: Container(
          width: double.infinity,
          height: 56.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.accentGreen, AppColors.accentBlue]),
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                  color: AppColors.accentGreen.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Icon(Icons.share_rounded, color: Colors.black, size: 20.sp),
            SizedBox(width: 10.w),
            Text('Share Invite Link',
                style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold)),
          ]),
        ),
      );

  // ════════════════════════════════════════════════════════════
  // SMALL HELPERS
  // ════════════════════════════════════════════════════════════
  Widget _iconBox(IconData icon, Color color) => Container(
        width: 40.w, height: 40.h,
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12.r)),
        child: Icon(icon, color: color, size: 20.sp),
      );

  Widget _copyBtn(Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36.w, height: 36.h,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: color.withOpacity(0.25))),
          child: Icon(Icons.copy_rounded, color: color, size: 16.sp),
        ),
      );

  Widget _sec(String text) => Text(text,
      style: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 16.sp,
          fontWeight: FontWeight.bold));
}
