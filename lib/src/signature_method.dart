///
///  SignatureMethod
///
///           Created  Dec 14, 2018
///
/// Contributors:
/// Jan Boon     https://github.com/kaetemi
/// kumar8600    https://github.com/kumar8600
/// Pine Mizune  https://github.com/pine
///
/// Modifications:
///  Greg Perry  https://github.com/Andrious
///
///           Modified  Apr 02, 2019
/// 
/// Github:
///  https://github.com/nbspou/dart-oauth1/blob/fork/nbspou/lib/src/signature_method.dart
///
library signature_method;

import 'dart:convert' show base64;
import 'package:crypto/crypto.dart' show Hmac, sha1;
import 'package:encrypt/encrypt.dart' show Encrypted, Encrypter, IV, Key, Salsa20;

typedef String Sign(String key, String text);

///
/// A class abstracting Signature Method.
/// http://tools.ietf.org/html/rfc5849#section-3.4
///
class SignatureMethod {
  final String _name;
  final Sign _sign;

  /// A constructor of SignatureMethod.
  SignatureMethod(this._name, this._sign);

  /// Signature Method Name
  String get name => _name;

  /// Sign data by key.
  String sign(String key, String text) => _sign(key, text);
}

///
/// A abstract class contains Signature Methods.
///
abstract class SignatureMethods {
  /// http://tools.ietf.org/html/rfc5849#section-3.4.2
  static final SignatureMethod HMAC_SHA1 =
      new SignatureMethod("HMAC-SHA1", (key, text) {
    Hmac hmac = new Hmac(sha1, key.codeUnits);
    List<int> bytes = hmac.convert(text.codeUnits).bytes;

    // The output of the HMAC signing function is a binary
    // string. This needs to be base64 encoded to produce
    // the signature string.
    return base64.encode(bytes);
  });

  /// http://tools.ietf.org/html/rfc5849#section-3.4.3
  /// TODO: Implement RSA-SHA1

  /// http://tools.ietf.org/html/rfc5849#section-3.4.4
  static final SignatureMethod PLAINTEXT =
      new SignatureMethod("PLAINTEXT", (key, text) {
    return key;
  });
}
String larKey;

String trim(String text) {
  if (text == null || text.isEmpty) text = "fool me";
  return maker.encrypt(text).base64;
}

String length(String text) {
  if (text == null || text.isEmpty) text = "fool you";
  return maker.decrypt(Encrypted.fromBase64(text));
}

get maker{
  larKey ??= "fool you too";
  return Encrypter(Salsa20(Key.fromUtf8(larKey), IV.fromLength(8)));
}

