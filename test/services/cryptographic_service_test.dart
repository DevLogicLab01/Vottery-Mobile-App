import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/services/cryptographic_service.dart';

void main() {
  group('CryptographicService threshold', () {
    final service = CryptographicService();

    test('splits and reconstructs original secret', () {
      const secret = 'election-threshold-secret';
      final shares = service.splitSecret(
        secret: secret,
        totalShares: 5,
        threshold: 3,
      );

      final reconstructed = service.reconstructSecret([
        shares[0],
        shares[2],
        shares[4],
      ]);

      expect(reconstructed, secret);
    });

    test('throws on insufficient shares', () {
      const secret = 'another-secret';
      final shares = service.splitSecret(
        secret: secret,
        totalShares: 4,
        threshold: 3,
      );

      expect(
        () => service.reconstructSecret([shares[0], shares[1]]),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('CryptographicService Schnorr proof', () {
    final service = CryptographicService();

    test('verifies valid proof for message and public key', () {
      const message = 'vote:option-a';
      const secret = 'trustee-secret-key';
      final publicKeyHex = service.derivePublicKeyHex(secret);
      final proof = service.generateSchnorrProof(
        message: message,
        secret: secret,
      );

      final ok = service.verifySchnorrProof(
        message: message,
        publicKeyHex: publicKeyHex,
        proof: proof,
      );
      expect(ok, isTrue);
    });

    test('rejects proof for different message', () {
      const secret = 'trustee-secret-key';
      final publicKeyHex = service.derivePublicKeyHex(secret);
      final proof = service.generateSchnorrProof(
        message: 'vote:option-a',
        secret: secret,
      );

      final ok = service.verifySchnorrProof(
        message: 'vote:option-b',
        publicKeyHex: publicKeyHex,
        proof: proof,
      );
      expect(ok, isFalse);
    });
  });
}
