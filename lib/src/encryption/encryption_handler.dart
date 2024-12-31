import 'dart:developer';
import 'package:encrypt/encrypt.dart';

class EncryptionHandler {
  final String _key;
  late final Key _encryptionKey;
  final IV _iv; // Initialization Vector

  EncryptionHandler(this._key) : _iv = IV.fromUtf8('put16characters!') {
    // Ensure the IV is consistent and 16 characters long
    // Ensure the key is 32 bytes for AES-256
    if (_key.length != 32) {
      throw ArgumentError('Encryption key must be 32 characters long.');
    }
    _encryptionKey = Key.fromUtf8(_key);
    log('encrypted key: $_key');
  }

  String encrypt(String data) {
    final encrypter =
        Encrypter(AES(_encryptionKey, mode: AESMode.cbc)); // Use CBC mode
    final encrypted = encrypter.encrypt(data, iv: _iv);
    log('encrypted.base64: ${encrypted.base64}');
    return encrypted.base64; // Encode encrypted data as Base64
  }

  String decrypt(String data) {
    log("data: $data");
    final encrypter =
        Encrypter(AES(_encryptionKey, mode: AESMode.cbc)); // Use CBC mode
    log("encrypter: ${encrypter.algo}");

    final decrypted = encrypter.decrypt(Encrypted.fromBase64(data), iv: _iv);
    log("decrypted: $decrypted");

    return decrypted;
  }
}
