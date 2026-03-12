import 'package:supabase_flutter/supabase_flutter.dart';

class FraudPatternDetectionService {
  static final FraudPatternDetectionService _instance =
      FraudPatternDetectionService._internal();
  factory FraudPatternDetectionService() => _instance;
  FraudPatternDetectionService._internal();

  final _supabase = Supabase.instance.client;

  /// Detect multi-account abuse patterns
  Future<List<Map<String, dynamic>>> detectMultiAccountAbuse(
    List<Map<String, dynamic>> logs,
  ) async {
    final patterns = <Map<String, dynamic>>[];

    // Group by device fingerprint and IP address
    final deviceGroups = <String, List<Map<String, dynamic>>>{};
    final ipGroups = <String, List<Map<String, dynamic>>>{};

    for (final log in logs) {
      final deviceFingerprint =
          log['metadata']?['device_fingerprint'] as String?;
      final ipAddress = log['ip_address'] as String?;
      final userId = log['user_id'] as String?;

      if (deviceFingerprint != null && userId != null) {
        deviceGroups.putIfAbsent(deviceFingerprint, () => []).add(log);
      }
      if (ipAddress != null && userId != null) {
        ipGroups.putIfAbsent(ipAddress, () => []).add(log);
      }
    }

    // Detect same device/IP for multiple accounts
    for (final entry in deviceGroups.entries) {
      final uniqueUsers = entry.value.map((l) => l['user_id']).toSet();
      if (uniqueUsers.length >= 3) {
        patterns.add({
          'pattern_name': 'Multi-Account Abuse (Device)',
          'pattern_description':
              'Same device used by ${uniqueUsers.length} different accounts',
          'confidence_score': 0.85,
          'evidence': entry.value.map((l) => l['log_id']).toList(),
          'affected_users': uniqueUsers.toList(),
          'severity': 'high',
          'recommended_actions': [
            'Flag accounts for review',
            'Require additional verification',
            'Monitor for coordinated actions',
          ],
        });
      }
    }

    for (final entry in ipGroups.entries) {
      final uniqueUsers = entry.value.map((l) => l['user_id']).toSet();
      if (uniqueUsers.length >= 5) {
        patterns.add({
          'pattern_name': 'Multi-Account Abuse (IP)',
          'pattern_description':
              'Same IP address used by ${uniqueUsers.length} different accounts',
          'confidence_score': 0.75,
          'evidence': entry.value.map((l) => l['log_id']).toList(),
          'affected_users': uniqueUsers.toList(),
          'severity': 'medium',
          'recommended_actions': [
            'Investigate IP address',
            'Check for VPN/proxy usage',
            'Monitor account activity',
          ],
        });
      }
    }

    return patterns;
  }

