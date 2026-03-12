class VotteryAdCandidate {
  final String adId;
  final int bidCents;
  final double qualityScore;
  final Map<String, dynamic> raw;

  VotteryAdCandidate({
    required this.adId,
    required this.bidCents,
    required this.qualityScore,
    required this.raw,
  });
}

class VotteryAuctionResult {
  final VotteryAdCandidate winner;
  final VotteryAdCandidate? runnerUp;
  final int clearingPriceCents;
  final double winnerTvs;
  final double? runnerUpTvs;

  VotteryAuctionResult({
    required this.winner,
    required this.runnerUp,
    required this.clearingPriceCents,
    required this.winnerTvs,
    required this.runnerUpTvs,
  });
}

class VotteryAuctionService {
  VotteryAuctionService._();

  static double _normalizeQuality(double qs) {
    if (qs.isNaN || qs.isInfinite) return 100;
    if (qs < 0) return 0;
    if (qs > 200) return 200;
    return qs;
  }

  static double _estimateActionRate(double qualityScore) {
    // Placeholder for ML pCTR/pConversion.
    // quality 0..200 => 0.02..0.25
    final q = _normalizeQuality(qualityScore);
    return 0.02 + (q / 200.0) * 0.23;
  }

  static double _totalValueScore({
    required int bidCents,
    required double qualityScore,
  }) {
    final bid = bidCents < 0 ? 0 : bidCents;
    final p = _estimateActionRate(qualityScore);
    final qFactor = _normalizeQuality(qualityScore) / 100.0;
    return bid * p * qFactor;
  }

  static VotteryAuctionResult? runSecondPriceAuction(
    List<VotteryAdCandidate> candidates,
  ) {
    if (candidates.isEmpty) return null;

    final scored = candidates
        .map((c) => (
              c,
              _totalValueScore(
                bidCents: c.bidCents,
                qualityScore: c.qualityScore,
              )
            ))
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    final winner = scored.first.$1;
    final winnerTvs = scored.first.$2;
    final runnerUp = scored.length > 1 ? scored[1].$1 : null;
    final runnerUpTvs = scored.length > 1 ? scored[1].$2 : null;

    int clearing = 1;
    if (runnerUpTvs != null) {
      final p = _estimateActionRate(winner.qualityScore);
      final qFactor = _normalizeQuality(winner.qualityScore) / 100.0;
      final denom = p * qFactor;
      final neededBid = denom > 0 ? (runnerUpTvs / denom).ceil() : winner.bidCents;
      clearing = (neededBid + 1);
      if (clearing < 1) clearing = 1;
      if (clearing > winner.bidCents) clearing = winner.bidCents;
    } else {
      clearing = winner.bidCents > 0 ? 1 : 0;
    }

    return VotteryAuctionResult(
      winner: winner,
      runnerUp: runnerUp,
      clearingPriceCents: clearing,
      winnerTvs: winnerTvs,
      runnerUpTvs: runnerUpTvs,
    );
  }
}

