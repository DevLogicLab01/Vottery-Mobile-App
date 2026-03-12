import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Carousel Widget Pool Service
/// Object pool pattern for reusing carousel widget instances
/// Reduces GC pressure and improves frame rates
class CarouselWidgetPoolService {
  static CarouselWidgetPoolService? _instance;
  static CarouselWidgetPoolService get instance =>
      _instance ??= CarouselWidgetPoolService._();

  CarouselWidgetPoolService._();

  static const int _maxPoolSize = 50;

  // Pools per carousel type
  final Queue<CarouselItemData> _horizontalSnapPool = Queue();
  final Queue<CarouselItemData> _verticalCardPool = Queue();
  final Queue<CarouselItemData> _gradientFlowPool = Queue();

  // Active instances tracking
  final Map<String, CarouselItemData> _activeInstances = {};

  // Memory leak tracking
  int _totalAcquired = 0;
  int _totalReleased = 0;

  /// Pre-warm pools with initial instances
  void initialize() {
    for (int i = 0; i < 10; i++) {
      _horizontalSnapPool.add(
        CarouselItemData(type: CarouselType.horizontalSnap),
      );
      _verticalCardPool.add(CarouselItemData(type: CarouselType.verticalCard));
      _gradientFlowPool.add(CarouselItemData(type: CarouselType.gradientFlow));
    }
    debugPrint(
      '✅ CarouselWidgetPool initialized with 30 pre-created instances',
    );
  }

  /// Acquire a carousel item from pool
  CarouselItemData acquire(CarouselType type, String itemId) {
    final pool = _getPool(type);
    CarouselItemData item;

    if (pool.isNotEmpty) {
      item = pool.removeFirst();
      item.reset(itemId);
    } else {
      // Create new if pool exhausted
      item = CarouselItemData(type: type, itemId: itemId);
    }

    _activeInstances[itemId] = item;
    _totalAcquired++;
    return item;
  }

  /// Release a carousel item back to pool
  void release(String itemId) {
    final item = _activeInstances.remove(itemId);
    if (item == null) return;

    final pool = _getPool(item.type);
    if (pool.length < _maxPoolSize) {
      item.clear();
      pool.add(item);
    }
    // If pool is full, item is GC'd
    _totalReleased++;
  }

  /// Release all items for a carousel type
  void releaseAll(CarouselType type) {
    final toRelease = _activeInstances.entries
        .where((e) => e.value.type == type)
        .map((e) => e.key)
        .toList();
    for (final id in toRelease) {
      release(id);
    }
  }

  Queue<CarouselItemData> _getPool(CarouselType type) {
    switch (type) {
      case CarouselType.horizontalSnap:
        return _horizontalSnapPool;
      case CarouselType.verticalCard:
        return _verticalCardPool;
      case CarouselType.gradientFlow:
        return _gradientFlowPool;
    }
  }

  /// Get pool statistics
  Map<String, dynamic> getStats() {
    return {
      'horizontal_snap_pool_size': _horizontalSnapPool.length,
      'vertical_card_pool_size': _verticalCardPool.length,
      'gradient_flow_pool_size': _gradientFlowPool.length,
      'active_instances': _activeInstances.length,
      'total_acquired': _totalAcquired,
      'total_released': _totalReleased,
      'potential_leaks':
          _totalAcquired - _totalReleased - _activeInstances.length,
    };
  }

  /// Detect potential memory leaks
  bool hasMemoryLeaks() {
    final leaks = _totalAcquired - _totalReleased - _activeInstances.length;
    return leaks > 10;
  }

  void dispose() {
    _horizontalSnapPool.clear();
    _verticalCardPool.clear();
    _gradientFlowPool.clear();
    _activeInstances.clear();
  }
}

enum CarouselType { horizontalSnap, verticalCard, gradientFlow }

class CarouselItemData {
  final CarouselType type;
  String itemId;
  Map<String, dynamic> data;
  bool isActive;

  CarouselItemData({
    required this.type,
    this.itemId = '',
    this.data = const {},
    this.isActive = false,
  });

  void reset(String newId) {
    itemId = newId;
    isActive = true;
    data = {};
  }

  void clear() {
    itemId = '';
    isActive = false;
    data = {};
  }
}
