import 'dart:typed_data';
import "package:pointycastle/export.dart";

AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair(
  SecureRandom secureRandom, {
  int bitLength = 4096,
}) {
  // Create an RSA key generator and initialize it

  // final keyGen = KeyGenerator('RSA'); // Get using registry
  final keyGen = RSAKeyGenerator();

  keyGen.init(
    ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
      secureRandom,
    ),
  );

  // Use the generator

  final pair = keyGen.generateKeyPair();

  // Cast the generated key pair into the RSA key types

  final myPublic = pair.publicKey;
  final myPrivate = pair.privateKey;

  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(myPublic, myPrivate);
}

SecureRandom createSecureRandom(Uint8List bytes) {
  final secureRandom = SecureRandom('Fortuna')..seed(KeyParameter(bytes));
  return secureRandom;
}

Uint8List rsaSign(RSAPrivateKey privateKey, Uint8List dataToSign) {
  final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
  signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
  final sig = signer.generateSignature(dataToSign);
  final signatureBytes = sig.bytes;
  return signatureBytes;
}

bool rsaVerify(
  RSAPublicKey publicKey,
  Uint8List signedData,
  Uint8List signature,
) {
  final sig = RSASignature(signature);
  final verifier = RSASigner(SHA256Digest(), '0609608648016503040201');
  verifier.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));
  try {
    return verifier.verifySignature(signedData, sig);
  } on ArgumentError {
    return false; // for Pointy Castle 1.0.2 when signature has been modified
  }
}

Uint8List rsaEncrypt(RSAPublicKey myPublic, Uint8List dataToEncrypt) {
  final encryptor = OAEPEncoding(RSAEngine())
    ..init(true, PublicKeyParameter<RSAPublicKey>(myPublic)); // true=encrypt

  return _processInBlocks(encryptor, dataToEncrypt);
}

Uint8List rsaDecrypt(RSAPrivateKey myPrivate, Uint8List cipherText) {
  final decryptor = OAEPEncoding(RSAEngine())..init(
    false,
    PrivateKeyParameter<RSAPrivateKey>(myPrivate),
  ); // false=decrypt

  return _processInBlocks(decryptor, cipherText);
}

Uint8List _processInBlocks(AsymmetricBlockCipher engine, Uint8List input) {
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
