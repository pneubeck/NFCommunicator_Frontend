import 'dart:convert';
import 'dart:typed_data';

enum MessageType {
  text(1),
  image(2),
  video(3);

  const MessageType(this.value);
  final num value;

  static MessageType getByValue(num i) {
    return MessageType.values.firstWhere((x) => x.value == i);
  }
}

class Message {
  int? messageId;
  final DateTime? creationDate;
  final DateTime? lastUpdateDate;
  final DateTime? deletionDate;
  DateTime? messageSentDate;
  final int senderUserId;
  final int recipientUserId;
  final MessageType messageType;
  final int? groupChatId;
  final Uint8List encryptedMessage;
  final String? decryptedMessage;
  final Uint8List? decryptedMessageBlob;

  Message({
    this.messageId,
    this.creationDate,
    this.lastUpdateDate,
    this.deletionDate,
    this.messageSentDate,
    required this.senderUserId,
    required this.recipientUserId,
    required this.messageType,
    this.groupChatId,
    required this.encryptedMessage,
    this.decryptedMessage,
    this.decryptedMessageBlob,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'creationDate': creationDate?.toIso8601String(),
      'lastUpdateDate': lastUpdateDate?.toIso8601String(),
      'deletionDate': deletionDate?.toIso8601String(),
      'messageSentData': messageSentDate?.toIso8601String(),
      'senderUserId': senderUserId,
      'recipientUserId': recipientUserId,
      'messageType': messageType.value, // convert enum to int
      'groupChatId': groupChatId,
      'encryptedMessage': base64Encode(
        encryptedMessage,
      ), // encode binary to base64
      'decryptedMessage': decryptedMessage,
      'decryptedMessageBlob': decryptedMessageBlob,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      messageId: map['messageId'],
      creationDate:
          map['creationDate'] != null
              ? DateTime.parse(map['creationDate'])
              : null,
      lastUpdateDate:
          map['lastUpdateDate'] != null
              ? DateTime.parse(map['lastUpdateDate'])
              : null,
      deletionDate:
          map['deletionDate'] != null
              ? DateTime.parse(map['deletionDate'])
              : null,
      messageSentDate:
          map['messageSentDate'] != null
              ? DateTime.parse(map['messageSentDate'])
              : null,
      senderUserId: map['senderUserId'],
      recipientUserId: map['recipientUserId'],
      messageType: MessageType.getByValue(map['messageType']),
      groupChatId: map['groupChatId'],
      encryptedMessage: base64Decode(map['encryptedMessage']),
      decryptedMessage: map['decryptedMessage'],
      decryptedMessageBlob: map['decryptedMessageBlob'],
    );
  }

  // factory Message.fromJson(String source) => Message.fromMap(json.decode(source));
}
