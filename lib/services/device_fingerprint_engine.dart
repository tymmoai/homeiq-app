/// Device Fingerprint Engine — client-side device identification.
///
/// Combines TTL, port scan results, DHCP hostname patterns, mDNS services,
/// MAC vendor, and SSDP model data to produce a structured identification
/// BEFORE backend enrichment. Mirrors the backend engine logic so devices
/// get immediate labels even when the server is unreachable.
///
/// Called from [WifiDiscoveryService] after all local discovery layers merge.
library;

// ─── Result model ──────────────────────────────────────────────────────────

class FingerprintResult {
  final String deviceType;
  final String brandGuess;
  final String osGuess;
  final int confidenceScore;
  final List<String> reasoning;

  const FingerprintResult({
    required this.deviceType,
    required this.brandGuess,
    required this.osGuess,
    required this.confidenceScore,
    required this.reasoning,
  });
}

// ─── TTL → OS mapping ──────────────────────────────────────────────────────

class _TtlRange {
  final int min;
  final int max;
  final String os;
  const _TtlRange(this.min, this.max, this.os);
}

const _ttlOsTable = <_TtlRange>[
  _TtlRange(200, 255, 'Router / Network Device'),
  _TtlRange(125, 130, 'Windows'),
  _TtlRange(60, 65, 'Linux / Android'),
  _TtlRange(55, 60, 'iOS / macOS'),
  _TtlRange(30, 35, 'Legacy Windows'),
];

/// Map raw ICMP TTL value to an OS guess string.
String ttlToOsGuess(int ttl) {
  for (final row in _ttlOsTable) {
    if (ttl >= row.min && ttl <= row.max) return row.os;
  }
  if (ttl == 64) return 'Linux / Android';
  return 'Unknown OS';
}

// ─── Port → device type table ──────────────────────────────────────────────

class PortHint {
  final String deviceType;
  final int confidence;
  const PortHint(this.deviceType, this.confidence);
}

const portFingerprintMap = <int, PortHint>{
  62078: PortHint('iPhone / iPad', 95),
  5555: PortHint('Android Device', 90),
  8009: PortHint('Chromecast', 92),
  8008: PortHint('Chromecast / Google TV', 85),
  9100: PortHint('Printer', 92),
  515: PortHint('Printer', 88),
  631: PortHint('Printer', 85),
  9197: PortHint('Printer', 80),
  445: PortHint('Windows PC / NAS', 72),
  135: PortHint('Windows PC', 75),
  3389: PortHint('Windows PC', 88),
  5357: PortHint('Windows PC', 70),
  22: PortHint('Linux Device', 60),
  554: PortHint('IP Camera', 88),
  8001: PortHint('Smart TV (Samsung)', 88),
  8060: PortHint('Roku Player', 92),
  3689: PortHint('Apple Device (iTunes)', 82),
  7000: PortHint('Apple AirPlay Device', 80),
  548: PortHint('Mac / NAS', 75),
  1400: PortHint('Sonos Speaker', 92),
  32400: PortHint('Plex Media Server', 92),
  8123: PortHint('Home Assistant Hub', 95),
  1883: PortHint('Smart Hub / MQTT', 68),
  8096: PortHint('Jellyfin Server', 92),
  5001: PortHint('Synology NAS', 85),
  8291: PortHint('MikroTik Router', 92),
  55443: PortHint('Eufy Camera', 88),
  // ── Home Appliance Ports ──────────────────────────────────────────────
  2878: PortHint('LG ThinQ Appliance', 90),
  7676: PortHint('LG Smart Device', 72),
  7677: PortHint('LG ThinQ Appliance', 82),
  6000: PortHint('LG Smart Device', 65),
  8900: PortHint('Smart Appliance', 60),
  55000: PortHint('GE Appliance', 72),
  4999: PortHint('Robot Vacuum', 65),
};

/// Produce human-readable port labels for UI display.
List<String> generatePortFingerprints(List<int> ports) {
  const wellKnownPorts = <int, String>{
    21: 'FTP',
    22: 'SSH',
    23: 'Telnet',
    25: 'SMTP',
    53: 'DNS',
    80: 'HTTP',
    110: 'POP3',
    143: 'IMAP',
    161: 'SNMP',
    389: 'LDAP',
    443: 'HTTPS',
    515: 'LPR',
    993: 'IMAPS',
    995: 'POP3S',
    1080: 'SOCKS',
    1900: 'UPnP/SSDP',
    2049: 'NFS',
    2869: 'UPnP-Event',
    3306: 'MySQL',
    5000: 'UPnP-HTTP',
    5060: 'SIP',
    5432: 'PostgreSQL',
    5900: 'VNC',
    6379: 'Redis',
    8080: 'HTTP-Alt',
    8443: 'HTTPS-Alt',
    9200: 'Elasticsearch',
    27017: 'MongoDB',
  };

  return ports.map((p) {
    final hint = portFingerprintMap[p];
    if (hint != null) return '$p → ${hint.deviceType}';
    final name = wellKnownPorts[p];
    if (name != null) return '$p ($name)';
    return '$p';
  }).toList();
}

