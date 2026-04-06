import '../../shared/models/maintenance_models.dart';

/// Get warranty status from an ISO end date and fallback label.
///
/// Returns 'expired', 'expiring-soon', or 'active'.
String getWarrantyStatusFromDate(String? endDateIso, String fallbackLabel) {
  if (endDateIso == null || endDateIso.isEmpty || endDateIso == 'null') {
    if (fallbackLabel.toLowerCase().contains('expired')) return 'expired';
    return 'active';
  }

  try {
    final endDate = DateTime.parse(endDateIso);
    final now = DateTime.now();
    final diffDays = endDate.difference(now).inDays;

    if (diffDays < 0) return 'expired';
    if (diffDays <= 30) return 'expiring-soon';
    return 'active';
  } on Object catch (_) {
    if (fallbackLabel.toLowerCase().contains('expired')) return 'expired';
    return 'active';
  }
}

/// Extract brand name from asset name string.
String getBrandFromName(String name) {
  if (name.contains('Samsung')) return 'Samsung';
  if (name.contains('LG')) return 'LG';
  if (name.contains('Whirlpool')) return 'Whirlpool';
  if (name.contains('Bosch')) return 'Bosch';
  if (name.contains('GE')) return 'GE';
  if (name.contains('Maytag')) return 'Maytag';
  return 'Unknown';
}

/// Format an ISO date string to human-readable format (e.g., "Jan 15, 2024").
String formatDateDisplay(String dateString) {
  try {
    final date = DateTime.parse(dateString);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  } on Object catch (_) {
    // If parsing fails, return the original string
    return dateString;
  }
}

/// Calculate asset age from purchase date string (e.g., "Jan 2022" or "2022").
String getAssetAge(String purchaseDate) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  try {
    // Try to parse "Jan 2022" format
    final parts = purchaseDate.split(' ');
    if (parts.length == 2) {
      final monthIndex = months.indexOf(parts[0]);
      final year = int.tryParse(parts[1]);

      if (monthIndex != -1 && year != null) {
        final now = DateTime.now();
        final ageInMonths =
            (now.year - year) * 12 + (now.month - monthIndex - 1);

        final years = ageInMonths ~/ 12;
        final remainingMonths = ageInMonths % 12;

        if (years == 0) return '$remainingMonths months';
        if (remainingMonths == 0) return '$years years';
        return '$years.${(remainingMonths / 12 * 10).round()} years';
      }
    }

    // Fallback to just year
    final year = int.tryParse(purchaseDate);
    if (year != null) {
      final age = DateTime.now().year - year;
      return '$age years';
    }
  } on Object catch (_) {
    // If parsing fails, return unknown
  }

  return 'Unknown';
}

