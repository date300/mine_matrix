import 'package:flutter/material.dart';
import '../web3/web3_service.dart';

class WalletConnectButton extends StatefulWidget {
  final Web3Service web3Service;

  const WalletConnectButton({super.key, required this.web3Service});

  @override
  State<WalletConnectButton> createState() => _WalletConnectButtonState();
}

class _WalletConnectButtonState extends State<WalletConnectButton> {
  String? account;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final acc = await widget.web3Service.getAccount();
        setState(() {
          account = acc;
        });
      },
      child: Text(account != null ? "Connected: $account" : "Connect Wallet"),
    );
  }
}
