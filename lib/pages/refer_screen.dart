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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfile();
    });
  }

  Future<void> _fetchProfile() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;

      if (token == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('https://web3.ltcminematrix.com/api/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final user = data['user'];
          if (mounted) {
            setState(() {
              _referralCode    = user['referral_code']?.toString() ?? "";
              _referredBy      = user['referred_by']?.toString() ?? "";
              _name            = user['name']?.toString() ?? "";
              _email           = user['email']?.toString() ?? "";
              _walletAddress   = user['wallet_address']?.toString() ?? "";
              _balance         = double.tryParse(user['balance']?.toString() ?? '0') ?? 0;
              _mainBalance     = double.tryParse(user['main_balance']?.toString() ?? '0') ?? 0;
              _miningBalance   = double.tryParse(user['mining_balance']?.toString() ?? '0') ?? 0;
              _coins           = double.tryParse(user['coins']?.toString() ?? '0') ?? 0;
              _withdrawable    = double.tryParse(user['withdrawable_coins']?.toString() ?? '0') ?? 0;
              _boostAmount     = double.tryParse(user['boost_amount']?.toString() ?? '0') ?? 0;
              _boostMultiplier = double.tryParse(user['boost_multiplier']?.toString() ?? '1') ?? 1;
              _isLoading       = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final referLink = "https://web3.ltcminematrix.com?ref=$_referralCode";

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF14F195)),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 30.h),

                    // ── Avatar ─────────────────────────────────────────────
                    Container(
                      height: 80.h,
                      width: 80.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [
                          const Color(0xFF14F195).withOpacity(0.25),
                          Colors.transparent,
                        ]),
                        border: Border.all(
                            color: const Color(0xFF14F195).withOpacity(0.4),
                            width: 1.5),
                      ),
                      child: Icon(Icons.person_rounded,
                          size: 38.sp, color: const Color(0xFF14F195)),
                    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

                    SizedBox(height: 12.h),

                    if (_name.isNotEmpty)
                      Text(_name,
                          style: GoogleFonts.inter(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),

                    if (_email.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Text(_email,
                            style: GoogleFonts.inter(
                                fontSize: 12.sp, color: Colors.white54)),
                      ),

                    SizedBox(height: 24.h),

                    // ── Balance Cards ──────────────────────────────────────
                    Row(children: [
                      Expanded(child: _balanceCard("Total Balance", _balance.toStringAsFixed(4), "LTC", const Color(0xFF14F195))),
                      SizedBox(width: 12.w),
                      Expanded(child: _balanceCard("Main Balance", _mainBalance.toStringAsFixed(4), "LTC", Colors.purpleAccent)),
                    ]).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

                    SizedBox(height: 12.h),

                    Row(children: [
                      Expanded(child: _balanceCard("Mining Balance", _miningBalance.toStringAsFixed(4), "LTC", Colors.orangeAccent)),
                      SizedBox(width: 12.w),
                      Expanded(child: _balanceCard("Withdrawable", _withdrawable.toStringAsFixed(2), "Coins", Colors.blueAccent)),
                    ]).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                    SizedBox(height: 12.h),

                    Row(children: [
                      Expanded(child: _balanceCard("Coins", _coins.toStringAsFixed(2), "Coins", Colors.amberAccent)),
                      SizedBox(width: 12.w),
                      Expanded(child: _balanceCard(
                        "Boost",
                        "${_boostMultiplier.toStringAsFixed(1)}x  +${_boostAmount.toStringAsFixed(2)}",
                        "Active",
                        Colors.redAccent,
                      )),
                    ]).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

                    SizedBox(height: 20.h),

                    // ── Wallet Address ─────────────────────────────────────
                    if (_walletAddress.isNotEmpty) ...[
                      _infoBox("Wallet Address", _walletAddress, false)
                          .animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                      SizedBox(height: 12.h),
                    ],

                    // ── Referral Code ──────────────────────────────────────
                    _infoBox(
                      "Your Referral Code",
                      _referralCode.isEmpty ? "N/A" : _referralCode,
                      true,
                    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),

                    SizedBox(height: 12.h),

                    _infoBox("Your Referral Link", referLink, false)
                        .animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                    if (_referredBy.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      _infoBox("Referred By", _referredBy, false)
                          .animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
                    ],

                    SizedBox(height: 30.h),

                    // ── Network Earnings ───────────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Network Earnings",
                          style: GoogleFonts.inter(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                    SizedBox(height: 15.h),

                    _levelCard("Level 1", "Direct Friends", "10% Reward", const Color(0xFF14F195))
                        .animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),
                    SizedBox(height: 12.h),
                    _levelCard("Level 2", "Friends of Friends", "5% Reward", Colors.orangeAccent)
                        .animate().fadeIn(delay: 600.ms).slideX(begin: 0.1),
                    SizedBox(height: 12.h),
                    _levelCard("Level 3", "Sub-Network", "2% Reward", Colors.blueAccent)
                        .animate().fadeIn(delay: 700.ms).slideX(begin: 0.1),

                    SizedBox(height: 35.h),

                    // ── Share Button ───────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 55.h,
                      child: ElevatedButton.icon(
                        onPressed: () => auth.shareReferralLink(),
                        icon: const Icon(Icons.share_rounded, color: Colors.black),
                        label: Text("Share Invite Link",
                            style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14F195),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.r)),
                        ),
                      ),
                    ).animate().scale(delay: 800.ms),

                    SizedBox(height: 50.h),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _balanceCard(String label, String value, String unit, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B22),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.sp)),
        SizedBox(height: 6.h),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(color: color, fontSize: 15.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 2.h),
        Text(unit, style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp)),
      ]),
    );
  }

  Widget _infoBox(String title, String content, bool isCode) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B22),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11.sp)),
        SizedBox(height: 8.h),
        Row(children: [
          Expanded(
            child: Text(content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF14F195),
                  fontSize: isCode ? 22.sp : 13.sp,
                  fontWeight: isCode ? FontWeight.bold : FontWeight.w400,
                )),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Copied to clipboard!")),
              );
            },
            icon: Icon(Icons.copy_rounded, color: Colors.white70, size: 18.sp),
          ),
        ]),
      ]),
    );
  }

  Widget _levelCard(String level, String desc, String reward, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B22),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.group_add_rounded, color: color, size: 22.sp),
        ),
        SizedBox(width: 15.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(level, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp)),
            Text(desc, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11.sp)),
          ]),
        ),
        Text(reward, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold, fontSize: 14.sp)),
      ]),
    );
  }
}

