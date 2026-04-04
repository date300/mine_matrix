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

  // Profile fields
  String _referralCode = "";
  String _referredBy = "";
  String _name = "";
  String _email = "";
  String _walletAddress = "";
  double _balance = 0;
  double _mainBalance = 0;
  double _miningBalance = 0;
  double _coins = 0;
  double _withdrawableCoins = 0;
  double _boostAmount = 0;
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
              _referralCode = user['referral_code']?.toString() ?? "";
              _referredBy = user['referred_by']?.toString() ?? "";
              _name = user['name']?.toString() ?? "";
              _email = user['email']?.toString() ?? "";
              _walletAddress = user['wallet_address']?.toString() ?? "";
              _balance = double.tryParse(user['balance']?.toString() ?? '0') ?? 0;
              _mainBalance = double.tryParse(user['main_balance']?.toString() ?? '0') ?? 0;
              _miningBalance = double.tryParse(user['mining_balance']?.toString() ?? '0') ?? 0;
              _coins = double.tryParse(user['coins']?.toString() ?? '0') ?? 0;
              _withdrawableCoins = double.tryParse(user['withdrawable_coins']?.toString() ?? '0') ?? 0;
              _boostAmount = double.tryParse(user['boost_amount']?.toString() ?? '0') ?? 0;
              _boostMultiplier = double.tryParse(user['boost_multiplier']?.toString() ?? '1') ?? 1;
              _isLoading = false;
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

                    // ── Avatar & Name ──────────────────────────────────────
                    Container(
                      height: 80.h,
                      width: 80.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF14F195).withOpacity(0.25),
                            Colors.transparent,
                          ],
                        ),
                        border: Border.all(
                            color: const Color(0xFF14F195).withOpacity(0.4),
                            width: 1.5),
                      ),
                      child: Icon(Icons.person_rounded,
                          size: 38.sp, color: const Color(0xFF14F195)),
                    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

                    SizedBox(height: 12.h),

                    if (_name.isNotEmpty)
                      Text(
                        _name,
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                    if (_email.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Text(
                          _email,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.white54,
                          ),
                        ),
                      ),

                    SizedBox(height: 24.h),

                    // ── Balance Cards Row ──────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _buildBalanceCard(
                            label: "Total Balance",
                            value: _balance.toStringAsFixed(4),
                            unit: "LTC",
                            iconColor: const Color(0xFF14F195),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildBalanceCard(
                            label: "Main Balance",
                            value: _mainBalance.toStringAsFixed(4),
                            unit: "LTC",
                            iconColor: Colors.purpleAccent,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

                    SizedBox(height: 12.h),

                    Row(
                      children: [
                        Expanded(
                          child: _buildBalanceCard(
                            label: "Mining Balance",
                            value: _miningBalance.toStringAsFixed(4),
                            unit: "LTC",
                            iconColor: Colors.orangeAccent,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildBalanceCard(
                            label: "Withdrawable",
                            value: _withdrawableCoins.toStringAsFixed(2),
                            unit: "Coins",
                            iconColor: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                    SizedBox(height: 12.h),

                    // ── Coins & Boost Row ──────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _buildBalanceCard(
                            label: "Coins",
                            value: _coins.toStringAsFixed(2),
                            unit: "Coins",
                            iconColor: Colors.amberAccent,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildBalanceCard(
                            label: "Boost",
                            value:
                                "${_boostMultiplier.toStringAsFixed(1)}x  (+${_boostAmount.toStringAsFixed(2)})",
                            unit: "Active",
                            iconColor: Colors.redAccent,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

                    SizedBox(height: 20.h),

                    // ── Wallet Address ────────────────────────────────────
                    if (_walletAddress.isNotEmpty)
                      _buildInfoBox(
                        title: "Wallet Address",
                        content: _walletAddress,
                        isCode: false,
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                    if (_walletAddress.isNotEmpty) SizedBox(height: 12.h),

                    // ── Referral Code ─────────────────────────────────────
                    _buildInfoBox(
                      title: "Your Referral Code",
                      content: _referralCode.isEmpty ? "N/A" : _referralCode,
                      isCode: true,
                    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),

                    SizedBox(height: 12.h),

                    _buildInfoBox(
                      title: "Your Referral Link",
                      content: referLink,
                      isCode: false,
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                    if (_referredBy.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      _buildInfoBox(
                        title: "Referred By",
                        content: _referredBy,
                        isCode: false,
                      ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
                    ],

                    SizedBox(height: 30.h),

                    // ── Network Earnings ──────────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Network Earnings",
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),

                    _buildLevelCard(
                      levelName: "Level 1",
                      description: "Direct Friends",
                      reward: "10% Reward",
                      iconColor: const Color(0xFF14F195),
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),

                    SizedBox(height: 12.h),

                    _buildLevelCard(
                      levelName: "Level 2",
                      description: "Friends of Friends",
                      reward: "5% Reward",
                      iconColor: Colors.orangeAccent,
                    ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1),

                    SizedBox(height: 12.h),

                    _buildLevelCard(
                      levelName: "Level 3",
                      description: "Sub-Network",
                      reward: "2% Reward",
                      iconColor: Colors.blueAccent,
                    ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.1),

                    SizedBox(height: 35.h),

                    // ── Share Button ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 55.h,
                      child: ElevatedButton.icon(
                        onPressed: () => auth.shareReferralLink(),
                        icon: const Icon(Icons.share_rounded, color: Colors.black),
                        label: Text(
                          "Share Invite Link",
                          style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
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

  // ── Balance Card ─────────────────────────────────────────────────────────
  Widget _buildBalanceCard({
    required String label,
    required String value,
    required String unit,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B22),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  GoogleFonts.inter(color: Colors.white54, fontSize: 10.sp)),
          SizedBox(height: 6.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: iconColor,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(unit,
              style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 9.sp)),
        ],
      ),
    );
  }

  // ── Info Box (code / link / wallet) ──────────────────────────────────────
  Widget _buildInfoBox(
      {required String title,
      required String content,
      required bool isCode}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B22),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  color: Colors.white54, fontSize: 11.sp)),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF14F195),
                    fontSize: isCode ? 22.sp : 13.sp,
                    fontWeight:
                        isCode ? FontWeight.bold : FontWeight.w400,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Copied to clipboard!")),
                  );
                },
                icon: Icon(Icons.copy_rounded,
                    color: Colors.white70, size: 18.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Level Card ────────────────────────────────────────────────────────────
  Widget _buildLevelCard({
    required String levelName,
    required String description,
    required String reward,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B22),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.group_add_rounded,
                color: iconColor, size: 22.sp),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(levelName,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp)),
                Text(description,
                    style: GoogleFonts.inter(
                        color: Colors.white54, fontSize: 11.sp)),
              ],
            ),
          ),
          Text(reward,
              style: GoogleFonts.inter(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp)),
        ],
      ),
    );
  }
}