  /// Detect account takeover patterns
  Future<List<Map<String, dynamic>>> detectAccountTakeover(
    List<Map<String, dynamic>> logs,
  ) async {
    final patterns = <Map<String, dynamic>>[];

    // Group by user_id
    final userLogs = <String, List<Map<String, dynamic>>>{};
    for (final log in logs) {
      final userId = log['user_id'] as String?;
      if (userId != null) {
        userLogs.putIfAbsent(userId, () => []).add(log);
      }
    }

    for (final entry in userLogs.entries) {
      final userId = entry.key;
      final userEvents = entry.value;

      // Check for suspicious indicators
      final indicators = <String>[];
      var suspicionScore = 0.0;

      // 1. Login from unusual location
      final locations = userEvents
          .where((l) => l['metadata']?['location'] != null)
          .map((l) => l['metadata']?['location'])
          .toSet();
      if (locations.length > 2) {
        indicators.add('Multiple login locations');
        suspicionScore += 0.3;
      }

      // 2. Login after password reset
      final hasPasswordReset = userEvents.any(
        (l) => l['action']?.toString().contains('password_reset') ?? false,
      );
      final hasLoginAfterReset =
          hasPasswordReset && userEvents.any((l) => l['action'] == 'login');
      if (hasLoginAfterReset) {
        indicators.add('Login immediately after password reset');
        suspicionScore += 0.4;
      }

      // 3. Rapid permission changes
      final permissionChanges = userEvents
          .where((l) => l['action']?.toString().contains('permission') ?? false)
          .length;
      if (permissionChanges >= 3) {
        indicators.add('Rapid permission changes');
        suspicionScore += 0.3;
      }

      // 4. Failed login attempts spike
      final failedLogins = userEvents
          .where((l) => l['action'] == 'failed_login')
          .length;
      if (failedLogins >= 5) {
        indicators.add('Multiple failed login attempts');
        suspicionScore += 0.2;
      }

      // Flag if 2+ indicators present
      if (indicators.length >= 2) {
        patterns.add({
          'pattern_name': 'Account Takeover',
          'pattern_description':
              'Suspicious account activity detected: ${indicators.join(", ")}',
          'confidence_score': suspicionScore.clamp(0.0, 1.0),
          'evidence': userEvents.map((l) => l['log_id']).toList(),
          'affected_users': [userId],
          'severity': suspicionScore > 0.7 ? 'critical' : 'high',
          'recommended_actions': [
            'Lock account immediately',
            'Require identity verification',
            'Reset credentials',
            'Notify user of suspicious activity',
          ],
        });
      }
    }

    return patterns;
  }

  /// Detect payment fraud patterns
  Future<List<Map<String, dynamic>>> detectPaymentFraud(
    List<Map<String, dynamic>> logs,
  ) async {
    final patterns = <Map<String, dynamic>>[];

    final paymentLogs = logs
        .where((l) => l['event_type'] == 'payment_transaction')
        .toList();

    // Group by user_id and IP
    final userPayments = <String, List<Map<String, dynamic>>>{};
    final ipPayments = <String, List<Map<String, dynamic>>>{};

    for (final log in paymentLogs) {
      final userId = log['user_id'] as String?;
      final ipAddress = log['ip_address'] as String?;

      if (userId != null) {
        userPayments.putIfAbsent(userId, () => []).add(log);
      }
      if (ipAddress != null) {
        ipPayments.putIfAbsent(ipAddress, () => []).add(log);
      }
    }

    // Detect failed attempts followed by success
    for (final entry in userPayments.entries) {
      final userId = entry.key;
      final payments = entry.value
        ..sort(
          (a, b) => DateTime.parse(
            a['timestamp'],
          ).compareTo(DateTime.parse(b['timestamp'])),
        );

      for (var i = 0; i < payments.length - 1; i++) {
        final current = payments[i];
        final next = payments[i + 1];

        final isFailed = current['action'] == 'payment_failed';
        final isSuccess = next['action'] == 'payment_success';

        if (isFailed && isSuccess) {
          final timeDiff = DateTime.parse(
            next['timestamp'],
          ).difference(DateTime.parse(current['timestamp']));

          if (timeDiff.inMinutes < 5) {
            patterns.add({
              'pattern_name': 'Payment Fraud (Failed then Success)',
              'pattern_description':
                  'Failed payment followed by successful payment within ${timeDiff.inMinutes} minutes',
              'confidence_score': 0.8,
              'evidence': [current['log_id'], next['log_id']],
              'affected_users': [userId],
              'severity': 'high',
              'recommended_actions': [
                'Review payment details',
                'Verify card ownership',
                'Check for stolen cards',
                'Contact user for verification',
              ],
            });
          }
        }
      }
    }

    // Detect high-value transactions from new accounts
    for (final entry in userPayments.entries) {
      final userId = entry.key;
      final payments = entry.value;

      final highValuePayments = payments.where((p) {
        final amount = p['metadata']?['amount'] as num? ?? 0;
        return amount > 500; // High value threshold
      }).toList();

      if (highValuePayments.isNotEmpty) {
        patterns.add({
          'pattern_name': 'Payment Fraud (High Value)',
          'pattern_description':
              'High-value transaction (\$${highValuePayments.first['metadata']?['amount']}) detected',
          'confidence_score': 0.65,
          'evidence': highValuePayments.map((p) => p['log_id']).toList(),
          'affected_users': [userId],
          'severity': 'medium',
          'recommended_actions': [
            'Manual review required',
            'Verify user identity',
            'Check transaction legitimacy',
          ],
        });
      }
    }

    return patterns;
  }

