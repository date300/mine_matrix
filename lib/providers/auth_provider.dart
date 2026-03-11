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

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  
  // Wallet Connection Check
  bool get isConnected => _appKitModal?.isConnected ?? false; 
  bool get isAuthenticated => isConnected && _isLoggedIn;
  
  // Get Wallet Address (Supporting both Solana and EVM)
  String? get address {
    final session = _appKitModal?.session;
    if (session == null) return null;
    return session.getAddress('solana') ?? session.getAddress('eip155');
  }

  // Initializing Auth State from Local Storage
  Future<void> initAuth(BuildContext context) async {
    _setLoading(true);
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('session_id');

    if (_sessionId != null) {
      _isLoggedIn = true;
    }
    _setLoading(false);

    // Initialize Reown Wallet
    await initWallet(context); 
  }

  void setReferralCode(String code) {
    _referralCode = code;
  }

  // Initialize Reown AppKit Modal
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

  // Listening to Wallet Changes (Connect/Disconnect/Switch)
  void _onWalletUpdate() {
    final currentAddress = address;

    if (isConnected && currentAddress != null) {
      // If address changes or new connection, login to backend
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
      // Handle Disconnection
      if (_lastLoggedAddress != null || _isLoggedIn) {
        _lastLoggedAddress = null;
        _isLoggedIn = false;
        notifyListeners();
      }
    }
  }

  // Backend API Integration
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
          return true;
        }
      }
    } catch (e) {
      debugPrint("Login Failed: $e");
    }
    return false;
  }

  // UI Trigger to Open Wallet Selection Modal
  void openModal(BuildContext context) {
    if (_isInitialized && _appKitModal != null) {
      _appKitModal!.openModalView();
    }
  }

  // Logout Functionality
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

  // Loading State Helper
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
