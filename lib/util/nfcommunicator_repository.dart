import 'package:http/http.dart' as http;
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
}
