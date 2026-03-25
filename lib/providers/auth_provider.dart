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

  // --- Getters ---
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  
  bool get isConnected => _appKitModal?.isConnected ?? false; 
  bool get isAuthenticated => isConnected && _isLoggedIn;
  
  String? get address {
    final session = _appKitModal?.session;
    if (session == null) return null;
    return session.getAddress('solana') ?? session.getAddress('eip155');
  }

  // --- Logic Methods ---

  Future<void> initAuth(BuildContext context) async {
    _setLoading(true);
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('session_id');

    if (_sessionId != null) {
      _isLoggedIn = true;
    }
    _setLoading(false);

    await initWallet(context); 
  }

  void setReferralCode(String code) {
    _referralCode = code;
  }

  Future<void> initWallet(BuildContext context) async {
    if (_isInitialized) return;

    try {
      _appKitModal = ReownAppKitModal(
        context: context,
        projectId: 'de4fd9cc5d44e0e8a830b232a38184da',
        metadata: const PairingMetadata(
          name: 'Mine Matrix',
          description: 'Decentralized Mining Platform',
          url: 'https://ltcminematrix.com',
          icons: ['https://ltcminematrix.com/logo.png'],
          redirect: Redirect(native: 'ltcminematrix://', universal: 'https://ltcminematrix.com'),
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
      if (currentAddress != _lastLoggedAddress) {
        _lastLoggedAddress = currentAddress;
        _setLoading(true);

        _loginToBackend(currentAddress).then((success) {
          if (success) {
            _isLoggedIn = true;
          } else {
            _lastLoggedAddress = null;
            _isLoggedIn = false;
          }
          _setLoading(false);
          notifyListeners();
        });
      }
    } else if (!isConnected) {
      if (_lastLoggedAddress != null || _isLoggedIn) {
        _lastLoggedAddress = null;
        _isLoggedIn = false;
        notifyListeners();
      }
    }
  }

  Future<bool> _loginToBackend(String walletAddress) async {
    final url = Uri.parse('https://ltcminematrix.com/api/auth/login');

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
          return true;
        }
      }
    } catch (e) {
      debugPrint("Login Failed: $e");
    }
    return false;
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

  // এই সেই মেথড যেটা মিসিং দেখাচ্ছিল। এটা এখন ক্লাসের ভেতরেই আছে।
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
