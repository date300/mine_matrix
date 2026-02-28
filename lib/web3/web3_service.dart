import 'package:flutter_web3/flutter_web3.dart';

class Web3Service {
  Ethereum? ethereum;

  // Infura Project ID দিয়ে RPC URL
  static const String infuraProjectId = "a8db11f4eba940ae8baef730fd23792b"; // এখানে তোমার Project ID বসাও

  final Map<int, String> rpc = {
    1: "https://mainnet.infura.io/v3/$infuraProjectId", // Ethereum Mainnet
    5: "https://goerli.infura.io/v3/$infuraProjectId",  // Goerli Testnet
  };

  Web3Service() {
    if (Ethereum.isSupported) {
      ethereum = Ethereum();
    }
  }

  bool get isConnected => ethereum != null && ethereum!.isConnected;

  /// Connected account address ফেরত দেয়
  Future<String?> getAccount() async {
    if (ethereum == null) return null;
    final accounts = await ethereum!.requestAccount();
    return accounts.isNotEmpty ? accounts.first : null;
  }

  /// Account balance Ether এ ফেরত দেয়
  Future<String?> getBalance(String account) async {
    if (ethereum == null) return null;
    try {
      final balance = await ethereum!.getBalance(account);
      return EtherAmount.fromBigInt(balance).getValueInUnit(EtherUnit.ether).toString();
    } catch (e) {
      print("Error fetching balance: $e");
      return null;
    }
  }
}
