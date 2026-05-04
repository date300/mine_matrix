import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../providers/auth_provider.dart';
import '../../widgets/custom_error_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg0     = Color(0xFF060609);
  static const bg1     = Color(0xFF0E0E17);
  static const bg2     = Color(0xFF141421);
  static const bg3     = Color(0xFF1C1C2E);

  static const cyan    = Color(0xFF00D4FF);
  static const green   = Color(0xFF00E87A);
  static const purple  = Color(0xFF8B5CF6);
  static const magenta = Color(0xFFFF3B6B);
  static const amber   = Color(0xFFF59E0B);

  static const t1 = Color(0xFFF0F0FF);
  static const t2 = Color(0xFF6B6B90);
  static const t3 = Color(0xFF32324A);

  static const b1 = Color(0xFF222235);
  static const b2 = Color(0xFF2E2E48);
}

// ─────────────────────────────────────────────────────────────────────────────
//  LOTTIE — only where animation genuinely adds value
//
//  ✅ txPending  — looping animation shows "in progress" — meaningful
//  ✅ txSuccess  — plays once on approved items & success dialog
//  ✅ txFailed   — plays once on rejected items
//  ✅ emptyHistory — welcoming empty state
//  ✅ confetti   — celebratory success overlay
//  ✅ withdrawCta — hero CTA button, single animated accent
//
//  ❌ refresh, wallet, copy, warning, arrowRight, verifyLoading → Icons
// ─────────────────────────────────────────────────────────────────────────────
class _L {
  static const txPending    = 'https://assets10.lottiefiles.com/packages/lf20_b88nh30c.json';
  static const txSuccess    = 'https://assets10.lottiefiles.com/packages/lf20_pqnfmkj9.json';
  static const txFailed     = 'https://assets10.lottiefiles.com/packages/lf20_tl52xzvn.json';
  static const emptyHistory = 'https://assets10.lottiefiles.com/packages/lf20_s8pbrcfw.json';
  static const confetti     = 'https://assets10.lottiefiles.com/packages/lf20_u4yrau.json';
  static const withdrawCta  = 'https://assets10.lottiefiles.com/packages/lf20_qp1q7mct.json';
}

const String _baseUrl = 'https://web3.ltcminematrix.com';

// ─────────────────────────────────────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────────────────────────────────────
class WithdrawMethod {
  final String name, symbol;
  final Color  color;
  final IconData icon;
  final double minAmount, maxAmount;
  const WithdrawMethod({
    required this.name, required this.symbol,
    required this.color, required this.icon,
    required this.minAmount, required this.maxAmount,
  });
}

