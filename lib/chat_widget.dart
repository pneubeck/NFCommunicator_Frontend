import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nfcommunicator_frontend/models/contact.dart';
import 'package:nfcommunicator_frontend/models/message.dart';
import 'package:nfcommunicator_frontend/models/user_data.dart';
import 'package:nfcommunicator_frontend/util/globals.dart' as globals;
import 'package:nfcommunicator_frontend/util/nfcommunicator_repository.dart';
import 'package:nfcommunicator_frontend/util/pointycastle_util.dart';
import 'package:nfcommunicator_frontend/util/sqllite_database_util.dart';

class ChatMessage {
  final String message;
  final bool isSender;
  bool isSent;
  bool isSending;

  ChatMessage({
    required this.message,
    required this.isSender,
    this.isSent = false,
    this.isSending = true,
  });
}

List<Message> getMessages(int userId) {
  //TODO->Load potential new messages from backend
  return messageMaps.map((map) => Message.fromMap(map)).toList();
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.contact});
  final Contact contact;

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late RSAPublicKey _contactPublicKey;
  late UserData _userData;
  Timer? _messageLoadTimer;

  @override
  void initState() {
    super.initState();
    final dbHelper = DatabaseHelper();
    Future(() async {
      _userData = await dbHelper.getUserData();
    });
    _contactPublicKey = CryptoUtils.rsaPublicKeyFromPem(
      widget.contact.publicKeyPem,
    );
    _messageLoadTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      loadMessages();
    });
  }

  @override
  void dispose() {
    _messageLoadTimer?.cancel();
    super.dispose();
  }

  void loadMessages() async {
    // Heavy computation runs in a background isolate using compute()
    final newMessages = await compute(getMessages, _userData.userId);
    newMessages.sort((a, b) {
      // Use `?? DateTime(0)` to handle nulls and push them to the end
      final dateA = a.creationDate ?? DateTime(0);
      final dateB = b.creationDate ?? DateTime(0);
      return dateA.compareTo(dateB); // descending order
    });
    //then add them to message list like
    var dbHelper = DatabaseHelper();
    var userData = await dbHelper.getUserData();
    for (final msg in newMessages) {
      _messages.add(
        ChatMessage(
          message: msg.decryptedMessage!,
          isSender: msg.senderUserId == userData.userId,
          isSending:
              msg.messageSentDate == DateTime(0)
                  ? true
                  : false, // or true if it's still sending
        ),
      );
    }
    setState(() {});
  }

  Future getInitialMessages() async {
    var dbHelper = DatabaseHelper();
    var messages = await dbHelper.getMessages(widget.contact.userId);
    messages.sort((a, b) {
      // Use `?? DateTime(0)` to handle nulls and push them to the end
      final dateA = a.creationDate ?? DateTime(0);
      final dateB = b.creationDate ?? DateTime(0);
      return dateA.compareTo(dateB); // descending order
    });
    //then add them to message list like
    var userData = await dbHelper.getUserData();
    for (final msg in messages) {
      _messages.add(
        ChatMessage(
          message: msg.decryptedMessage!,
          isSender: msg.senderUserId == userData.userId,
          isSending:
              msg.messageSentDate == DateTime(0)
                  ? true
                  : false, // or true if it's still sending
        ),
      );
    }
    return true;
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    String plainText = _controller.text.trim();
    setState(() {
      _messages.add(
        ChatMessage(message: plainText, isSender: true, isSending: true),
      );
    });
    final int messageIndex =
        _messages.length - 1; // Save index for updating later
    var encryptedMessage = await PointycastleUtil.rsaEncrypt(
      _contactPublicKey,
      Uint8List.fromList(utf8.encode(plainText)),
    );
    var signedMessage = await PointycastleUtil.rsaSignAsync(
      globals.privateKey!,
      encryptedMessage,
    );
    var message = Message(
      creationDate: DateTime.now(),
      lastUpdateDate: DateTime.now(),
      senderUserId: _userData.userId,
      recipientUserId: widget.contact.userId,
      messageType: MessageType.text,
      encryptedMessage: signedMessage,
    );
    message.messageId = await DatabaseHelper().insertMessage(message);
    await NFCommunicatorRepository().sendMessage(message);
    setState(() {
      _messages[messageIndex].isSending = false;
      _messages[messageIndex].isSent = true;
    });
    message.messageSentDate = DateTime.now();
    await DatabaseHelper().updateMessage(message);
    _controller.clear();
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildMessage(ChatMessage msg) {
    return Align(
      alignment: msg.isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment:
              msg.isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center, // ← center vertically
          children: [
            // Status icon (only for sender)
            if (msg.isSender)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child:
                    msg.isSending
                        ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Icon(Icons.check, size: 16, color: Colors.green),
              ),

            // Message bubble
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: 250),
              decoration: BoxDecoration(
                color:
                    msg.isSender
                        ? Theme.of(context).colorScheme.inversePrimary
                        : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(msg.message, style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration.collapsed(
                  hintText: 'Nachricht eingeben...',
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.send,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact.userName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder(
        future: getInitialMessages(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessage(_messages[index]);
                    },
                  ),
                ),
                Divider(height: 1),
                _buildInputArea(),
              ],
            );
          }
          return Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              height: MediaQuery.of(context).size.width / 2,
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          );
        },
      ),
    );
  }
}
