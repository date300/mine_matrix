import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

class ReferScreen extends StatefulWidget {
  const ReferScreen({super.key});

  @override
  State<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends State<ReferScreen> {
  bool _isLoading = true;
  bool _hasError = false;

  String _referralCode    = "";
  String _referredBy      = "";
  String _name            = "";
  String _email           = "";
  String _walletAddress   = "";
  double _balance         = 0;
  double _mainBalance     = 0;
  double _miningBalance   = 0;
  double _coins           = 0;
  double _withdrawable    = 0;
  double _boostAmount     = 0;
  double _boostMultiplier = 1;

  static const _green  = Color(0xFF14F195);
  static const _bgCard = Color(0xFF1B1B22);
  static const _bg     = Color(0xFF0D0D12);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchProfile());
  }

  Future<void> _fetchProfile() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _hasError = false; });

    try {
      final auth  = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;

      if (token == null) {
        setState(() { _isLoading = false; _hasError = true; });
        return;
      }

      final response = await http.get(
        Uri.parse('https://web3.ltcminematrix.com/api/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final u = data['user'];
          setState(() {
            _referralCode    = u['referral_code']?.toString()    ?? "";
            _referredBy      = u['referred_by']?.toString()      ?? "";
            _name            = u['name']?.toString()             ?? "";
            _email           = u['email']?.toString()            ?? "";
            _walletAddress   = u['wallet_address']?.toString()   ?? "";
            _balance         = _d(u['balance']);
            _mainBalance     = _d(u['main_balance']);
            _miningBalance   = _d(u['mining_balance']);
            _coins           = _d(u['coins']);
            _withdrawable    = _d(u['withdrawable_coins']);
            _boostAmount     = _d(u['boost_amount']);
            _boostMultiplier = _d(u['boost_multiplier'], def: 1);
            _isLoading       = false;
          });
        } else {
          setState(() { _isLoading = false; _hasError = true; });
        }
      } else {
        setState(() { _isLoading = false; _hasError = true; });
      }
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  double _d(dynamic v, {double def = 0}) =>
      double.tryParse(v?.toString() ?? '') ?? def;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth      = Provider.of<AuthProvider>(context);
    final referLink = "https://web3.ltcminematrix.com?ref=$_referralCode";

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _green))
            : _hasError
                ? _buildError()
                : RefreshIndicator(
                    color: _green,
                    backgroundColor: _bgCard,
                    onRefresh: _fetchProfile,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 24.h),

                          // ── Profile Header ───────────────────────────────
                          _buildProfileHeader(),

                          SizedBox(height: 24.h),

                          // ── Balance Grid ─────────────────────────────────
                          _sectionLabel("💰 Balances"),
                          SizedBox(height: 12.h),
                          _buildBalanceGrid(),

                          SizedBox(height: 24.h),

                          // ── Boost Card ───────────────────────────────────
                          _sectionLabel("⚡ Boost Status"),
                          SizedBox(height: 12.h),
                          _buildBoostCard()
                              .animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                          SizedBox(height: 24.h),

                          // ── Wallet & Referral Info ───────────────────────
                          _sectionLabel("🔗 Your Info"),
                          SizedBox(height: 12.h),

                          if (_walletAddress.isNotEmpty) ...[
                            _infoBox("Wallet Address", _walletAddress, isCode: false)
                                .animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                            SizedBox(height: 10.h),
                          ],

                          _infoBox(
                            "Referral Code",
                            _referralCode.isEmpty ? "N/A" : _referralCode,
                            isCode: true,
                          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                          SizedBox(height: 10.h),

                          _infoBox("Referral Link", referLink, isCode: false)
                              .animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),

                          if (_referredBy.isNotEmpty) ...[
                            SizedBox(height: 10.h),
                            _infoBox("Referred By", _referredBy, isCode: false)
                                .animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                          ],

                          SizedBox(height: 24.h),

                          // ── Network Earnings ─────────────────────────────
                          _sectionLabel("🌐 Network Earnings"),
                          SizedBox(height: 12.h),
                          _buildLevelCard("Level 1", "Direct Referrals",   "10%", _green,             delay: 550)
                              .animate().fadeIn(delay: 550.ms).slideX(begin: 0.1),
                          SizedBox(height: 10.h),
                          _buildLevelCard("Level 2", "Friends of Friends", "5%",  Colors.orangeAccent, delay: 620)
                              .animate().fadeIn(delay: 620.ms).slideX(begin: 0.1),
                          SizedBox(height: 10.h),
                          _buildLevelCard("Level 3", "Sub-Network",        "2%",  Colors.blueAccent,   delay: 690)
                              .animate().fadeIn(delay: 690.ms).slideX(begin: 0.1),

                          SizedBox(height: 30.h),

                          // ── Share Button ──────────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 54.h,
                            child: ElevatedButton.icon(
                              onPressed: () => auth.shareReferralLink(),
                              icon: const Icon(Icons.share_rounded, color: Colors.black),
                              label: Text(
                                "Share Invite Link",
                                style: GoogleFonts.inter(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _green,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14.r)),
                              ),
                            ),
                          ).animate().scale(delay: 750.ms),

                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  // ── Profile Header ─────────────────────────────────────────────────────────
  Widget _buildProfileHeader() {
    return Column(children: [
      Container(
        height: 78.h,
        width: 78.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [
            _green.withOpacity(0.25),
            Colors.transparent,
          ]),
          border: Border.all(color: _green.withOpacity(0.45), width: 1.5),
        ),
        child: Icon(Icons.person_rounded, size: 36.sp, color: _green),
      ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

      SizedBox(height: 12.h),

      if (_name.isNotEmpty)
        Text(_name,
            style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white))
            .animate().fadeIn(delay: 200.ms),

      if (_email.isNotEmpty)
        Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Text(_email,
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.white54)),
        ).animate().fadeIn(delay: 250.ms),
    ]);
  }

  // ── Balance Grid ───────────────────────────────────────────────────────────
  Widget _buildBalanceGrid() {
    final items = [
      ("Total",      _balance.toStringAsFixed(4),      "LTC",   _green),
      ("Main",       _mainBalance.toStringAsFixed(4),   "LTC",   Colors.purpleAccent),
      ("Mining",     _miningBalance.toStringAsFixed(4), "LTC",   Colors.orangeAccent),
      ("Withdrawable", _withdrawable.toStringAsFixed(2),"Coins", Colors.blueAccent),
      ("Coins",      _coins.toStringAsFixed(2),         "Coins", Colors.amberAccent),
    ];

    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: items.asMap().entries.map((e) {
        final i = e.key;
        final item = e.value;
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 50.w) / 2,
          child: _balanceCard(item.$1, item.$2, item.$3, item.$4)
              .animate().fadeIn(delay: Duration(milliseconds: 150 + i * 60))
              .slideY(begin: 0.1),
        );
      }).toList(),
    );
  }

  // ── Boost Card ─────────────────────────────────────────────────────────────
  Widget _buildBoostCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        gradient: LinearGradient(
          colors: [
            Colors.redAccent.withOpacity(0.08),
            _bgCard,
          ],
        ),
      ),
      child: Row(children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.rocket_launch_rounded,
              color: Colors.redAccent, size: 24.sp),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Boost Active",
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp)),
            SizedBox(height: 4.h),
            Text(
              "${_boostMultiplier.toStringAsFixed(1)}x Multiplier  •  +${_boostAmount.toStringAsFixed(2)} Bonus",
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 11.sp),
            ),
          ]),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            "${_boostMultiplier.toStringAsFixed(1)}x",
            style: GoogleFonts.inter(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp),
          ),
        ),
      ]),
    );
  }

  // ── Balance Card ───────────────────────────────────────────────────────────
  Widget _balanceCard(String label, String value, String unit, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 6.w),
          Text(label,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.sp)),
        ]),
        SizedBox(height: 8.h),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                color: color, fontSize: 16.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 2.h),
        Text(unit,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp)),
      ]),
    );
  }

  // ── Info Box ───────────────────────────────────────────────────────────────
  Widget _infoBox(String title, String content, {required bool isCode}) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 10.sp)),
        SizedBox(height: 6.h),
        Row(children: [
          Expanded(
            child: Text(
              content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: _green,
                fontSize: isCode ? 20.sp : 13.sp,
                fontWeight: isCode ? FontWeight.bold : FontWeight.w400,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: content));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$title copied!",
                      style: GoogleFonts.inter(color: Colors.black)),
                  backgroundColor: _green,
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.copy_rounded, color: _green, size: 16.sp),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Level Card ─────────────────────────────────────────────────────────────
  Widget _buildLevelCard(String level, String desc, String pct, Color color,
      {int delay = 0}) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(Icons.group_add_rounded, color: color, size: 20.sp),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(level,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp)),
            Text(desc,
                style:
                    GoogleFonts.inter(color: Colors.white54, fontSize: 11.sp)),
          ]),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text("$pct Reward",
              style: GoogleFonts.inter(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp)),
        ),
      ]),
    );
  }

  // ── Section Label ──────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white70)),
    );
  }

  // ── Error State ────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.wifi_off_rounded, color: Colors.white30, size: 48.sp),
        SizedBox(height: 12.h),
        Text("Could not load profile",
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14.sp)),
        SizedBox(height: 16.h),
        ElevatedButton(
          onPressed: _fetchProfile,
          style: ElevatedButton.styleFrom(backgroundColor: _green),
          child: Text("Retry",
              style: GoogleFonts.inter(
                  color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}
