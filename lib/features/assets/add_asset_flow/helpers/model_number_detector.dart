/// Detects the likely asset type from a model number prefix.
///
/// Major appliance manufacturers use well-known prefix conventions
/// in their model numbers. For example, Samsung model numbers starting
/// with "RF" are always refrigerators, "WF" are washers, "DV" are dryers, etc.
///
/// This helper covers Samsung, LG, GE, Whirlpool, Maytag, Frigidaire,
/// Bosch, KitchenAid, Electrolux, Amana, Kenmore, and other major brands.
class ModelNumberDetector {
  ModelNumberDetector._();

  /// Attempts to determine the asset type from a model number string.
  ///
  /// Returns the detected asset type (matching the names in
  /// Step 1 type selection) or `null` if no match is found.
  ///
  /// Example:
  /// ```dart
  /// ModelNumberDetector.detectAssetType('RF29A9071SR/AA'); // → 'Refrigerator'
  /// ModelNumberDetector.detectAssetType('WF45R6100AW');    // → 'Washer'
  /// ModelNumberDetector.detectAssetType('DVE45R6100W');    // → 'Dryer'
  /// ```
  static String? detectAssetType(String? modelNumber) {
    if (modelNumber == null || modelNumber.trim().isEmpty) return null;

    // Normalize: uppercase, remove spaces, remove common suffixes like /AA
    final model = modelNumber.trim().toUpperCase().replaceAll(
      RegExp(r'\s+'),
      '',
    );

    // Try each manufacturer's prefix patterns
    for (final entry in _prefixRules) {
      final prefix = entry.prefix;
      final isRegex = entry.isRegex;

      if (isRegex) {
        if (RegExp(prefix).hasMatch(model)) {
          return entry.assetType;
        }
      } else {
        if (model.startsWith(prefix)) {
          return entry.assetType;
        }
      }
    }

    return null;
  }

  /// Returns a human-readable explanation of why a model number was detected
  /// as a particular asset type (for UI display).
  static String? getDetectionReason(String? modelNumber) {
    if (modelNumber == null || modelNumber.trim().isEmpty) return null;

    final model = modelNumber.trim().toUpperCase().replaceAll(
      RegExp(r'\s+'),
      '',
    );

    for (final entry in _prefixRules) {
      final matches = entry.isRegex
          ? RegExp(entry.prefix).hasMatch(model)
          : model.startsWith(entry.prefix);

      if (matches) {
        return 'Model numbers starting with "${_getMatchedPrefix(model, entry)}" '
            'are typically ${entry.assetType}s (${entry.brand})';
      }
    }

    return null;
  }

  static String _getMatchedPrefix(String model, _PrefixRule entry) {
    if (entry.isRegex) {
      final match = RegExp(entry.prefix).firstMatch(model);
      return match?.group(0) ?? entry.prefix;
    }
    return entry.prefix;
  }
}

class _PrefixRule {
  final String prefix;
  final String assetType;
  final String brand;
  final bool isRegex;

  const _PrefixRule(
    this.prefix,
    this.assetType,
    this.brand, {
    this.isRegex = false,
  });
}