final List<WithdrawMethod> _withdrawMethods = [
  WithdrawMethod(
    name: 'BEP20 (BSC)', symbol: 'BEP20',
    color: _C.amber, icon: Icons.currency_bitcoin_rounded,
    minAmount: 5, maxAmount: 10000,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
//  HEX GRID BACKGROUND PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _HexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _C.cyan.withOpacity(0.028)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    const r = 26.0;
    const dx = r * 1.732;
    const dy = r * 1.5;
    int row = 0;
    for (double y = -r; y < size.height + r; y += dy) {
      final offset = (row % 2 == 0) ? 0.0 : dx / 2;
      for (double x = -r + offset; x < size.width + r; x += dx) {
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final a = math.pi / 180 * (60 * i - 30);
          final pt = Offset(x + r * math.cos(a), y + r * math.sin(a));
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        path.close();
        canvas.drawPath(path, p);
      }
      row++;
    }
  }
  @override bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  ROTATING NEON BORDER
// ─────────────────────────────────────────────────────────────────────────────
class _SpinBorder extends StatefulWidget {
  final Widget child;
  final double radius;
  final Color color;
  const _SpinBorder({required this.child, this.radius = 20, this.color = _C.cyan});
  @override
  State<_SpinBorder> createState() => _SpinBorderState();
}

class _SpinBorderState extends State<_SpinBorder> with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }
  @override void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: SweepGradient(
            transform: GradientRotation(_ac.value * math.pi * 2),
            colors: [
              widget.color.withOpacity(0.0),
              widget.color.withOpacity(0.65),
              widget.color.withOpacity(0.0),
            ],
          ),
          boxShadow: [BoxShadow(color: widget.color.withOpacity(0.1), blurRadius: 18)],
        ),
        padding: const EdgeInsets.all(1.2),
        child: Container(
          decoration: BoxDecoration(
            color: _C.bg2,
            borderRadius: BorderRadius.circular(widget.radius - 1.2),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TEXT STYLE HELPERS
//  Outfit = body, labels, buttons (readable, modern)
//  Orbitron = screen title + balance number only (Web3 identity)
//  SpaceMono = wallet addresses only
// ─────────────────────────────────────────────────────────────────────────────
TextStyle _ts(double size, Color color, {FontWeight w = FontWeight.w400, double spacing = 0}) =>
    GoogleFonts.outfit(fontSize: size.sp, color: color, fontWeight: w, letterSpacing: spacing);

TextStyle _mono(double size, Color color) =>
    GoogleFonts.spaceMono(fontSize: size.sp, color: color);

// ─────────────────────────────────────────────────────────────────────────────
//  WITHDRAW SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});
  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> with TickerProviderStateMixin {
  bool   _loading    = true;
  bool   _hasError   = false;
  bool   _refreshing = false;
  double _balance    = 0;
  double _displayBal = 0;
  List<Map<String, dynamic>> _history = [];
  int  _page    = 1;
  bool _hasMore = true;

  late AnimationController _balCtrl;
  late Animation<double>   _balAnim;

  @override
  void initState() {
    super.initState();
    _balCtrl = AnimationController(vsync: this, duration: 1400.ms);
    _balAnim = CurvedAnimation(parent: _balCtrl, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }
  @override void dispose() { _balCtrl.dispose(); super.dispose(); }

  String? get _token => Provider.of<AuthProvider>(context, listen: false).token;
  Map<String, String> get _hdrs => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  void _animateBal(double nv) {
    final old = _displayBal;
    _balAnim.addListener(() {
      if (mounted) setState(() => _displayBal = old + (nv - old) * _balAnim.value);
    });
    _balCtrl.forward(from: 0);
  }

  Future<void> _load({bool silent = false, bool more = false}) async {
    if (!silent) setState(() { _loading = true; _hasError = false; });
    try {
      if (_token == null) { setState(() { _loading = false; _hasError = true; }); return; }
      if (!more) { _page = 1; _hasMore = true; }
      final pg = more ? _page + 1 : 1;

      final res = await Future.wait([
        http.get(Uri.parse('$_baseUrl/api/mining/status'), headers: _hdrs).timeout(15.seconds),
        http.get(Uri.parse('$_baseUrl/api/withdraw/history?page=$pg&limit=10'), headers: _hdrs).timeout(15.seconds),
      ]);
      if (!mounted) return;

      if (res[0].statusCode == 200) {
        final s = jsonDecode(res[0].body);
        final nb = double.tryParse(s['withdrawable']?.toString() ?? '0') ?? 0;
        if (_balance != nb) { _balance = nb; _animateBal(nb); }
      }
      if (res[1].statusCode == 200) {
        final h = jsonDecode(res[1].body);
        final nd = List<Map<String, dynamic>>.from(h['data'] ?? []);
        if (more) {
          if (nd.isEmpty) { _hasMore = false; } else { _history.addAll(nd); _page = pg; }
        } else {
          _history = nd; _page = 1; _hasMore = nd.length >= 10;
        }
      }
      setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _hasError = true; });
        _snack(e.toString().contains('timeout') ? 'Connection timeout.' : 'Network error.', _C.magenta);
      }
    }
  }

  void _snack(String msg, Color color, {IconData icon = Icons.info_outline_rounded}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        SizedBox(width: 10.w),
        Expanded(child: Text(msg, style: _ts(13, Colors.white, w: FontWeight.w500))),
      ]),
      backgroundColor: color.withOpacity(0.92),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      margin: EdgeInsets.all(16.w),
      duration: 3.seconds,
    ));
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await _load(silent: true);
    setState(() => _refreshing = false);
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg0,
      body: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _HexPainter())),
        Positioned(top: -140, left: -100, child: _glow(_C.cyan, 300, 0.055)),
        Positioned(bottom: -100, right: -80, child: _glow(_C.purple, 260, 0.045)),
        if (_loading)
          const _Skeleton()
        else if (_hasError)
          CustomErrorWidget(onRetry: _load)
        else
          RefreshIndicator(
            color: _C.cyan, backgroundColor: _C.bg2, strokeWidth: 2,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _topSection()),
                _historySliver(),
                if (_hasMore && _history.isNotEmpty)
                  SliverToBoxAdapter(child: _loadMoreBtn()),
                SliverToBoxAdapter(child: SizedBox(height: 100.h)),
              ],
            ),
          ),
      ]),
    );
  }

  Widget _glow(Color c, double s, double o) => Container(
    width: s, height: s,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [c.withOpacity(o), Colors.transparent]),
    ),
  );

  // ── TOP SECTION ───────────────────────────────────────────────────────────
  Widget _topSection() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 20.w),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 56.h),
      _header(),
      SizedBox(height: 22.h),
      _balanceCard(),
      SizedBox(height: 16.h),
      _statsRow(),
      SizedBox(height: 18.h),
      _ctaButton(),
      SizedBox(height: 32.h),
      _sectionTitle('Recent Withdrawals'),
      SizedBox(height: 14.h),
    ]),
  );

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _header() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Orbitron only for the screen title
        Text('Withdraw',
          style: GoogleFonts.orbitron(
            fontSize: 26.sp, color: _C.t1,
            fontWeight: FontWeight.w700, letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 5.h),
        Row(children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(
              color: _C.green, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _C.green.withOpacity(0.55), blurRadius: 8)],
            ),
          ),
          SizedBox(width: 7.w),
          Text('BEP20 · BSC Network', style: _ts(12, _C.t2)),
        ]),
      ]),
      // Refresh — Icon is correct here, simple and fast
      GestureDetector(
        onTap: _refreshing ? null : _refresh,
        child: Container(
          width: 44.w, height: 44.h,
          decoration: BoxDecoration(
            color: _C.bg2,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: _C.b1),
          ),
          child: _refreshing
              ? Center(child: SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: _C.cyan)))
              : const Center(child: Icon(Icons.sync_rounded, color: _C.t2, size: 20)),
        ),
      ),
    ],
  );

  // ── BALANCE CARD ──────────────────────────────────────────────────────────
  Widget _balanceCard() {
    return _SpinBorder(
      radius: 22,
      color: _C.cyan,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.8.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _C.bg3.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20.8.r),
            ),
            padding: EdgeInsets.all(22.w),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _pill('● AVAILABLE', _C.green),
                // Icon: static decorative label — no animation needed
                Row(children: [
                  const Icon(Icons.account_balance_wallet_outlined, color: _C.t2, size: 16),
                  SizedBox(width: 6.w),
                  Text('Withdrawable', style: _ts(12, _C.t2)),
                ]),
              ]),
              SizedBox(height: 18.h),
              Text('Available Balance', style: _ts(13, _C.t2)),
              SizedBox(height: 6.h),
              // Orbitron only for the balance number
              AnimatedBuilder(
                animation: _balAnim,
                builder: (_, __) => RichText(text: TextSpan(children: [
                  TextSpan(
                    text: '\$',
                    style: GoogleFonts.orbitron(
                      fontSize: 20.sp, color: _C.cyan.withOpacity(0.6), fontWeight: FontWeight.w400),
                  ),
                  TextSpan(
                    text: _displayBal.toStringAsFixed(2),
                    style: GoogleFonts.orbitron(
                      fontSize: 36.sp, color: _C.t1, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                  ),
                ])),
              ),
              SizedBox(height: 14.h),
              Row(children: [
                _chip('Min \$5', _C.green),
                SizedBox(width: 8.w),
                _chip('Max \$10,000', _C.cyan),
                SizedBox(width: 8.w),
                _chip('Zero Fee', _C.amber),
              ]),
            ]),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.12, end: 0);
  }

  Widget _pill(String label, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: c.withOpacity(0.1),
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: c.withOpacity(0.28)),
    ),
    child: Text(label, style: _ts(10, c, w: FontWeight.w600, spacing: 0.3)),
  );

  Widget _chip(String label, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: c.withOpacity(0.07),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: c.withOpacity(0.18)),
    ),
    child: Text(label, style: _ts(10, c.withOpacity(0.85), w: FontWeight.w500)),
  );

  // ── STATS ROW ─────────────────────────────────────────────────────────────
  Widget _statsRow() {
    final pending  = _history.where((h) => h['status'] == 'pending').length;
    final approved = _history.where((h) => h['status'] == 'approved').length;
    final rejected = _history.where((h) => h['status'] == 'rejected').length;

    return Row(children: [
      Expanded(child: _statCard('Pending',  '$pending',  _C.amber,   Icons.hourglass_empty_rounded)),
      SizedBox(width: 10.w),
      Expanded(child: _statCard('Approved', '$approved', _C.green,   Icons.check_circle_outline_rounded)),
      SizedBox(width: 10.w),
      Expanded(child: _statCard('Rejected', '$rejected', _C.magenta, Icons.cancel_outlined)),
    ]);
  }

  Widget _statCard(String label, String val, Color c, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 13.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: _C.bg2,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: c.withOpacity(0.16)),
      ),
      child: Row(children: [
        Container(
          width: 34.w, height: 34.h,
          decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(9.r),
          ),
          child: Icon(icon, color: c, size: 17),
        ),
        SizedBox(width: 9.w),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(val, style: _ts(18, c, w: FontWeight.w700)),
          Text(label, style: _ts(10, _C.t2, w: FontWeight.w500)),
        ]),
      ]),
    ).animate().fadeIn(delay: 150.ms);
  }

  // ── CTA BUTTON ────────────────────────────────────────────────────────────
  Widget _ctaButton() => GestureDetector(
    onTap: _showSheet,
    child: Container(
      width: double.infinity, height: 56.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF8B5CF6)]),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: _C.cyan.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 6)),
          BoxShadow(color: _C.purple.withOpacity(0.16), blurRadius: 24, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        // ✅ Lottie: Hero CTA — the one animated element that draws attention
        SizedBox(width: 30.w, height: 30.h,
          child: Lottie.network(_L.withdrawCta, fit: BoxFit.contain)),
        SizedBox(width: 10.w),
        Text('Withdraw Now', style: _ts(15, Colors.black, w: FontWeight.w700)),
        SizedBox(width: 8.w),
        const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 18),
      ]),
    ),
  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08, end: 0);

  Widget _sectionTitle(String t) => Row(children: [
    Container(
      width: 3, height: 16,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [_C.cyan, _C.purple],
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
    SizedBox(width: 10.w),
    Text(t, style: _ts(16, _C.t1, w: FontWeight.w600)),
  ]);

  // ── HISTORY ───────────────────────────────────────────────────────────────
  Widget _historySliver() {
    if (_history.isEmpty) {
      return SliverToBoxAdapter(child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: _emptyState(),
      ));
    }
    return SliverList(delegate: SliverChildBuilderDelegate(
      (_, i) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
        child: _txCard(_history[i], i),
      ),
      childCount: _history.length,
    ));
  }

  Widget _emptyState() => Container(
    padding: EdgeInsets.symmetric(vertical: 40.h),
    decoration: BoxDecoration(
      color: _C.bg2,
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(color: _C.b1),
    ),
    child: Column(children: [
      // ✅ Lottie: Empty state — welcoming animation, great UX moment
      SizedBox(width: 110.w, height: 110.h, child: Lottie.network(_L.emptyHistory)),
      SizedBox(height: 12.h),
      Text('No withdrawals yet', style: _ts(15, _C.t1, w: FontWeight.w600)),
      SizedBox(height: 5.h),
      Text('Your transaction history will appear here', style: _ts(13, _C.t2)),
      SizedBox(height: 20.h),
      GestureDetector(
        onTap: _showSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_C.cyan, _C.purple]),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text('Make First Withdrawal', style: _ts(12, Colors.black, w: FontWeight.w700)),
        ),
      ),
    ]),
  );

  Widget _txCard(Map<String, dynamic> data, int index) {
    final amount  = double.tryParse(data['amount']?.toString() ?? '0') ?? 0;
    final status  = data['status']?.toString() ?? 'pending';
    final address = data['wallet_address']?.toString() ?? '';
    final date    = data['created_at']?.toString() ?? '';
    final network = data['network']?.toString() ?? 'BEP20';

    final Color c;
    final String lottieUrl;
    final String statusLabel;
    final bool   loopAnim;

    switch (status) {
      case 'approved':
        c = _C.green;   lottieUrl = _L.txSuccess; statusLabel = 'Approved'; loopAnim = false; break;
      case 'rejected':
        c = _C.magenta; lottieUrl = _L.txFailed;  statusLabel = 'Rejected'; loopAnim = false; break;
      default:
        c = _C.amber;   lottieUrl = _L.txPending; statusLabel = 'Pending';  loopAnim = true;
    }

    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: address));
        _snack('Address copied!', _C.green, icon: Icons.copy_rounded);
      },
      child: Container(
        decoration: BoxDecoration(
          color: _C.bg2,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _C.b1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(children: [
            // Left status accent bar
            Positioned(left: 0, top: 0, bottom: 0,
              child: Container(
                width: 3.5,
                decoration: BoxDecoration(
                  color: c,
                  boxShadow: [BoxShadow(color: c.withOpacity(0.45), blurRadius: 8)],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 14.h, 14.w, 14.h),
              child: Row(children: [
                // ✅ Lottie: TX status icon — pending loops (shows live state),
                //    success/failed play once (communicates outcome)
                Container(
                  width: 44.w, height: 44.h,
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(child: SizedBox(
                    width: 26.w, height: 26.h,
                    child: Lottie.network(lottieUrl, repeat: loopAnim),
                  )),
                ),
                SizedBox(width: 12.w),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('\$${amount.toStringAsFixed(2)}',
                      style: _ts(15, _C.t1, w: FontWeight.w700)),
                  SizedBox(height: 3.h),
                  Text(_fmtAddr(address), style: _mono(10, _C.t3)),
                  SizedBox(height: 3.h),
                  Text(_fmtDate(date), style: _ts(11, _C.t2)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: c.withOpacity(0.28)),
                    ),
                    child: Text(statusLabel, style: _ts(10, c, w: FontWeight.w600)),
                  ),
                  SizedBox(height: 6.h),
                  Text(network, style: _mono(10, _C.t2)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: (index * 70).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _loadMoreBtn() => Padding(
    padding: EdgeInsets.all(16.w),
    child: Center(child: GestureDetector(
      onTap: () { if (_hasMore && !_loading) _load(silent: true, more: true); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
        decoration: BoxDecoration(
          color: _C.bg2,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: _C.b2),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('Load More', style: _ts(13, _C.cyan, w: FontWeight.w600)),
          SizedBox(width: 6.w),
          const Icon(Icons.keyboard_arrow_down_rounded, color: _C.cyan, size: 18),
        ]),
      ),
    )),
  );

  String _fmtAddr(String a) =>
      a.length < 20 ? a : '${a.substring(0, 8)}...${a.substring(a.length - 8)}';
  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d);
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return d; }
  }

  void _showSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => WithdrawSheet(
        balance: _balance, headers: _hdrs,
        onSuccess: () { Navigator.pop(context); _load(silent: true); },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SKELETON LOADER
// ─────────────────────────────────────────────────────────────────────────────
class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _C.bg2, highlightColor: _C.bg3,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(children: [
          SizedBox(height: 60.h),
          _b(200), SizedBox(height: 14.h),
          Row(children: [
            Expanded(child: _b(72, r: 14)),
            SizedBox(width: 10.w),
            Expanded(child: _b(72, r: 14)),
            SizedBox(width: 10.w),
            Expanded(child: _b(72, r: 14)),
          ]),
          SizedBox(height: 14.h),
          _b(56, r: 16),
          SizedBox(height: 28.h),
          ...List.generate(3, (_) => Padding(
            padding: EdgeInsets.only(bottom: 10.h), child: _b(74),
          )),
        ]),
      ),
    );
  }
  Widget _b(double h, {double r = 20}) => Container(
    width: double.infinity, height: h.h,
    decoration: BoxDecoration(color: _C.bg2, borderRadius: BorderRadius.circular(r.r)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  WITHDRAW SHEET
// ─────────────────────────────────────────────────────────────────────────────
class WithdrawSheet extends StatefulWidget {
  final double balance;
  final Map<String, String> headers;
  final VoidCallback onSuccess;
  const WithdrawSheet({super.key, required this.balance, required this.headers, required this.onSuccess});
  @override
  State<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<WithdrawSheet> with TickerProviderStateMixin {
  int    _step = 0;
  WithdrawMethod _method = _withdrawMethods[0];
  final _amtCtrl  = TextEditingController();
  final _addrCtrl = TextEditingController();
  bool   _busy = false;
  String _err  = '';

  late AnimationController _successCtrl;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(vsync: this, duration: 2.seconds);
  }
  @override void dispose() {
    _amtCtrl.dispose(); _addrCtrl.dispose(); _successCtrl.dispose(); super.dispose();
  }

  void _setMax() {
    if (widget.balance > 0) _amtCtrl.text = widget.balance.toStringAsFixed(2);
  }

  void _validate() {
    final amt  = double.tryParse(_amtCtrl.text) ?? 0;
    final addr = _addrCtrl.text.trim();
    if (amt <= 0)                        { setState(() => _err = 'Enter a valid amount'); return; }
    if (amt < _method.minAmount)         { setState(() => _err = 'Minimum withdrawal is \$${_method.minAmount}'); return; }
    if (amt > _method.maxAmount)         { setState(() => _err = 'Maximum limit is \$${_method.maxAmount}'); return; }
    if (amt > widget.balance)            { setState(() => _err = 'Insufficient balance'); return; }
    if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(addr))
                                         { setState(() => _err = 'Enter a valid BEP20 address (0x...)'); return; }
    setState(() { _err = ''; _step = 1; });
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/withdraw'),
        headers: widget.headers,
        body: jsonEncode({'amount': double.parse(_amtCtrl.text), 'wallet': _addrCtrl.text.trim()}),
      ).timeout(20.seconds);
      if (!mounted) return;
      final d = jsonDecode(res.body);
      if (res.statusCode == 200 && d['success'] == true) {
        setState(() => _busy = false);
        _successCtrl.forward();
        _showSuccess(d);
      } else {
        setState(() { _busy = false; _err = d['error'] ?? 'Withdrawal failed'; _step = 0; });
      }
    } catch (e) {
      if (mounted) setState(() {
        _busy = false;
        _err = e.toString().contains('timeout') ? 'Timeout. Try again.' : 'Connection error.';
        _step = 0;
      });
    }
  }

  void _showSuccess(Map d) {
    final amount = d['data']?['amount']?.toString() ?? '0';
    final wallet = d['data']?['wallet']?.toString() ?? '';
    final id     = d['data']?['withdrawId']?.toString() ?? '';
    final addr   = wallet.length >= 20
        ? '${wallet.substring(0, 8)}...${wallet.substring(wallet.length - 8)}'
        : wallet;

    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => Stack(children: [
        Center(child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.88,
            decoration: BoxDecoration(
              color: _C.bg1,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: _C.green.withOpacity(0.32)),
              boxShadow: [BoxShadow(color: _C.green.withOpacity(0.1), blurRadius: 40)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [_C.green.withOpacity(0.1), Colors.transparent],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                ),
                child: Column(children: [
                  // ✅ Lottie: Success animation — meaningful, plays once, celebratory
                  SizedBox(width: 78.w, height: 78.h,
                    child: Lottie.network(_L.txSuccess, repeat: false, controller: _successCtrl)),
                  SizedBox(height: 10.h),
                  Text('Request Submitted', style: _ts(18, _C.t1, w: FontWeight.w700)),
                  SizedBox(height: 4.h),
                  Text('Processing your withdrawal', style: _ts(12, _C.t2)),
                ]),
              ),
              // Body
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 14.h, 24.w, 24.h),
                child: Column(children: [
                  Text('-\$$amount',
                    style: GoogleFonts.orbitron(color: _C.magenta, fontSize: 28.sp, fontWeight: FontWeight.w700)),
                  SizedBox(height: 16.h),
                  _dRow('Network', 'BEP20 (BSC)', _C.amber),
                  _dRow('Wallet',  addr,          _C.t1),
                  _dRow('Ref ID',  '#$id',         _C.cyan),
                  SizedBox(height: 20.h),
                  GestureDetector(
                    onTap: () { Navigator.pop(ctx); widget.onSuccess(); },
                    child: Container(
                      width: double.infinity, height: 50.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_C.green, _C.cyan]),
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [BoxShadow(color: _C.green.withOpacity(0.25), blurRadius: 20)],
                      ),
                      alignment: Alignment.center,
                      child: Text('Got it!', style: _ts(15, Colors.black, w: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        )),
        // ✅ Lottie: Confetti — perfect celebratory overlay, plays once
        Positioned.fill(child: IgnorePointer(
          child: Lottie.network(_L.confetti, controller: _successCtrl, fit: BoxFit.cover),
        )),
      ]),
    );
  }

  Widget _dRow(String label, String val, Color c) => Padding(
    padding: EdgeInsets.symmetric(vertical: 6.h),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: _ts(13, _C.t2)),
      Text(val,   style: _ts(13, c, w: FontWeight.w600)),
    ]),
  );

  // ── SHEET BUILD ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: _C.bg1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
        border: Border(
          top:   BorderSide(color: _C.cyan.withOpacity(0.18)),
          left:  BorderSide(color: _C.b1),
          right: BorderSide(color: _C.b1),
        ),
      ),
      child: Column(children: [
        SizedBox(height: 12.h),
        Container(
          width: 36.w, height: 4.h,
          decoration: BoxDecoration(color: _C.b2, borderRadius: BorderRadius.circular(10.r)),
        ),
        SizedBox(height: 18.h),
        _sheetHeader(),
        SizedBox(height: 20.h),
        _stepBar(),
        SizedBox(height: 20.h),
        Expanded(child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 22.w),
          child: _step == 0 ? _step0() : _step1(),
        )),
      ]),
    );
  }

  Widget _sheetHeader() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 22.w),
    child: Row(children: [
      // Icon: sheet header — static context, clean
      Container(
        width: 46.w, height: 46.h,
        decoration: BoxDecoration(
          color: _C.magenta.withOpacity(0.1),
          borderRadius: BorderRadius.circular(13.r),
          border: Border.all(color: _C.magenta.withOpacity(0.22)),
        ),
        child: const Icon(Icons.account_balance_wallet_outlined, color: _C.magenta, size: 22),
      ),
      SizedBox(width: 14.w),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Withdraw Funds', style: _ts(17, _C.t1, w: FontWeight.w700)),
        Text('Balance: \$${widget.balance.toStringAsFixed(2)}',
            style: _ts(12, _C.cyan, w: FontWeight.w600)),
      ])),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _C.bg2, shape: BoxShape.circle, border: Border.all(color: _C.b2)),
          child: const Icon(Icons.close, color: _C.t2, size: 17),
        ),
      ),
    ]),
  );

  Widget _stepBar() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 22.w),
    child: Row(children: [
      _dot(0, 'Amount',  Icons.attach_money_rounded),
      Expanded(child: Stack(children: [
        Container(height: 1.5, color: _C.b1),
        if (_step >= 1) Container(height: 1.5,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_C.cyan, _C.purple]),
          )),
      ])),
      _dot(1, 'Confirm', Icons.check_rounded),
    ]),
  );

  Widget _dot(int s, String label, IconData icon) {
    final active  = _step >= s;
    final current = _step == s;
    return Column(children: [
      Container(
        width: 38.w, height: 38.h,
        decoration: BoxDecoration(
          gradient: active ? const LinearGradient(colors: [_C.cyan, _C.purple]) : null,
          color: active ? null : _C.bg2,
          shape: BoxShape.circle,
          border: Border.all(color: active ? Colors.transparent : _C.b2, width: 1.5),
          boxShadow: active ? [BoxShadow(color: _C.cyan.withOpacity(0.28), blurRadius: 14)] : null,
        ),
        child: Icon(icon, color: active ? Colors.black : _C.t3, size: 17),
      ),
      SizedBox(height: 5.h),
      Text(label, style: _ts(10, active ? _C.cyan : _C.t3,
          w: current ? FontWeight.w600 : FontWeight.w400)),
    ]);
  }

  // ── STEP 0 ────────────────────────────────────────────────────────────────
  Widget _step0() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _lbl('Network'),
    SizedBox(height: 10.h),
    ..._withdrawMethods.map(_networkCard),
    SizedBox(height: 18.h),
    _lbl('Amount (USD)'),
    SizedBox(height: 10.h),
    _amountField(),
    SizedBox(height: 18.h),
    _lbl('BEP20 Wallet Address'),
    SizedBox(height: 10.h),
    _addressField(),
    if (_err.isNotEmpty) ...[SizedBox(height: 12.h), _errBox()],
    SizedBox(height: 26.h),
    _btnGrad('Continue', _validate, trailingIcon: Icons.arrow_forward_rounded),
    SizedBox(height: 24.h),
  ]);

  Widget _lbl(String t) => Text(t, style: _ts(13, _C.t2, w: FontWeight.w600));

  Widget _networkCard(WithdrawMethod m) {
    final sel = _method.symbol == m.symbol;
    return GestureDetector(
      onTap: () => setState(() => _method = m),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: sel ? m.color.withOpacity(0.07) : _C.bg2,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: sel ? m.color.withOpacity(0.42) : _C.b1, width: sel ? 1.5 : 1),
        ),
        child: Row(children: [
          // Icon: network selector — static branded icon, clean and fast
          Container(
            width: 42.w, height: 42.h,
            decoration: BoxDecoration(
              color: m.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(m.icon, color: m.color, size: 22),
          ),
          SizedBox(width: 12.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name, style: _ts(14, _C.t1, w: FontWeight.w600)),
            SizedBox(height: 2.h),
            Text('Min \$${m.minAmount}  ·  Max \$${m.maxAmount}', style: _ts(11, _C.t2)),
          ])),
          Container(
            width: 22.w, height: 22.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: sel ? m.color : _C.t3, width: 2),
              color: sel ? m.color : Colors.transparent,
            ),
            child: sel ? const Icon(Icons.check, color: Colors.black, size: 13) : null,
          ),
        ]),
      ),
    );
  }

  Widget _amountField() => Container(
    decoration: BoxDecoration(
      color: _C.bg2, borderRadius: BorderRadius.circular(14.r),
      border: Border.all(color: _C.b2),
    ),
    child: Row(children: [
      SizedBox(width: 16.w),
      Text('\$', style: GoogleFonts.orbitron(color: _C.cyan, fontSize: 18.sp, fontWeight: FontWeight.w600)),
      Expanded(child: TextField(
        controller: _amtCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.orbitron(color: _C.t1, fontSize: 18.sp, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: '0.00',
          hintStyle: GoogleFonts.orbitron(color: _C.t3, fontSize: 18.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 16.h),
        ),
      )),
      GestureDetector(
        onTap: _setMax,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_C.cyan, _C.green]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('MAX', style: _ts(10, Colors.black, w: FontWeight.w800, spacing: 0.5)),
        ),
      ),
    ]),
  );

  Widget _addressField() => Container(
    decoration: BoxDecoration(
      color: _C.bg2, borderRadius: BorderRadius.circular(14.r),
      border: Border.all(color: _C.b2),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: TextField(
        controller: _addrCtrl,
        style: _mono(12, _C.t1),
        maxLines: 2,
        decoration: InputDecoration(
          hintText: '0x... BEP20 wallet address',
          hintStyle: _mono(12, _C.t3),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16.w),
        ),
      )),
      // Icon: paste — functional action, icon is clear and instant
      GestureDetector(
        onTap: () async {
          final d = await Clipboard.getData('text/plain');
          if (d?.text != null) { _addrCtrl.text = d!.text!.trim(); setState(() {}); }
        },
        child: Container(
          margin: EdgeInsets.all(10.w),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: _C.purple.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _C.purple.withOpacity(0.25)),
          ),
          child: const Icon(Icons.content_paste_rounded, color: _C.purple, size: 18),
        ),
      ),
    ]),
  );

  Widget _errBox() => Container(
    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
    decoration: BoxDecoration(
      color: _C.magenta.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10.r),
      border: Border.all(color: _C.magenta.withOpacity(0.22)),
    ),
    child: Row(children: [
      // Icon: static error message — no animation needed here
      const Icon(Icons.error_outline_rounded, color: _C.magenta, size: 18),
      SizedBox(width: 10.w),
      Expanded(child: Text(_err, style: _ts(12, _C.magenta, w: FontWeight.w500))),
    ]),
  );

  Widget _btnGrad(String label, VoidCallback onTap,
      {List<Color>? colors, IconData? trailingIcon}) {
    final c = colors ?? [_C.cyan, _C.purple];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 54.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: c),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [BoxShadow(color: c.first.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        alignment: Alignment.center,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: _ts(15, Colors.black, w: FontWeight.w700)),
          if (trailingIcon != null) ...[
            SizedBox(width: 8.w),
            Icon(trailingIcon, color: Colors.black, size: 18),
          ],
        ]),
      ),
    );
  }

  // ── STEP 1 ────────────────────────────────────────────────────────────────
  Widget _step1() {
    final amt = double.tryParse(_amtCtrl.text) ?? 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _lbl('Transaction Summary'),
      SizedBox(height: 14.h),
      Container(
        decoration: BoxDecoration(
          color: _C.bg2, borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _C.b1),
        ),
        child: Column(children: [
          _sRow('Network',         _method.name),
          Divider(color: _C.b1, height: 1),
          _sRow('Amount',          '\$${amt.toStringAsFixed(2)}'),
          Divider(color: _C.b1, height: 1),
          _sRow('To Wallet',       _fmtA(_addrCtrl.text.trim())),
          Divider(color: _C.b1, height: 1),
          _sRow('Fee',             'Zero',               vc: _C.green, icon: Icons.check_circle_outline_rounded),
          Divider(color: _C.b1, height: 1),
          _sRow('Total Deduction', '\$${amt.toStringAsFixed(2)}', vc: _C.magenta, bold: true),
        ]),
      ),
      SizedBox(height: 14.h),
      Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: _C.amber.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: _C.amber.withOpacity(0.18)),
        ),
        child: Row(children: [
          // Icon: static warning message — no animation needed
          const Icon(Icons.warning_amber_rounded, color: _C.amber, size: 20),
          SizedBox(width: 10.w),
          Expanded(child: Text(
            'Verify the wallet address carefully. Transactions cannot be reversed.',
            style: _ts(12, _C.amber),
          )),
        ]),
      ),
      SizedBox(height: 26.h),
      _busy
          ? Container(
              width: double.infinity, height: 54.h,
              decoration: BoxDecoration(
                color: _C.bg3, borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: _C.b2),
              ),
              alignment: Alignment.center,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _C.cyan)),
                SizedBox(width: 12.w),
                Text('Processing...', style: _ts(14, _C.cyan, w: FontWeight.w600)),
              ]),
            )
          : _btnGrad('Confirm Withdrawal', _confirm,
              colors: [_C.magenta, _C.purple],
              trailingIcon: Icons.lock_outline_rounded),
      SizedBox(height: 12.h),
      GestureDetector(
        onTap: () => setState(() { _step = 0; _err = ''; }),
        child: Container(
          width: double.infinity, height: 48.h,
          decoration: BoxDecoration(
            color: _C.bg2, borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: _C.b2),
          ),
          alignment: Alignment.center,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.arrow_back_rounded, color: _C.t2, size: 16),
            SizedBox(width: 6.w),
            Text('Back', style: _ts(14, _C.t2, w: FontWeight.w500)),
          ]),
        ),
      ),
      SizedBox(height: 32.h),
    ]);
  }

  Widget _sRow(String label, String val, {Color? vc, bool bold = false, IconData? icon}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: _ts(13, _C.t2)),
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, color: vc ?? _C.t1, size: 14), SizedBox(width: 5.w)],
          Text(val, style: _ts(bold ? 14 : 13, vc ?? _C.t1,
              w: bold ? FontWeight.w700 : FontWeight.w600)),
        ]),
      ]),
    );
  }

  String _fmtA(String a) =>
      a.length < 20 ? a : '${a.substring(0, 8)}...${a.substring(a.length - 8)}';
}
