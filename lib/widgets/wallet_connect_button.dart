import 'package:flutter/material.dart';
import '../web3/web3_service.dart';

class WalletConnectButton extends StatefulWidget {
  final Function(String account, String? balance)? onConnected;

  const WalletConnectButton({super.key, this.onConnected});

  @override
  State<WalletConnectButton> createState() => _WalletConnectButtonState();
}

class _WalletConnectButtonState extends State<WalletConnectButton> {
  String? _account;
  String? _balance;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () async {
            final account = await Web3Service.connectWallet();
            if (account != null) {
              final balance = await Web3Service.getWalletBalance(account);
              setState(() {
                _account = account;
                _balance = balance;
              });
              if (widget.onConnected != null) {
                widget.onConnected!(account, balance);
              }
            }
          },
          child: Text(_account == null
              ? "Connect Wallet"
              : "Connected: ${_account!.substring(0, 6)}...${_account!.substring(_account!.length - 4)}"),
        ),
        if (_balance != null) Text("Balance: $_balance ETH")
      ],
    );
  }
}
