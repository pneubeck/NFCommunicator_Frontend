class UserData {
  final int userId;
  final String userName;

  UserData({required this.userId, required this.userName});

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'userName': userName};
  }
}
