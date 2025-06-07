import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:nfcommunicator_frontend/util/globals.dart' as globals;
import "package:pointycastle/export.dart";

class PointycastleUtil {
  static SecureRandom _createSecureRandom(Uint8List bytes) {
    final secureRandom = SecureRandom('Fortuna')..seed(KeyParameter(bytes));
    return secureRandom;
  }

  static AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _generateRSAkeyPair(
    SecureRandom secureRandom, {
    int bitLength = 4096,
  }) {
    final keyGen = RSAKeyGenerator();
    keyGen.init(
      ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
        secureRandom,
      ),
    );
    final pair = keyGen.generateKeyPair();
    final myPublic = pair.publicKey;
    final myPrivate = pair.privateKey;
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(myPublic, myPrivate);
  }

  static Future<Map<String, String>> generateRSAkeyPair(
    String collectedEntropy,
  ) async {
    return await Isolate.run(() {
      Uint8List bytes = utf8.encode(
        md5.convert(utf8.encode(collectedEntropy)).toString(),
      );
      AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> keys = _generateRSAkeyPair(
        _createSecureRandom(bytes),
      );
      var keyMap = <String, String>{};
      keyMap[globals.keystoreKPrivateKeyKey] =
          CryptoUtils.encodeRSAPrivateKeyToPem(keys.privateKey);
      keyMap[globals.keystorePublicKeyKey] =
          CryptoUtils.encodeRSAPublicKeyToPem(keys.publicKey);
      return keyMap;
    });
  }

  static Future<Uint8List> rsaEncrypt(
    RSAPublicKey myPublic,
    Uint8List dataToEncrypt,
  ) async {
    return Future(() {
      final encryptor = OAEPEncoding(
        RSAEngine(),
      )..init(true, PublicKeyParameter<RSAPublicKey>(myPublic)); // true=encrypt
      return _processInBlocks(encryptor, dataToEncrypt);
    });
  }

  static Future<Uint8List> rsaDecrypt(
    RSAPrivateKey myPrivate,
    Uint8List cipherText,
  ) {
    final decryptor = OAEPEncoding(RSAEngine())..init(
      false,
      PrivateKeyParameter<RSAPrivateKey>(myPrivate),
    ); // false=decrypt

    return _processInBlocks(decryptor, cipherText);
  }

  static Future<Uint8List> rsaSignAsync(
    RSAPrivateKey privateKey,
    Uint8List dataToSign,
  ) async {
    return Future(() {
      final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
      signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
      final sig = signer.generateSignature(dataToSign);
      return sig.bytes;
    });
  }

  static Future<bool> rsaVerifyAsync(
    RSAPublicKey publicKey,
    Uint8List signedData,
    Uint8List signature,
  ) async {
    return Future(() {
      final sig = RSASignature(signature);
      final verifier = RSASigner(SHA256Digest(), '0609608648016503040201');
      verifier.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));
      try {
        return verifier.verifySignature(signedData, sig);
      } on ArgumentError {
        return false;
      }
    });
  }

  static _processInBlocks(AsymmetricBlockCipher engine, Uint8List input) {
    final numBlocks =
        input.length ~/ engine.inputBlockSize +
        ((input.length % engine.inputBlockSize != 0) ? 1 : 0);

    final output = Uint8List(numBlocks * engine.outputBlockSize);

    var inputOffset = 0;
    var outputOffset = 0;
    while (inputOffset < input.length) {
      final chunkSize =
          (inputOffset + engine.inputBlockSize <= input.length)
              ? engine.inputBlockSize
              : input.length - inputOffset;

      outputOffset += engine.processBlock(
        input,
        inputOffset,
        chunkSize,
        output,
        outputOffset,
      );

      inputOffset += chunkSize;
    }

    return (output.length == outputOffset)
        ? output
        : output.sublist(0, outputOffset);
  }
}
