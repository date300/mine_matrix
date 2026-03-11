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
  
  // ?. isConnected à¦à§à¦
  bool get isConnected => _appKitModal?.isConnected ?? false; 
  bool get isAuthenticated => isConnected && _isLoggedIn;
  
  // ?. Reown 1.8.3 à¦¤à§ address à¦ªà¦¾à¦à§à¦¾à¦° à¦à¦¨à§à¦¯
  String? get address {
    final session = _appKitModal?.session;
    if (session == null) return null;
    
    // à¦ªà§à¦°à¦¥à¦®à§ Solana à¦à¦° à¦à§à¦¯à¦¾à¦¡à§à¦°à§à¦¸ à¦à§à¦à¦à¦¬à§, à¦¨à¦¾ à¦ªà§à¦²à§ EVM 
    return session.getAddress('solana') ?? session.getAddress('eip155');
  }

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

  // à¦à¦ function à¦à¦¬à¦¶à§à¦¯à¦ class-à¦à¦° à¦­à¦¿à¦¤à¦°à§ à¦à¦¿à¦¨à§à¦¤à§ initWallet-à¦à¦° à¦¬à¦¾à¦à¦°à§
  void _onWalletUpdate() {
    final currentAddress = address;

    if (isConnected && currentAddress != null) {
      if (currentAddress != _lastLoggedAddress) {
        _lastLoggedAddress = currentAddress;
        _setLoading(true);

        _loginToBackend(currentAddress).then((success) {
          if (success) {
            _isLoggedIn = true; // API success â wallet active
          } else {
            _lastLoggedAddress = null; // API fail â wallet connect inactive
          }
          _setLoading(false);
          notifyListeners();
        });
      }
    } else if (!isConnected) {
      // (à¦¤à§à¦°à§à¦à¦¿ à¦¸à¦à¦¶à§à¦§à¦¨ à¦à¦°à¦¾ à¦¹à§à§à¦à§) à¦¯à¦¦à¦¿ à¦¡à¦¿à¦¸à¦à¦¾à¦¨à§à¦à§à¦à§à¦¡ à¦¹à§à§ à¦¯à¦¾à§, à¦¤à¦¾à¦¹à¦²à§ à¦¡à§à¦à¦¾ à¦à§à¦²à¦¿à§à¦¾à¦° à¦à¦°à¦¤à§ à¦¹à¦¬à§
      if (_lastLoggedAddress != null || _isLoggedIn) {
        _lastLoggedAddress = null;
        _isLoggedIn = false;
        notifyListeners();
      }
    }
  }

  Future<bool> _loginToBackend(String walletAddress) async {
    final url = Uri.parse('http://192.168.0.113:8000/auth/login.php');

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
          return true; // API success
        }
      }
    } catch (e) {
      debugPrint("Login Failed: $e");
    }

    return false; // API fail
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
  
