import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:reown_appkit/reown_appkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class AuthProvider extends ChangeNotifier {
  ReownAppKitModal? _appKitModal;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isLoggingIn = false;

  String? _token;
  String? _referralCode;
  String? _inputReferralCode;
  String? _lastLoggedAddress;

  Map<String, dynamic>? _userData;

  // --- Getters ---
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isConnected => _appKitModal?.isConnected ?? false;
  bool get isAuthenticated => isConnected && _isLoggedIn;

  String? get token => _token;
  String? get referralCode => _referralCode;
  Map<String, dynamic>? get userData => _userData;

  // সব possible namespace চেক করা হচ্ছে
  String? get address {
    final session = _appKitModal?.session;
    if (session == null) return null;

    // Normal wallet: eip155 (Ethereum)
    final eip155 = session.getAddress('eip155');
    if (eip155 != null && eip155.isNotEmpty) return eip155;

    // Solana wallet
    final solana = session.getAddress('solana');
    if (solana != null && solana.isNotEmpty) return solana;

    // Social login fallback: topic বা peer থেকে address বের করা
    try {
      final account = _appKitModal?.selectedChain != null
          ? session.getAddress(_appKitModal!.selectedChain!.namespace)
          : null;
      if (account != null && account.isNotEmpty) return account;
    } catch (_) {}

    return null;
  }

  String? get balance => _userData?['balance']?.toString();

  String get myReferralLink {
    if (_referralCode == null) return "";
    return "https://web3.ltcminematrix.com?ref=$_referralCode";
  }

  // =========================
  // INIT
  // =========================
  Future<void> initAuth(BuildContext context) async {
    _setLoading(true);

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token != null) {
      bool valid = await verifyToken();

      if (valid) {
        _isLoggedIn = true;

        final userStr = prefs.getString('user');
        if (userStr != null) {
          _userData = jsonDecode(userStr);
          _referralCode = _userData?['referral_code'];
        }
      } else {
        await prefs.remove('token');
        await prefs.remove('user');
        _token = null;
      }
    }

    _setLoading(false);
    await initWallet(context);
  }

  // =========================
  // TOKEN VERIFY
  // =========================
  Future<bool> verifyToken() async {
    try {
      final res = await http.get(
        Uri.parse('https://web3.ltcminematrix.com/api/user/profile'),
        headers: {
          'Authorization': 'Bearer $_token'
        },
      );

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // =========================
  // REFERRAL
  // =========================
  void setInputReferralCode(String code) {
    _inputReferralCode = code;
  }

  void generateReferralCode() {
    if (_referralCode != null) return;

    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();

    _referralCode = String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );

    notifyListeners();
  }

  // =========================
  // WALLET INIT
  // =========================
  Future<void> initWallet(BuildContext context) async {
    if (_isInitialized) return;

    try {
      _appKitModal = ReownAppKitModal(
        context: context,
        projectId: 'de4fd9cc5d44e0e8a830b232a38184da',

        metadata: const PairingMetadata(
          name: 'Mine Matrix',
          description: 'Decentralized Mining Platform',
          url: 'https://web3.ltcminematrix.com',
          icons: ['https://web3.ltcminematrix.com/logo.png'],

          redirect: Redirect(
            native: 'web3.ltcminematrix://',
            universal: 'https://web3.ltcminematrix.com',
          ),
        ),

        featuresConfig: FeaturesConfig(
          socials: [
            AppKitSocialOption.Email,
            AppKitSocialOption.Google,
            AppKitSocialOption.Apple,
            AppKitSocialOption.Telegram,
            AppKitSocialOption.Discord,
          ],
          showMainWallets: true,
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

  // =========================
  // WALLET UPDATE
  // =========================
  void _onWalletUpdate() {
    final currentAddress = address;

    // Social login এ address পেতে সামান্য delay লাগে, তাই retry লজিক
    if (isConnected && currentAddress == null) {
      debugPrint("Connected but address is null — retrying in 1s...");
      Future.delayed(const Duration(seconds: 1), () {
        _onWalletUpdate();
      });
      return;
    }

    if (isConnected && currentAddress != null) {
      debugPrint("Wallet connected: $currentAddress");

      // wallet change fix
      if (_userData?['wallet_address'] != null &&
          _userData!['wallet_address'] != currentAddress) {
        logout();
        return;
      }

      // duplicate login fix
      if (currentAddress != _lastLoggedAddress && !_isLoggingIn) {
        _isLoggingIn = true;
        _lastLoggedAddress = currentAddress;
        _setLoading(true);

        // ✅ Reown/Social Login থেকে ইমেইল এবং নাম নেওয়ার চেষ্টা
        final session = _appKitModal?.session;
        
        // Reown AppKit এর সেশন থেকে ইমেইল ও নাম বের করা (যদি সোশ্যাল লগইন হয়)
        String? extractedEmail = session?.email; 
        String? extractedName = session?.userName; 

        // ✅ API তে অ্যাড্রেসের সাথে ইমেইল ও নাম পাঠানো হচ্ছে
        _loginToBackend(
          currentAddress, 
          email: extractedEmail, 
          name: extractedName,
        ).then((success) {
          _isLoggedIn = success;

          if (!success) {
            _lastLoggedAddress = null;
          }

          _isLoggingIn = false;
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

  // =========================
  // LOGIN API (Updated with Email & Name)
  // =========================
  Future<bool> _loginToBackend(String walletAddress, {String? email, String? name}) async {
    final url = Uri.parse('https://ltcminematrix.com/api/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'wallet_address': walletAddress,
          'email': email ?? "", // ডাটাবেসে সেভ করার জন্য
          'name': name ?? "",   // ডাটাবেসে সেভ করার জন্য
          'referred_by': _inputReferralCode ?? ""
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();

          await prefs.setString('token', data['token']);
          await prefs.setString('user', jsonEncode(data['user']));

          _token = data['token'];
          _userData = data['user'];
          _referralCode = _userData?['referral_code'];

          return true;
        }
      } else {
        debugPrint("API ERROR: ${response.body}");
      }

    } catch (e) {
      debugPrint("Login Failed: $e");
    }

    return false;
  }

  // =========================
  // OPEN WALLET MODAL
  // =========================
  void openModal(BuildContext context) {
    if (_isInitialized && _appKitModal != null) {
      _appKitModal!.openModalView();
    }
  }

  // =========================
  // SHARE
  // =========================
  void shareReferralLink() {
    if (_referralCode != null && myReferralLink.isNotEmpty) {
      Share.share(
        "Join Mine Matrix: $myReferralLink",
        subject: "Referral",
      );
    }
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('user');

    if (_appKitModal != null && isConnected) {
      await _appKitModal!.disconnect();
    }

    _isLoggedIn = false;
    _token = null;
    _userData = null;
    _lastLoggedAddress = null;
    _referralCode = null;

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
