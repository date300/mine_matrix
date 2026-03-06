import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';

class AuthProvider extends ChangeNotifier {
  ReownAppKitModal? _appKitModal;
  bool _isInitialized = false;

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
      notifyListeners(); // UI-কে আপডেট করার জন্য
    } catch (e) {
      debugPrint("Wallet Init Error: $e");
    }
  }

  void _onUpdate() {
    notifyListeners();
  }

  // ওয়ালেট মোডাল ওপেন করার ফাংশন (যে কোনো পেজ থেকে কল করা যাবে)
  void openWalletModal(BuildContext context) {
    if (_isInitialized && _appKitModal != null) {
      _appKitModal!.openModalView();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Initializing Wallet, please wait...")),
      );
    }
  }

  @override
  void dispose() {
    _appKitModal?.removeListener(_onUpdate);
    super.dispose();
  }
}
