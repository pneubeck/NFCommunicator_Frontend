import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:nfcommunicator_frontend/models/contact.dart';
import 'package:nfcommunicator_frontend/models/message.dart';
import 'package:nfcommunicator_frontend/util/globals.dart' as globals;
import 'package:nfcommunicator_frontend/util/nfcommunicator_repository.dart';
import 'package:nfcommunicator_frontend/util/pointycastle_util.dart';
import 'package:nfcommunicator_frontend/util/sqllite_database_util.dart';
import 'package:pointycastle/impl.dart';

class ChatMessage {
  final String message;
  final bool isSender; // true = you, false = other person

  ChatMessage({required this.message, required this.isSender});
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

  @override
  void initState() {
    super.initState();
    _contactPublicKey = CryptoUtils.rsaPublicKeyFromPem(
      widget.contact.publicKeyPem,
    );
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    var encryptedMessage = await PointycastleUtil.rsaEncrypt(
      _contactPublicKey,
      Uint8List.fromList(utf8.encode(_controller.text.trim())),
    );
    var signedMessage = await PointycastleUtil.rsaSignAsync(
      globals.privateKey!,
      encryptedMessage,
    );
    setState(() {
      _messages.add(
        ChatMessage(message: _controller.text.trim(), isSender: true),
      );
    });
    final dbHelper = DatabaseHelper();
    final userData = await dbHelper.getUserData();
    var message = Message(
      senderUserId: userData.userId,
      recipientUserId: widget.contact.userId,
      messageType: MessageType.text,
      encryptedMessage: signedMessage,
    );
    await NFCommunicatorRepository().sendMessage(message);
    _controller.clear();
    // Optional: Scroll to bottom after sending
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
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
                  hintText: 'Type a message...',
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
      body: Column(
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
      ),
    );
  }
}
