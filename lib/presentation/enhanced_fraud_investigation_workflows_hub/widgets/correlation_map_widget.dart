import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class CorrelationMapWidget extends StatefulWidget {
  final List<Map<String, dynamic>> entities;
  final List<Map<String, dynamic>> correlations;

  const CorrelationMapWidget({
    super.key,
    required this.entities,
    required this.correlations,
  });

  @override
  State<CorrelationMapWidget> createState() => _CorrelationMapWidgetState();
}

class _CorrelationMapWidgetState extends State<CorrelationMapWidget> {
  final Graph graph = Graph();
  late BuchheimWalkerConfiguration builder;
  TransformationController? _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _buildGraph();

    builder = BuchheimWalkerConfiguration()
      ..siblingSeparation = 50
      ..levelSeparation = 50
      ..subtreeSeparation = 50
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
  }

  @override
  void dispose() {
    _transformationController?.dispose();
    super.dispose();
  }

  void _buildGraph() {
    graph.nodes.clear();
    graph.edges.clear();

    // Create nodes for entities
    final nodeMap = <String, Node>{};
    for (final entity in widget.entities) {
      final nodeId = entity['entity_id'] as String;
      final node = Node.Id(nodeId);
      graph.addNode(node);
      nodeMap[nodeId] = node;
    }

    // Create edges for correlations
    for (final correlation in widget.correlations) {
      final sourceId = correlation['source_entity_id'] as String?;
      final targetId = correlation['target_entity_id'] as String?;

      if (sourceId != null &&
          targetId != null &&
          nodeMap.containsKey(sourceId) &&
          nodeMap.containsKey(targetId)) {
        graph.addEdge(nodeMap[sourceId]!, nodeMap[targetId]!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entities.isEmpty) {
      return Center(
        child: Text(
          'No correlation data available',
          style: TextStyle(fontSize: 14.sp, color: AppTheme.textSecondaryLight),
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(2.w),
          color: AppTheme.surfaceLight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Correlation Map (${widget.entities.length} entities)',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, size: 5.w),
                onPressed: () => setState(() {
                  _transformationController?.value = Matrix4.identity();
                }),
              ),
            ],
          ),
        ),

        // Graph visualization
        Expanded(
          child: InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: EdgeInsets.all(20.w),
            minScale: 0.5,
            maxScale: 3.0,
            child: GraphView(
              graph: graph,
              algorithm: BuchheimWalkerAlgorithm(
                builder,
                TreeEdgeRenderer(builder),
              ),
              paint: Paint()
                ..color = AppTheme.primaryLight
                ..strokeWidth = 2
                ..style = PaintingStyle.stroke,
              builder: (Node node) {
                final entityId = node.key?.value as String;
                final entity = widget.entities.firstWhere(
                  (e) => e['entity_id'] == entityId,
                  orElse: () => {
                    'entity_type': 'unknown',
                    'entity_value': entityId,
                  },
                );

                return _buildEntityNode(entity);
              },
            ),
          ),
        ),

        // Legend
        Container(
          padding: EdgeInsets.all(2.w),
          color: AppTheme.surfaceLight,
          child: Wrap(
            spacing: 4.w,
            children: [
              _buildLegendItem('User', Colors.blue),
              _buildLegendItem('IP', Colors.orange),
              _buildLegendItem('Device', Colors.green),
              _buildLegendItem('Account', Colors.purple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEntityNode(Map<String, dynamic> entity) {
    final entityType = entity['entity_type'] as String? ?? 'unknown';
    final entityValue = entity['entity_value'] as String? ?? 'N/A';
    final involvementScore = entity['involvement_score'] as num? ?? 0;

    Color color;
    IconData icon;

    switch (entityType.toLowerCase()) {
      case 'user':
        color = Colors.blue;
        icon = Icons.person;
        break;
      case 'ip':
      case 'ip_address':
        color = Colors.orange;
        icon = Icons.location_on;
        break;
      case 'device':
        color = Colors.green;
        icon = Icons.phone_android;
        break;
      case 'account':
        color = Colors.purple;
        icon = Icons.account_circle;
        break;
      default:
        color = AppTheme.textSecondaryLight;
        icon = Icons.help_outline;
    }

    final size = 40.0 + (involvementScore * 20);

    return GestureDetector(
      onTap: () => _showEntityDetails(entity),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withAlpha(51),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: size * 0.4, color: color),
            if (size > 50)
              Text(
                entityValue.length > 8
                    ? '${entityValue.substring(0, 8)}...'
                    : entityValue,
                style: TextStyle(fontSize: 8.sp, color: color),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(
            color: color.withAlpha(51),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }

  void _showEntityDetails(Map<String, dynamic> entity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Entity Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${entity['entity_type']}'),
            SizedBox(height: 1.h),
            Text('Value: ${entity['entity_value']}'),
            SizedBox(height: 1.h),
            Text('Involvement Score: ${entity['involvement_score']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
