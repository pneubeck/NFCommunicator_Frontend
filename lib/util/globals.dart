import 'package:pointycastle/asymmetric/api.dart';

const String webApiBaseUrl = "http://localhost:8080/";

const String keystoreKPrivateKeyKey = "NFCommunicatorPrivateKey";
const String keystorePublicKeyKey = "NFCommunicatorPublicKey";
RSAPrivateKey? privateKey;
RSAPublicKey? publicKey;