// ─── DHCP hostname normalization ────────────────────────────────────────────

/// Normalize raw hostname by stripping `.local`, `.home`, `.lan` suffixes,
/// trimming whitespace, and lowercasing. Returns `null` if the result is
/// empty or looks like a bare IP address.
String? normalizeDhcpHostname(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  var h = raw.trim();
  // Strip common local-network suffixes
  for (final suffix in [
    '.local',
    '.home',
    '.lan',
    '.localdomain',
    '.internal',
  ]) {
    if (h.toLowerCase().endsWith(suffix)) {
      h = h.substring(0, h.length - suffix.length);
    }
  }
  h = h.trim();
  if (h.isEmpty) return null;
  // Discard if it's just an IP address
  if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(h)) return null;
  // Discard if it's just a number (first octet leftover)
  if (RegExp(r'^\d+$').hasMatch(h)) return null;
  return h;
}

// ─── DHCP hostname patterns → device identification ─────────────────────────

class _HostnamePattern {
  final RegExp pattern;
  final String deviceType;
  final String brand;
  const _HostnamePattern(this.pattern, this.deviceType, this.brand);
}

final _hostnamePatterns = <_HostnamePattern>[
  // Apple mobile — check before generic Apple
  _HostnamePattern(RegExp(r'iphone', caseSensitive: false), 'iPhone', 'Apple'),
  _HostnamePattern(RegExp(r'ipad', caseSensitive: false), 'iPad', 'Apple'),
  _HostnamePattern(RegExp(r'ipod', caseSensitive: false), 'iPod', 'Apple'),
  _HostnamePattern(
    RegExp(r'macbook', caseSensitive: false),
    'MacBook',
    'Apple',
  ),
  _HostnamePattern(RegExp(r'^imac', caseSensitive: false), 'iMac', 'Apple'),
  _HostnamePattern(
    RegExp(r'apple-?tv', caseSensitive: false),
    'Apple TV',
    'Apple',
  ),
  _HostnamePattern(
    RegExp(r'homepod', caseSensitive: false),
    'HomePod',
    'Apple',
  ),
  // Android manufacturers
  _HostnamePattern(
    RegExp(r'^android-', caseSensitive: false),
    'Android Phone',
    'Android',
  ),
  _HostnamePattern(
    RegExp(r'^vivo-', caseSensitive: false),
    'Android Phone',
    'Vivo',
  ),
  _HostnamePattern(
    RegExp(r'^(oneplus|one-plus)', caseSensitive: false),
    'Android Phone',
    'OnePlus',
  ),
  _HostnamePattern(
    RegExp(r'^oppo-?', caseSensitive: false),
    'Android Phone',
    'Oppo',
  ),
  _HostnamePattern(
    RegExp(r'^realme-?', caseSensitive: false),
    'Android Phone',
    'Realme',
  ),
  _HostnamePattern(
    RegExp(r'^poco-?', caseSensitive: false),
    'Android Phone',
    'Poco',
  ),
  _HostnamePattern(
    RegExp(r'^redmi-?', caseSensitive: false),
    'Android Phone',
    'Xiaomi',
  ),
  _HostnamePattern(
    RegExp(r'^mi-', caseSensitive: false),
    'Android Phone',
    'Xiaomi',
  ),
  _HostnamePattern(
    RegExp(r'^nokia-', caseSensitive: false),
    'Android Phone',
    'Nokia',
  ),
  _HostnamePattern(
    RegExp(r'^moto(rola)?-?', caseSensitive: false),
    'Android Phone',
    'Motorola',
  ),
  _HostnamePattern(
    RegExp(r'^honor-?', caseSensitive: false),
    'Android Phone',
    'Honor',
  ),
  // Samsung model prefixes
  _HostnamePattern(
    RegExp(r'^(sm-[agf]\d|samsung-sm-[agf])', caseSensitive: false),
    'Android Phone',
    'Samsung',
  ),
  _HostnamePattern(
    RegExp(r'^(sm-[tx]\d|samsung-sm-[tx])', caseSensitive: false),
    'Android Tablet',
    'Samsung',
  ),
  _HostnamePattern(
    RegExp(r'galaxy', caseSensitive: false),
    'Samsung Galaxy',
    'Samsung',
  ),
  // Google Pixel
  _HostnamePattern(
    RegExp(r'^pixel-?', caseSensitive: false),
    'Google Pixel',
    'Google',
  ),
  // Windows
  _HostnamePattern(RegExp(r'^DESKTOP-'), 'Windows PC', 'Windows'),
  _HostnamePattern(
    RegExp(r'^(PC|LAPTOP|NOTEBOOK)-', caseSensitive: false),
    'Windows PC',
    'Windows',
  ),
  // Lenovo
  _HostnamePattern(
    RegExp(r'thinkpad', caseSensitive: false),
    'Laptop',
    'Lenovo',
  ),
  _HostnamePattern(
    RegExp(r'ideapad', caseSensitive: false),
    'Laptop',
    'Lenovo',
  ),
  // Raspberry Pi
  _HostnamePattern(
    RegExp(r'^raspberrypi', caseSensitive: false),
    'Raspberry Pi',
    'Raspberry Pi',
  ),
  // Streaming / smart home
  _HostnamePattern(
    RegExp(r'chromecast', caseSensitive: false),
    'Chromecast',
    'Google',
  ),
  _HostnamePattern(
    RegExp(r'^roku', caseSensitive: false),
    'Roku Player',
    'Roku',
  ),
  _HostnamePattern(
    RegExp(r'(amazon-)?(echo|alexa)', caseSensitive: false),
    'Amazon Echo',
    'Amazon',
  ),
  _HostnamePattern(
    RegExp(r'fire-?tv', caseSensitive: false),
    'Fire TV',
    'Amazon',
  ),
  _HostnamePattern(
    RegExp(r'(ring-?|doorbell)', caseSensitive: false),
    'Ring Doorbell',
    'Ring',
  ),
  // NAS
  _HostnamePattern(
    RegExp(r'(diskstation|synology)', caseSensitive: false),
    'Synology NAS',
    'Synology',
  ),
  _HostnamePattern(RegExp(r'^qnap', caseSensitive: false), 'QNAP NAS', 'QNAP'),
  // Printers
  _HostnamePattern(
    RegExp(r'(printer|laserjet|officejet|deskjet)', caseSensitive: false),
    'Printer',
    '',
  ),

  // ── US Smart Home Appliances ─────────────────────────────────────────────
  // DHCP hostnames assigned by appliance firmware often include type/brand words.
  // Samsung Family Hub: "Samsung-RF23M8570SG", LG ThinQ: "LG-WM4000HWA"
  // GE SmartHQ: "GE-GFW850SPNRS", Whirlpool: "Whirlpool-WFW6620HC", etc.
  _HostnamePattern(
    RegExp(r'refriger|fridge|family.?hub', caseSensitive: false),
    'Refrigerator',
    '',
  ),
  _HostnamePattern(
    RegExp(r'washer|washing.?machine|front.?load|top.?load', caseSensitive: false),
    'Washer',
    '',
  ),
  _HostnamePattern(
    RegExp(r'\bdryer\b|gas.?dryer|elec.?dryer', caseSensitive: false),
    'Dryer',
    '',
  ),
  _HostnamePattern(
    RegExp(r'dishwash', caseSensitive: false),
    'Dishwasher',
    '',
  ),
  _HostnamePattern(
    RegExp(r'\boven\b|\brange\b|\bstove\b|\bcooktop\b', caseSensitive: false),
    'Range / Stove',
    '',
  ),
  _HostnamePattern(
    RegExp(r'microwave', caseSensitive: false),
    'Microwave',
    '',
  ),
  _HostnamePattern(
    RegExp(r'\bfreezer\b', caseSensitive: false),
    'Freezer',
    '',
  ),
  _HostnamePattern(
    RegExp(r'hvac|air.?cond|heat.?pump', caseSensitive: false),
    'HVAC System',
    '',
  ),
  _HostnamePattern(
    RegExp(r'water.?heat|waterheater|econet', caseSensitive: false),
    'Water Heater',
    '',
  ),
  _HostnamePattern(
    RegExp(r'roomba|irobot|robovac', caseSensitive: false),
    'Robot Vacuum',
    'iRobot',
  ),
  _HostnamePattern(
    RegExp(r'thinq', caseSensitive: false),
    'LG Appliance',
    'LG',
  ),
  _HostnamePattern(
    RegExp(r'smarthq', caseSensitive: false),
    'GE Appliance',
    'GE Appliances',
  ),
  _HostnamePattern(
    RegExp(r'home.?connect', caseSensitive: false),
    'BSH Appliance',
    'BSH (Bosch/Siemens)',
  ),
  _HostnamePattern(
    RegExp(r'icomfort', caseSensitive: false),
    'HVAC System',
    'Lennox',
  ),
  _HostnamePattern(
    RegExp(r'comfortlink|nexia', caseSensitive: false),
    'HVAC System',
    'Trane',
  ),
  _HostnamePattern(
    RegExp(r'infinity.?touch|infinitytouch', caseSensitive: false),
    'HVAC System',
    'Carrier',
  ),
];

