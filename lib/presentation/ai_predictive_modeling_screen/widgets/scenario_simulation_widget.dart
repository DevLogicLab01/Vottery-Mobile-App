import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/election_forecast_service.dart';

/// Scenario Simulation Widget
/// What-if analysis with real-time recalculation
class ScenarioSimulationWidget extends StatefulWidget {
  final String electionId;
  final Map<String, dynamic>? currentForecast;

  const ScenarioSimulationWidget({
    super.key,
    required this.electionId,
    this.currentForecast,
  });

  @override
  State<ScenarioSimulationWidget> createState() =>
      _ScenarioSimulationWidgetState();
}

class _ScenarioSimulationWidgetState extends State<ScenarioSimulationWidget> {
  final ElectionForecastService _forecastService =
      ElectionForecastService.instance;
  final TextEditingController _scenarioController = TextEditingController();

  bool _isSimulating = false;
  Map<String, dynamic>? _simulationResult;

  @override
  void dispose() {
    _scenarioController.dispose();
    super.dispose();
  }

  Future<void> _runSimulation() async {
    if (_scenarioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a scenario description'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSimulating = true);

    try {
      final result = await _forecastService.runScenarioSimulation(
        electionId: widget.electionId,
        scenarioParameters: {
          'description': _scenarioController.text,
          'changes': {},
        },
      );

      setState(() {
        _simulationResult = result;
        _isSimulating = false;
      });
    } catch (e) {
      setState(() => _isSimulating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Simulation error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What-If Scenario Simulation',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Analyze how changes affect election outcomes',
          style: TextStyle(
            fontSize: 13.sp,
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
        SizedBox(height: 2.h),
        TextField(
          controller: _scenarioController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Example: What if candidate A gets 10% more youth votes?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSimulating ? null : _runSimulation,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: _isSimulating
                ? SizedBox(
                    height: 2.h,
                    width: 2.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: Colors.white,
                    ),
                  )
                : Text('Run Simulation', style: TextStyle(fontSize: 14.sp)),
          ),
        ),
        if (_simulationResult != null) ...[
          SizedBox(height: 3.h),
          _buildSimulationResults(theme),
        ],
      ],
    );
  }

  Widget _buildSimulationResults(ThemeData theme) {
    final impact =
        _simulationResult!['impact_analysis'] as Map<String, dynamic>? ?? {};
    final confidenceChange = impact['confidence_change'] ?? 0.0;
    final winnerChanged = impact['winner_changed'] ?? false;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Simulation Results',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildResultRow(
            'Confidence Change',
            '${confidenceChange >= 0 ? '+' : ''}${confidenceChange.toStringAsFixed(1)}%',
            confidenceChange >= 0 ? Colors.green : Colors.red,
            theme,
          ),
          SizedBox(height: 1.h),
          _buildResultRow(
            'Winner Changed',
            winnerChanged ? 'Yes' : 'No',
            winnerChanged ? Colors.orange : Colors.green,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(
    String label,
    String value,
    Color color,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color: theme.colorScheme.onSurface.withAlpha(179),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
