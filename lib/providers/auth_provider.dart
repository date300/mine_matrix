import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:reown_appkit/reown_appkit.dart';

class AuthProvider extends ChangeNotifier {
  ReownAppKitModal? _appKitModal;
  bool _isInitialized = false;
  bool _isLoading = false; 
  String? _lastLoggedAddress; 

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isConnected => _appKitModal?.isConnected ?? false;
  ReownAppKitModal? get appKitModal => _appKitModal;

  // অ্যাড্রেস পাওয়ার নিরাপদ লজিক
  String? get address {
    if (isConnected && _appKitModal?.session != null) {
      try {
        return (_appKitModal?.session as dynamic).address;
      } catch (e) {
        debugPrint("Address Parse Error: $e");
        return null;
      }
    }
    return null;
  }

  // ১. ওয়ালেট ইনিশিয়ালাইজেশন
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
          redirect: Redirect(
            native: 'minematrix://',
            universal: 'https://minematrix.com',
          ),
        ),
      );

      await _appKitModal!.init().timeout(
        const Duration(seconds: 15), // রিয়েল নেটওয়ার্কের জন্য টাইমআউট একটু বাড়ানো হলো
        onTimeout: () {
          debugPrint("Reown Initialization Timeout");
        },
      );

      _appKitModal!.addListener(_onUpdate);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Wallet Init Error: $e");
    }
  }

  // ২. স্টেট আপডেট লিসেনার
  void _onUpdate() {
    notifyListeners();
    _checkAndLoginToBackend();
  }

  // ৩. ব্যাকএন্ডে লগইন চেক করার লজিক
  Future<void> _checkAndLoginToBackend() async {
    final currentAddress = address;

    // যদি কানেক্টেড থাকে এবং নতুন অ্যাড্রেস হয়
    if (isConnected && currentAddress != null && currentAddress != _lastLoggedAddress) {
      _lastLoggedAddress = currentAddress;
      await _sendLoginRequest(currentAddress);
    } 
    // যদি ডিসকানেক্ট হয়ে যায়
    else if (!isConnected) {
      _lastLoggedAddress = null;
    }
  }

  // ৪. রিয়েল API কল (আপনার লোকাল সার্ভারের সাথে)
  Future<void> _sendLoginRequest(String walletAddress) async {
    // আপনার ফিজিক্যাল ডিভাইসের জন্য রিয়েল লিংক
    final url = Uri.parse('http://192.168.0.113:8000/auth/login.php');

    _setLoading(true);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'wallet_address': walletAddress}),
      ).timeout(const Duration(seconds: 10)); // API কলের জন্য টাইমআউট

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint("Backend Login Success: $responseData");
        // এখানে আপনি ইউজার ডেটা SharedPreferences বা অন্য কোথাও সেভ করতে পারেন
      } else {
        debugPrint("Backend Error: Status Code ${response.statusCode}");
        debugPrint("Error Body: ${response.body}");
        _lastLoggedAddress = null; // ফেইল করলে রিসেট করে দিলাম
      }
    } catch (e) {
      debugPrint("API Request Failed: $e");
      _lastLoggedAddress = null; 
    } finally {
      _setLoading(false);
    }
  }

  // ৫. লোডিং স্টেট ম্যানেজমেন্ট
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ৬. মোডাল ওপেন করার ফাংশন
  void openModal(BuildContext context) {
    if (_isInitialized && _appKitModal != null) {
      _appKitModal!.openModalView();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Initializing Wallet, please wait...")),
      );
    }
  }

  // ৭. ওয়ালেট ডিসকানেক্ট ফাংশন
  Future<void> disconnectWallet() async {
    if (_appKitModal != null && isConnected) {
      await _appKitModal!.disconnect();
      _lastLoggedAddress = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _appKitModal?.removeListener(_onUpdate);
    super.dispose();
  }
}