// ─── mDNS service type → device identification ─────────────────────────────

class _MdnsHint {
  final String deviceType;
  final String brand;
  final int confidence;
  const _MdnsHint(this.deviceType, this.brand, this.confidence);
}

const _mdnsDeviceMap = <String, _MdnsHint>{
  '_googlecast._tcp': _MdnsHint('Chromecast / Google TV', 'Google', 92),
  '_airplay._tcp': _MdnsHint('Apple AirPlay Device', 'Apple', 80),
  '_apple-mobdev2._tcp': _MdnsHint('iPhone / iPad', 'Apple', 92),
  '_apple-mobdev._tcp': _MdnsHint('iPhone / iPad', 'Apple', 90),
  '_rdlink._tcp': _MdnsHint('iPhone (AirDrop)', 'Apple', 88),
  '_companion-link._tcp': _MdnsHint('iPhone / iPad', 'Apple', 88),
  '_continuity._tcp': _MdnsHint('iPhone / iPad', 'Apple', 85),
  '_apple-pairable._tcp': _MdnsHint('iPhone / iPad', 'Apple', 85),
  '_raop._tcp': _MdnsHint('AirPlay Audio', 'Apple', 82),
  '_daap._tcp': _MdnsHint('Mac (iTunes Library)', 'Apple', 80),
  '_afpovertcp._tcp': _MdnsHint('Mac / NAS', '', 72),
  '_sonos._tcp': _MdnsHint('Sonos Speaker', 'Sonos', 92),
  '_spotify-connect._tcp': _MdnsHint('Spotify Device', 'Spotify', 75),
  '_ipp._tcp': _MdnsHint('Printer', '', 85),
  '_printer._tcp': _MdnsHint('Printer', '', 85),
  '_hap._tcp': _MdnsHint('HomeKit Device', 'Apple', 80),
  '_hue._tcp': _MdnsHint('Philips Hue Hub', 'Philips', 92),
  '_workstation._tcp': _MdnsHint('Linux / Mac Computer', '', 68),
  '_smb._tcp': _MdnsHint('NAS / File Server', '', 65),
  '_matter._tcp': _MdnsHint('Matter Smart Device', '', 72),

  // ── US Smart Appliance mDNS service types ──────────────────────────────
  '_samsung-connect._tcp': _MdnsHint('Samsung Appliance', 'Samsung', 85),
  '_smartthings._tcp': _MdnsHint('SmartThings Device', 'Samsung', 80),
  '_thinq._tcp': _MdnsHint('LG ThinQ Appliance', 'LG', 92),
  '_thinq2._tcp': _MdnsHint('LG ThinQ Appliance', 'LG', 92),
  '_lge-tv._tcp': _MdnsHint('LG Smart TV', 'LG', 90),
  '_smarthq._tcp': _MdnsHint('GE Appliance', 'GE Appliances', 88),
  '_ge-appliance._tcp': _MdnsHint('GE Appliance', 'GE Appliances', 88),
  '_homeconnect._tcp': _MdnsHint('BSH Appliance', 'Bosch', 90),
  '_home-connect._tcp': _MdnsHint('BSH Appliance', 'Bosch', 90),
  '_miele._tcp': _MdnsHint('Miele Appliance', 'Miele', 90),
  '_whirlpool._tcp': _MdnsHint('Whirlpool Appliance', 'Whirlpool', 88),
  '_roomba._tcp': _MdnsHint('Robot Vacuum', 'iRobot', 92),
  '_irobot._tcp': _MdnsHint('Robot Vacuum', 'iRobot', 92),
  '_robot._tcp': _MdnsHint('Robot Vacuum', '', 72),
  '_roborock._tcp': _MdnsHint('Robot Vacuum', 'Roborock', 90),
  '_dyson_mqtt._tcp': _MdnsHint('Dyson Device', 'Dyson', 90),
  '_dyson._tcp': _MdnsHint('Dyson Device', 'Dyson', 88),
  '_ecobee._tcp': _MdnsHint('Smart Thermostat', 'Ecobee', 90),
  '_nest._tcp': _MdnsHint('Smart Thermostat', 'Google Nest', 90),
  '_sensibo._tcp': _MdnsHint('Air Conditioner', 'Sensibo', 88),
  '_airassistant._tcp': _MdnsHint('Air Purifier', '', 72),
  '_econet._tcp': _MdnsHint('Water Heater', 'Rheem', 88),
  '_icomfort._tcp': _MdnsHint('HVAC System', 'Lennox', 88),
  '_matter._udp': _MdnsHint('Matter Smart Device', '', 72),
};

