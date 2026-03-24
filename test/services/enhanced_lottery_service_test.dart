import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/services/enhanced_lottery_service.dart';

void main() {
  group('EnhancedLotteryService cryptographic seed behavior', () {
    test('generateCryptographicSeed returns 64-char hex digest', () {
      final seed =
          EnhancedLotteryService.instance.generateCryptographicSeed('election-1');
      expect(seed.length, 64);
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(seed), isTrue);
    });

    test('generateCryptographicSeed varies across calls', () {
      final first =
          EnhancedLotteryService.instance.generateCryptographicSeed('election-1');
      final second =
          EnhancedLotteryService.instance.generateCryptographicSeed('election-1');
      expect(first == second, isFalse);
    });
  });
}
