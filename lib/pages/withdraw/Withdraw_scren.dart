import 'dart:async';
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
  // Backgrounds
  static const bg0     = Color(0xFF050508);   // deepest
  static const bg1     = Color(0xFF0D0D14);   // base
  static const bg2     = Color(0xFF13131F);   // surface
  static const bg3     = Color(0xFF1A1A28);   // elevated

  // Neon accents
  static const cyan    = Color(0xFF00E5FF);
  static const green   = Color(0xFF00FF94);
  static const purple  = Color(0xFF7B4FFF);
  static const magenta = Color(0xFFFF2D78);
  static const amber   = Color(0xFFFFB800);

  // Text
  static const t1 = Color(0xFFEEEEFF);
  static const t2 = Color(0xFF7878A0);
  static const t3 = Color(0xFF3C3C58);

  // Border
  static const b1 = Color(0xFF252538);
  static const b2 = Color(0xFF353550);
}

// ─────────────────────────────────────────────────────────────────────────────
//  LOTTIE ASSETS
// ─────────────────────────────────────────────────────────────────────────────
class _L {
  static const coinSpin      = 'https://assets10.lottiefiles.com/packages/lf20_6wutsrox.json';
  static const refresh       = 'https://assets10.lottiefiles.com/packages/lf20_7fwvvesa.json';
  static const emptyHistory  = 'https://assets10.lottiefiles.com/packages/lf20_s8pbrcfw.json';
  static const txPending     = 'https://assets10.lottiefiles.com/packages/lf20_b88nh30c.json';
  static const txSuccess     = 'https://assets10.lottiefiles.com/packages/lf20_pqnfmkj9.json';
  static const txFailed      = 'https://assets10.lottiefiles.com/packages/lf20_tl52xzvn.json';
  static const copy          = 'https://assets10.lottiefiles.com/packages/lf20_3s913D.json';
  static const warning       = 'https://assets10.lottiefiles.com/packages/lf20_Tkwjw8.json';
  static const wallet        = 'https://assets10.lottiefiles.com/packages/lf20_hu7birqV.json';
  static const moneyOut      = 'https://assets10.lottiefiles.com/packages/lf20_qp1q7mct.json';
  static const arrowRight    = 'https://assets10.lottiefiles.com/packages/lf20_7z8wtyb0.json';
  static const confetti      = 'https://assets10.lottiefiles.com/packages/lf20_u4yrau.json';
  static const verifyLoading = 'https://assets10.lottiefiles.com/packages/lf20_p8bfn5to.json';
}

const String _baseUrl = 'https://web3.ltcminematrix.com';

// ─────────────────────────────────────────────────────────────────────────────
//  WITHDRAW METHOD MODEL
// ─────────────────────────────────────────────────────────────────────────────
class WithdrawMethod {
  final String name;
  final String symbol;
  final String iconUrl;
  final Color  color;
  final double minAmount;
  final double maxAmount;

  const WithdrawMethod({
    required this.name,
    required this.symbol,
    required this.iconUrl,
    required this.color,
    required this.minAmount,
    required this.maxAmount,
  });
}

