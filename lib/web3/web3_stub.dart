class Web3Service {
  Web3Service();

  Future<String> getBalance(String account) async {
    return "0"; // Web এ dummy balance
  }

  Future<String> sendTransaction(String to, double amount) async {
    return "0x0"; // Web এ dummy txn
  }
}
