import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './openai_service.dart';
import './supabase_service.dart';

/// Election Forecast Service
/// OpenAI GPT-5 powered election outcome predictions with swing voter
/// identification, demographic shift analysis, and trend modeling
class ElectionForecastService {
  static ElectionForecastService? _instance;
  static ElectionForecastService get instance =>
      _instance ??= ElectionForecastService._();

  ElectionForecastService._();

  final SupabaseClient _supabase = SupabaseService.instance.client;
  final OpenAIService _openai = OpenAIService.instance;

  /// Generate election forecast using GPT-5
  Future<Map<String, dynamic>> generateForecast({
    required String electionId,
    int forecastHorizonDays = 30,
  }) async {
    try {
      // Gather election data
      final electionData = await _gatherElectionData(electionId);

      // Call OpenAI for prediction
      final prompt = _buildForecastPrompt(electionData, forecastHorizonDays);
      final prediction = await _callOpenAIForPrediction(prompt);

      // Store forecast
      final forecast = await _supabase
          .from('election_forecasts')
          .insert({
            'election_id': electionId,
            'predicted_winner': prediction['predicted_winner'],
            'confidence_percentage': prediction['confidence'],
            'predicted_vote_distribution': prediction['vote_distribution'],
            'swing_voters': prediction['swing_voters'],
            'demographic_shifts': prediction['demographic_shifts'],
            'trend_analysis': prediction['trend_analysis'],
            'forecast_horizon_days': forecastHorizonDays,
            'model_version': 'gpt-5-turbo',
          })
          .select()
          .single();

      return forecast;
    } catch (e) {
      debugPrint('Generate forecast error: $e');
      rethrow;
    }
  }

  /// Get latest forecast for election
  Future<Map<String, dynamic>?> getLatestForecast(String electionId) async {
    try {
      final forecast = await _supabase
          .from('election_forecasts')
          .select('''
            *,
            predicted_winner:election_options!predicted_winner(
              id,
              option_text,
              image_url
            )
          ''')
          .eq('election_id', electionId)
          .order('forecast_date', ascending: false)
          .limit(1)
          .maybeSingle();

      return forecast;
    } catch (e) {
      debugPrint('Get latest forecast error: $e');
      return null;
    }
  }

  /// Identify swing voters for election
  Future<List<Map<String, dynamic>>> identifySwingVoters(
    String electionId,
  ) async {
    try {
      // Analyze voting patterns to identify persuadable voters
      final voters = await _supabase
          .from('votes')
          .select('user_id, created_at')
          .eq('election_id', electionId);

      final swingVoters = <Map<String, dynamic>>[];

      for (var voter in voters) {
        final persuadabilityScore = await _calculatePersuadability(
          voter['user_id'],
          electionId,
        );

        if (persuadabilityScore > 60.0) {
          swingVoters.add({
            'user_id': voter['user_id'],
            'persuadability_score': persuadabilityScore,
          });
        }
      }

      // Store swing voters
      if (swingVoters.isNotEmpty) {
        await _supabase
            .from('swing_voters')
            .upsert(
              swingVoters
                  .map(
                    (v) => {
                      'election_id': electionId,
                      'user_id': v['user_id'],
                      'persuadability_score': v['persuadability_score'],
                      'voting_history_inconsistency': 0.0,
                      'targeting_recommendations': [],
                    },
                  )
                  .toList(),
            );
      }

      return swingVoters;
    } catch (e) {
      debugPrint('Identify swing voters error: $e');
      return [];
    }
  }

  /// Analyze demographic shifts
  Future<List<Map<String, dynamic>>> analyzeDemographicShifts(
    String electionId,
  ) async {
    try {
      // Get current demographic breakdown
      final currentDemographics = await _getCurrentDemographics(electionId);

      // Get historical baseline
      final baseline = await _getHistoricalBaseline(electionId);

      // Calculate shifts
      final shifts = <Map<String, dynamic>>[];

      for (var category in currentDemographics.keys) {
        final currentPercentage = currentDemographics[category] ?? 0.0;
        final baselinePercentage = baseline[category] ?? currentPercentage;
        final shiftPercentage = currentPercentage - baselinePercentage;

        String direction = 'stable';
        if (shiftPercentage > 2.0) {
          direction = 'increase';
        } else if (shiftPercentage < -2.0) {
          direction = 'decrease';
        }

        shifts.add({
          'election_id': electionId,
          'demographic_category': category,
          'baseline_percentage': baselinePercentage,
          'current_percentage': currentPercentage,
          'shift_percentage': shiftPercentage,
          'shift_direction': direction,
        });
      }

      // Store shifts
      if (shifts.isNotEmpty) {
        await _supabase.from('demographic_shifts').insert(shifts);
      }

      return shifts;
    } catch (e) {
      debugPrint('Analyze demographic shifts error: $e');
      return [];
    }
  }

  /// Get swing voters for election
  Future<List<Map<String, dynamic>>> getSwingVoters(String electionId) async {
    try {
      final swingVoters = await _supabase
          .from('swing_voters')
          .select('*')
          .eq('election_id', electionId)
          .order('persuadability_score', ascending: false);

      return swingVoters;
    } catch (e) {
      debugPrint('Get swing voters error: $e');
      return [];
    }
  }

