// Static local mapping of product type → label highlight position.
// Eliminates the need for a ChatGPT API call to determine
// where the nameplate/label sticker is on a given appliance.
// Positions are fractional offsets (0.0–1.0) on the wireframe image.
//
/// Positions are fractional offsets (0.0–1.0) on the wireframe image.
/// The `angle` describes the viewing angle used in the DALL-E prompt.
library;

class LabelPositionInfo {
  /// Fractional X position on image (0.0 = left, 1.0 = right)
  final double x;

  /// Fractional Y position on image (0.0 = top, 1.0 = bottom)
  final double y;

  /// Short description for the DALL-E prompt (e.g. "inside the door frame")
  final String promptHint;

  /// Viewing angle for DALL-E (e.g. "front view, door open")
  final String viewAngle;

  const LabelPositionInfo({
    required this.x,
    required this.y,
    required this.promptHint,
    this.viewAngle = 'front view',
  });
}

/// Returns the label highlight position for a given asset type.
///
/// Looks up by `assetType` first (e.g. "Refrigerator"), with optional
/// brand-specific overrides. Falls back to a centered default.
LabelPositionInfo getLabelPosition({
  required String assetType,
  String? brand,
  String? subCategory,
}) {
  // Brand-specific overrides (optional fine-tuning)
  final brandKey = '${assetType.toLowerCase()}|${(brand ?? '').toLowerCase()}';
  if (_brandOverrides.containsKey(brandKey)) {
    return _brandOverrides[brandKey]!;
  }

  // Primary lookup by asset type
  final typeKey = assetType.toLowerCase();
  if (_assetTypePositions.containsKey(typeKey)) {
    return _assetTypePositions[typeKey]!;
  }

  // Fallback — center of image
  return const LabelPositionInfo(
    x: 0.50,
    y: 0.50,
    promptHint: 'on the back panel or inside the door',
    viewAngle: 'front view',
  );
}

/// ── Primary mapping: asset type → label position ──────────────────────
const Map<String, LabelPositionInfo> _assetTypePositions = {
  // ─── APPLIANCES ───
  'refrigerator': LabelPositionInfo(
    x: 0.28,
    y: 0.30,
    promptHint: 'inside the refrigerator door frame, upper left wall',
    viewAngle: 'front view with door open',
  ),
  'washer': LabelPositionInfo(
    x: 0.22,
    y: 0.25,
    promptHint: 'inside the washer lid or door frame rim',
    viewAngle: 'front view with door open',
  ),
  'dryer': LabelPositionInfo(
    x: 0.22,
    y: 0.25,
    promptHint: 'inside the dryer door frame rim',
    viewAngle: 'front view with door open',
  ),
  'dishwasher': LabelPositionInfo(
    x: 0.25,
    y: 0.18,
    promptHint: 'inside the dishwasher door, top left edge',
    viewAngle: 'front view with door open',
  ),
  'range/stove': LabelPositionInfo(
    x: 0.50,
    y: 0.50,
    promptHint: 'behind the oven door or on the frame edge',
    viewAngle: 'front view with oven door open',
  ),
  'microwave': LabelPositionInfo(
    x: 0.50,
    y: 0.85,
    promptHint: 'on the back panel or inside the door frame',
    viewAngle: 'front view with door open',
  ),

  // ─── HOME SYSTEMS ───
  'hvac system': LabelPositionInfo(
    x: 0.50,
    y: 0.45,
    promptHint: 'on the side panel or access panel of the unit',
    viewAngle: 'front view',
  ),
  'water heater': LabelPositionInfo(
    x: 0.50,
    y: 0.35,
    promptHint: 'on the front or side of the tank, near the top third',
    viewAngle: 'front view',
  ),
  'garbage disposal': LabelPositionInfo(
    x: 0.50,
    y: 0.50,
    promptHint: 'on the bottom of the disposal unit',
    viewAngle: 'side view under the sink',
  ),
  'sump pump': LabelPositionInfo(
    x: 0.50,
    y: 0.40,
    promptHint: 'on the side of the motor housing',
    viewAngle: 'side view',
  ),

  // ─── ELECTRONICS ───
  'television': LabelPositionInfo(
    x: 0.50,
    y: 0.55,
    promptHint: 'on the back panel of the TV',
    viewAngle: 'rear view',
  ),
  'computer': LabelPositionInfo(
    x: 0.50,
    y: 0.50,
    promptHint: 'on the bottom or back panel',
    viewAngle: 'rear view',
  ),
  'gaming console': LabelPositionInfo(
    x: 0.50,
    y: 0.85,
    promptHint: 'on the bottom of the console',
    viewAngle: 'rear view tilted slightly',
  ),
  'smart speaker': LabelPositionInfo(
    x: 0.50,
    y: 0.90,
    promptHint: 'on the bottom of the speaker',
    viewAngle: 'bottom view tilted',
  ),
};

/// ── Brand-specific overrides (key = "assettype|brand") ────────────────
const Map<String, LabelPositionInfo> _brandOverrides = {
  // Samsung French-door fridges: label inside right door wall
  'refrigerator|samsung': LabelPositionInfo(
    x: 0.72,
    y: 0.25,
    promptHint: 'inside the right wall of the fresh food compartment',
    viewAngle: 'front view with door open',
  ),
  // LG washers: label inside the door rim (front loader)
  'washer|lg': LabelPositionInfo(
    x: 0.50,
    y: 0.40,
    promptHint: 'inside the washer door rim at the top',
    viewAngle: 'front view with door open',
  ),
  // GE/Whirlpool fridges: inside left wall
  'refrigerator|ge': LabelPositionInfo(
    x: 0.22,
    y: 0.28,
    promptHint: 'inside the left wall of the refrigerator near the top',
    viewAngle: 'front view with door open',
  ),
  'refrigerator|whirlpool': LabelPositionInfo(
    x: 0.22,
    y: 0.28,
    promptHint: 'inside the left wall of the refrigerator near the top',
    viewAngle: 'front view with door open',
  ),
};