  /// Detect credential stuffing patterns
  Future<List<Map<String, dynamic>>> detectCredentialStuffing(
    List<Map<String, dynamic>> logs,
  ) async {
    final patterns = <Map<String, dynamic>>[];

    final authLogs = logs
        .where((l) => l['event_type'] == 'auth_event')
        .toList();

    // Group by IP address
    final ipAuthAttempts = <String, List<Map<String, dynamic>>>{};
    for (final log in authLogs) {
      final ipAddress = log['ip_address'] as String?;
      if (ipAddress != null) {
        ipAuthAttempts.putIfAbsent(ipAddress, () => []).add(log);
      }
    }

    for (final entry in ipAuthAttempts.entries) {
      final ipAddress = entry.key;
      final attempts = entry.value;

      // Calculate velocity (attempts per minute)
      if (attempts.length >= 10) {
        final timestamps =
            attempts.map((a) => DateTime.parse(a['timestamp'])).toList()
              ..sort();

        final duration = timestamps.last.difference(timestamps.first);
        final velocity = attempts.length / duration.inMinutes.clamp(1, 999999);

        if (velocity > 10) {
          final uniqueUsers = attempts.map((a) => a['user_id']).toSet();

          patterns.add({
            'pattern_name': 'Credential Stuffing',
            'pattern_description':
                'Rapid login attempts from IP $ipAddress: ${attempts.length} attempts in ${duration.inMinutes} minutes (${velocity.toStringAsFixed(1)} per minute)',
            'confidence_score': 0.9,
            'evidence': attempts.map((a) => a['log_id']).toList(),
            'affected_users': uniqueUsers.toList(),
            'severity': 'critical',
            'recommended_actions': [
              'Block IP address immediately',
              'Enable CAPTCHA',
              'Implement rate limiting',
              'Alert security team',
            ],
          });
        }
      }
    }

    return patterns;
  }

  /// Detect referral fraud patterns
  Future<List<Map<String, dynamic>>> detectReferralFraud(
    List<Map<String, dynamic>> logs,
  ) async {
    final patterns = <Map<String, dynamic>>[];

    // This would require referral data - placeholder implementation
    final referralLogs = logs
        .where((l) => l['action']?.toString().contains('referral') ?? false)
        .toList();

    if (referralLogs.isNotEmpty) {
      // Detect circular referral chains
      final referralMap = <String, String>{};
      for (final log in referralLogs) {
        final userId = log['user_id'] as String?;
        final referrerId = log['metadata']?['referrer_id'] as String?;
        if (userId != null && referrerId != null) {
          referralMap[userId] = referrerId;
        }
      }

      // Check for circular chains
      for (final entry in referralMap.entries) {
        final chain = <String>[entry.key];
        var current = entry.value;

        while (referralMap.containsKey(current) && chain.length < 10) {
          if (chain.contains(current)) {
            // Circular chain detected
            patterns.add({
              'pattern_name': 'Referral Fraud (Circular Chain)',
              'pattern_description':
                  'Circular referral chain detected: ${chain.join(" → ")} → $current',
              'confidence_score': 0.95,
              'evidence': referralLogs.map((l) => l['log_id']).toList(),
              'affected_users': chain,
              'severity': 'high',
              'recommended_actions': [
                'Revoke referral bonuses',
                'Flag accounts for review',
                'Investigate referral network',
              ],
            });
            break;
          }
          chain.add(current);
          current = referralMap[current]!;
        }
      }
    }

    return patterns;
  }