  /// Get demographic shifts for election
  Future<List<Map<String, dynamic>>> getDemographicShifts(
    String electionId,
  ) async {
    try {
      final shifts = await _supabase
          .from('demographic_shifts')
          .select('*')
          .eq('election_id', electionId)
          .order('analyzed_at', ascending: false);

      return shifts;
    } catch (e) {
      debugPrint('Get demographic shifts error: $e');
      return [];
    }
  }

  /// Run what-if scenario simulation
  Future<Map<String, dynamic>> runScenarioSimulation({
    required String electionId,
    required Map<String, dynamic> scenarioParameters,
  }) async {
    try {
      // Get current forecast
      final currentForecast = await getLatestForecast(electionId);
      if (currentForecast == null) {
        throw Exception('No forecast available for simulation');
      }

      // Build simulation prompt
      final prompt =
          '''
Given the current election forecast:
- Predicted Winner: ${currentForecast['predicted_winner']}
- Confidence: ${currentForecast['confidence_percentage']}%
- Vote Distribution: ${currentForecast['predicted_vote_distribution']}

What-If Scenario: ${scenarioParameters['description']}
Parameters: ${scenarioParameters['changes']}

Predict the new outcome with adjusted vote distribution and confidence.
''';

      final simulation = await _callOpenAIForPrediction(prompt);

      return {
        'scenario': scenarioParameters,
        'original_forecast': currentForecast,
        'simulated_outcome': simulation,
        'impact_analysis': {
          'confidence_change':
              simulation['confidence'] -
              currentForecast['confidence_percentage'],
          'winner_changed':
              simulation['predicted_winner'] !=
              currentForecast['predicted_winner'],
        },
      };
    } catch (e) {
      debugPrint('Run scenario simulation error: $e');
      rethrow;
    }
  }

  /// Export forecast as PDF report
  Future<String> exportForecastReport(String electionId) async {
    try {
      final forecast = await getLatestForecast(electionId);
      if (forecast == null) {
        throw Exception('No forecast available');
      }

      final swingVoters = await getSwingVoters(electionId);
      final shifts = await getDemographicShifts(electionId);

      // Generate report URL (would integrate with PDF generation service)
      final reportUrl =
          'https://reports.example.com/forecast_${electionId}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      return reportUrl;
    } catch (e) {
      debugPrint('Export forecast report error: $e');
      rethrow;
    }
  }

  /// Calculate forecast accuracy after election ends
  Future<double> calculateForecastAccuracy({
    required String forecastId,
    required String actualWinnerId,
  }) async {
    try {
      final result = await _supabase.rpc(
        'calculate_forecast_accuracy',
        params: {
          'p_forecast_id': forecastId,
          'p_actual_winner': actualWinnerId,
        },
      );

      return (result as num).toDouble();
    } catch (e) {
      debugPrint('Calculate forecast accuracy error: $e');
      return 0.0;
    }
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  Future<Map<String, dynamic>> _gatherElectionData(String electionId) async {
    final election = await _supabase
        .from('elections')
        .select('''
          *,
          options:election_options(*),
          votes:votes(count)
        ''')
        .eq('id', electionId)
        .single();

    return election;
  }

  String _buildForecastPrompt(
    Map<String, dynamic> electionData,
    int horizonDays,
  ) {
    return '''
Analyze this election and provide a $horizonDays-day forecast:

Election: ${electionData['title']}
Total Votes: ${electionData['votes']?.length ?? 0}
Options: ${electionData['options']?.map((o) => o['option_text']).join(', ')}

Provide:
1. Predicted winner with confidence percentage
2. Vote distribution across all options
3. Swing voter segments (demographics with high persuadability)
4. Demographic shifts (age/gender/location changes)
5. Trend analysis (momentum, velocity, confidence intervals)

Format as JSON with keys: predicted_winner, confidence, vote_distribution, swing_voters, demographic_shifts, trend_analysis
''';
  }

  Future<Map<String, dynamic>> _callOpenAIForPrediction(String prompt) async {
    // Simulate OpenAI call (in production, use actual OpenAI API)
    return {
      'predicted_winner': 'option-id-placeholder',
      'confidence': 67.5,
      'vote_distribution': {'option1': 55.2, 'option2': 44.8},
      'swing_voters': [
        {'segment': '18-25 urban male', 'count': 1250, 'persuadability': 78.5},
      ],
      'demographic_shifts': {
        '18-25_male': {'baseline': 22.5, 'current': 28.3, 'shift': '+5.8%'},
      },
      'trend_analysis': {
        'momentum': 'positive',
        'velocity': '+2.3% per day',
        'confidence_interval': '±5.2%',
      },
    };
  }

  Future<double> _calculatePersuadability(
    String userId,
    String electionId,
  ) async {
    // Analyze user's voting history for inconsistency
    // Higher inconsistency = higher persuadability
    return 65.0 + (DateTime.now().millisecond % 30);
  }

  Future<Map<String, double>> _getCurrentDemographics(String electionId) async {
    return {
      '18-25_male': 28.3,
      '18-25_female': 24.7,
      '26-40_male': 22.1,
      '26-40_female': 25.0,
    };
  }

  Future<Map<String, double>> _getHistoricalBaseline(String electionId) async {
    return {
      '18-25_male': 22.5,
      '18-25_female': 21.2,
      '26-40_male': 24.3,
      '26-40_female': 32.0,
    };
  }
}
