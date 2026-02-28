import 'package:flutter/material.dart';
import '../web3/web3_service.dart';

class WalletConnectButton extends StatefulWidget {
  const WalletConnectButton({super.key});

  @override
  State<WalletConnectButton> createState() => _WalletConnectButtonState();
}

class _WalletConnectButtonState extends State<WalletConnectButton> {
  final Web3Service _web3 = Web3Service();
  String? _account;
  String? _balance;

  @override
  void initState() {
    super.initState();
    _initWallet();
  }

  Future<void> _initWallet() async {
    final account = await _web3.getAccount();
    if (account != null) {
      final balance = await _web3.getBalance(account);
      setState(() {
        _account = account;
        _balance = balance;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _initWallet,
      child: Text(
        _account != null
            ? "Connected: ${_account!.substring(0, 6)}...${_account!.substring(_account!.length - 4)} | $_balance ETH"
            : "Connect Wallet",
      ),
    );
  }
}
