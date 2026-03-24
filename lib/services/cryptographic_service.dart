import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class ThresholdShare {
  final int x;
  final String yHex;
  final int threshold;
  final int totalShares;

  const ThresholdShare({
    required this.x,
    required this.yHex,
    required this.threshold,
    required this.totalShares,
  });
}

class SchnorrProof {
  final String commitmentHex;
  final String challengeHex;
  final String responseHex;

  const SchnorrProof({
    required this.commitmentHex,
    required this.challengeHex,
    required this.responseHex,
  });
}

class CryptographicService {
  static final BigInt _prime = BigInt.parse(
    'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',
    radix: 16,
  );

  static final BigInt _generator = BigInt.from(5);
  static final BigInt _groupOrder = _prime - BigInt.one;

  BigInt _mod(BigInt n) {
    final r = n % _prime;
    return r < BigInt.zero ? (r + _prime) : r;
  }

  BigInt _modPow(BigInt base, BigInt exp) {
    var result = BigInt.one;
    var b = _mod(base);
    var e = exp;
    while (e > BigInt.zero) {
      if ((e & BigInt.one) == BigInt.one) {
        result = _mod(result * b);
      }
      b = _mod(b * b);
      e = e >> 1;
    }
    return result;
  }

  BigInt _modInverse(BigInt a) {
    var t = BigInt.zero;
    var newT = BigInt.one;
    var r = _prime;
    var newR = _mod(a);

    while (newR != BigInt.zero) {
      final q = r ~/ newR;
      final oldT = t;
      t = newT;
      newT = oldT - q * newT;
      final oldR = r;
      r = newR;
      newR = oldR - q * newR;
    }

    if (r != BigInt.one) {
      throw StateError('No modular inverse for provided value');
    }
    return _mod(t);
  }

  BigInt _utf8ToBigInt(String value) {
    final bytes = utf8.encode(value);
    var result = BigInt.zero;
    for (final b in bytes) {
      result = (result << 8) | BigInt.from(b);
    }
    return result;
  }

  String _bigIntToUtf8(BigInt value) {
    var n = _mod(value);
    if (n == BigInt.zero) return '';
    final bytes = <int>[];
    while (n > BigInt.zero) {
      bytes.add((n & BigInt.from(255)).toInt());
      n = n >> 8;
    }
    return utf8.decode(bytes.reversed.toList());
  }

  List<ThresholdShare> splitSecret({
    required String secret,
    required int totalShares,
    required int threshold,
  }) {
    if (secret.isEmpty || threshold < 2 || totalShares < threshold) {
      throw ArgumentError('Invalid threshold split parameters');
    }

    final secretInt = _utf8ToBigInt(secret);
    if (secretInt >= _prime) {
      throw ArgumentError('Secret exceeds field size');
    }

    final random = Random.secure();
    final coefficients = <BigInt>[secretInt];
    for (var i = 1; i < threshold; i++) {
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      final coeff = _mod(_utf8ToBigInt(base64.encode(bytes)));
      coefficients.add(coeff);
    }

    final shares = <ThresholdShare>[];
    for (var x = 1; x <= totalShares; x++) {
      final bx = BigInt.from(x);
      var y = BigInt.zero;
      for (var p = 0; p < coefficients.length; p++) {
        y = _mod(y + coefficients[p] * _modPow(bx, BigInt.from(p)));
      }
      shares.add(
        ThresholdShare(
          x: x,
          yHex: y.toRadixString(16),
          threshold: threshold,
          totalShares: totalShares,
        ),
      );
    }
    return shares;
  }

  String reconstructSecret(List<ThresholdShare> shares) {
    if (shares.isEmpty) {
      throw ArgumentError('No shares provided');
    }
    final threshold = shares.first.threshold;
    if (shares.length < threshold) {
      throw ArgumentError('Insufficient shares');
    }
    final selected = shares.take(threshold).toList();

    var secret = BigInt.zero;
    for (var i = 0; i < selected.length; i++) {
      final xi = BigInt.from(selected[i].x);
      final yi = BigInt.parse(selected[i].yHex, radix: 16);
      var numerator = BigInt.one;
      var denominator = BigInt.one;

      for (var j = 0; j < selected.length; j++) {
        if (i == j) continue;
        final xj = BigInt.from(selected[j].x);
        numerator = _mod(numerator * (_prime - xj));
        denominator = _mod(denominator * (xi - xj));
      }

      final li = _mod(numerator * _modInverse(denominator));
      secret = _mod(secret + yi * li);
    }

    return _bigIntToUtf8(secret);
  }

  SchnorrProof generateSchnorrProof({
    required String message,
    required String secret,
  }) {
    final secretInt = _utf8ToBigInt(secret) % _groupOrder;
    final random = Random.secure();
    final nonceBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final nonce = _utf8ToBigInt(base64.encode(nonceBytes)) % _groupOrder;

    final commitment = _modPow(_generator, nonce);
    final pubKey = _modPow(_generator, secretInt);

    final challengeHex = sha256
        .convert(utf8.encode('$message:${commitment.toRadixString(16)}:${pubKey.toRadixString(16)}'))
        .toString();
    final challenge = BigInt.parse(challengeHex, radix: 16) % _groupOrder;
    final response = (nonce + challenge * secretInt) % _groupOrder;

    return SchnorrProof(
      commitmentHex: commitment.toRadixString(16),
      challengeHex: challengeHex,
      responseHex: response.toRadixString(16),
    );
  }

  bool verifySchnorrProof({
    required String message,
    required String publicKeyHex,
    required SchnorrProof proof,
  }) {
    final commitment = BigInt.parse(proof.commitmentHex, radix: 16);
    final publicKey = BigInt.parse(publicKeyHex, radix: 16);
    final response = BigInt.parse(proof.responseHex, radix: 16);

    final expectedChallengeHex = sha256
        .convert(utf8.encode('$message:${proof.commitmentHex}:$publicKeyHex'))
        .toString();
    if (expectedChallengeHex != proof.challengeHex) return false;

    final challenge = BigInt.parse(proof.challengeHex, radix: 16) % _groupOrder;
    final left = _modPow(_generator, response);
    final right = _mod(commitment * _modPow(publicKey, challenge));
    return left == right;
  }

  String derivePublicKeyHex(String secret) {
    final secretInt = _utf8ToBigInt(secret) % _groupOrder;
    return _modPow(_generator, secretInt).toRadixString(16);
  }
}
