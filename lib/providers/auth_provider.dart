import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:reown_appkit/reown_appkit.dart';

class AuthProvider extends ChangeNotifier {
  ReownAppKitModal? _appKitModal;
  bool _isInitialized = false;
  String? _lastLoggedAddress; // বারবার API কল ঠেকানোর জন্য

  bool get isInitialized => _isInitialized;
  bool get isConnected => _appKitModal?.isConnected ?? false;
  ReownAppKitModal? get appKitModal => _appKitModal;

  // অ্যাড্রেস পাওয়ার লজিক
  String? get address {
    if (isConnected && _appKitModal?.session != null) {
      try {
        return (_appKitModal?.session as dynamic).address;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // ওয়ালেট ইনিশিয়ালাইজ করার ফাংশন
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
        const Duration(seconds: 10),
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

  void _onUpdate() {
    notifyListeners();
    _checkAndLoginToBackend();
  }

  // ওয়ালেট কানেক্ট হওয়ার পর ব্যাকএন্ডে রিকোয়েস্ট পাঠানোর লজিক
  Future<void> _checkAndLoginToBackend() async {
    final currentAddress = address;

    // যদি কানেক্টেড থাকে, অ্যাড্রেস পাওয়া যায় এবং এই অ্যাড্রেস দিয়ে আগে লগইন না হয়ে থাকে
    if (isConnected && currentAddress != null && currentAddress != _lastLoggedAddress) {
      _lastLoggedAddress = currentAddress;
      await _sendLoginRequest(currentAddress);
    } 
    // যদি ডিসকানেক্ট হয়ে যায়, তাহলে স্টেট রিসেট করা
    else if (!isConnected) {
      _lastLoggedAddress = null;
    }
  }

  // এপিআই কল করার মূল ফাংশন
  Future<void> _sendLoginRequest(String walletAddress) async {
    // লক্ষ্য করুন: ফিজিক্যাল ডিভাইস বা এমুলেটরে টেস্টিংয়ের সময় localhost কাজ নাও করতে পারে।
    final url = Uri.parse('http://localhost:8000/auth/login.php');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'wallet_address': walletAddress}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint("Backend Login Success: $responseData");
        // এখানে চাইলে ব্যাকএন্ড থেকে আসা ইউজারের ব্যালেন্স বা অন্যান্য ডাটা সেভ করে রাখতে পারেন
      } else {
        debugPrint("Backend Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("API Request Failed: $e");
      // API ফেইল করলে অ্যাড্রেস ক্লিয়ার করে দিচ্ছি যাতে পরে আবার ট্রাই করতে পারে
      _lastLoggedAddress = null; 
    }
  }

  void openModal(BuildContext context) {
    if (_isInitialized && _appKitModal != null) {
      _appKitModal!.openModalView();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Initializing Wallet, please wait...")),
      );
    }
  }

  // ডিসকানেক্ট করার ফাংশন (যেকোনো পেজ থেকে কল করা যাবে)
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
