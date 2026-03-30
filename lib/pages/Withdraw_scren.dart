import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  String _selectedMethod = 'USDT';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _methods = [
    {'name': 'USDT', 'icon': CupertinoIcons.bitcoin, 'color': Color(0xFF26A17B)},
    {'name': 'BTC', 'icon': CupertinoIcons.bitcoin, 'color': Color(0xFFF7931A)},
    {'name': 'SOL', 'icon': CupertinoIcons.bolt_fill, 'color': Color(0xFF9945FF)},
  ];

  // Demo balance
  final double _balance = 245.75;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _addressController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _setMax() {
    _amountController.text = _balance.toStringAsFixed(2);
  }

  void _submit() async {
    if (_amountController.text.isEmpty || _addressController.text.isEmpty) {
      _showSnack('সব তথ্য পূরণ করুন', isError: true);
      return;
    }
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      _showSnack('সঠিক পরিমাণ দিন', isError: true);
      return;
    }
    if (amount > _balance) {
      _showSnack('ব্যালেন্স পর্যাপ্ত নয়', isError: true);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
    _showSnack('Withdraw অনুরোধ সফল হয়েছে! ✅');
    _amountController.clear();
    _addressController.clear();
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF14F195).withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 120.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Balance Card ──
            _buildBalanceCard(),
            SizedBox(height: 24.h),

            // ── Method Selector ──
            Text(
              'Withdraw মেথড',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 10.h),
            _buildMethodSelector(),
            SizedBox(height: 24.h),

            // ── Amount Input ──
            Text(
              'পরিমাণ',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 10.h),
            _buildAmountInput(),
            SizedBox(height: 20.h),

            // ── Address Input ──
            Text(
              'Wallet Address',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 10.h),
            _buildAddressInput(),
            SizedBox(height: 12.h),

            // ── Fee Note ──
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFF14F195).withOpacity(0.07),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFF14F195).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.info_circle, color: const Color(0xFF14F195), size: 16.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Network fee: 1 USDT। Minimum withdraw: 10 USDT',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF14F195),
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28.h),

            // ── Submit Button ──
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A25), Color(0xFF12121C)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14F195).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.wallet_pass_fill,
                  color: const Color(0xFF14F195), size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                'Available Balance',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${_balance.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(width: 8.w),
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  'USDT',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF14F195),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '≈ ৳${(_balance * 110).toStringAsFixed(0)} BDT',
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Row(
      children: _methods.map((method) {
        final bool selected = _selectedMethod == method['name'];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedMethod = method['name']);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(right: method['name'] != 'SOL' ? 10.w : 0),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: selected
                    ? (method['color'] as Color).withOpacity(0.15)
                    : const Color(0xFF1A1A25),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: selected
                      ? (method['color'] as Color).withOpacity(0.6)
                      : Colors.white10,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    method['icon'] as IconData,
                    color: selected ? method['color'] as Color : Colors.white38,
                    size: 22.sp,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    method['name'] as String,
                    style: GoogleFonts.inter(
                      color: selected ? Colors.white : Colors.white38,
                      fontSize: 12.sp,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A25),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.inter(color: Colors.white, fontSize: 16.sp),
        decoration: InputDecoration(
          hintText: '0.00',
          hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 16.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          suffixWidget: GestureDetector(
            onTap: _setMax,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF14F195), Color(0xFF9945FF)],
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'MAX',
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A25),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: _addressController,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 13.sp),
        decoration: InputDecoration(
          hintText: 'Wallet address পেস্ট করুন...',
          hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          prefixIcon: Icon(
            CupertinoIcons.link,
            color: Colors.white38,
            size: 18.sp,
          ),
          suffixWidget: GestureDetector(
            onTap: () async {
              final data = await Clipboard.getData('text/plain');
              if (data?.text != null) {
                _addressController.text = data!.text!;
                HapticFeedback.selectionClick();
              }
            },
            child: Padding(
              padding: EdgeInsets.only(right: 14.w),
              child: Icon(CupertinoIcons.doc_on_clipboard,
                  color: const Color(0xFF14F195), size: 20.sp),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isLoading
                ? [Colors.white12, Colors.white12]
                : [const Color(0xFF14F195), const Color(0xFF0AC47A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF14F195).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: _isLoading
              ? SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.arrow_up_circle_fill,
                        color: Colors.black, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Withdraw করুন',
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
