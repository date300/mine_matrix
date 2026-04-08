import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../providers/auth_provider.dart';

class ReferScreen extends StatefulWidget {
  const ReferScreen({super.key});

  @override
  State<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends State<ReferScreen> {
  bool _isLoading = true;
  bool _hasError  = false;

  // Profile fields — API থেকে আসা সব data
  int    _id              = 0;
  String _walletAddress   = "";
  String _referralCode    = "";
  String _referredBy      = "";
  String _name            = "";
  String _email           = "";
  String _balance         = "0.00";
  String _mainBalance     = "0.00";
  String _miningBalance   = "0.00";
  String _coins           = "0.00";
  String _withdrawable    = "0.00";
  String _boostAmount     = "0.00";
  String _boostMultiplier = "1.0";

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
        if (mounted) setState(() { _isLoading = false; _hasError = true; });
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
            _id              = u['id'] ?? 0;
            _walletAddress   = u['wallet_address']?.toString()   ?? "";
            _referralCode    = u['referral_code']?.toString()    ?? "";
            _referredBy      = u['referred_by']?.toString()      ?? "";
            _name            = u['name']?.toString()             ?? "";
            _email           = u['email']?.toString()            ?? "";
            _balance         = u['balance']?.toString()          ?? "0.00";
            _mainBalance     = u['main_balance']?.toString()     ?? "0.00";
            _miningBalance   = u['mining_balance']?.toString()   ?? "0.00";
            _coins           = u['coins']?.toString()            ?? "0.00";
            _withdrawable    = u['withdrawable_coins']?.toString() ?? "0.00";
            _boostAmount     = u['boost_amount']?.toString()     ?? "0.00";
            _boostMultiplier = u['boost_multiplier']?.toString() ?? "1.0";
            _isLoading       = false;
          });
        } else {
          setState(() { _isLoading = false; _hasError = true; });
        }
      } else {
        setState(() { _isLoading = false; _hasError = true; });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

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
                      padding: EdgeInsets.symmetric(horizontal: 18.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20.h),

                          // ── Profile Card ──────────────────────────────
                          _buildProfileCard()
                              .animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),

                          SizedBox(height: 20.h),

                          // ── Balance Section ───────────────────────────
                          _label("💰 Balances"),
                          SizedBox(height: 10.h),
                          Row(children: [
                            Expanded(child: _balCard("Balance", _balance, "LTC", _green)
                                .animate().fadeIn(delay: 100.ms).slideY(begin: 0.1)),
                            SizedBox(width: 10.w),
                            Expanded(child: _balCard("Main", _mainBalance, "LTC", Colors.purpleAccent)
                                .animate().fadeIn(delay: 150.ms).slideY(begin: 0.1)),
                          ]),
                          SizedBox(height: 10.h),
                          Row(children: [
                            Expanded(child: _balCard("Mining", _miningBalance, "LTC", Colors.orangeAccent)
                                .animate().fadeIn(delay: 200.ms).slideY(begin: 0.1)),
                            SizedBox(width: 10.w),
                            Expanded(child: _balCard("Withdrawable", _withdrawable, "Coins", Colors.blueAccent)
                                .animate().fadeIn(delay: 250.ms).slideY(begin: 0.1)),
                          ]),
                          SizedBox(height: 10.h),
                          Row(children: [
                            Expanded(child: _balCard("Coins", _coins, "Coins", Colors.amberAccent)
                                .animate().fadeIn(delay: 300.ms).slideY(begin: 0.1)),
                            SizedBox(width: 10.w),
                            Expanded(child: _balCard("Boost Amount", _boostAmount, "Bonus", Colors.redAccent)
                                .animate().fadeIn(delay: 350.ms).slideY(begin: 0.1)),
                          ]),

                          SizedBox(height: 10.h),

                          // ── Boost Multiplier ──────────────────────────
                          _buildBoostBar()
                              .animate().fadeIn(delay: 380.ms).slideY(begin: 0.1),

                          SizedBox(height: 20.h),

                          // ── Referral Info ─────────────────────────────
                          _label("🔗 Referral Info"),
                          SizedBox(height: 10.h),
                          _infoBox("Referral Code", _referralCode.isEmpty ? "N/A" : _referralCode, isCode: true)
                              .animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                          SizedBox(height: 10.h),
                          _infoBox("Referral Link", referLink, isCode: false)
                              .animate().fadeIn(delay: 440.ms).slideY(begin: 0.1),
                          if (_referredBy.isNotEmpty && _referredBy != "null") ...[
                            SizedBox(height: 10.h),
                            _infoBox("Referred By", _referredBy, isCode: false)
                                .animate().fadeIn(delay: 470.ms).slideY(begin: 0.1),
                          ],

                          SizedBox(height: 20.h),

                          // ── Network Levels ────────────────────────────
                          _label("🌐 Network Earnings"),
                          SizedBox(height: 10.h),
                          _levelCard("Level 1", "Direct Referrals",   "10% Reward", _green)
                              .animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),
                          SizedBox(height: 8.h),
                          _levelCard("Level 2", "Friends of Friends", "5% Reward",  Colors.orangeAccent)
                              .animate().fadeIn(delay: 560.ms).slideX(begin: 0.1),
                          SizedBox(height: 8.h),
                          _levelCard("Level 3", "Sub-Network",        "2% Reward",  Colors.blueAccent)
                              .animate().fadeIn(delay: 620.ms).slideX(begin: 0.1),

                          SizedBox(height: 28.h),

                          // ── Share Button ──────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 52.h,
                            child: ElevatedButton.icon(
                              onPressed: () => auth.shareReferralLink(),
                              icon: const Icon(Icons.share_rounded, color: Colors.black),
                              label: Text("Share Invite Link",
                                  style: GoogleFonts.inter(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _green,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14.r)),
                              ),
                            ),
                          ).animate().scale(delay: 680.ms),

                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  // ── Profile Card ────────────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: _green.withOpacity(0.25)),
      ),
      child: Row(children: [
        Container(
          height: 60.h,
          width: 60.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [
              _green.withOpacity(0.3),
              Colors.transparent,
            ]),
            border: Border.all(color: _green.withOpacity(0.5), width: 1.5),
          ),
          child: Icon(Icons.person_rounded, size: 30.sp, color: _green),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_name.isNotEmpty)
              Text(_name,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp)),
            if (_email.isNotEmpty)
              Text(_email,
                  style: GoogleFonts.inter(
                      color: Colors.white54, fontSize: 11.sp)),
            SizedBox(height: 4.h),
            // Wallet address (short)
            if (_walletAddress.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _walletAddress));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Wallet copied!",
                        style: GoogleFonts.inter(color: Colors.black)),
                    backgroundColor: _green,
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
                child: Row(children: [
                  Icon(Icons.wallet_rounded, size: 11.sp, color: _green),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      "${_walletAddress.substring(0, 8)}...${_walletAddress.substring(_walletAddress.length - 6)}",
                      style: GoogleFonts.inter(color: _green, fontSize: 11.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.copy_rounded, size: 10.sp, color: Colors.white38),
                ]),
              ),
          ]),
        ),
        // User ID badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: _green.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            "#$_id",
            style: GoogleFonts.inter(
                color: _green, fontWeight: FontWeight.bold, fontSize: 12.sp),
          ),
        ),
      ]),
    );
  }

  // ── Boost Bar ───────────────────────────────────────────────────────────────
  Widget _buildBoostBar() {
    final multiplier = double.tryParse(_boostMultiplier) ?? 1.0;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
      ),
      child: Row(children: [
        Icon(Icons.rocket_launch_rounded, color: Colors.redAccent, size: 22.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Boost Multiplier",
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.sp)),
            SizedBox(height: 4.h),
            Text("${multiplier.toStringAsFixed(1)}x Speed",
                style: GoogleFonts.inter(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp)),
          ]),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            "${multiplier.toStringAsFixed(1)}x",
            style: GoogleFonts.inter(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp),
          ),
        ),
      ]),
    );
  }

  // ── Balance Card ────────────────────────────────────────────────────────────
  Widget _balCard(String label, String value, String unit, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 6.w, height: 6.w,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: 6.w),
          Text(label,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.sp)),
        ]),
        SizedBox(height: 8.h),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                color: color, fontSize: 15.sp, fontWeight: FontWeight.bold)),
        Text(unit,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp)),
      ]),
    );
  }

  // ── Info Box ────────────────────────────────────────────────────────────────
  Widget _infoBox(String title, String content, {required bool isCode}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
            child: Text(content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: _green,
                  fontSize: isCode ? 20.sp : 13.sp,
                  fontWeight: isCode ? FontWeight.bold : FontWeight.w400,
                )),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: content));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Copied!",
                    style: GoogleFonts.inter(color: Colors.black)),
                backgroundColor: _green,
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: Container(
              padding: EdgeInsets.all(7.w),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.copy_rounded, color: _green, size: 15.sp),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Level Card ──────────────────────────────────────────────────────────────
  Widget _levelCard(String level, String desc, String reward, Color color) {
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
        SizedBox(width: 12.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(level,
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp)),
          Text(desc,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 11.sp)),
        ])),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(reward,
              style: GoogleFonts.inter(
                  color: color, fontWeight: FontWeight.bold, fontSize: 11.sp)),
        ),
      ]),
    );
  }

  // ── Section Label ───────────────────────────────────────────────────────────
  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.white70));

  // ── Error State ─────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.cloud_off_rounded, color: Colors.white30, size: 48.sp),
        SizedBox(height: 12.h),
        Text("Could not load profile",
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14.sp)),
        SizedBox(height: 16.h),
        ElevatedButton.icon(
          onPressed: _fetchProfile,
          icon: const Icon(Icons.refresh_rounded, color: Colors.black),
          label: Text("Retry",
              style: GoogleFonts.inter(
                  color: Colors.black, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: _green),
        ),
      ]),
    );
  }
}
