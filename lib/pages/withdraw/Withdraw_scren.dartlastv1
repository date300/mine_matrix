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

class AppLottie {
  static const String refresh      = 'https://assets10.lottiefiles.com/packages/lf20_7fwvvesa.json';
  static const String coinSpin     = 'https://assets10.lottiefiles.com/packages/lf20_6wutsrox.json';
  static const String emptyHistory = 'https://assets10.lottiefiles.com/packages/lf20_s8pbrcfw.json';
  static const String success      = 'https://assets10.lottiefiles.com/packages/lf20_kz9pjc9p.json';
}

const String _baseUrl = 'https://web3.ltcminematrix.com';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> with TickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _walletController = TextEditingController();
  
  bool _isLoading    = true;
  bool _isSubmitting = false;
  bool _hasError     = false;
  
  double _withdrawableBalance = 0.0;
  List<dynamic> _withdrawHistory = [];

  // Animation controller for balance
  late AnimationController _balanceCtrl;
  late Animation<double>   _balanceAnim;
  double _displayBalance = 0;

  @override
  void initState() {
    super.initState();
    _balanceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _balanceAnim = CurvedAnimation(parent: _balanceCtrl, curve: Curves.easeOutExpo);
    _balanceAnim.addListener(() {
      if (mounted) setState(() => _displayBalance = _withdrawableBalance * _balanceAnim.value);
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

  String? _token() => Provider.of<AuthProvider>(context, listen: false).token;

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_token()}',
  };

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      await Future.wait([
        _fetchBalance(),
        _fetchHistory(),
      ]);
      if (mounted) {
        setState(() => _isLoading = false);
        _balanceCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  Future<void> _fetchBalance() async {
    final res = await http.get(Uri.parse('$_baseUrl/api/mining/stats'), headers: _headers());
    if (res.statusCode == 200) {
      final d = jsonDecode(res.body);
      _withdrawableBalance = double.tryParse(d['withdrawable']?.toString() ?? '0') ?? 0.0;
    }
  }

  Future<void> _fetchHistory() async {
    final res = await http.get(Uri.parse('$_baseUrl/api/withdraw/history'), headers: _headers());
    if (res.statusCode == 200) {
      final d = jsonDecode(res.body);
      _withdrawHistory = d['data'] ?? [];
    }
  }

  Future<void> _submitWithdraw() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final wallet = _walletController.text.trim();

    if (amount < 5) {
      _showSnack("Minimum withdrawal is \$5", isError: true);
      return;
    }
    if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(wallet)) {
      _showSnack("Invalid BEP20 address", isError: true);
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
        body: jsonEncode({'amount': amount, 'wallet': wallet}),
      );

      final d = jsonDecode(res.body);
      if (res.statusCode == 200 && d['success'] == true) {
        _showSnack("Withdrawal request submitted successfully!");
        _amountController.clear();
        _walletController.clear();
        _loadData();
      } else {
        _showSnack(d['error'] ?? "Failed to process withdrawal", isError: true);
      }
    } catch (e) {
      _showSnack("Network error. Please try again.", isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w500)),
      backgroundColor: isError ? AppColors.accentRed : AppColors.accentGreen,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(16.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ));
  }

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
                          _balanceHero().animate().fadeIn().slideY(begin: 0.1, end: 0),
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
                  )
                ],
              ),
            ),
    );
  }

  Widget _header() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Withdraw', style: GoogleFonts.inter(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.bold)),
        Text('Transfer funds to your BEP20 wallet', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13.sp)),
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
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
      boxShadow: [BoxShadow(color: AppColors.accentBlue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
    ),
    child: Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.account_balance_wallet_outlined, color: AppColors.accentBlue, size: 18.sp),
          SizedBox(width: 8.w),
          Text('WITHDRAWABLE BALANCE', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11.sp, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ]),
        SizedBox(height: 12.h),
        Text('\$${_displayBalance.toStringAsFixed(2)}', style: GoogleFonts.inter(color: Colors.white, fontSize: 42.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 8.h),
        Text('Available for instant withdrawal', style: GoogleFonts.inter(color: AppColors.accentGreen.withOpacity(0.8), fontSize: 12.sp)),
      ],
    ),
  );

  Widget _inputForm() => Container(
    padding: EdgeInsets.all(20.w),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24.r),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(children: [
      _customField(
        controller: _amountController,
        label: "Amount",
        hint: "Min \$5.00",
        icon: Icons.monetization_on_outlined,
        isNumber: true,
      ),
      SizedBox(height: 20.h),
      _customField(
        controller: _walletController,
        label: "BEP20 Wallet Address",
        hint: "0x...",
        icon: Icons.account_balance_wallet_rounded,
      ),
      SizedBox(height: 24.h),
      _withdrawBtn(),
    ]),
  );

  Widget _withdrawBtn() => GestureDetector(
    onTap: _isSubmitting ? null : _submitWithdraw,
    child: Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _isSubmitting ? [AppColors.border, AppColors.border] : [AppColors.accentBlue, AppColors.accentPurple]),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: _isSubmitting ? [] : [BoxShadow(color: AppColors.accentBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Center(
        child: _isSubmitting 
          ? SizedBox(width: 24.w, height: 24.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text('Confirm Withdrawal', style: GoogleFonts.inter(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
      ),
    ),
  );

  Widget _customField({required TextEditingController controller, required String label, required String hint, required IconData icon, bool isNumber = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12.sp, fontWeight: FontWeight.w600)),
      SizedBox(height: 10.h),
      TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 15.sp),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
          prefixIcon: Icon(icon, color: AppColors.accentBlue, size: 20.sp),
          filled: true,
          fillColor: AppColors.background,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: AppColors.accentBlue)),
        ),
      ),
    ],
  );

  Widget _historyList() {
    if (_withdrawHistory.isEmpty) return _emptyState();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _withdrawHistory.length,
      itemBuilder: (context, index) {
        final item = _withdrawHistory[index];
        return _historyItem(item).animate().fadeIn(delay: Duration(milliseconds: index * 50)).slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _historyItem(Map<String, dynamic> item) {
    final status = item['status'].toString().toLowerCase();
    Color statusColor = AppColors.textSecondary;
    if (status == 'pending') statusColor = Colors.orange;
    if (status == 'approved') statusColor = AppColors.accentGreen;
    if (status == 'rejected') statusColor = AppColors.accentRed;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w, height: 48.w,
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14.r)),
            child: Icon(
              status == 'approved' ? Icons.check_circle_outline : status == 'rejected' ? Icons.error_outline : Icons.pending_actions_rounded,
              color: statusColor, size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('\$${item['amount']}', style: GoogleFonts.inter(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 4.h),
            Text(item['wallet_address'].toString().replaceRange(6, 36, '...'), style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11.sp)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6.r)),
              child: Text(status.toUpperCase(), style: GoogleFonts.inter(color: statusColor, fontSize: 9.sp, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 6.h),
            Text(item['created_at'].toString().substring(0, 10), style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10.sp)),
          ]),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(children: [
      SizedBox(height: 20.h),
      Opacity(opacity: 0.5, child: Icon(Icons.history_rounded, size: 60.sp, color: AppColors.textMuted)),
      SizedBox(height: 12.h),
      Text("No withdrawal history found", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14.sp)),
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
    width: double.infinity, height: height,
    margin: EdgeInsets.only(bottom: 20.h),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20.r)),
  );

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.border)),
      child: Icon(icon, color: Colors.white, size: 20.sp),
    ),
  );

  Widget _sec(String title) => Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold));
}
