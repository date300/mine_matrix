import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_error_widget.dart';

class ReferScreen extends StatefulWidget {
  const ReferScreen({super.key});

  @override
  State<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends State<ReferScreen> {
  bool _isLoading = true;
  bool _hasError  = false;

  // API data
  String _referralCode = "";
  String _referralLink = "";
  Map<String, dynamic>? _referredBy;
  Map<String, dynamic>? _network;
  List<dynamic> _levelProgress     = [];
  Map<String, dynamic>? _commission;
  List<dynamic> _commissionHistory  = [];
  List<dynamic> _referralTree       = [];
  Map<String, dynamic>? _guide;

  static const _green  = Color(0xFF14F195);
  static const _bgCard = Color(0xFF1B1B22);
  static const _bg     = Color(0xFF0D0D12);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchStats());
  }

  Future<void> _fetchStats() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _hasError = false; });

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        setState(() { _isLoading = false; _hasError = true; });
        return;
      }

      final response = await http.get(
        Uri.parse('https://web3.ltcminematrix.com/api/referral/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _referralCode      = data['myReferralCode']  ?? "";
          _referralLink      = data['referralLink']     ?? "";
          _referredBy        = data['referredBy'];
          _network           = data['network'];
          _levelProgress     = data['levelProgress']    ?? [];
          _commission        = data['commission'];
          _commissionHistory = data['commissionHistory'] ?? [];
          _referralTree      = data['referralTree']     ?? [];
          _guide             = data['guide'];
          _isLoading         = false;
        });
      } else {
        setState(() { _isLoading = false; _hasError = true; });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("$label copied!",
          style: GoogleFonts.inter(color: Colors.black)),
      backgroundColor: _green,
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _green))
            : _hasError
                ? CustomErrorWidget(onRetry: _fetchStats)
                : RefreshIndicator(
                    color: _green,
                    backgroundColor: _bgCard,
                    onRefresh: _fetchStats,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 18.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20.h),

                          // ── Referral Link Card ──
                          _buildLinkCard()
                              .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                          SizedBox(height: 16.h),

                          // ── Network Summary ──
                          _label("🌐 My Network"),
                          SizedBox(height: 10.h),
                          _buildNetworkSummary()
                              .animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                          SizedBox(height: 20.h),

                          // ── Level Progress ──
                          _label("🏆 Level Progress"),
                          SizedBox(height: 10.h),
                          ..._levelProgress.asMap().entries.map((e) =>
                            Padding(
                              padding: EdgeInsets.only(bottom: 10.h),
                              child: _buildLevelCard(e.value)
                                  .animate().fadeIn(delay: Duration(milliseconds: 150 + e.key * 80))
                                  .slideX(begin: 0.1),
                            ),
                          ),

                          SizedBox(height: 10.h),

                          // ── Commission Summary ──
                          _label("💰 Commission Earned"),
                          SizedBox(height: 10.h),
                          _buildCommissionSummary()
                              .animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                          SizedBox(height: 20.h),

                          // ── Referral Tree ──
                          if (_referralTree.isNotEmpty) ...[
                            _label("🌳 Referral Tree"),
                            SizedBox(height: 10.h),
                            _buildTree()
                                .animate().fadeIn(delay: 450.ms),
                            SizedBox(height: 20.h),
                          ],

                          // ── Commission History ──
                          if (_commissionHistory.isNotEmpty) ...[
                            _label("📋 Commission History"),
                            SizedBox(height: 10.h),
                            _buildHistory()
                                .animate().fadeIn(delay: 500.ms),
                            SizedBox(height: 20.h),
                          ],

                          // ── Guide ──
                          _label("📖 How It Works"),
                          SizedBox(height: 10.h),
                          _buildGuide()
                              .animate().fadeIn(delay: 550.ms),

                          SizedBox(height: 20.h),

                          // ── Referred By ──
                          if (_referredBy != null) ...[
                            _label("👤 Referred By"),
                            SizedBox(height: 10.h),
                            _buildReferredBy()
                                .animate().fadeIn(delay: 580.ms),
                            SizedBox(height: 20.h),
                          ],

                          // ── Share Button ──
                          SizedBox(
                            width: double.infinity,
                            height: 52.h,
                            child: ElevatedButton.icon(
                              onPressed: () => Share.share(
                                  "Join LTC Mine Matrix and start earning! Use my referral link: $_referralLink"),
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
                          ).animate().scale(delay: 620.ms),

                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // Referral Link Card
  // ══════════════════════════════════════════
  Widget _buildLinkCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: _green.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.link_rounded, color: _green, size: 18.sp),
          SizedBox(width: 8.w),
          Text("Your Referral",
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
        ]),
        SizedBox(height: 14.h),

        // Code
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Code", style: GoogleFonts.inter(color: Colors.white38, fontSize: 10.sp)),
              SizedBox(height: 4.h),
              Text(_referralCode,
                  style: GoogleFonts.inter(
                      color: _green, fontSize: 22.sp, fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
            ]),
          ),
          GestureDetector(
            onTap: () => _copy(_referralCode, "Referral code"),
            child: _copyBtn(),
          ),
        ]),

        SizedBox(height: 12.h),
        Divider(color: Colors.white10),
        SizedBox(height: 12.h),

        // Link
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Invite Link", style: GoogleFonts.inter(color: Colors.white38, fontSize: 10.sp)),
              SizedBox(height: 4.h),
              Text(_referralLink,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: _green, fontSize: 11.sp)),
            ]),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () => _copy(_referralLink, "Referral link"),
            child: _copyBtn(),
          ),
        ]),
      ]),
    );
  }

  // ══════════════════════════════════════════
  // Network Summary
  // ══════════════════════════════════════════
  Widget _buildNetworkSummary() {
    final total    = _network?['totalReferred']  ?? 0;
    final active   = _network?['totalActive']    ?? 0;
    final inactive = _network?['totalInactive']  ?? 0;

    return Row(children: [
      Expanded(child: _statCard("Total", total.toString(),    Colors.white70)),
      SizedBox(width: 10.w),
      Expanded(child: _statCard("Active", active.toString(),  _green)),
      SizedBox(width: 10.w),
      Expanded(child: _statCard("Inactive", inactive.toString(), Colors.redAccent)),
    ]);
  }

  // ══════════════════════════════════════════
  // Level Card with progress bar
  // ══════════════════════════════════════════
  Widget _buildLevelCard(Map<String, dynamic> lv) {
    final colors   = [_green, Colors.orangeAccent, Colors.blueAccent];
    final color    = colors[(lv['level'] as int) - 1];
    final unlocked = lv['unlocked'] as bool? ?? false;
    final pct      = (lv['progressPct'] as num?)?.toDouble() ?? 0.0;
    final active   = lv['activeReferred'] ?? 0;
    final required = lv['minReferrals']   ?? 0;
    final reward   = lv['reward']         ?? 0;
    final status   = lv['status']         ?? "";
    final hint     = lv['hint']           ?? "";

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: unlocked ? color.withOpacity(0.4) : Colors.white12,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
              color: color, size: 18.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Level ${lv['level']}",
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp)),
            Text(status,
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.sp)),
          ])),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text("\$$reward",
                style: GoogleFonts.inter(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13.sp)),
          ),
        ]),

        SizedBox(height: 12.h),

        // Progress bar
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6.h,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Text("$active / $required",
              style: GoogleFonts.inter(color: color, fontSize: 11.sp,
                  fontWeight: FontWeight.bold)),
        ]),

        SizedBox(height: 8.h),
        Text(hint, style: GoogleFonts.inter(color: Colors.white38, fontSize: 10.sp)),
      ]),
    );
  }

  // ══════════════════════════════════════════
  // Commission Summary
  // ══════════════════════════════════════════
  Widget _buildCommissionSummary() {
    final total = _commission?['totalEarned']  ?? 0.0;
    final l1    = _commission?['level1Earned'] ?? 0.0;
    final l2    = _commission?['level2Earned'] ?? 0.0;
    final l3    = _commission?['level3Earned'] ?? 0.0;
    final pays  = _commission?['totalPayouts'] ?? 0;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _green.withOpacity(0.2)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("Total Earned",
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 11.sp)),
          Text("\$$total",
              style: GoogleFonts.inter(
                  color: _green, fontSize: 20.sp, fontWeight: FontWeight.bold)),
        ]),
        SizedBox(height: 12.h),
        Divider(color: Colors.white10),
        SizedBox(height: 10.h),
        Row(children: [
          Expanded(child: _miniStat("L1", "\$$l1", _green)),
          Expanded(child: _miniStat("L2", "\$$l2", Colors.orangeAccent)),
          Expanded(child: _miniStat("L3", "\$$l3", Colors.blueAccent)),
          Expanded(child: _miniStat("Payouts", pays.toString(), Colors.white54)),
        ]),
      ]),
    );
  }

  // ══════════════════════════════════════════
  // Referral Tree
  // ══════════════════════════════════════════
  Widget _buildTree() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _referralTree.map<Widget>((l1) {
          final l1Active = l1['active'] as bool? ?? false;
          final l2List   = l1['children'] as List<dynamic>? ?? [];

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Level 1 user
            _treeRow(
              wallet: l1['wallet'] ?? "",
              active: l1Active,
              color: _green,
              prefix: "L1",
            ),

            // Level 2
            ...l2List.map<Widget>((l2) {
              final l2Active = l2['active'] as bool? ?? false;
              final l3List   = l2['children'] as List<dynamic>? ?? [];

              return Padding(
                padding: EdgeInsets.only(left: 20.w),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _treeRow(
                    wallet: l2['wallet'] ?? "",
                    active: l2Active,
                    color: Colors.orangeAccent,
                    prefix: "L2",
                  ),
                  // Level 3
                  ...l3List.map<Widget>((l3) => Padding(
                    padding: EdgeInsets.only(left: 20.w),
                    child: _treeRow(
                      wallet: l3['wallet'] ?? "",
                      active: l3['active'] as bool? ?? false,
                      color: Colors.blueAccent,
                      prefix: "L3",
                    ),
                  )),
                ]),
              );
            }),
            SizedBox(height: 6.h),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _treeRow({
    required String wallet,
    required bool active,
    required Color color,
    required String prefix,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(5.r),
          ),
          child: Text(prefix,
              style: GoogleFonts.inter(color: color, fontSize: 9.sp,
                  fontWeight: FontWeight.bold)),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(wallet,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 11.sp)),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: active
                ? _green.withOpacity(0.15)
                : Colors.redAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(5.r),
          ),
          child: Text(active ? "Active" : "Inactive",
              style: GoogleFonts.inter(
                  color: active ? _green : Colors.redAccent,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════
  // Commission History
  // ══════════════════════════════════════════
  Widget _buildHistory() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: _commissionHistory.map<Widget>((h) {
          final level  = h['level']   ?? 0;
          final reward = h['reward']  ?? 0.0;
          final from   = h['from']    ?? "";
          final colors = [_green, Colors.orangeAccent, Colors.blueAccent];
          final color  = colors[(level as int).clamp(1, 3) - 1];

          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Row(children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Text("L$level",
                    style: GoogleFonts.inter(
                        color: color, fontSize: 10.sp, fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("From: $from",
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 11.sp)),
                  Text(h['earnedAt']?.toString().substring(0, 16) ?? "",
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp)),
                ]),
              ),
              Text("+\$$reward",
                  style: GoogleFonts.inter(
                      color: color, fontSize: 14.sp, fontWeight: FontWeight.bold)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════
  // How It Works Guide
  // ══════════════════════════════════════════
  Widget _buildGuide() {
    final steps = [
      _guide?['step1'] ?? "",
      _guide?['step2'] ?? "",
      _guide?['step3'] ?? "",
      _guide?['step4'] ?? "",
    ].where((s) => s.isNotEmpty).toList();

    final rewards = (_guide?['rewards'] as List<dynamic>?) ?? [];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ...steps.asMap().entries.map((e) => Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 22.w, height: 22.w,
              decoration: BoxDecoration(
                color: _green.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text("${e.key + 1}",
                  style: GoogleFonts.inter(
                      color: _green, fontSize: 10.sp, fontWeight: FontWeight.bold)),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(e.value,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 11.sp)),
            ),
          ]),
        )),

        if (rewards.isNotEmpty) ...[
          Divider(color: Colors.white10),
          SizedBox(height: 8.h),
          Text("Rewards",
              style: GoogleFonts.inter(
                  color: Colors.white54, fontSize: 10.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 6.h),
          ...rewards.map<Widget>((r) => Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: Row(children: [
              Icon(Icons.monetization_on_rounded, color: _green, size: 13.sp),
              SizedBox(width: 6.w),
              Expanded(child: Text(r.toString(),
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 11.sp))),
            ]),
          )),
        ],
      ]),
    );
  }

  // ══════════════════════════════════════════
  // Referred By
  // ══════════════════════════════════════════
  Widget _buildReferredBy() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(children: [
        Icon(Icons.person_pin_rounded, color: Colors.purpleAccent, size: 22.sp),
        SizedBox(width: 12.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Referred By",
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 10.sp)),
          SizedBox(height: 3.h),
          Text(_referredBy?['wallet'] ?? "",
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w600)),
        ])),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.purpleAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(_referredBy?['referralCode'] ?? "",
              style: GoogleFonts.inter(
                  color: Colors.purpleAccent, fontSize: 11.sp,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════
  // Small Helpers
  // ══════════════════════════════════════════
  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(value,
            style: GoogleFonts.inter(
                color: color, fontSize: 18.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 4.h),
        Text(label,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 10.sp)),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(children: [
      Text(value,
          style: GoogleFonts.inter(
              color: color, fontSize: 14.sp, fontWeight: FontWeight.bold)),
      SizedBox(height: 2.h),
      Text(label,
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp)),
    ]);
  }

  Widget _copyBtn() => Container(
    padding: EdgeInsets.all(7.w),
    decoration: BoxDecoration(
      color: _green.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8.r),
    ),
    child: Icon(Icons.copy_rounded, color: _green, size: 15.sp),
  );

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.white70));
}
