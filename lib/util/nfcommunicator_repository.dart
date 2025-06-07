import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nfcommunicator_frontend/models/message.dart';
import 'package:nfcommunicator_frontend/util/globals.dart' as globals;

class NFCommunicatorRepository {
  Future<int> getUserId() async {
    //var client = http.Client();
    var uri = Uri.parse('${globals.webApiBaseUrl}NextUserId');
    var response = await http.get(uri);
    if (response.statusCode == 200) {
      return int.parse(response.body);
    }
    throw "Unable to get a UserId from backen";
  }

  Future<bool> sendMessage(Message message) async {
    var uri = Uri.parse('${globals.webApiBaseUrl}PostMessage');
    var response = await http.post(uri, body: json.encode(message.toMap()));
    if (response.statusCode == 201) {
      return true;
    }
    throw "Unable to get a UserId from backen";
  }
}