// ─── Main fingerprint function ──────────────────────────────────────────────

/// Run the device fingerprint engine on a single device's signals.
///
/// Combines TTL, open ports, hostname, mDNS services, MAC vendor, and
/// SSDP model data to produce a structured identification.
///
/// Parameters:
/// - [manufacturer]: MAC OUI vendor or cleaned manufacturer name
/// - [hostname]: normalized DHCP/DNS hostname
/// - [openPorts]: list of open TCP ports
/// - [ttl]: raw ICMP TTL value from ping
/// - [mdnsServices]: advertised mDNS service types (e.g. `_googlecast._tcp`)
/// - [ssdpModelName], [ssdpFriendlyName], [ssdpManufacturer]: UPnP data
/// - [httpBanner]: HTTP Server header
/// - [currentCategory]: existing device category from earlier layers
FingerprintResult fingerprintDevice({
  String? manufacturer,
  String? hostname,
  List<int> openPorts = const [],
  int? ttl,
  List<String>? mdnsServices,
  String? ssdpModelName,
  String? ssdpModelNumber,
  String? ssdpFriendlyName,
  String? ssdpManufacturer,
  String? netbiosName,
  String? snmpDescr,
  String? httpBanner,
  String? currentCategory,
}) {
  var deviceType = currentCategory ?? 'Unknown';
  var brandGuess = (manufacturer != null && manufacturer != 'Unknown')
      ? manufacturer
      : '';
  var osGuess = '';
  var score = 0;
  final reasoning = <String>[];

  // ─ 1. TTL → OS guess (+10 / +15 for router) ─────────────────────────
  if (ttl != null && ttl > 0) {
    osGuess = ttlToOsGuess(ttl);
    if (osGuess != 'Unknown OS') {
      reasoning.add('TTL $ttl → $osGuess');
      score += ttl >= 200 ? 15 : 10;
    }
  }

  // ─ 2. Port fingerprinting (+15 for high confidence) ──────────────────
  var bestPortConf = 0;
  var bestPortType = '';
  var bestPortNum = 0;
  for (final port in openPorts) {
    final hint = portFingerprintMap[port];
    if (hint != null && hint.confidence > bestPortConf) {
      bestPortConf = hint.confidence;
      bestPortType = hint.deviceType;
      bestPortNum = port;
    }
  }
  if (bestPortType.isNotEmpty) {
    reasoning.add(
      'Port $bestPortNum ($bestPortType) — confidence $bestPortConf%',
    );
    if (bestPortConf >= 85) {
      deviceType = bestPortType;
      score += 15;
    } else {
      score += 8;
    }
  }

  // ─ 3. DHCP / DNS hostname pattern matching (+20) ─────────────────────
  final cleanHost = hostname ?? netbiosName ?? '';
  if (cleanHost.isNotEmpty) {
    for (final entry in _hostnamePatterns) {
      if (entry.pattern.hasMatch(cleanHost)) {
        deviceType = entry.deviceType;
        if (entry.brand.isNotEmpty) brandGuess = entry.brand;
        reasoning.add('Hostname "$cleanHost" → ${entry.deviceType}');
        score += 20;
        break;
      }
    }
  }

  // ─ 4. mDNS service types (+20 max) ──────────────────────────────────
  if (mdnsServices != null) {
    for (final svc in mdnsServices) {
      final match = _mdnsDeviceMap[svc];
      if (match != null) {
        deviceType = match.deviceType;
        if (match.brand.isNotEmpty && brandGuess.isEmpty) {
          brandGuess = match.brand;
        }
        reasoning.add('mDNS "$svc" → ${match.deviceType}');
        score += (match.confidence * 0.2).floor(); // max +20
        break;
      }
    }
  }

  // ─ 5. SSDP UPnP data (+25 for TV/printer/router, +30 for appliance) ────
  final ssdpStr =
      '${ssdpModelName ?? ''} ${ssdpModelNumber ?? ''} '
              '${ssdpFriendlyName ?? ''} ${ssdpManufacturer ?? ''}'
          .toLowerCase();
  if (ssdpStr.trim().isNotEmpty) {
    // ── Home Appliances — check BEFORE generic TV/router entries ────────
    bool _ssdpMatch(RegExp re) => re.hasMatch(ssdpStr);
    if (_ssdpMatch(RegExp(r'wash(ing|er)|washing.machine|laundry'))) {
      deviceType = 'Washing Machine';
      reasoning.add('SSDP "${ssdpFriendlyName ?? ssdpModelName}" → Washing Machine');
      score += 30;
    } else if (_ssdpMatch(RegExp(r'dryer|tumble.dry|drying.machine'))) {
      deviceType = 'Dryer';
      reasoning.add('SSDP → Dryer');
      score += 30;
    } else if (_ssdpMatch(RegExp(r'refriger|fridge|freezer|family.hub'))) {
      deviceType = 'Refrigerator';
      reasoning.add('SSDP "${ssdpFriendlyName ?? ssdpModelName}" → Refrigerator');
      score += 30;
    } else if (_ssdpMatch(RegExp(r'dish.?wash'))) {
      deviceType = 'Dishwasher';
      reasoning.add('SSDP → Dishwasher');
      score += 30;
    } else if (_ssdpMatch(RegExp(r'\boven\b|range|cooktop|stove'))) {
      deviceType = 'Oven / Range';
      reasoning.add('SSDP → Oven / Range');
      score += 30;
    } else if (ssdpStr.contains('microwave')) {
      deviceType = 'Microwave';
      reasoning.add('SSDP → Microwave');
      score += 30;
    } else if (_ssdpMatch(RegExp(r'air.cond|aircondition|hvac|heat.pump|ac.unit'))) {
      deviceType = 'Air Conditioner';
      reasoning.add('SSDP → Air Conditioner');
      score += 28;
    } else if (_ssdpMatch(RegExp(r'robot.vac|roomba|robovac|vacuum.clean'))) {
      deviceType = 'Robot Vacuum';
      reasoning.add('SSDP → Robot Vacuum');
      score += 30;
    } else if (_ssdpMatch(RegExp(r'air.purif|purifier|air.clean'))) {
      deviceType = 'Air Purifier';
      reasoning.add('SSDP → Air Purifier');
      score += 28;
    } else if (ssdpStr.contains('tv') ||
        ssdpStr.contains('television') ||
        ssdpStr.contains('bravia')) {
      deviceType = 'Smart TV';
      reasoning.add(
        'SSDP model "${ssdpModelName ?? ssdpFriendlyName}" → Smart TV',
      );
      score += 25;
    } else if (ssdpStr.contains('router') ||
        ssdpStr.contains('gateway') ||
        ssdpStr.contains('igd')) {
      deviceType = 'Router';
      reasoning.add('SSDP → Router / Gateway');
      score += 20;
    } else if (ssdpStr.contains('printer')) {
      deviceType = 'Printer';
      reasoning.add('SSDP → Printer');
      score += 25;
    } else if (ssdpStr.contains('roku')) {
      deviceType = 'Roku Player';
      brandGuess = 'Roku';
      reasoning.add('SSDP → Roku Player');
      score += 25;
    } else if (ssdpStr.contains('mediarenderer') || ssdpStr.contains('dlna')) {
      if (deviceType == 'Unknown') deviceType = 'Smart TV / Media Player';
      reasoning.add('SSDP UPnP MediaRenderer → Smart TV / Media Player');
      score += 15;
    }
    if (ssdpManufacturer != null && brandGuess.isEmpty) {
      brandGuess = ssdpManufacturer
          .replaceAll(
            RegExp(
              r'\s+(Electronics?|Corporation|Corp\.?|Inc\.?|Co\.?|Ltd\.?|GmbH|LLC)\s*$',
              caseSensitive: false,
            ),
            '',
          )
          .trim();
    }
  }

  // ─ 6. Combined MAC vendor + TTL rules ────────────────────────────────
  final macLower = (manufacturer ?? brandGuess).toLowerCase();

  if (macLower.contains('apple')) {
    brandGuess = 'Apple';
    if (openPorts.contains(62078)) {
      deviceType = 'iPhone / iPad';
      reasoning.add('Apple MAC + port 62078 (iOS Lockdown) → iPhone / iPad');
      score += 35;
    } else if (osGuess.contains('iOS')) {
      deviceType = 'iPhone';
      reasoning.add('Apple MAC + iOS TTL range → iPhone');
      score += 25;
    } else if (openPorts.contains(548) || openPorts.contains(3689)) {
      deviceType = 'MacBook';
      reasoning.add('Apple MAC + AFP/DAAP port → MacBook / Mac');
      score += 25;
    } else if (!osGuess.contains('Windows')) {
      if (deviceType == 'Unknown') deviceType = 'Apple Device';
      reasoning.add('Apple MAC vendor → Apple Device');
      score += 10;
    }
  }

  if (macLower.contains('samsung')) {
    brandGuess = 'Samsung';
    if (osGuess.contains('Linux / Android') || openPorts.contains(8001)) {
      if (!deviceType.toLowerCase().contains('tv') &&
          !deviceType.toLowerCase().contains('print')) {
        deviceType = openPorts.contains(8001)
            ? 'Samsung Smart TV'
            : 'Samsung Android Phone';
        reasoning.add(
          'Samsung MAC + ${openPorts.contains(8001) ? 'port 8001' : 'Android TTL'} → $deviceType',
        );
        score += 25;
      }
    }
  }

  if (macLower.contains('huawei')) {
    brandGuess = 'Huawei';
    if (osGuess.contains('Linux / Android')) {
      deviceType = 'Android Phone';
      reasoning.add('Huawei MAC + Android TTL → Android Phone');
      score += 20;
    }
  }

  if (macLower.contains('xiaomi')) {
    brandGuess = 'Xiaomi';
    if (osGuess.contains('Linux / Android')) {
      deviceType = 'Android Phone';
      reasoning.add('Xiaomi MAC + Android TTL → Android Phone');
      score += 20;
    }
  }

  // ─ 6b. US Home Appliance brand + SSDP/mDNS/hostname signals ─────────
  // Smart appliances (Samsung Family Hub, LG ThinQ, Whirlpool, GE SmartHQ,
  // Electrolux, Miele, iRobot) don't open standard TCP ports but advertise
  // via UPnP/SSDP and mDNS. We detect them by combining MAC vendor with
  // any available name/model signals.
  {
    const applianceMfrs = [
      'whirlpool', 'ge appliances', 'maytag', 'kitchenaid', 'ge appliance',
      'electrolux', 'frigidaire', 'haier', 'midea', 'miele',
      'bsh', 'sub-zero', 'wolf', 'rheem', 'a.o. smith', 'ao smith',
      'carrier', 'trane', 'lennox', 'irobot', 'smartthings',
    ];
    final isApplianceBrand =
        applianceMfrs.any((m) => macLower.contains(m));
    // Also detect Samsung/LG when not phone/TV (no Android TTL, no port 8001)
    final isSamsungAppliance = macLower.contains('samsung') &&
        !osGuess.contains('Linux / Android') &&
        !openPorts.contains(8001) &&
        deviceType != 'Samsung Smart TV' &&
        deviceType != 'Android Phone';
    final isLgAppliance = macLower.contains('lg') &&
        deviceType == 'Unknown';

    if (isApplianceBrand || isSamsungAppliance || isLgAppliance) {
      // Build combined signal from all available SSDP + hostname fields
      final allSignals = [
        ssdpFriendlyName,
        ssdpModelName,
        ssdpModelNumber,
        ssdpManufacturer,
        hostname,
        netbiosName,
        currentCategory,
      ].whereType<String>().join(' ').toLowerCase();

      final applianceKeywords = <String, String>{
        'refriger': 'Refrigerator',
        'fridge': 'Refrigerator',
        'family hub': 'Refrigerator',
        'french door': 'Refrigerator',
        'side-by-side': 'Refrigerator',
        'washer': 'Washer',
        'washing': 'Washer',
        'front load': 'Washer',
        'top load': 'Washer',
        'laundry': 'Washer',
        'dryer': 'Dryer',
        'dishwash': 'Dishwasher',
        'oven': 'Oven / Range',
        'range': 'Range / Stove',
        'stove': 'Range / Stove',
        'cooktop': 'Cooktop',
        'microwave': 'Microwave',
        'freezer': 'Freezer',
        'hvac': 'HVAC System',
        'air cond': 'Air Conditioner',
        'heat pump': 'Heat Pump',
        'furnace': 'Furnace',
        'water heat': 'Water Heater',
        'econet': 'Water Heater',
        'roomba': 'Robot Vacuum',
        'irobot': 'Robot Vacuum',
        'thinq': 'LG Appliance',
        'smarthq': 'GE Appliance',
        'icomfort': 'HVAC System',
        'comfortlink': 'HVAC System',
        'infinity': 'HVAC System',
      };

      for (final entry in applianceKeywords.entries) {
        if (allSignals.contains(entry.key)) {
          deviceType = entry.value;
          if (isSamsungAppliance && brandGuess.isEmpty) brandGuess = 'Samsung';
          if (isLgAppliance && brandGuess.isEmpty) brandGuess = 'LG';
          reasoning.add(
            'Appliance brand + signal "${entry.key}" → ${entry.value}',
          );
          score += 30;
          break;
        }
      }

      // If brand is known appliance but type still unresolved, mark as Smart Appliance
      if ((deviceType == 'Unknown' || deviceType.isEmpty) &&
          (isApplianceBrand || isSamsungAppliance || isLgAppliance)) {
        final brandName = isSamsungAppliance
            ? 'Samsung'
            : isLgAppliance
                ? 'LG'
                : (manufacturer ?? '');
        deviceType = '$brandName Appliance';
        if (brandGuess.isEmpty) brandGuess = brandName;
        reasoning.add('Known appliance brand "$brandName" → Smart Appliance');
        score += 15;
      }
    }
  }

  // ─ 7. Port combination rules (high-confidence overrides) ─────────────
  if (openPorts.contains(62078)) {
    deviceType = 'iPhone / iPad';
    brandGuess = 'Apple';
    reasoning.add(
      'iOS Lockdown port 62078 → iPhone / iPad (highest confidence)',
    );
    score += 35;
  }

  if (openPorts.contains(5555)) {
    deviceType = 'Android Device';
    reasoning.add('ADB over TCP (port 5555) → Android Device');
    score += 30;
  }

  if (openPorts.contains(9100) ||
      openPorts.contains(515) ||
      openPorts.contains(631)) {
    deviceType = 'Printer';
    final printerPorts = openPorts
        .where((p) => [9100, 515, 631, 9197].contains(p))
        .toList();
    reasoning.add('Printer port(s) [${printerPorts.join(', ')}] → Printer');
    score += 25;
  }

  if (openPorts.contains(554)) {
    deviceType = 'IP Camera';
    reasoning.add('RTSP port 554 → IP Camera / CCTV');
    score += 25;
  }

  if ((openPorts.contains(445) || openPorts.contains(135)) &&
      (osGuess.contains('Windows') || openPorts.contains(3389))) {
    deviceType = 'Windows PC';
    reasoning.add('SMB/RPC port + Windows signals → Windows PC');
    score += 25;
  }

  if (openPorts.contains(8009) || openPorts.contains(8008)) {
    deviceType = 'Chromecast';
    brandGuess = 'Google';
    reasoning.add(
      'Chromecast port ${openPorts.contains(8009) ? 8009 : 8008} → Chromecast',
    );
    score += 28;
  }

  if (openPorts.contains(1400)) {
    deviceType = 'Sonos Speaker';
    brandGuess = 'Sonos';
    reasoning.add('Sonos port 1400 → Sonos Speaker');
    score += 28;
  }

  if (openPorts.contains(8060)) {
    deviceType = 'Roku Player';
    brandGuess = 'Roku';
    reasoning.add('Roku ECP port 8060 → Roku Player');
    score += 30;
  }

  if (openPorts.contains(8001)) {
    deviceType = 'Samsung Smart TV';
    if (brandGuess.isEmpty) brandGuess = 'Samsung';
    reasoning.add('Samsung Smart TV API port 8001 → Samsung Smart TV');
    score += 28;
  }

  if (openPorts.contains(8123)) {
    deviceType = 'Home Assistant Hub';
    reasoning.add('Home Assistant port 8123 → Smart Home Hub');
    score += 30;
  }

  // ─ 7b. Appliance port rules (+18–30) ──────────────────────────────────
  if (openPorts.contains(2878)) {
    deviceType = 'LG ThinQ Appliance';
    brandGuess = 'LG';
    reasoning.add('LG ThinQ local API port 2878 → LG ThinQ Smart Appliance');
    score += 30;
  }
  if (openPorts.contains(7677) || openPorts.contains(7676)) {
    if (deviceType == 'Unknown' || deviceType.isEmpty) {
      deviceType = 'LG ThinQ Appliance';
      brandGuess = 'LG';
    }
    reasoning.add('LG IoT port ${openPorts.contains(7677) ? 7677 : 7676} → LG Smart Device');
    score += 22;
  }
  if (openPorts.contains(55000)) {
    if (deviceType == 'Unknown' || deviceType.isEmpty) {
      deviceType = 'GE Appliance';
      brandGuess = 'GE Appliances';
    }
    reasoning.add('GE WiFi module port 55000 → GE Smart Appliance');
    score += 22;
  }
  if (openPorts.contains(4999)) {
    if (deviceType == 'Unknown' || deviceType.isEmpty) {
      deviceType = 'Robot Vacuum';
    }
    reasoning.add('Port 4999 → iRobot / Roborock robot vacuum relay');
    score += 18;
  }

  // ─ 8. SNMP sysDescr ─────────────────────────────────────────────────
  if (snmpDescr != null && snmpDescr.isNotEmpty) {
    final sysD = snmpDescr.toLowerCase();
    if (sysD.contains('windows')) {
      deviceType = 'Windows PC';
      osGuess = 'Windows';
      reasoning.add('SNMP sysDescr → Windows');
      score += 30;
    } else if (sysD.contains('ios') && sysD.contains('cisco')) {
      deviceType = 'Cisco Router';
      osGuess = 'Cisco IOS';
      if (brandGuess.isEmpty) brandGuess = 'Cisco';
      reasoning.add('SNMP sysDescr → Cisco IOS Router');
      score += 30;
    } else if (sysD.contains('linux')) {
      if (osGuess.isEmpty) osGuess = 'Linux';
      reasoning.add('SNMP sysDescr → Linux OS');
      score += 20;
    } else if (sysD.contains('synology')) {
      deviceType = 'Synology NAS';
      brandGuess = 'Synology';
      score += 30;
    }
  }

  // ─ 9. HTTP banner ───────────────────────────────────────────────────
  if (httpBanner != null && httpBanner.isNotEmpty) {
    final b = httpBanner.toLowerCase();
    if (b.contains('hikvision')) {
      deviceType = 'IP Camera';
      brandGuess = 'Hikvision';
      score += 25;
    } else if (b.contains('dahua')) {
      deviceType = 'IP Camera';
      brandGuess = 'Dahua';
      score += 25;
    } else if (b.contains('synology')) {
      deviceType = 'Synology NAS';
      brandGuess = 'Synology';
      score += 25;
    }
    reasoning.add(
      'HTTP banner "${httpBanner.length > 40 ? httpBanner.substring(0, 40) : httpBanner}" → $deviceType',
    );
  }

  return FingerprintResult(
    deviceType: deviceType.isEmpty ? 'Unknown' : deviceType,
    brandGuess: brandGuess,
    osGuess: osGuess,
    confidenceScore: score.clamp(0, 100),
    reasoning: reasoning,
  );
}