final List<WithdrawMethod> _withdrawMethods = [
  WithdrawMethod(
    name: 'BEP20 (BSC)',
    symbol: 'BEP20',
    iconUrl: _L.coinSpin,
    color: _C.amber,
    minAmount: 5,
    maxAmount: 10000,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
//  HEX GRID PAINTER  (background decoration)
// ─────────────────────────────────────────────────────────────────────────────
class _HexGridPainter extends CustomPainter {
  final double opacity;
  const _HexGridPainter({this.opacity = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _C.cyan.withOpacity(0.035 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    const r = 28.0;
    const dx = r * 1.732;
    const dy = r * 1.5;

    int row = 0;
    for (double y = -r; y < size.height + r; y += dy) {
      final offset = (row % 2 == 0) ? 0.0 : dx / 2;
      for (double x = -r + offset; x < size.width + r; x += dx) {
        _drawHex(canvas, paint, Offset(x, y), r);
      }
      row++;
    }
  }

  void _drawHex(Canvas canvas, Paint paint, Offset center, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 180 * (60 * i - 30);
      final pt = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HexGridPainter old) => old.opacity != opacity;
}

// ─────────────────────────────────────────────────────────────────────────────
//  NEON BORDER WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _NeonBorder extends StatefulWidget {
  final Widget child;
  final double radius;
  final Color color;
  final bool animate;

  const _NeonBorder({
    required this.child,
    this.radius = 20,
    this.color = _C.cyan,
    this.animate = false,
  });

  @override
  State<_NeonBorder> createState() => _NeonBorderState();
}

class _NeonBorderState extends State<_NeonBorder> with SingleTickerProviderStateMixin {
  late AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(color: widget.color.withOpacity(0.3), width: 1),
          boxShadow: [BoxShadow(color: widget.color.withOpacity(0.08), blurRadius: 16)],
        ),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _ac,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: SweepGradient(
              center: Alignment.center,
              startAngle: 0,
              endAngle: math.pi * 2,
              transform: GradientRotation(_ac.value * math.pi * 2),
              colors: [
                widget.color.withOpacity(0.0),
                widget.color.withOpacity(0.8),
                widget.color.withOpacity(0.0),
              ],
            ),
            boxShadow: [
              BoxShadow(color: widget.color.withOpacity(0.15), blurRadius: 24),
            ],
          ),
          padding: const EdgeInsets.all(1.2),
          child: Container(
            decoration: BoxDecoration(
              color: _C.bg2,
              borderRadius: BorderRadius.circular(widget.radius - 1),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  GLOWING TAG
// ─────────────────────────────────────────────────────────────────────────────
class _GlowTag extends StatelessWidget {
  final String label;
  final Color color;
  const _GlowTag(this.label, {this.color = _C.green});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 10)],
      ),
      child: Text(
        label,
        style: GoogleFonts.orbitron(
          color: color,
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  WITHDRAW SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> with TickerProviderStateMixin {
  bool   _isLoading    = true;
  bool   _hasError     = false;
  bool   _isRefreshing = false;
  double _balance      = 0;
  double _displayBal   = 0;
  List<Map<String, dynamic>> _history = [];
  int  _currentPage  = 1;
  bool _hasMoreData  = true;

  late AnimationController _balCtrl;
  late Animation<double>   _balAnim;
  late AnimationController _scanCtrl;

  @override
  void initState() {
    super.initState();

    _balCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _balAnim = CurvedAnimation(parent: _balCtrl, curve: Curves.easeOutCubic);

    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    _balCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  String? _getToken() =>
      Provider.of<AuthProvider>(context, listen: false).token;

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_getToken()}',
  };

  void _animateBalance(double newVal) {
    final old = _displayBal;
    _balAnim.addListener(() {
      if (mounted) setState(() => _displayBal = old + (newVal - old) * _balAnim.value);
    });
    _balCtrl.forward(from: 0);
  }

  Future<void> _loadAll({bool silent = false, bool loadMore = false}) async {
    if (!silent) setState(() { _isLoading = true; _hasError = false; });
    try {
      final token = _getToken();
      if (token == null) { setState(() { _isLoading = false; _hasError = true; }); return; }

      if (!loadMore) { _currentPage = 1; _hasMoreData = true; }
      final page = loadMore ? _currentPage + 1 : 1;

      final results = await Future.wait([
        http.get(Uri.parse('$_baseUrl/api/mining/status'), headers: _headers())
            .timeout(const Duration(seconds: 15)),
        http.get(Uri.parse('$_baseUrl/api/withdraw/history?page=$page&limit=10'), headers: _headers())
            .timeout(const Duration(seconds: 15)),
      ]);

      if (!mounted) return;
      final statusRes = results[0];
      final histRes   = results[1];

      if (statusRes.statusCode == 200) {
        final status  = jsonDecode(statusRes.body);
        final newBal  = double.tryParse(status['withdrawable']?.toString() ?? '0') ?? 0;
        if (_balance != newBal) { _balance = newBal; _animateBalance(newBal); }
      }
      if (histRes.statusCode == 200) {
        final h   = jsonDecode(histRes.body);
        final List<Map<String, dynamic>> nd = List<Map<String, dynamic>>.from(h['data'] ?? []);
        if (loadMore) {
          if (nd.isEmpty) { _hasMoreData = false; } else { _history.addAll(nd); _currentPage = page; }
        } else {
          _history = nd; _currentPage = 1; _hasMoreData = nd.length >= 10;
        }
      }
      setState(() => _isLoading = false);
    } on Exception catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _hasError = true; });
        _toast(e.toString().contains('timeout') ? 'Connection timeout.' : 'Network error.', _C.magenta);
      }
    }
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w600)),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadAll(silent: true);
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg0,
      body: Stack(
        children: [
          // Hex grid background
          Positioned.fill(
            child: CustomPaint(painter: _HexGridPainter()),
          ),
          // Radial glow top-left
          Positioned(
            top: -120, left: -80,
            child: Container(
              width: 320, height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _C.cyan.withOpacity(0.07),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Radial glow bottom-right
          Positioned(
            bottom: -100, right: -60,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _C.purple.withOpacity(0.06),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          if (_isLoading)
            _buildSkeleton()
          else if (_hasError)
            CustomErrorWidget(onRetry: _loadAll)
          else
            RefreshIndicator(
              color: _C.cyan,
              backgroundColor: _C.bg2,
              strokeWidth: 2,
              onRefresh: _onRefresh,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildTopSection()),
                  _buildHistorySliver(),
                  if (_hasMoreData && _history.isNotEmpty)
                    SliverToBoxAdapter(child: _buildLoadMore()),
                  SliverToBoxAdapter(child: SizedBox(height: 100.h)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── TOP SECTION ──────────────────────────────────────────────────────────
  Widget _buildTopSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 56.h),
          _buildHeader(),
          SizedBox(height: 24.h),
          _buildBalanceCard(),
          SizedBox(height: 20.h),
          _buildQuickStats(),
          SizedBox(height: 20.h),
          _buildWithdrawButton(),
          SizedBox(height: 32.h),
          _buildSectionLabel('TRANSACTION HISTORY'),
          SizedBox(height: 14.h),
        ],
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
              'WITHDRAW',
              style: GoogleFonts.orbitron(
                color: _C.t1,
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: _C.green,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _C.green.withOpacity(0.6), blurRadius: 6)],
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  'BEP20 Network  •  Live',
                  style: GoogleFonts.rajdhani(
                    color: _C.t2,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: _isRefreshing ? null : _onRefresh,
          child: Container(
            width: 44.w, height: 44.h,
            decoration: BoxDecoration(
              color: _C.bg2,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: _C.b1),
            ),
            child: _isRefreshing
                ? Center(child: SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: _C.cyan),
                  ))
                : Center(child: SizedBox(
                    width: 24.w, height: 24.h,
                    child: Lottie.network(_L.refresh, repeat: false),
                  )),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return _NeonBorder(
      radius: 24,
      color: _C.cyan,
      animate: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _C.bg3.withOpacity(0.95),
                  _C.bg2.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(24.r),
            ),
            padding: EdgeInsets.all(24.w),
            child: Stack(
              children: [
                // Decorative circuit lines
                Positioned(
                  top: 0, right: 0,
                  child: CustomPaint(
                    size: const Size(80, 80),
                    painter: _CircuitPainter(color: _C.cyan.withOpacity(0.12)),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _GlowTag('● WITHDRAWABLE', color: _C.green),
                        Row(
                          children: [
                            SizedBox(
                              width: 18.w, height: 18.h,
                              child: Lottie.network(_L.wallet),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'BSC CHAIN',
                              style: GoogleFonts.orbitron(
                                color: _C.t2, fontSize: 9.sp, letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 22.h),
                    Text(
                      'Available Balance',
                      style: GoogleFonts.rajdhani(
                        color: _C.t2, fontSize: 13.sp, fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    AnimatedBuilder(
                      animation: _balAnim,
                      builder: (_, __) => RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: '\$',
                            style: GoogleFonts.orbitron(
                              color: _C.cyan.withOpacity(0.7),
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: _displayBal.toStringAsFixed(2),
                            style: GoogleFonts.orbitron(
                              color: _C.t1,
                              fontSize: 38.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                            ),
                          ),
                        ]),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _C.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _C.green.withOpacity(0.2)),
                          ),
                          child: Text(
                            'MIN \$5 · MAX \$10,000',
                            style: GoogleFonts.orbitron(
                              color: _C.green.withOpacity(0.8),
                              fontSize: 8.sp,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _C.amber.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _C.amber.withOpacity(0.2)),
                          ),
                          child: Text(
                            'ZERO FEE',
                            style: GoogleFonts.orbitron(
                              color: _C.amber,
                              fontSize: 8.sp,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.15, end: 0);
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _statTile('PENDING', '${_history.where((h) => h['status'] == 'pending').length}', _C.amber)),
        SizedBox(width: 10.w),
        Expanded(child: _statTile('APPROVED', '${_history.where((h) => h['status'] == 'approved').length}', _C.green)),
        SizedBox(width: 10.w),
        Expanded(child: _statTile('REJECTED', '${_history.where((h) => h['status'] == 'rejected').length}', _C.magenta)),
      ],
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: BoxDecoration(
        color: _C.bg2,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 16)],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.rajdhani(
              color: _C.t2,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildWithdrawButton() {
    return GestureDetector(
      onTap: _showWithdrawSheet,
      child: Container(
        width: double.infinity,
        height: 58.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF7B4FFF)],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(color: _C.cyan.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8)),
            BoxShadow(color: _C.purple.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28.w, height: 28.h,
              child: Lottie.network(_L.moneyOut),
            ),
            SizedBox(width: 12.w),
            Text(
              'WITHDRAW NOW',
              style: GoogleFonts.orbitron(
                color: Colors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3, height: 14,
          decoration: BoxDecoration(
            color: _C.cyan,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [BoxShadow(color: _C.cyan.withOpacity(0.6), blurRadius: 8)],
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: GoogleFonts.orbitron(
            color: _C.t2,
            fontSize: 11.sp,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── HISTORY ──────────────────────────────────────────────────────────────
  Widget _buildHistorySliver() {
    if (_history.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: _buildEmptyState(),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
          child: _buildTxCard(_history[i], i),
        ),
        childCount: _history.length,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      decoration: BoxDecoration(
        color: _C.bg2,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _C.b1),
      ),
      child: Column(
        children: [
          SizedBox(width: 100.w, height: 100.h, child: Lottie.network(_L.emptyHistory)),
          SizedBox(height: 14.h),
          Text('No transactions yet', style: GoogleFonts.orbitron(color: _C.t1, fontSize: 14.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 6.h),
          Text('Your withdrawals will appear here', style: GoogleFonts.rajdhani(color: _C.t2, fontSize: 13.sp)),
          SizedBox(height: 20.h),
          GestureDetector(
            onTap: _showWithdrawSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_C.cyan, _C.purple]),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'MAKE FIRST WITHDRAWAL',
                style: GoogleFonts.orbitron(color: Colors.black, fontSize: 10.sp, fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTxCard(Map<String, dynamic> data, int index) {
    final amount  = double.tryParse(data['amount']?.toString() ?? '0') ?? 0;
    final status  = data['status']?.toString() ?? 'pending';
    final address = data['wallet_address']?.toString() ?? '';
    final date    = data['created_at']?.toString() ?? '';
    final network = data['network']?.toString() ?? 'BEP20';

    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';

    final Color statusColor;
    final String statusLottie;
    final String statusText;

    if (isApproved) {
      statusColor = _C.green; statusLottie = _L.txSuccess; statusText = 'APPROVED';
    } else if (isRejected) {
      statusColor = _C.magenta; statusLottie = _L.txFailed; statusText = 'REJECTED';
    } else {
      statusColor = _C.amber; statusLottie = _L.txPending; statusText = 'PENDING';
    }

    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: address));
        _toast('Address copied!', _C.green);
      },
      child: Container(
        decoration: BoxDecoration(
          color: _C.bg2,
          borderRadius: BorderRadius.circular(16.r),
          border: Border(left: BorderSide(color: statusColor, width: 3)),
          boxShadow: [BoxShadow(color: statusColor.withOpacity(0.06), blurRadius: 20)],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: _C.b1),
          ),
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              Container(
                width: 46.w, height: 46.h,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: statusColor.withOpacity(0.25)),
                ),
                child: Center(
                  child: SizedBox(
                    width: 26.w, height: 26.h,
                    child: Lottie.network(statusLottie, repeat: status == 'pending'),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${amount.toStringAsFixed(2)}',
                      style: GoogleFonts.orbitron(
                        color: _C.t1,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _fmtAddr(address),
                      style: GoogleFonts.spaceMono(color: _C.t3, fontSize: 10.sp),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _fmtDate(date),
                      style: GoogleFonts.rajdhani(color: _C.t2, fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.orbitron(
                        color: statusColor,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    network,
                    style: GoogleFonts.spaceMono(color: _C.t2, fontSize: 10.sp),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.15, end: 0);
  }

  Widget _buildLoadMore() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Center(
        child: GestureDetector(
          onTap: () {
            if (_hasMoreData && !_isLoading) _loadAll(silent: true, loadMore: true);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: _C.bg2,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: _C.b2),
            ),
            child: Text(
              'LOAD MORE',
              style: GoogleFonts.orbitron(color: _C.cyan, fontSize: 10.sp, letterSpacing: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  // ── SKELETON ─────────────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: _C.bg2,
      highlightColor: _C.bg3,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            SizedBox(height: 60.h),
            Container(height: 200.h, decoration: BoxDecoration(color: _C.bg2, borderRadius: BorderRadius.circular(24.r))),
            SizedBox(height: 16.h),
            Row(children: List.generate(3, (_) => Expanded(child: Container(
              margin: EdgeInsets.only(right: _ < 2 ? 10.w : 0),
              height: 70.h,
              decoration: BoxDecoration(color: _C.bg2, borderRadius: BorderRadius.circular(14.r)),
            )))),
            SizedBox(height: 16.h),
            Container(height: 58.h, decoration: BoxDecoration(color: _C.bg2, borderRadius: BorderRadius.circular(16.r))),
            SizedBox(height: 24.h),
            ...List.generate(3, (_) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Container(height: 76.h, decoration: BoxDecoration(color: _C.bg2, borderRadius: BorderRadius.circular(16.r))),
            )),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  String _fmtAddr(String a) => a.length < 20 ? a : '${a.substring(0, 8)}...${a.substring(a.length - 8)}';
  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d);
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return d; }
  }

  void _showWithdrawSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WithdrawSheet(
        balance: _balance,
        headers: _headers(),
        onSuccess: () {
          Navigator.pop(context);
          _loadAll(silent: true);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CIRCUIT PAINTER  (decorative)
// ─────────────────────────────────────────────────────────────────────────────
class _CircuitPainter extends CustomPainter {
  final Color color;
  const _CircuitPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 1..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 20), Offset(size.width * 0.6, 20), p);
    canvas.drawLine(Offset(size.width * 0.6, 20), Offset(size.width * 0.6, 45), p);
    canvas.drawLine(Offset(size.width * 0.6, 45), Offset(size.width, 45), p);
    canvas.drawLine(Offset(size.width * 0.3, 20), Offset(size.width * 0.3, 0), p);
    canvas.drawCircle(Offset(size.width * 0.6, 20), 3, p..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(size.width * 0.3, 20), 3, p);
    p.style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width * 0.8, 45), Offset(size.width * 0.8, 70), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  WITHDRAW SHEET
// ─────────────────────────────────────────────────────────────────────────────
class WithdrawSheet extends StatefulWidget {
  final double balance;
  final Map<String, String> headers;
  final VoidCallback onSuccess;

  const WithdrawSheet({
    super.key,
    required this.balance,
    required this.headers,
    required this.onSuccess,
  });

  @override
  State<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<WithdrawSheet> with TickerProviderStateMixin {
  int    _step = 0;
  WithdrawMethod _method = _withdrawMethods[0];
  final _amtCtrl  = TextEditingController();
  final _addrCtrl = TextEditingController();
  bool   _busy    = false;
  String _err     = '';

  late AnimationController _successCtrl;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _amtCtrl.dispose(); _addrCtrl.dispose(); _successCtrl.dispose();
    super.dispose();
  }

  void _setMax() {
    if (widget.balance > 0) _amtCtrl.text = widget.balance.toStringAsFixed(2);
  }

  void _validate() {
    final amt  = double.tryParse(_amtCtrl.text) ?? 0;
    final addr = _addrCtrl.text.trim();

    if (amt <= 0) { setState(() => _err = 'Enter a valid amount'); return; }
    if (amt < _method.minAmount) { setState(() => _err = 'Minimum is \$${_method.minAmount}'); return; }
    if (amt > _method.maxAmount) { setState(() => _err = 'Maximum is \$${_method.maxAmount}'); return; }
    if (amt > widget.balance) { setState(() => _err = 'Insufficient balance'); return; }
    if (addr.isEmpty || !RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(addr)) {
      setState(() => _err = 'Enter a valid BEP20 address (0x...)');
      return;
    }
    setState(() { _err = ''; _step = 1; });
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/withdraw'),
        headers: widget.headers,
        body: jsonEncode({'amount': double.parse(_amtCtrl.text), 'wallet': _addrCtrl.text.trim()}),
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;
      final d = jsonDecode(res.body);

      if (res.statusCode == 200 && d['success'] == true) {
        setState(() => _busy = false);
        _successCtrl.forward();
        _showSuccess(d);
      } else {
        setState(() { _busy = false; _err = d['error'] ?? 'Withdrawal failed'; _step = 0; });
      }
    } on Exception catch (e) {
      if (mounted) setState(() { _busy = false; _err = e.toString().contains('timeout') ? 'Timeout. Try again.' : 'Connection error.'; _step = 0; });
    }
  }

  void _showSuccess(Map d) {
    final amount = d['data']?['amount']?.toString() ?? '0';
    final wallet = d['data']?['wallet']?.toString() ?? '';
    final id     = d['data']?['withdrawId']?.toString() ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Stack(
        children: [
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(ctx).size.width * 0.88,
                decoration: BoxDecoration(
                  color: _C.bg1,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: _C.green.withOpacity(0.4)),
                  boxShadow: [BoxShadow(color: _C.green.withOpacity(0.15), blurRadius: 40)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [_C.green.withOpacity(0.15), Colors.transparent],
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 80.w, height: 80.h,
                            child: Lottie.network(_L.txSuccess, repeat: false, controller: _successCtrl),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'REQUEST SUBMITTED',
                            style: GoogleFonts.orbitron(
                              color: _C.t1, fontSize: 16.sp, fontWeight: FontWeight.w700, letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Body
                    Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        children: [
                          Text(
                            '-\$$amount',
                            style: GoogleFonts.orbitron(
                              color: _C.magenta, fontSize: 32.sp, fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'BEP20 · PENDING APPROVAL',
                            style: GoogleFonts.rajdhani(color: _C.t2, fontSize: 13.sp, letterSpacing: 1),
                          ),
                          SizedBox(height: 8.h),
                          _fmtAddr(wallet).let((a) => Text(
                            a,
                            style: GoogleFonts.spaceMono(color: _C.t3, fontSize: 11.sp),
                          )),
                          SizedBox(height: 4.h),
                          Text(
                            'ID: #$id',
                            style: GoogleFonts.orbitron(color: _C.t3, fontSize: 10.sp, letterSpacing: 0.5),
                          ),
                          SizedBox(height: 24.h),
                          GestureDetector(
                            onTap: () { Navigator.pop(ctx); widget.onSuccess(); },
                            child: Container(
                              width: double.infinity,
                              height: 50.h,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [_C.green, _C.cyan]),
                                borderRadius: BorderRadius.circular(14.r),
                                boxShadow: [BoxShadow(color: _C.green.withOpacity(0.3), blurRadius: 20)],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'DONE',
                                style: GoogleFonts.orbitron(
                                  color: Colors.black, fontSize: 14.sp, fontWeight: FontWeight.w700, letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Lottie.network(_L.confetti, controller: _successCtrl, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtAddr(String a) => a.length < 20 ? a : '${a.substring(0, 8)}...${a.substring(a.length - 8)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: _C.bg1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border(
          top: BorderSide(color: _C.cyan.withOpacity(0.25), width: 1),
          left: BorderSide(color: _C.b1),
          right: BorderSide(color: _C.b1),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          // Drag handle
          Container(
            width: 36.w, height: 3.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_C.cyan, _C.purple]),
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          SizedBox(height: 20.h),
          _buildSheetHeader(),
          SizedBox(height: 24.h),
          _buildStepBar(),
          SizedBox(height: 24.h),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: _step == 0 ? _buildStep0() : _buildStep1(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: [
          Container(
            width: 46.w, height: 46.h,
            decoration: BoxDecoration(
              color: _C.magenta.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: _C.magenta.withOpacity(0.3)),
            ),
            child: Center(child: SizedBox(width: 26.w, height: 26.h, child: Lottie.network(_L.moneyOut))),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WITHDRAW FUNDS',
                  style: GoogleFonts.orbitron(color: _C.t1, fontSize: 16.sp, fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
                Text(
                  'Balance: \$${widget.balance.toStringAsFixed(2)}',
                  style: GoogleFonts.rajdhani(color: _C.cyan, fontSize: 13.sp, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _C.bg2,
                shape: BoxShape.circle,
                border: Border.all(color: _C.b2),
              ),
              child: const Icon(Icons.close, color: _C.t2, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: [
          _stepDot(0, 'AMOUNT'),
          Expanded(
            child: Stack(
              children: [
                Container(height: 1, color: _C.b1),
                if (_step >= 1)
                  Container(
                    height: 1,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [_C.cyan, _C.purple]),
                    ),
                  ),
              ],
            ),
          ),
          _stepDot(1, 'CONFIRM'),
        ],
      ),
    );
  }

  Widget _stepDot(int s, String label) {
    final active  = _step >= s;
    final current = _step == s;
    return Column(
      children: [
        Container(
          width: 36.w, height: 36.h,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(colors: [_C.cyan, _C.purple])
                : null,
            color: active ? null : _C.bg2,
            shape: BoxShape.circle,
            border: Border.all(color: active ? Colors.transparent : _C.b2, width: 1.5),
            boxShadow: active ? [BoxShadow(color: _C.cyan.withOpacity(0.3), blurRadius: 16)] : null,
          ),
          child: Center(
            child: active
                ? Icon(s == 0 ? Icons.account_balance_wallet_outlined : Icons.check_rounded,
                    color: Colors.black, size: 16)
                : Text('${s + 1}', style: GoogleFonts.orbitron(color: _C.t3, fontSize: 12.sp)),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: GoogleFonts.orbitron(
            color: active ? _C.cyan : _C.t3,
            fontSize: 8.sp,
            fontWeight: current ? FontWeight.w700 : FontWeight.normal,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ── STEP 0 ────────────────────────────────────────────────────────────────
  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('SELECT NETWORK'),
        SizedBox(height: 10.h),
        ..._withdrawMethods.map(_methodCard),
        SizedBox(height: 20.h),
        _label('AMOUNT (USD)'),
        SizedBox(height: 10.h),
        _amountField(),
        SizedBox(height: 20.h),
        _label('BEP20 WALLET ADDRESS'),
        SizedBox(height: 10.h),
        _addressField(),
        if (_err.isNotEmpty) ...[SizedBox(height: 12.h), _errBox()],
        SizedBox(height: 28.h),
        _primaryBtn('CONTINUE', _validate),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _label(String t) => Text(
    t,
    style: GoogleFonts.orbitron(color: _C.t2, fontSize: 10.sp, letterSpacing: 1.5, fontWeight: FontWeight.w600),
  );

  Widget _methodCard(WithdrawMethod m) {
    final sel = _method.symbol == m.symbol;
    return GestureDetector(
      onTap: () => setState(() => _method = m),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: sel ? m.color.withOpacity(0.08) : _C.bg2,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: sel ? m.color.withOpacity(0.5) : _C.b1, width: sel ? 1.5 : 1),
          boxShadow: sel ? [BoxShadow(color: m.color.withOpacity(0.1), blurRadius: 16)] : null,
        ),
        child: Row(
          children: [
            Container(
              width: 42.w, height: 42.h,
              decoration: BoxDecoration(
                color: m.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(child: SizedBox(width: 24.w, height: 24.h, child: Lottie.network(m.iconUrl))),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name, style: GoogleFonts.orbitron(color: _C.t1, fontSize: 13.sp, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2.h),
                  Text(
                    'Min \$${m.minAmount}  ·  Max \$${m.maxAmount}',
                    style: GoogleFonts.rajdhani(color: _C.t2, fontSize: 11.sp),
                  ),
                ],
              ),
            ),
            Container(
              width: 20.w, height: 20.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: sel ? m.color : _C.t3, width: 2),
                color: sel ? m.color : Colors.transparent,
              ),
              child: sel ? const Center(child: Icon(Icons.check, color: Colors.black, size: 12)) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountField() {
    return Container(
      decoration: BoxDecoration(
        color: _C.bg2,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _C.b2),
      ),
      child: TextField(
        controller: _amtCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.orbitron(color: _C.t1, fontSize: 18.sp, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: '0.00',
          hintStyle: GoogleFonts.orbitron(color: _C.t3, fontSize: 18.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 18.w, right: 6.w, top: 14.h),
            child: Text('\$', style: GoogleFonts.orbitron(color: _C.cyan, fontSize: 18.sp, fontWeight: FontWeight.w700)),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffix: GestureDetector(
            onTap: _setMax,
            child: Container(
              margin: EdgeInsets.only(right: 12.w),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_C.cyan, _C.green]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('MAX', style: GoogleFonts.orbitron(color: Colors.black, fontSize: 9.sp, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _addressField() {
    return Container(
      decoration: BoxDecoration(
        color: _C.bg2,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _C.b2),
      ),
      child: TextField(
        controller: _addrCtrl,
        style: GoogleFonts.spaceMono(color: _C.t1, fontSize: 12.sp),
        maxLines: 2,
        decoration: InputDecoration(
          hintText: '0x... BEP20 wallet address',
          hintStyle: GoogleFonts.spaceMono(color: _C.t3, fontSize: 12.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16.w),
          suffix: GestureDetector(
            onTap: () async {
              final d = await Clipboard.getData('text/plain');
              if (d?.text != null) { _addrCtrl.text = d!.text!.trim(); setState(() {}); }
            },
            child: Container(
              margin: EdgeInsets.all(10.w),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _C.purple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _C.purple.withOpacity(0.3)),
              ),
              child: SizedBox(width: 18.w, height: 18.h, child: Lottie.network(_L.copy)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errBox() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: _C.magenta.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _C.magenta.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SizedBox(width: 16.w, height: 16.h, child: Lottie.network(_L.warning, repeat: false)),
          SizedBox(width: 8.w),
          Expanded(child: Text(_err, style: GoogleFonts.rajdhani(color: _C.magenta, fontSize: 13.sp, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _primaryBtn(String label, VoidCallback onTap, {List<Color>? colors}) {
    final c = colors ?? [_C.cyan, _C.purple];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: c),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [BoxShadow(color: c.first.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.orbitron(color: Colors.black, fontSize: 14.sp, fontWeight: FontWeight.w700, letterSpacing: 1.5),
        ),
      ),
    );
  }

  // ── STEP 1 ────────────────────────────────────────────────────────────────
  Widget _buildStep1() {
    final amt = double.tryParse(_amtCtrl.text) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('TRANSACTION SUMMARY'),
        SizedBox(height: 16.h),
        Container(
          decoration: BoxDecoration(
            color: _C.bg2,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: _C.b1),
          ),
          child: Column(
            children: [
              _confirmRow('Network', _method.name),
              Divider(color: _C.b1, height: 1),
              _confirmRow('Amount', '\$${amt.toStringAsFixed(2)}'),
              Divider(color: _C.b1, height: 1),
              _confirmRow('To Wallet', _fmtAddr(_addrCtrl.text.trim())),
              Divider(color: _C.b1, height: 1),
              _confirmRow('Fee', 'ZERO', valueColor: _C.green),
              Divider(color: _C.b1, height: 1),
              _confirmRow('Total', '\$${amt.toStringAsFixed(2)}', valueColor: _C.magenta, bold: true),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: _C.amber.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: _C.amber.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              SizedBox(width: 18.w, height: 18.h, child: Lottie.network(_L.warning)),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Double-check the wallet address. Transactions cannot be reversed.',
                  style: GoogleFonts.rajdhani(color: _C.amber, fontSize: 12.sp, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 28.h),
        _busy
            ? Container(
                width: double.infinity, height: 56.h,
                decoration: BoxDecoration(
                  color: _C.bg3,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: _C.b2),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20.w, height: 20.h, child: Lottie.network(_L.verifyLoading)),
                    SizedBox(width: 10.w),
                    Text('PROCESSING...', style: GoogleFonts.orbitron(color: _C.cyan, fontSize: 12.sp, letterSpacing: 1.5)),
                  ],
                ),
              )
            : _primaryBtn('CONFIRM WITHDRAWAL', _confirm, colors: [_C.magenta, _C.purple]),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: () => setState(() { _step = 0; _err = ''; }),
          child: Container(
            width: double.infinity, height: 48.h,
            decoration: BoxDecoration(
              color: _C.bg2,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: _C.b2),
            ),
            alignment: Alignment.center,
            child: Text('BACK', style: GoogleFonts.orbitron(color: _C.t2, fontSize: 12.sp, letterSpacing: 1.5)),
          ),
        ),
        SizedBox(height: 32.h),
      ],
    );
  }

  Widget _confirmRow(String label, String value, {Color? valueColor, bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.rajdhani(color: _C.t2, fontSize: 14.sp, fontWeight: FontWeight.w500)),
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: valueColor ?? _C.t1,
              fontSize: bold ? 14.sp : 13.sp,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// Extension helper
extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
