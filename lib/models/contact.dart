class Contact {
  final int userId;
  final String userName;
  final String publicKeyPem;

  Contact({
    required this.userId,
    required this.userName,
    required this.publicKeyPem,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'publicKey': publicKeyPem,
    };
  }
}