/// Format file size in bytes to human-readable string.
String formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  } else if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Create an asset-specific maintenance reminder based on asset type.
Reminder createAssetSpecificReminder(Map<String, dynamic> asset) {
  final assetId = asset['id']?.toString() ?? '0';
  final assetName = asset['name'] as String? ?? 'Asset';
  final assetLocation = asset['location'] as String? ?? 'Home';
  // Prefer the structured 'type' field (e.g. "Dryer", "Range / Stove",
  // "Heating & Cooling") then fall back to the display name.
  final assetType =
      ((asset['type'] as String?)?.trim().isNotEmpty == true
              ? asset['type'] as String
              : assetName)
          .toLowerCase();

  // Determine task based on asset type
  String taskId, taskName, taskDescription, whyItMatters, estimatedEffort;
  int riskLevel;

  if (assetType.contains('refrigerator') || assetType.contains('fridge')) {
    taskId = 'fridge-monthly-gasket';
    taskName = 'Door Gasket Cleaning';
    taskDescription = 'Clean door gaskets to maintain seal';
    whyItMatters = 'Prevents air leaks and reduces energy consumption';
    estimatedEffort = '5 minutes';
    riskLevel = 3;
  } else if (assetType.contains('dryer')) {
    taskId = 'dryer-vent-clean';
    taskName = 'Exhaust Vent Cleaning';
    taskDescription = 'Clean dryer exhaust vent and lint trap';
    whyItMatters =
        'Prevents fire hazards — clogged dryer vents are a leading cause of home fires';
    estimatedEffort = '15 minutes';
    riskLevel = 8;
  } else if (assetType.contains('washer') || assetType.contains('washing')) {
    taskId = 'washer-drum-clean';
    taskName = 'Drum Cleaning Cycle';
    taskDescription = 'Run a drum cleaning cycle and wipe door gasket';
    whyItMatters = 'Prevents mold, mildew, and unpleasant odors';
    estimatedEffort = '20 minutes';
    riskLevel = 4;
  } else if (assetType.contains('dishwasher')) {
    taskId = 'dishwasher-filter-clean';
    taskName = 'Filter Cleaning';
    taskDescription = 'Clean dishwasher filter and check spray arms';
    whyItMatters = 'Improves cleaning performance and prevents odors';
    estimatedEffort = '15 minutes';
    riskLevel = 3;
  } else if (assetType.contains('range') ||
      assetType.contains('stove') ||
      assetType.contains('oven') ||
      assetType.contains('cooktop')) {
    taskId = 'oven-element-check';
    taskName = 'Burner & Heating Element Check';
    taskDescription =
        'Inspect burners, grates, and heating elements for residue';
    whyItMatters =
        'Ensures safe and efficient cooking; prevents grease fire buildup';
    estimatedEffort = '10 minutes';
    riskLevel = 5;
  } else if (assetType.contains('microwave')) {
    taskId = 'microwave-interior-clean';
    taskName = 'Interior Deep Cleaning';
    taskDescription = 'Clean interior walls, turntable, and vent filter';
    whyItMatters = 'Removes food residue that can cause arcing and odors';
    estimatedEffort = '10 minutes';
    riskLevel = 3;
  } else if (assetType.contains('water heater') ||
      assetType.contains('heater')) {
    taskId = 'water-heater-tank-flush';
    taskName = 'Tank Sediment Flush';
    taskDescription = 'Flush water heater tank to remove mineral sediment';
    whyItMatters = 'Prevents corrosion and extends tank life by years';
    estimatedEffort = '30–45 minutes';
    riskLevel = 4;
  } else if (assetType.contains('heating') ||
      assetType.contains('cooling') ||
      assetType.contains('furnace') ||
      assetType.contains('hvac') ||
      assetType.contains('heat pump')) {
    taskId = 'furnace-filter-replace';
    taskName = 'Air Filter Replacement';
    taskDescription = 'Replace HVAC / furnace air filter';
    whyItMatters =
        'Dirty filters restrict airflow, raising energy costs and shortening system life';
    estimatedEffort = '10 minutes';
    riskLevel = 6;
  } else if (assetType.contains('air conditioner') ||
      assetType.contains('ac')) {
    taskId = 'ac-monthly-filter';
    taskName = 'AC Filter Replacement';
    taskDescription = 'Replace or clean AC filter';
    whyItMatters = 'Improves air quality and AC efficiency';
    estimatedEffort = '10 minutes';
    riskLevel = 7;
  } else if (assetType.contains('garbage disposal') ||
      assetType.contains('disposal')) {
    taskId = 'disposal-deodorize';
    taskName = 'Disposal Deodorizing & Cleaning';
    taskDescription =
        'Clean grinding chamber and deodorize with ice and citrus';
    whyItMatters = 'Prevents foul odors and keeps blades sharp';
    estimatedEffort = '10 minutes';
    riskLevel = 2;
  } else if (assetType.contains('garage door') ||
      assetType.contains('door opener')) {
    taskId = 'garage-lubricate';
    taskName = 'Spring & Track Lubrication';
    taskDescription = 'Lubricate springs, rollers, and tracks';
    whyItMatters = 'Reduces wear and prevents costly spring breakage';
    estimatedEffort = '15 minutes';
    riskLevel = 5;
  } else if (assetType.contains('water softener') ||
      assetType.contains('softener')) {
    taskId = 'softener-salt-refill';
    taskName = 'Salt Tank Refill Check';
    taskDescription = 'Check and refill salt in the brine tank';
    whyItMatters =
        'Ensures continued hard water treatment and appliance protection';
    estimatedEffort = '10 minutes';
    riskLevel = 3;
  } else if (assetType.contains('sump pump')) {
    taskId = 'sump-float-test';
    taskName = 'Float Switch Test';
    taskDescription = 'Test float switch operation by pouring water in the pit';
    whyItMatters = 'A failed sump pump can lead to basement flooding';
    estimatedEffort = '10 minutes';
    riskLevel = 7;
  } else if (assetType.contains('thermostat')) {
    taskId = 'thermostat-battery';
    taskName = 'Battery Replacement';
    taskDescription = 'Replace thermostat batteries';
    whyItMatters =
        'Dead batteries cause heating/cooling to stop working unexpectedly';
    estimatedEffort = '5 minutes';
    riskLevel = 4;
  } else if (assetType.contains('television') ||
      assetType.contains('smart tv') ||
      assetType.contains(' tv ') ||
      assetType.endsWith(' tv')) {
    taskId = 'tv-screen-clean';
    taskName = 'Screen Cleaning';
    taskDescription =
        'Clean screen with a microfiber cloth and check ventilation';
    whyItMatters = 'Dust buildup in vents can cause overheating';
    estimatedEffort = '10 minutes';
    riskLevel = 2;
  } else if (assetType.contains('computer') || assetType.contains('laptop')) {
    taskId = 'computer-dust-clean';
    taskName = 'Fan & Vent Dusting';
    taskDescription = 'Blow out dust from fans and vents';
    whyItMatters = 'Overheating shortens component lifespan and causes crashes';
    estimatedEffort = '15 minutes';
    riskLevel = 5;
  } else if (assetType.contains('gaming console') ||
      assetType.contains('playstation') ||
      assetType.contains('xbox') ||
      assetType.contains('nintendo')) {
    taskId = 'console-vent-dust';
    taskName = 'Vent & Fan Dust Cleaning';
    taskDescription = 'Clean dust from console vents and fans';
    whyItMatters = 'Prevents thermal throttling and component damage';
    estimatedEffort = '10 minutes';
    riskLevel = 4;
  } else if (assetType.contains('printer')) {
    taskId = 'printer-head-clean';
    taskName = 'Printhead Cleaning';
    taskDescription = 'Run printhead cleaning cycle and check ink levels';
    whyItMatters = 'Prevents clogged heads that cause streaky or blank prints';
    estimatedEffort = '10 minutes';
    riskLevel = 3;
  } else if (assetType.contains('router') ||
      assetType.contains('gateway') ||
      assetType.contains('modem')) {
    taskId = 'router-firmware-update';
    taskName = 'Firmware Update';
    taskDescription = 'Check and apply available firmware updates';
    whyItMatters = 'Security patches protect your network from vulnerabilities';
    estimatedEffort = '15 minutes';
    riskLevel = 6;
  } else if (assetType.contains('speaker') || assetType.contains('audio')) {
    taskId = 'audio-dust-clean';
    taskName = 'Speaker Dust Cleaning';
    taskDescription = 'Clean speaker grills and cables';
    whyItMatters = 'Dust in drivers affects sound quality over time';
    estimatedEffort = '10 minutes';
    riskLevel = 2;
  } else {
    // Generic maintenance for unknown asset types
    taskId = 'general-inspection';
    taskName = 'General Inspection';
    taskDescription = 'Perform general inspection and cleaning';
    whyItMatters = 'Maintains optimal performance and longevity';
    estimatedEffort = '15 minutes';
    riskLevel = 3;
  }

  return Reminder(
    id: 'overview-$assetId',
    assetId: assetId,
    assetName: assetName,
    assetLocation: assetLocation,
    taskId: taskId,
    taskName: taskName,
    taskDescription: taskDescription,
    whyItMatters: whyItMatters,
    estimatedEffort: estimatedEffort,
    dueDate: DateTime.now().add(const Duration(days: 15)),
    status: ReminderStatus.upcoming,
    priority: ReminderPriority.medium,
    riskLevel: riskLevel,
  );
}
