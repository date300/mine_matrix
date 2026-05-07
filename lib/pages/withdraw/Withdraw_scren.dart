import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_error_widget.dart';

// --- Colors ---
class AppColors {
  static const Color background    = Color(0xFF0A0A0F);
  static const Color surface       = Color(0xFF12121A);
  static const Color accentGreen   = Color(0xFF00FFA3);
  static const Color accentPurple  = Color(0xFFB829F7);
  static const Color accentBlue    = Color(0xFF00D4FF);
  static const Color accentRed     = Color(0xFFFF4D4D);
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B8B9E);
  static const Color textMuted     = Color(0xFF4A4A5A);
  static const Color border        = Color(0xFF2A2A3A);
  static const Color cardBg        = Color(0xFF161620);
}

const String _baseUrl = 'https://web3.ltcminematrix.com';

// Network options matching backend ALLOWED_NETWORKS
const List<String> _networks = ['BEP20', 'TRC20'];

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen>
    with TickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _walletController = TextEditingController();

  bool _isLoading    = true;
  bool _isSubmitting = false;
  bool _hasError     = false;

  double _withdrawableBalance = 0.0;
  List<dynamic> _withdrawHistory = [];
  String _selectedNetwork = 'BEP20';

  // Balance count-up animation
  late AnimationController _balanceCtrl;
  late Animation<double>   _balanceAnim;
  double _displayBalance = 0;

  @override
  void initState() {
    super.initState();
    _balanceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _balanceAnim = CurvedAnimation(
      parent: _balanceCtrl,
      curve: Curves.easeOutExpo,
    );
    _balanceAnim.addListener(() {
      if (mounted) {
        setState(() => _displayBalance = _withdrawableBalance * _balanceAnim.value);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _walletController.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  String? _token() =>
      Provider.of<AuthProvider>(context, listen: false).token;

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_token()}',
  };

  // ── LOAD DATA ──────────────────────
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError  = false;
    });
    try {
      await Future.wait([_fetchBalance(), _fetchHistory()]);
      if (mounted) {
        setState(() => _isLoading = false);
        _balanceCtrl.forward(from: 0);
      }
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  // ── GET /api/withdraw/balance ──────
  // Response: { success, data: { balance, withdrawable } }
  Future<void> _fetchBalance() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/api/withdraw/balance'),
      headers: _headers(),
    );

    if (res.statusCode == 200) {
      final d = jsonDecode(res.body);
      if (d['success'] == true && d['data'] != null) {
        _withdrawableBalance =
            double.tryParse(d['data']['withdrawable']?.toString() ?? '0') ?? 0.0;
      } else {
        throw Exception(d['error'] ?? 'Balance fetch failed');
      }
    } else {
      final d = jsonDecode(res.body);
      throw Exception(d['error'] ?? 'Balance fetch failed');
    }
  }

  // ── GET /api/withdraw/history ──────
  // Response: { success, data: [ { id, amount, wallet_address, network, status, created_at, approved_at } ] }
  Future<void> _fetchHistory() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/api/withdraw/history?page=1&limit=20'),
      headers: _headers(),
    );

    if (res.statusCode == 200) {
      final d = jsonDecode(res.body);
      if (d['success'] == true) {
        _withdrawHistory = d['data'] ?? [];
      } else {
        throw Exception(d['error'] ?? 'History fetch failed');
      }
    } else {
      throw Exception('History fetch failed');
    }
  }

  // ── POST /api/withdraw ─────────────
  // Body:     { amount, wallet, network }
  // Success:  { success: true, data: { withdrawId, amount, wallet, network, status } }
  // Error:    { success: false, error: "..." }
  Future<void> _submitWithdraw() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final wallet = _walletController.text.trim();

    // ── Client-side validation (mirrors backend) ──
    if (amount < 5) {
      _showSnack("Minimum withdrawal is \$5", isError: true);
      return;
    }
    if (!_isValidWallet(wallet, _selectedNetwork)) {
      _showSnack(
        _selectedNetwork == 'BEP20'
            ? "Invalid BEP20 address (0x + 40 hex chars)"
            : "Invalid TRC20 address (T + 33 base58 chars)",
        isError: true,
      );
      return;
    }
    if (amount > _withdrawableBalance) {
      _showSnack("Insufficient balance", isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/withdraw'),
        headers: _headers(),
        body: jsonEncode({
          'amount':  amount,
          'wallet':  wallet,
          'network': _selectedNetwork,  // BEP20 | TRC20
        }),
      );

      final d = jsonDecode(res.body);

      if (res.statusCode == 200 && d['success'] == true) {
        _showSnack("Withdrawal request submitted successfully!");
        _amountController.clear();
        _walletController.clear();
        await _loadData();
      } else {
        _showSnack(d['error'] ?? "Failed to process withdrawal", isError: true);
      }
    } catch (_) {
      _showSnack("Network error. Please try again.", isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Wallet validation (matches backend isValidWallet) ──
  bool _isValidWallet(String wallet, String network) {
    if (network == 'BEP20') {
      return RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(wallet);
    }
    if (network == 'TRC20') {
      return RegExp(r'^T[1-9A-HJ-NP-Za-km-z]{33}$').hasMatch(wallet);
    }
    return false;
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        msg,
        style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w500),
      ),
      backgroundColor: isError ? AppColors.accentRed : AppColors.accentGreen,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(16.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ));
  }

  // ── BUILD ──────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? _skeleton()
          : _hasError
              ? CustomErrorWidget(onRetry: _loadData)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.accentGreen,
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
                              _balanceHero()
                                  .animate()
                                  .fadeIn()
                                  .slideY(begin: 0.1, end: 0),
                              SizedBox(height: 24.h),
                              _inputForm().animate().fadeIn(delay: 200.ms),
                              SizedBox(height: 32.h),
                              _sec("Withdrawal History"),
                              SizedBox(height: 16.h),
                              _historyList(),
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

  // ── WIDGETS ────────────────────────

  Widget _header() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'Withdraw',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Transfer funds to your wallet',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13.sp,
          ),
        ),
      ]),
      _iconBtn(Icons.refresh_rounded, _loadData),
    ],
  );

  Widget _balanceHero() => Container(
    width: double.infinity,
    padding: EdgeInsets.all(24.w),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24.r),
      gradient: LinearGradient(
        colors: [AppColors.accentBlue.withOpacity(0.2), AppColors.surface],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
      boxShadow: [
        BoxShadow(
          color: AppColors.accentBlue.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.account_balance_wallet_outlined,
            color: AppColors.accentBlue, size: 18.sp),
        SizedBox(width: 8.w),
        Text(
          'WITHDRAWABLE BALANCE',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ]),
      SizedBox(height: 12.h),
      Text(
        '\$${_displayBalance.toStringAsFixed(2)}',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 42.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 8.h),
      Text(
        'Available for instant withdrawal',
        style: GoogleFonts.inter(
          color: AppColors.accentGreen.withOpacity(0.8),
          fontSize: 12.sp,
        ),
      ),
    ]),
  );

  Widget _inputForm() => Container(
    padding: EdgeInsets.all(20.w),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24.r),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(children: [
      // ── Network Selector ──
      _networkSelector(),
      SizedBox(height: 20.h),
      // ── Amount ──
      _customField(
        controller: _amountController,
        label: "Amount (USD)",
        hint: "Min \$5.00",
        icon: Icons.monetization_on_outlined,
        isNumber: true,
      ),
      SizedBox(height: 20.h),
      // ── Wallet Address (hint changes by network) ──
      _customField(
        controller: _walletController,
        label: "$_selectedNetwork Wallet Address",
        hint: _selectedNetwork == 'BEP20' ? "0x..." : "T...",
        icon: Icons.account_balance_wallet_rounded,
      ),
      SizedBox(height: 24.h),
      _withdrawBtn(),
    ]),
  );

  // ── Network Toggle ─────────────────
  Widget _networkSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Network",
        style: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 10.h),
      Row(
        children: _networks.map((net) {
          final isSelected = _selectedNetwork == net;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedNetwork = net;
                  _walletController.clear(); // clear on network switch
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(
                  right: net == _networks.first ? 8.w : 0,
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentBlue.withOpacity(0.15)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentBlue
                        : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    net,
                    style: GoogleFonts.inter(
                      color: isSelected
                          ? AppColors.accentBlue
                          : AppColors.textSecondary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );

  Widget _withdrawBtn() => GestureDetector(
    onTap: _isSubmitting ? null : _submitWithdraw,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isSubmitting
              ? [AppColors.border, AppColors.border]
              : [AppColors.accentBlue, AppColors.accentPurple],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: _isSubmitting
            ? []
            : [
                BoxShadow(
                  color: AppColors.accentBlue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Center(
        child: _isSubmitting
            ? SizedBox(
                width: 24.w,
                height: 24.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Confirm Withdrawal',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    ),
  );

  Widget _customField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: controller,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 15.sp),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
              prefixIcon:
                  Icon(icon, color: AppColors.accentBlue, size: 20.sp),
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide:
                    const BorderSide(color: AppColors.accentBlue),
              ),
            ),
          ),
        ],
      );

  // ── HISTORY LIST ───────────────────
  Widget _historyList() {
    if (_withdrawHistory.isEmpty) return _emptyState();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _withdrawHistory.length,
      itemBuilder: (context, index) {
        final item = _withdrawHistory[index];
        return _historyItem(item)
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 50))
            .slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _historyItem(Map<String, dynamic> item) {
    final status = item['status'].toString().toLowerCase();
    final network = item['network']?.toString() ?? 'BEP20';

    Color statusColor = AppColors.textSecondary;
    if (status == 'pending')  statusColor = Colors.orange;
    if (status == 'approved') statusColor = AppColors.accentGreen;
    if (status == 'rejected') statusColor = AppColors.accentRed;

    // Safely shorten wallet address
    final rawWallet = item['wallet_address']?.toString() ?? '';
    final shortWallet = rawWallet.length > 12
        ? '${rawWallet.substring(0, 6)}...${rawWallet.substring(rawWallet.length - 4)}'
        : rawWallet;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(
            status == 'approved'
                ? Icons.check_circle_outline
                : status == 'rejected'
                    ? Icons.error_outline
                    : Icons.pending_actions_rounded,
            color: statusColor,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '\$${item['amount']}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              shortWallet,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 11.sp,
              ),
            ),
            SizedBox(height: 2.h),
            // Show network badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                network,
                style: GoogleFonts.inter(
                  color: AppColors.accentBlue,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.inter(
                color: statusColor,
                fontSize: 9.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            item['created_at']?.toString().substring(0, 10) ?? '',
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 10.sp,
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _emptyState() => Center(
    child: Column(children: [
      SizedBox(height: 20.h),
      Opacity(
        opacity: 0.5,
        child: Icon(Icons.history_rounded,
            size: 60.sp, color: AppColors.textMuted),
      ),
      SizedBox(height: 12.h),
      Text(
        "No withdrawal history found",
        style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14.sp),
      ),
    ]),
  );

  Widget _skeleton() => Shimmer.fromColors(
    baseColor: AppColors.surface,
    highlightColor: AppColors.cardBg,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(children: [
        SizedBox(height: 60.h),
        _skelBox(height: 80.h),
        SizedBox(height: 24.h),
        _skelBox(height: 180.h),
        SizedBox(height: 24.h),
        _skelBox(height: 250.h),
      ]),
    ),
  );

  Widget _skelBox({required double height}) => Container(
    width: double.infinity,
    height: height,
    margin: EdgeInsets.only(bottom: 20.h),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20.r),
    ),
  );

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, color: Colors.white, size: 20.sp),
    ),
  );

  Widget _sec(String title) => Text(
    title,
    style: GoogleFonts.inter(
      color: Colors.white,
      fontSize: 18.sp,
      fontWeight: FontWeight.bold,
    ),
  );
}
