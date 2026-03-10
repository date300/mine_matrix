import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:reown_appkit/reown_appkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  ReownAppKitModal? _appKitModal;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _sessionId;
  String? _referralCode;
  String? _lastLoggedAddress;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  
  // ১ নম্বর ফিক্স: isConnected গেটার
  bool get isConnected => _appKitModal?.isConnected ?? false;
  
  // ২ নম্বর ফিক্স: address পাওয়ার নতুন নিয়ম
  String? get address => _appKitModal?.address;

  Future<void> initAuth(BuildContext context) async {
    _setLoading(true);
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('session_id');

    if (_sessionId != null) {
      _isLoggedIn = true;
    }
    _setLoading(false);

    // ৩ নম্বর ফিক্স: ফাংশনটি এখন পাবলিক যাতে Topbar থেকে কল করা যায়
    await initWallet(context); 
  }

  void setReferralCode(String code) {
    _referralCode = code;
  }

  // এই ফাংশনটি এখন 'initWallet' (আগে ছিল _initWallet)
  Future<void> initWallet(BuildContext context) async {
    if (_isInitialized) return;

    try {
      _appKitModal = ReownAppKitModal(
        context: context,
        projectId: 'de4fd9cc5d44e0e8a830b232a38184da',
        metadata: const PairingMetadata(
          name: 'Mine Matrix',
          description: 'Decentralized Mining Platform',
          url: 'https://minematrix.com',
          icons: ['https://minematrix.com/logo.png'],
          redirect: Redirect(native: 'minematrix://', universal: 'https://minematrix.com'),
        ),
      );

      await _appKitModal!.init();
      _appKitModal!.addListener(_onWalletUpdate);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Wallet Init Error: $e");
    }
  }

  void _onWalletUpdate() {
    final currentAddress = address;

    if (isConnected && currentAddress != null) {
      if (!_isLoggedIn || currentAddress != _lastLoggedAddress) {
        _lastLoggedAddress = currentAddress;
        _loginToBackend(currentAddress);
      }
    } else if (!isConnected) {
      _lastLoggedAddress = null;
    }
    notifyListeners();
  }

  Future<void> _loginToBackend(String walletAddress) async {
    final url = Uri.parse('http://192.168.0.113:8000/auth/login.php');
    _setLoading(true);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'wallet_address': walletAddress,
          'referred_by': _referralCode ?? ""
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('session_id', data['session_id']);
          _sessionId = data['session_id'];
          _isLoggedIn = true;
        }
      }
    } catch (e) {
      debugPrint("Login Failed: $e");
    } finally {
      _setLoading(false);
    }
  }

  void openModal(BuildContext context) {
    if (_isInitialized && _appKitModal != null) {
      _appKitModal!.openModalView();
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_id');

    if (_appKitModal != null && isConnected) {
      await _appKitModal!.disconnect();
    }

    _isLoggedIn = false;
    _sessionId = null;
    _lastLoggedAddress = null;
    _referralCode = null;
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _appKitModal?.removeListener(_onWalletUpdate);
    super.dispose();
  }
}