/// Comprehensive prefix rules for major appliance/electronics manufacturers.
///
/// Rules are ordered from most-specific to least-specific.
/// Longer/more specific prefixes should come first.
const List<_PrefixRule> _prefixRules = [
  // ═══════════════════════════════════════════════════════════════
  //  SAMSUNG
  // ═══════════════════════════════════════════════════════════════
  // Refrigerators
  _PrefixRule('RF', 'Refrigerator', 'Samsung'), // French Door
  _PrefixRule('RS', 'Refrigerator', 'Samsung'), // Side-by-Side
  _PrefixRule('RT', 'Refrigerator', 'Samsung'), // Top Freezer
  _PrefixRule('RB', 'Refrigerator', 'Samsung'), // Bottom Freezer
  _PrefixRule('RZ', 'Refrigerator', 'Samsung'), // Upright Freezer
  _PrefixRule('RH', 'Refrigerator', 'Samsung'), // French Door (Hub)
  // Washers
  _PrefixRule('WF', 'Washer', 'Samsung'), // Front Load Washer
  _PrefixRule('WA', 'Washer', 'Samsung'), // Top Load Washer
  _PrefixRule('WV', 'Washer', 'Samsung'), // FlexWash
  // Dryers
  _PrefixRule('DV', 'Dryer', 'Samsung'), // Electric/Gas Dryer
  _PrefixRule('DVE', 'Dryer', 'Samsung'), // Electric Dryer
  _PrefixRule('DVG', 'Dryer', 'Samsung'), // Gas Dryer
  // Dishwashers
  _PrefixRule('DW', 'Dishwasher', 'Samsung'),

  // Ranges / Stoves
  _PrefixRule('NX', 'Range / Stove', 'Samsung'), // Gas/Electric Range
  _PrefixRule('NE', 'Range / Stove', 'Samsung'), // Electric Range
  _PrefixRule('NY', 'Range / Stove', 'Samsung'), // Dual Fuel Range
  _PrefixRule('NA', 'Range / Stove', 'Samsung'), // Gas Cooktop
  _PrefixRule('NZ', 'Range / Stove', 'Samsung'), // Electric Cooktop
  // Microwaves
  _PrefixRule('ME', 'Microwave', 'Samsung'), // Over-the-Range
  _PrefixRule('MC', 'Microwave', 'Samsung'), // Countertop
  _PrefixRule('MS', 'Microwave', 'Samsung'), // Solo
  // TVs
  _PrefixRule('QN', 'Television', 'Samsung'), // QLED
  _PrefixRule('QE', 'Television', 'Samsung'), // QLED (EU)
  _PrefixRule('UN', 'Television', 'Samsung'), // LED/Crystal UHD
  _PrefixRule('UE', 'Television', 'Samsung'), // LED (EU)
  _PrefixRule('QA', 'Television', 'Samsung'), // QLED (Asia)
  // AC
  _PrefixRule('AR', 'Heating & Cooling', 'Samsung'), // Split AC
  _PrefixRule('AJ', 'Heating & Cooling', 'Samsung'), // Wind-Free AC
  _PrefixRule('AC', 'Heating & Cooling', 'Samsung'), // AC units
  // ═══════════════════════════════════════════════════════════════
  //  LG
  // ═══════════════════════════════════════════════════════════════
  // Refrigerators
  _PrefixRule('LRF', 'Refrigerator', 'LG'), // French Door
  _PrefixRule('LSR', 'Refrigerator', 'LG'), // Side-by-Side
  _PrefixRule('LTN', 'Refrigerator', 'LG'), // Top Freezer
  _PrefixRule('LRM', 'Refrigerator', 'LG'), // Bottom Freezer
  _PrefixRule('LFX', 'Refrigerator', 'LG'), // French Door (older)
  // Washers
  _PrefixRule('WM', 'Washer', 'LG'), // Front Load
  _PrefixRule('WT', 'Washer', 'LG'), // Top Load
  // Dryers
  _PrefixRule('DLE', 'Dryer', 'LG'), // Electric
  _PrefixRule('DLG', 'Dryer', 'LG'), // Gas
  _PrefixRule('DLX', 'Dryer', 'LG'), // Mega Capacity
  // Dishwashers
  _PrefixRule('LDP', 'Dishwasher', 'LG'),
  _PrefixRule('LDT', 'Dishwasher', 'LG'),
  _PrefixRule('LDF', 'Dishwasher', 'LG'),

  // Ranges
  _PrefixRule('LRG', 'Range / Stove', 'LG'), // Gas Range
  _PrefixRule('LRE', 'Range / Stove', 'LG'), // Electric Range
  _PrefixRule('LSG', 'Range / Stove', 'LG'), // Slide-in Gas
  _PrefixRule('LSE', 'Range / Stove', 'LG'), // Slide-in Electric
  // Microwaves
  _PrefixRule('LMV', 'Microwave', 'LG'), // Over-the-Range
  _PrefixRule('LMC', 'Microwave', 'LG'), // Countertop
  // TVs
  _PrefixRule('OLED', 'Television', 'LG'), // OLED TVs
  // AC
  _PrefixRule('LW', 'Heating & Cooling', 'LG'), // Window AC
  _PrefixRule('LP', 'Heating & Cooling', 'LG'), // Portable AC
  // ═══════════════════════════════════════════════════════════════
  //  GE / GE PROFILE / GE CAFE
  // ═══════════════════════════════════════════════════════════════
  // Refrigerators
  _PrefixRule('GFE', 'Refrigerator', 'GE'), // French Door
  _PrefixRule('GNE', 'Refrigerator', 'GE'), // French Door
  _PrefixRule('GSE', 'Refrigerator', 'GE'), // Side-by-Side
  _PrefixRule('GSS', 'Refrigerator', 'GE'), // Side-by-Side
  _PrefixRule('GTE', 'Refrigerator', 'GE'), // Top Freezer
  _PrefixRule('GTS', 'Refrigerator', 'GE'), // Top Freezer
  _PrefixRule('GBE', 'Refrigerator', 'GE'), // Bottom Freezer
  _PrefixRule('PFE', 'Refrigerator', 'GE'), // GE Profile French Door
  _PrefixRule('PYE', 'Refrigerator', 'GE'), // GE Profile
  _PrefixRule('PSB', 'Refrigerator', 'GE'), // GE Profile Side-by-Side
  _PrefixRule('CYE', 'Refrigerator', 'GE'), // Café French Door
  _PrefixRule('CWE', 'Refrigerator', 'GE'), // Café
  // Washers
  _PrefixRule('GTW', 'Washer', 'GE'), // Top Load
  _PrefixRule('GFW', 'Washer', 'GE'), // Front Load
  _PrefixRule('PTW', 'Washer', 'GE'), // GE Profile Top Load
  _PrefixRule('PFQ', 'Washer', 'GE'), // GE Profile Front Load
  // Dryers
  _PrefixRule('GTD', 'Dryer', 'GE'), // Electric/Gas
  _PrefixRule('GFD', 'Dryer', 'GE'), // Front Load
  _PrefixRule('PTD', 'Dryer', 'GE'), // GE Profile
  // Dishwashers
  _PrefixRule('GDT', 'Dishwasher', 'GE'),
  _PrefixRule('GDP', 'Dishwasher', 'GE'), // GE Profile
  _PrefixRule('GDF', 'Dishwasher', 'GE'),
  _PrefixRule('CDT', 'Dishwasher', 'GE'), // Café
  // Ranges
  _PrefixRule('JGB', 'Range / Stove', 'GE'), // Gas Range
  _PrefixRule('JGS', 'Range / Stove', 'GE'), // Gas Slide-in
  _PrefixRule('JB', 'Range / Stove', 'GE'), // Electric Range
  _PrefixRule('JS', 'Range / Stove', 'GE'), // Electric Slide-in
  _PrefixRule('PGB', 'Range / Stove', 'GE'), // GE Profile Gas
  _PrefixRule('PGS', 'Range / Stove', 'GE'), // GE Profile Gas Slide-in
  _PrefixRule('PB', 'Range / Stove', 'GE'), // GE Profile Electric
  // Microwaves
  _PrefixRule('JVM', 'Microwave', 'GE'), // Over-the-Range
  _PrefixRule('PVM', 'Microwave', 'GE'), // GE Profile Over-the-Range
  _PrefixRule('JES', 'Microwave', 'GE'), // Countertop
  _PrefixRule('CVM', 'Microwave', 'GE'), // Café
  // Water Heater
  _PrefixRule('GE40', 'Water Heater', 'GE'),
  _PrefixRule('GE50', 'Water Heater', 'GE'),

  // Garbage Disposal
  _PrefixRule('GFC', 'Garbage Disposal', 'GE'),

  // ═══════════════════════════════════════════════════════════════
  //  WHIRLPOOL
  // ═══════════════════════════════════════════════════════════════
  // Refrigerators
  _PrefixRule('WRF', 'Refrigerator', 'Whirlpool'), // French Door
  _PrefixRule('WRS', 'Refrigerator', 'Whirlpool'), // Side-by-Side
  _PrefixRule('WRT', 'Refrigerator', 'Whirlpool'), // Top Freezer
  _PrefixRule('WRB', 'Refrigerator', 'Whirlpool'), // Bottom Freezer
  _PrefixRule('WRX', 'Refrigerator', 'Whirlpool'), // 4-Door
  // Washers
  _PrefixRule('WTW', 'Washer', 'Whirlpool'), // Top Load
  _PrefixRule('WFW', 'Washer', 'Whirlpool'), // Front Load
  // Dryers
  _PrefixRule('WED', 'Dryer', 'Whirlpool'), // Electric
  _PrefixRule('WGD', 'Dryer', 'Whirlpool'), // Gas
  // Dishwashers
  _PrefixRule('WDT', 'Dishwasher', 'Whirlpool'),
  _PrefixRule('WDF', 'Dishwasher', 'Whirlpool'),

  // Ranges
  _PrefixRule('WFG', 'Range / Stove', 'Whirlpool'), // Gas
  _PrefixRule('WFE', 'Range / Stove', 'Whirlpool'), // Electric
  _PrefixRule('WEG', 'Range / Stove', 'Whirlpool'), // Slide-in Gas
  _PrefixRule('WEE', 'Range / Stove', 'Whirlpool'), // Slide-in Electric
  // Microwaves
  _PrefixRule('WMH', 'Microwave', 'Whirlpool'), // Over-the-Range
  // ═══════════════════════════════════════════════════════════════
  //  MAYTAG
  // ═══════════════════════════════════════════════════════════════
  // Refrigerators
  _PrefixRule('MFI', 'Refrigerator', 'Maytag'), // French Door
  _PrefixRule('MSS', 'Refrigerator', 'Maytag'), // Side-by-Side
  _PrefixRule('MRT', 'Refrigerator', 'Maytag'), // Top Freezer
  _PrefixRule('MBF', 'Refrigerator', 'Maytag'), // Bottom Freezer
  // Washers
  _PrefixRule('MVW', 'Washer', 'Maytag'), // Top Load
  _PrefixRule('MHW', 'Washer', 'Maytag'), // Front Load
  // Dryers
  _PrefixRule('MED', 'Dryer', 'Maytag'), // Electric
  _PrefixRule('MGD', 'Dryer', 'Maytag'), // Gas
  // Dishwashers
  _PrefixRule('MDB', 'Dishwasher', 'Maytag'),

  // Ranges
  _PrefixRule('MGR', 'Range / Stove', 'Maytag'), // Gas
  _PrefixRule('MER', 'Range / Stove', 'Maytag'), // Electric
  // ═══════════════════════════════════════════════════════════════
  //  FRIGIDAIRE
  // ═══════════════════════════════════════════════════════════════
  // Refrigerators
  _PrefixRule('FRFG', 'Refrigerator', 'Frigidaire'),
  _PrefixRule('FGHB', 'Refrigerator', 'Frigidaire'),
  _PrefixRule('FFSS', 'Refrigerator', 'Frigidaire'),
  _PrefixRule('FFHD', 'Refrigerator', 'Frigidaire'),
  _PrefixRule('FGHT', 'Refrigerator', 'Frigidaire'),

  // Washers
  _PrefixRule('FFTW', 'Washer', 'Frigidaire'),
  _PrefixRule('FFFW', 'Washer', 'Frigidaire'),

  // Dryers
  _PrefixRule('FFRE', 'Dryer', 'Frigidaire'), // Electric
  _PrefixRule('FFRG', 'Dryer', 'Frigidaire'), // Gas
  // Dishwashers
  _PrefixRule('FFCD', 'Dishwasher', 'Frigidaire'),
  _PrefixRule('FGID', 'Dishwasher', 'Frigidaire'),

  // Ranges
  _PrefixRule('FFGF', 'Range / Stove', 'Frigidaire'), // Gas
  _PrefixRule('FFEF', 'Range / Stove', 'Frigidaire'), // Electric
  // Microwaves
  _PrefixRule('FFMV', 'Microwave', 'Frigidaire'),

  // ═══════════════════════════════════════════════════════════════
  //  BOSCH
  // ═══════════════════════════════════════════════════════════════
  // Refrigerators
  _PrefixRule('B36', 'Refrigerator', 'Bosch'), // French Door
  _PrefixRule('B26', 'Refrigerator', 'Bosch'), // Counter Depth
  _PrefixRule('B21', 'Refrigerator', 'Bosch'), // Side-by-Side
  // Dishwashers
  _PrefixRule('SHP', 'Dishwasher', 'Bosch'), // 500/800 Series
  _PrefixRule('SHE', 'Dishwasher', 'Bosch'), // 300 Series
  _PrefixRule('SHX', 'Dishwasher', 'Bosch'), // Bar Handle
  _PrefixRule('SHS', 'Dishwasher', 'Bosch'),
  _PrefixRule('SHV', 'Dishwasher', 'Bosch'), // Custom Panel
  _PrefixRule('SHM', 'Dishwasher', 'Bosch'), // Benchmark
  _PrefixRule('SPE', 'Dishwasher', 'Bosch'), // 18" ADA
  _PrefixRule('SPX', 'Dishwasher', 'Bosch'), // 18"
  // Washers
  _PrefixRule('WAW', 'Washer', 'Bosch'),
  _PrefixRule('WAT', 'Washer', 'Bosch'),

  // Dryers
  _PrefixRule('WTG', 'Dryer', 'Bosch'),

  // Ranges
  _PrefixRule('HGI', 'Range / Stove', 'Bosch'), // Gas
  _PrefixRule('HEI', 'Range / Stove', 'Bosch'), // Electric
  _PrefixRule('HSI', 'Range / Stove', 'Bosch'), // Induction
  // ═══════════════════════════════════════════════════════════════
  //  KITCHENAID
  // ═══════════════════════════════════════════════════════════════
  // Refrigerators
  _PrefixRule('KRFF', 'Refrigerator', 'KitchenAid'),
  _PrefixRule('KRSF', 'Refrigerator', 'KitchenAid'),
  _PrefixRule('KRMF', 'Refrigerator', 'KitchenAid'),
  _PrefixRule('KBFN', 'Refrigerator', 'KitchenAid'),

  // Dishwashers
  _PrefixRule('KDT', 'Dishwasher', 'KitchenAid'),
  _PrefixRule('KDF', 'Dishwasher', 'KitchenAid'),

  // Ranges
  _PrefixRule('KSG', 'Range / Stove', 'KitchenAid'), // Gas Slide-in
  _PrefixRule('KSE', 'Range / Stove', 'KitchenAid'), // Electric Slide-in
  _PrefixRule('KFG', 'Range / Stove', 'KitchenAid'), // Gas Freestanding
  // ═══════════════════════════════════════════════════════════════
  //  ELECTROLUX
  // ═══════════════════════════════════════════════════════════════
  // Refrigerators
  _PrefixRule('EI23', 'Refrigerator', 'Electrolux'),
  _PrefixRule('EW23', 'Refrigerator', 'Electrolux'),

  // Washers
  _PrefixRule('ELFW', 'Washer', 'Electrolux'),
  _PrefixRule('EFLS', 'Washer', 'Electrolux'),

  // Dryers
  _PrefixRule('ELFE', 'Dryer', 'Electrolux'), // Electric
  _PrefixRule('ELFG', 'Dryer', 'Electrolux'), // Gas
  _PrefixRule('EFME', 'Dryer', 'Electrolux'),

  // Dishwashers
  _PrefixRule('EI24', 'Dishwasher', 'Electrolux'),

  // ═══════════════════════════════════════════════════════════════
  //  AMANA (Whirlpool subsidiary)
  // ═══════════════════════════════════════════════════════════════
  _PrefixRule('ART', 'Refrigerator', 'Amana'), // Top Freezer
  _PrefixRule('ASI', 'Refrigerator', 'Amana'), // Side-by-Side
  _PrefixRule('ABB', 'Refrigerator', 'Amana'), // Bottom Freezer
  _PrefixRule('NTW', 'Washer', 'Amana'), // Top Load
  _PrefixRule('NED', 'Dryer', 'Amana'), // Electric
  _PrefixRule('NGD', 'Dryer', 'Amana'), // Gas
  _PrefixRule('ADB', 'Dishwasher', 'Amana'),
  _PrefixRule('AGR', 'Range / Stove', 'Amana'), // Gas
  _PrefixRule('AER', 'Range / Stove', 'Amana'), // Electric
  _PrefixRule('AMV', 'Microwave', 'Amana'),

  // ═══════════════════════════════════════════════════════════════
  //  SPEED QUEEN
  // ═══════════════════════════════════════════════════════════════
  _PrefixRule('TR', 'Washer', 'Speed Queen'), // Top Load
  _PrefixRule('FF', 'Washer', 'Speed Queen'), // Front Load
  _PrefixRule('DR', 'Dryer', 'Speed Queen'),

  // ═══════════════════════════════════════════════════════════════
  //  SONY (Electronics)
  // ═══════════════════════════════════════════════════════════════
  _PrefixRule('XBR', 'Television', 'Sony'), // BRAVIA XBR
  _PrefixRule('KD-', 'Television', 'Sony'), // BRAVIA KD
  _PrefixRule('KDL', 'Television', 'Sony'), // BRAVIA KDL
  _PrefixRule('XR-', 'Television', 'Sony'), // BRAVIA XR
  // ═══════════════════════════════════════════════════════════════
  //  TCL (Electronics)
  // ═══════════════════════════════════════════════════════════════
  _PrefixRule(r'^[0-9]{2}S', 'Television', 'TCL', isRegex: true), // e.g. 55S546
  _PrefixRule(r'^[0-9]{2}R', 'Television', 'TCL', isRegex: true), // e.g. 65R635
  // ═══════════════════════════════════════════════════════════════
  //  HISENSE
  // ═══════════════════════════════════════════════════════════════
  _PrefixRule(
    r'^[0-9]{2}A',
    'Television',
    'Hisense',
    isRegex: true,
  ), // e.g. 55A6G
  _PrefixRule(
    r'^[0-9]{2}U',
    'Television',
    'Hisense',
    isRegex: true,
  ), // e.g. 65U8G
  _PrefixRule(
    r'^[0-9]{2}H',
    'Television',
    'Hisense',
    isRegex: true,
  ), // e.g. 50H8G
  // ═══════════════════════════════════════════════════════════════
  //  RHEEM / A.O. SMITH (Water Heaters)
  // ═══════════════════════════════════════════════════════════════
  _PrefixRule('XE', 'Water Heater', 'Rheem'),
  _PrefixRule('XG', 'Water Heater', 'Rheem'),
  _PrefixRule('PROG', 'Water Heater', 'Rheem'), // ProTerra
  _PrefixRule('PROE', 'Water Heater', 'A.O. Smith'),
  _PrefixRule('GPVL', 'Water Heater', 'A.O. Smith'),

  // ═══════════════════════════════════════════════════════════════
  //  CHAMBERLAIN / LIFTMASTER (Garage Door Openers)
  // ═══════════════════════════════════════════════════════════════
  _PrefixRule('B97', 'Garage Door Opener', 'Chamberlain'),
  _PrefixRule('B67', 'Garage Door Opener', 'Chamberlain'),
  _PrefixRule('8500', 'Garage Door Opener', 'LiftMaster'),
  _PrefixRule('8550', 'Garage Door Opener', 'LiftMaster'),
  _PrefixRule('84501', 'Garage Door Opener', 'LiftMaster'),

  // ═══════════════════════════════════════════════════════════════
  //  INSINKERATOR (Garbage Disposal)
  // ═══════════════════════════════════════════════════════════════
  _PrefixRule('BADGER', 'Garbage Disposal', 'InSinkErator'),
  _PrefixRule('EVOLUTION', 'Garbage Disposal', 'InSinkErator'),
];
