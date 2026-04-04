import 'dart:typed_data';

/// Position hint for where the label is on the product wireframe
enum LabelPosition {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
  insideTopLeft,
  insideTopRight,
  insideLeft,
  insideRight,
  backPanel,
}

/// A single label location on the product
class LabelIndicator {
  final int number;
  final LabelPosition position;
  final String shortLabel;
  final String fullDescription;

  const LabelIndicator({
    required this.number,
    required this.position,
    required this.shortLabel,
    required this.fullDescription,
  });

  /// Convert position enum to fractional alignment on image
  ({double x, double y}) get fractionalOffset {
    switch (position) {
      case LabelPosition.topLeft:
        return (x: 0.18, y: 0.15);
      case LabelPosition.topCenter:
        return (x: 0.50, y: 0.12);
      case LabelPosition.topRight:
        return (x: 0.82, y: 0.15);
      case LabelPosition.centerLeft:
        return (x: 0.15, y: 0.48);
      case LabelPosition.center:
        return (x: 0.50, y: 0.48);
      case LabelPosition.centerRight:
        return (x: 0.85, y: 0.48);
      case LabelPosition.bottomLeft:
        return (x: 0.18, y: 0.82);
      case LabelPosition.bottomCenter:
        return (x: 0.50, y: 0.85);
      case LabelPosition.bottomRight:
        return (x: 0.82, y: 0.82);
      case LabelPosition.insideTopLeft:
        return (x: 0.28, y: 0.25);
      case LabelPosition.insideTopRight:
        return (x: 0.72, y: 0.25);
      case LabelPosition.insideLeft:
        return (x: 0.22, y: 0.45);
      case LabelPosition.insideRight:
        return (x: 0.78, y: 0.45);
      case LabelPosition.backPanel:
        return (x: 0.50, y: 0.55);
    }
  }

  factory LabelIndicator.fromJson(Map<String, dynamic> json, int index) {
    return LabelIndicator(
      number: index + 1,
      position: _parsePosition(json['position'] as String? ?? 'center'),
      shortLabel: json['short_label'] as String? ?? 'Label',
      fullDescription: json['description'] as String? ?? '',
    );
  }

  static LabelPosition _parsePosition(String pos) {
    final normalized = pos.replaceAll('-', '').replaceAll('_', '').toLowerCase();
    for (final value in LabelPosition.values) {
      if (value.name.toLowerCase() == normalized) return value;
    }
    // Fuzzy match
    if (normalized.contains('insideleft') || normalized.contains('interiorleft')) {
      return LabelPosition.insideLeft;
    }
    if (normalized.contains('insideright') || normalized.contains('interiorright')) {
      return LabelPosition.insideRight;
    }
    if (normalized.contains('insidetop')) return LabelPosition.insideTopLeft;
    if (normalized.contains('back')) return LabelPosition.backPanel;
    if (normalized.contains('topleft')) return LabelPosition.topLeft;
    if (normalized.contains('topright')) return LabelPosition.topRight;
    if (normalized.contains('top')) return LabelPosition.topCenter;
    if (normalized.contains('bottomleft')) return LabelPosition.bottomLeft;
    if (normalized.contains('bottomright')) return LabelPosition.bottomRight;
    if (normalized.contains('bottom')) return LabelPosition.bottomCenter;
    if (normalized.contains('left')) return LabelPosition.centerLeft;
    if (normalized.contains('right')) return LabelPosition.centerRight;
    return LabelPosition.center;
  }
}

/// Complete label location data for a product
class ProductLabelData {
  final Uint8List? wireframeImage;
  final List<LabelIndicator> indicators;
  final String viewDescription;

  const ProductLabelData({
    this.wireframeImage,
    this.indicators = const [],
    this.viewDescription = '',
  });
}
