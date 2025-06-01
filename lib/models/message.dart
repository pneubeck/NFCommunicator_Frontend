import 'dart:typed_data';

class Message {
final int messageId;
final DateTime creationDate;
final DateTime lastUpdateDate;
final DateTime deletionDate;
final int senderUserId;
final int recipientUserId;
final int messageType;
final int groupChatId;
final Uint8List encryptedMessage;

  Message({
    required this.messageId,
    required this.creationDate,
    required this.lastUpdateDate,
    required this.deletionDate,
    required this.senderUserId,
    required this.recipientUserId,
    required this.messageType,
    required this.groupChatId,
    required this.encryptedMessage
  });

  Map<String, dynamic> toMap() {
    return {
      'messageid': messageId,
      'creationDate': creationDate,
      'lastUpdateDate': lastUpdateDate,
      'deletionDate': deletionDate,
      'senderUserId': senderUserId,
      'recipientUserId': recipientUserId,
      'messageType': messageType,
      'groupChatId': groupChatId,
      'encryptedMessage': encryptedMessage
    };
  }
}