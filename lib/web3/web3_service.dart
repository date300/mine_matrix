import 'package:flutter_web3/flutter_web3.dart';

class Web3Service {
  // Project ID based provider (Infura / Alchemy)
  // Replace YOUR_PROJECT_ID with your actual project ID
  static final rpcProvider =
      Web3Provider("https://goerli.infura.io/v3/YOUR_PROJECT_ID");

  // Check if Ethereum is supported (MetaMask)
  static bool get isSupported => Ethereum.isSupported;

  // Connect Wallet (MetaMask)
  static Future<String?> connectWallet() async {
    if (!isSupported) return null;
    try {
      final accounts = await ethereum!.requestAccount();
      return accounts.first;
    } catch (e) {
      print("Wallet connect failed: $e");
      return null;
    }
  }

  // Get Balance using MetaMask
  static Future<String?> getWalletBalance(String account) async {
    if (!isSupported) return null;
    try {
      final balance = await ethereum!.getBalance(account);
      return (balance.getValueInUnit(EtherUnit.ether)).toString();
    } catch (e) {
      print("Get wallet balance failed: $e");
      return null;
    }
  }

  // Get Balance using RPC provider (project ID required)
  static Future<String> getBalanceRPC(String account) async {
    final balance = await rpcProvider.getBalance(account);
    return (balance.getValueInUnit(EtherUnit.ether)).toString();
  }
}