  /// Detect vote manipulation patterns
  Future<List<Map<String, dynamic>>> detectVoteManipulation(
    List<Map<String, dynamic>> logs,
  ) async {
    final patterns = <Map<String, dynamic>>[];

    final voteLogs = logs
        .where((l) => l['action']?.toString().contains('vote') ?? false)
        .toList();

    if (voteLogs.isEmpty) return patterns;

    // Group by election/resource
    final electionVotes = <String, List<Map<String, dynamic>>>{};
    for (final log in voteLogs) {
      final resource = log['resource'] as String? ?? 'unknown';
      electionVotes.putIfAbsent(resource, () => []).add(log);
    }

    for (final entry in electionVotes.entries) {
      final electionId = entry.key;
      final votes = entry.value;

      // 1. Detect coordinated voting (same timestamp)
      final timestampGroups = <String, List<Map<String, dynamic>>>{};
      for (final vote in votes) {
        final timestamp = vote['timestamp'] as String;
        timestampGroups.putIfAbsent(timestamp, () => []).add(vote);
      }

      for (final group in timestampGroups.values) {
        if (group.length >= 5) {
          patterns.add({
            'pattern_name': 'Vote Manipulation (Coordinated)',
            'pattern_description':
                '${group.length} votes cast at exact same timestamp for $electionId',
            'confidence_score': 0.85,
            'evidence': group.map((v) => v['log_id']).toList(),
            'affected_users': group.map((v) => v['user_id']).toSet().toList(),
            'severity': 'high',
            'recommended_actions': [
              'Investigate voting pattern',
              'Check for bot activity',
              'Review election integrity',
            ],
          });
        }
      }

      // 2. Detect bot-like behavior (consistent timing intervals)
      if (votes.length >= 10) {
        final timestamps =
            votes.map((v) => DateTime.parse(v['timestamp'])).toList()..sort();

        final intervals = <int>[];
        for (var i = 1; i < timestamps.length; i++) {
          intervals.add(timestamps[i].difference(timestamps[i - 1]).inSeconds);
        }

        // Check for consistent intervals (bot signature)
        final avgInterval =
            intervals.reduce((a, b) => a + b) / intervals.length;
        final variance =
            intervals
                .map((i) => (i - avgInterval).abs())
                .reduce((a, b) => a + b) /
            intervals.length;

        if (variance < 2.0) {
          patterns.add({
            'pattern_name': 'Vote Manipulation (Bot Activity)',
            'pattern_description':
                'Bot-like voting pattern detected: consistent ${avgInterval.toStringAsFixed(1)}s intervals',
            'confidence_score': 0.9,
            'evidence': votes.map((v) => v['log_id']).toList(),
            'affected_users': votes.map((v) => v['user_id']).toSet().toList(),
            'severity': 'critical',
            'recommended_actions': [
              'Block suspicious accounts',
              'Invalidate fraudulent votes',
              'Implement CAPTCHA',
              'Enable rate limiting',
            ],
          });
        }
      }
    }

    return patterns;
  }

  /// Run all fraud pattern detection
  Future<List<Map<String, dynamic>>> detectAllPatterns(
    List<Map<String, dynamic>> logs,
  ) async {
    final allPatterns = <Map<String, dynamic>>[];

    allPatterns.addAll(await detectMultiAccountAbuse(logs));
    allPatterns.addAll(await detectAccountTakeover(logs));
    allPatterns.addAll(await detectPaymentFraud(logs));
    allPatterns.addAll(await detectCredentialStuffing(logs));
    allPatterns.addAll(await detectReferralFraud(logs));
    allPatterns.addAll(await detectVoteManipulation(logs));

    return allPatterns;
  }
}
