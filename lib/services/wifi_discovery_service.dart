import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'api_client.dart';
import 'device_fingerprint_engine.dart' as fp_engine;

// ─────────────────────────────────────────────────────────────────────────────
// WiFi Discovery Service — Production Implementation
//
// How it works (simple explanation for terminal/log output):
//
//   LAYER 0 — Subnet Scan (finds ANY device on the WiFi)
//   1. Gets your phone's IP address (e.g. 192.168.1.105)
//   2. Quickly tries connecting to every IP in 192.168.1.1–254
//   3. If a device responds on common ports (80, 443, 8080, 554, 9197)
//      → it's alive on the network!
//   4. This finds ALL devices — even ones that don't support UPnP or mDNS
//
//   LAYER 1 — UPnP/SSDP (Smart TVs, Printers, Media Players)
//   1. Acquires Android MulticastLock (REQUIRED — without this Android
//      silently drops all multicast/broadcast UDP responses!)
//   2. Broadcasts M-SEARCH x3 on WiFi (UDP 239.255.255.250:1900)
//   3. Smart devices respond with their XML description URL
//   4. Fetches XML → parses brand, model, serial
//
//   LAYER 2 — mDNS/Bonjour (Apple TV, Chromecast, Sonos)
//   1. Sends DNS-SD queries to 224.0.0.251:5353
//   2. Devices advertising services respond with names
//
//   LAYER 3 — Backend Enrichment (optional)
//   1. Sends discovered device list to backend
//   2. Backend enriches with MAC vendor DB
//
// KEY FIX: Android MulticastLock — without this, Android's WiFi power
// saving mode silently drops ALL multicast/broadcast UDP packets,
// so UPnP and mDNS would find 0 devices.
// ─────────────────────────────────────────────────────────────────────────────

/// Holds a single log entry for display in the UI debug panel.
class DiscoveryLogEntry {
  final DateTime timestamp;
  final String layer; // 'NET', 'UPnP', 'mDNS', 'Enrich', 'Filter', 'SYSTEM'
  final String message;
  final String? detail;

  const DiscoveryLogEntry({
    required this.timestamp,
    required this.layer,
    required this.message,
    this.detail,
  });

  @override
  String toString() =>
      '[${timestamp.toIso8601String().substring(11, 19)}] [$layer] $message'
      '${detail != null ? '\n    $detail' : ''}';
}

/// Represents a single device discovered on the local WiFi network.
class WifiDevice {
  final String ipAddress;
  final String? macAddress;
  final String manufacturer;
  final String deviceName;
  final String?
  hostname; // reverse-DNS hostname (e.g. "ASUS-LAPTOP", "DESKTOP-ABC")
  final String? modelNumber;
  final String? serialNumber;
  final String deviceTypeRaw;
  final String deviceCategory;
  final IconCategory iconCategory;
  final int confidenceScore; // 0–100
  final String discoveryMethod; // 'subnet', 'upnp', 'mdns', 'both'
  final List<int> openPorts;

  /// Data returned from the backend /discovery/lookup endpoint.
  /// Non-null means the backend has a stored record for this device.
  final Map<String, dynamic>? backendData;

  /// HTTP Server: header captured during Layer 5 banner grab.
  final String? httpBanner;

  /// HTML <title> captured during Layer 5 banner grab.
  final String? htmlTitle;

  /// OS/platform hint derived from ICMP TTL value (FIX 5).
  /// e.g. "Linux / macOS / Android / iOS", "Windows", "Network equipment"
  final String? osHint;

  /// SSH version string (e.g. "SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.4").
  final String? sshBanner;

  /// TLS certificate Subject CN (e.g. "HP LaserJet M404n", "synology.local").
  final String? tlsCertSubject;

  /// Firmware / software version extracted from service banners or APIs.
  final String? firmwareVersion;

  /// Per-port service version strings (e.g. {22: 'OpenSSH_8.9', 554: 'RTSP/1.0'}).
  final Map<int, String> serviceVersions;

  /// OS version from SMB negotiation (e.g. "Windows 10.0", "Samba 4.15").
  final String? smbOsVersion;

  /// Product image URL returned by backend enrichment (SerpAPI only).
  final String? productImageUrl;

  /// Human-readable product name returned by backend enrichment.
  final String? productName;

  /// Raw ICMP TTL value captured during ping sweep (used for OS fingerprinting).
  final int? ttlValue;

  /// Normalized DHCP hostname (stripped of .local suffix).
  final String? dhcpHostname;

  /// Human-readable labels for open ports (e.g. ["62078 (iOS Lockdown)", "7000 (AirPlay)"]).
  final List<String> portFingerprint;

  /// Brand/manufacturer guess from fingerprint engine (e.g. "Apple", "Samsung").
  final String? brandGuess;

  /// OS guess from fingerprint engine (e.g. "iOS / macOS", "Windows", "Linux / Android").
  final String? osGuess;

  /// Ordered list of fingerprinting reasoning steps for debugging.
  final List<String> fingerprintReasoning;

  const WifiDevice({
    required this.ipAddress,
    this.macAddress,
    required this.manufacturer,
    required this.deviceName,
    this.hostname,
    this.modelNumber,
    this.serialNumber,
    required this.deviceTypeRaw,
    required this.deviceCategory,
    required this.iconCategory,
    required this.confidenceScore,
    this.discoveryMethod = 'upnp',
    this.openPorts = const [],
    this.backendData,
    this.httpBanner,
    this.htmlTitle,
    this.osHint,
    this.sshBanner,
    this.tlsCertSubject,
    this.firmwareVersion,
    this.serviceVersions = const {},
    this.smbOsVersion,
    this.productImageUrl,
    this.productName,
    this.ttlValue,
    this.dhcpHostname,
    this.portFingerprint = const [],
    this.brandGuess,
    this.osGuess,
    this.fingerprintReasoning = const [],
  });

  /// Maps well-known port numbers to human-readable service names.
  static const _portServiceNames = <int, String>{
    21: 'FTP',
    22: 'SSH',
    23: 'Telnet',
    25: 'SMTP',
    53: 'DNS',
    80: 'HTTP',
    81: 'HTTP',
    110: 'POP3',
    135: 'RPC',
    139: 'NetBIOS',
    143: 'IMAP',
    161: 'SNMP',
    389: 'LDAP',
    443: 'HTTPS',
    445: 'SMB',
    515: 'LPR',
    548: 'AFP',
    554: 'RTSP',
    587: 'SMTP',
    631: 'IPP',
    993: 'IMAPS',
    995: 'POP3S',
    1080: 'SOCKS',
    1400: 'Sonos',
    1883: 'MQTT',
    1900: 'UPnP',
    2049: 'NFS',
    2869: 'UPnP',
    3000: 'Web',
    3306: 'MySQL',
    3389: 'RDP',
    3478: 'STUN',
    3689: 'DAAP',
    5000: 'UPnP',
    5001: 'HTTPS',
    5060: 'SIP',
    5222: 'XMPP',
    5357: 'WSD',
    5432: 'PostgreSQL',
    5900: 'VNC',
    6379: 'Redis',
    7000: 'AirPlay',
    8001: 'Samsung TV',
    8008: 'Chromecast',
    8060: 'Roku',
    8080: 'HTTP',
    8081: 'HTTP',
    8096: 'Jellyfin',
    8123: 'Home Assistant',
    8181: 'HTTP',
    8200: 'DLNA',
    8291: 'Winbox',
    8443: 'HTTPS',
    8834: 'Nessus',
    8888: 'HTTP',
    9000: 'Portainer',
    9090: 'Prometheus',
    9100: 'JetDirect',
    9197: 'WSD Print',
    9200: 'Elasticsearch',
    10000: 'Webmin',
    27017: 'MongoDB',
    32400: 'Plex',
    49152: 'UPnP',
    55443: 'Eufy',
  };

  /// Returns open ports as labeled strings like "22 (SSH)", "80 (HTTP)".
  List<String> get labeledPorts => openPorts.map((p) {
    final name = _portServiceNames[p];
    return name != null ? '$p ($name)' : '$p';
  }).toList();

  /// Returns a summary of the OS / platform based on all available signals.
  String? get detectedOS {
    if (smbOsVersion != null && smbOsVersion!.isNotEmpty) return smbOsVersion;
    // For devices clearly identifiable as Mac, return macOS directly
    final title = displayTitle.toLowerCase();
    if (title.contains('macbook') ||
        title.contains('imac') ||
        title.contains('mac mini') ||
        title.contains('mac pro')) {
      return 'macOS';
    }
    if (osHint != null && osHint!.isNotEmpty) {
      // Simplify combined OS strings — pick the most relevant
      final hint = osHint!;
      if (hint.contains('/') && hint.length > 20) {
        // e.g. "Linux / macOS / Android / iOS" — too broad, skip
        return null;
      }
      return hint;
    }
    if (sshBanner != null) {
      final b = sshBanner!.toLowerCase();
      if (b.contains('ubuntu')) return 'Ubuntu Linux';
      if (b.contains('debian')) return 'Debian Linux';
      if (b.contains('raspbian') || b.contains('raspberry')) {
        return 'Raspberry Pi OS';
      }
      if (b.contains('freebsd')) return 'FreeBSD';
      if (b.contains('darwin') || b.contains('macos')) return 'macOS';
    }
    return null;
  }

  String get displayTitle {
    String decodeEntities(String s) {
      return s
          .replaceAllMapped(
            RegExp(r'&#x([0-9A-Fa-f]+);'),
            (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)),
          )
          .replaceAllMapped(
            RegExp(r'&#(\d+);'),
            (m) => String.fromCharCode(int.parse(m[1]!)),
          )
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&apos;', "'");
    }

    // Sanitize overly technical or generic device names into user-friendly ones
    String friendlyName(String raw) {
      final lower = raw.toLowerCase();
      if (lower == 'network router' || lower == 'network gateway') {
        return 'Router';
      }
      if (lower == 'database server') {
        return 'Computer';
      }
      if (lower == 'dns server') {
        return 'Router';
      }
      if (lower == 'server admin') {
        return 'Computer';
      }
      if (lower == 'iot hub / mqtt broker' || lower == 'iot hub') {
        return 'Smart Device';
      }
      if (lower == 'network device') {
        return 'Device';
      }
      if (lower == 'upnp device') {
        return 'Smart Device';
      }
      return raw;
    }

    if (deviceName.isNotEmpty &&
        deviceName != 'Unknown' &&
        !deviceName.startsWith('Device at ')) {
      return friendlyName(decodeEntities(deviceName));
    }
    if (hostname != null && hostname!.isNotEmpty) {
      return friendlyName(decodeEntities(hostname!));
    }
    if (manufacturer.isNotEmpty && manufacturer != 'Unknown') {
      // Include category for context: "Samsung Phone / Tablet" instead of just "Samsung"
      if (deviceCategory.isNotEmpty &&
          deviceCategory != 'Network Device' &&
          !deviceCategory.toLowerCase().contains(manufacturer.toLowerCase())) {
        return '$manufacturer $deviceCategory';
      }
      return manufacturer;
    }
    // Use identified category (e.g. "iPhone / iPad", "Smart TV") before raw IP
    if (deviceCategory.isNotEmpty &&
        deviceCategory != 'Network Device' &&
        deviceCategory != 'Unknown') {
      return deviceCategory;
    }
    return 'Device at $ipAddress';
  }

  String get displaySubtitle {
    final parts = <String>[];
    if (manufacturer.isNotEmpty &&
        manufacturer != 'Unknown' &&
        manufacturer != displayTitle) {
      parts.add(manufacturer);
    }
    if (modelNumber != null && modelNumber!.isNotEmpty) {
      parts.add(modelNumber!);
    }
    if (hostname != null && hostname!.isNotEmpty && hostname != displayTitle) {
      parts.add(hostname!);
    }
    parts.add(ipAddress);
    if (macAddress != null && macAddress!.isNotEmpty) {
      parts.add(macAddress!);
    }
    return parts.join(' · ');
  }

  /// Consumer-friendly asset type label shown in the scan result card title.
  /// Maps technical category / icon / ports to a human label like
  /// "TV", "Laptop", "Router", "Fridge", "AC", "Washing Machine", etc.
  String get assetType {
    final cat = deviceCategory.toLowerCase();
    final raw = deviceTypeRaw.toLowerCase();
    final mfr = manufacturer.toLowerCase();
    final hn = (hostname ?? '').toLowerCase();
    final dn = deviceName.toLowerCase();
    // Also check displayTitle for merged devices where deviceName may be empty
    final dt = displayTitle.toLowerCase();

    // ── Home appliances (smart / connected) ──────────────────────────────
    if (raw.contains('washing') ||
        dn.contains('washing') ||
        hn.contains('washing') ||
        cat.contains('washer') ||
        cat == 'washer') {
      return 'Washing Machine';
    }
    if (raw.contains('dishwash') ||
        dn.contains('dishwash') ||
        hn.contains('dishwash') ||
        cat.contains('dishwasher')) {
      return 'Dishwasher';
    }
    if (raw.contains('refriger') ||
        raw.contains('fridge') ||
        dn.contains('fridge') ||
        hn.contains('fridge') ||
        dn.contains('refriger') ||
        hn.contains('refriger') ||
        cat.contains('refrigerator') ||
        cat.contains('family hub')) {
      return 'Fridge';
    }
    if (raw.contains('freezer') ||
        dn.contains('freezer') ||
        hn.contains('freezer') ||
        cat == 'freezer') {
      return 'Freezer';
    }
    if (raw.contains('aircond') ||
        raw.contains('air_cond') ||
        raw.contains('hvac') ||
        raw.contains('air cond') ||
        raw.contains('heat pump') ||
        dn.contains('aircond') ||
        hn.contains('aircond') ||
        cat.contains('hvac') ||
        cat.contains('air conditioner') ||
        cat.contains('heat pump')) {
      return 'AC / HVAC';
    }
    if (raw.contains('furnace') ||
        dn.contains('furnace') ||
        cat.contains('furnace') ||
        cat.contains('boiler')) {
      return 'Furnace';
    }
    if (raw.contains('water heat') ||
        dn.contains('water heat') ||
        hn.contains('water heat') ||
        cat.contains('water heater') ||
        cat.contains('econet')) {
      return 'Water Heater';
    }
    if (raw.contains('dryer') ||
        dn.contains('dryer') ||
        hn.contains('dryer') ||
        cat == 'dryer') {
      return 'Dryer';
    }
    if (raw.contains('oven') ||
        dn.contains('oven') ||
        hn.contains('oven') ||
        raw.contains('range') ||
        dn.contains('range') ||
        raw.contains('stove') ||
        dn.contains('stove') ||
        cat.contains('oven') ||
        cat.contains('range') ||
        cat.contains('stove')) {
      return 'Oven / Range';
    }
    if (raw.contains('microwave') ||
        dn.contains('microwave') ||
        cat.contains('microwave')) {
      return 'Microwave';
    }
    if (raw.contains('roomba') ||
        dn.contains('roomba') ||
        hn.contains('roomba') ||
        raw.contains('irobot') ||
        dn.contains('irobot') ||
        cat.contains('robot vacuum')) {
      return 'Robot Vacuum';
    }
    // Generic smart appliance fallback — shown when brand is known but type unclear
    if (cat.contains('appliance') ||
        cat.contains('thinq') ||
        cat.contains('smarthq') ||
        cat.contains('smartthings') ||
        cat.contains('home connect') ||
        cat.contains('miele') ||
        cat.contains('whirlpool appliance') ||
        cat.contains('bsh appliance')) {
      final knownBrands = [
        'Samsung', 'LG', 'Whirlpool', 'GE', 'Maytag', 'KitchenAid',
        'Electrolux', 'Frigidaire', 'Haier', 'Miele', 'Bosch', 'Siemens',
        'Midea', 'Rheem', 'Carrier', 'Trane', 'Lennox', 'iRobot',
      ];
      final matchedBrand = knownBrands.firstWhere(
        (b) => mfr.toLowerCase().contains(b.toLowerCase()),
        orElse: () => '',
      );
      return matchedBrand.isNotEmpty ? '$matchedBrand Appliance' : 'Smart Appliance';
    }

    // ── Computer / Laptop — MUST check before Phone so MacBooks aren't misclassified
    if (cat.contains('windows pc') ||
        cat.contains('mac / apple') ||
        cat.contains('computer') ||
        cat.contains('macbook') ||
        hn.contains('laptop') ||
        hn.contains('notebook') ||
        hn.contains('desktop') ||
        hn.contains('macbook') ||
        dn.contains('laptop') ||
        dn.contains('notebook') ||
        dn.contains('desktop') ||
        dn.contains('macbook') ||
        dn.contains('mac pro') ||
        dn.contains('imac') ||
        dn.contains('mac mini') ||
        dt.contains('macbook') ||
        dt.contains('imac') ||
        dt.contains('mac mini') ||
        dt.contains('mac pro')) {
      return 'Laptop';
    }

    // ── Phone ─────────────────────────────────────────────────────────────
    if (cat.contains('phone') ||
        iconCategory == IconCategory.phone ||
        hn.contains('iphone') ||
        hn.contains('galaxy') ||
        hn.contains('pixel') ||
        hn.contains('android') ||
        hn.contains('oneplus') ||
        hn.contains('redmi') ||
        hn.contains('xiaomi') ||
        hn.contains('poco') ||
        hn.contains('oppo') ||
        hn.contains('vivo') ||
        hn.contains('realme') ||
        hn.contains('nokia-') ||
        hn.contains('moto') ||
        hn.contains('honor') ||
        hn.contains('huawei') ||
        // Samsung phone model prefixes (SM-A = Galaxy A, SM-G = Galaxy S/Note, SM-F = Fold/Flip)
        RegExp(r'^samsung-sm-[agf]').hasMatch(hn) ||
        RegExp(r'^sm-[agf]\d').hasMatch(hn)) {
      return 'Phone';
    }

    // ── Tablet ────────────────────────────────────────────────────────────
    if (cat.contains('tablet') ||
        iconCategory == IconCategory.tablet ||
        hn.contains('ipad') ||
        hn.contains('kindle') ||
        hn.contains('fire-hd') ||
        dn.contains('ipad') ||
        dn.contains('tablet') ||
        // Samsung tablet model prefixes (SM-T / SM-X = Galaxy Tab)
        RegExp(r'^sm-[tx]\d').hasMatch(hn) ||
        RegExp(r'^samsung-sm-[tx]').hasMatch(hn)) {
      return 'Tablet';
    }

    // ── Game Console ──────────────────────────────────────────────────────
    if (cat.contains('game console') ||
        iconCategory == IconCategory.gameConsole ||
        hn.contains('playstation') ||
        hn.contains('ps5') ||
        hn.contains('ps4') ||
        hn.contains('xbox') ||
        hn.contains('nintendo')) {
      return 'Game Console';
    }

    // ── TV & Streaming ────────────────────────────────────────────────────
    if (cat.contains('samsung tv') ||
        cat.contains('smart tv') ||
        cat.contains('streaming') ||
        cat.contains('roku') ||
        cat.contains('chromecast') ||
        cat.contains('airplay') ||
        raw.contains('mediarenderer') ||
        raw.contains('mediaplayer') ||
        raw.contains(':tv')) {
      return 'TV';
    }
    if (iconCategory == IconCategory.tv) {
      return 'TV';
    }
    if (iconCategory == IconCategory.computer) {
      return 'Laptop';
    }
    // ── Home Appliance icon category ──────────────────────────────────────
    if (iconCategory == IconCategory.appliance) {
      // Try to refine from raw / device name
      if (cat.contains('washing') || raw.contains('washing') || dn.contains('washing')) return 'Washing Machine';
      if (cat.contains('dryer')   || raw.contains('dryer')   || dn.contains('dryer'))   return 'Dryer';
      if (cat.contains('refriger') || cat.contains('fridge') ||
          raw.contains('refriger') || raw.contains('fridge') || dn.contains('fridge'))  return 'Refrigerator';
      if (cat.contains('dishwash') || raw.contains('dishwash') || dn.contains('dishwash')) return 'Dishwasher';
      if (cat.contains('oven')  || cat.contains('range') || raw.contains('oven'))       return 'Oven / Range';
      if (cat.contains('micro') || raw.contains('micro'))                                return 'Microwave';
      if (cat.contains('air cond') || cat.contains('aircond') || cat.contains('hvac') ||
          raw.contains('air cond')  || raw.contains('aircond') || raw.contains('hvac')) return 'AC Unit';
      if (cat.contains('robot') || cat.contains('vacuum') || cat.contains('roomba') ||
          raw.contains('robot') || raw.contains('vacuum') || dn.contains('roomba'))     return 'Robot Vacuum';
      if (cat.contains('purif') || raw.contains('purif'))                                return 'Air Purifier';
      if (cat.contains('thermostat'))                                                    return 'Thermostat';
      return 'Smart Appliance';
    }

    // ── Router / Gateway ──────────────────────────────────────────────────
    if (cat.contains('router') ||
        cat.contains('gateway') ||
        cat.contains('network equipment')) {
      return 'Router';
    }
    if (iconCategory == IconCategory.router) {
      return 'Router';
    }

    // ── Printer ───────────────────────────────────────────────────────────
    if (cat.contains('printer') || iconCategory == IconCategory.printer) {
      return 'Printer';
    }

    // ── Security Camera ───────────────────────────────────────────────────
    if (cat.contains('camera') || iconCategory == IconCategory.camera) {
      return 'Security Camera';
    }

    // ── Smart Speaker ─────────────────────────────────────────────────────
    if (cat.contains('speaker') ||
        cat.contains('sonos') ||
        cat.contains('audio') ||
        mfr == 'amazon' ||
        cat.contains('amazon') ||
        cat.contains('spotify')) {
      return 'Smart Speaker';
    }
    if (iconCategory == IconCategory.speaker) {
      return 'Smart Speaker';
    }

    // ── Smart Light ───────────────────────────────────────────────────────
    if (cat.contains('light') ||
        cat.contains('hue') ||
        iconCategory == IconCategory.lightBulb) {
      return 'Smart Light';
    }

    // ── Thermostat ────────────────────────────────────────────────────────
    if (cat.contains('thermostat') || iconCategory == IconCategory.thermostat) {
      return 'Thermostat';
    }

    // ── Smart Plug ────────────────────────────────────────────────────────
    if (cat.contains('plug') ||
        cat.contains('energy') ||
        iconCategory == IconCategory.smartPlug) {
      return 'Smart Plug';
    }

    // ── NAS / Storage ─────────────────────────────────────────────────────
    if (cat.contains('nas') || cat.contains('storage')) return 'NAS Drive';

    // ── Smart Hub (Home Assistant / Google Nest) ──────────────────────────
    if (cat.contains('home assistant') ||
        cat.contains('homekit') ||
        mfr == 'google' ||
        cat.contains('google') ||
        cat.contains('nest')) {
      return 'Smart Hub';
    }

    // ── Apple Device (unresolved — could be phone / tablet / Mac) ────────
    if (mfr == 'apple' || cat.contains('apple')) return 'Apple Device';

    // ── Manufacturer-based fallback ──────────────────────────────────────
    // When we know the brand but not the type, label it "[Brand] Device"
    // rather than the generic "Smart Device".
    if (manufacturer.isNotEmpty &&
        manufacturer != 'Unknown' &&
        manufacturer != 'Mobile Device') {
      return '$manufacturer Device';
    }

    // ── TTL / OS hint fallback ───────────────────────────────────────────
    // When no other signal identified the device, use OS guess from TTL
    // or the backend fingerprint engine to show a better label than just
    // "Unknown Device".
    final os = (osGuess ?? osHint ?? '').toLowerCase();
    if (os.isNotEmpty) {
      if (os.contains('windows')) return 'Windows Device';
      if (os.contains('android') || os.contains('linux')) {
        return 'Android / Linux Device';
      }
      if (os.contains('ios') || os.contains('macos')) return 'Apple Device';
      if (os.contains('router') || os.contains('network')) {
        return 'Network Device';
      }
    }
    // Raw TTL fallback when no osHint/osGuess was set
    if (ttlValue != null && ttlValue! > 0) {
      if (ttlValue! >= 200) return 'Network Device';
      if (ttlValue! >= 125 && ttlValue! <= 130) return 'Windows Device';
      if (ttlValue! >= 60 && ttlValue! <= 65) return 'Android / Linux Device';
      if (ttlValue! >= 55 && ttlValue! < 60) return 'Apple Device';
    }

    return 'Unknown Device';
  }

  Map<String, dynamic> toJson() => {
    'ipAddress': ipAddress,
    'macAddress': macAddress,
    'manufacturer': manufacturer,
    'deviceName': deviceName,
    'hostname': hostname,
    'modelNumber': modelNumber,
    'serialNumber': serialNumber,
    'deviceTypeRaw': deviceTypeRaw,
    'deviceCategory': deviceCategory,
    'confidenceScore': confidenceScore,
    'discoveryMethod': discoveryMethod,
    'openPorts': openPorts,
    if (httpBanner != null) 'httpBanner': httpBanner,
    if (htmlTitle != null) 'htmlTitle': htmlTitle,
    if (osHint != null) 'osHint': osHint,
    if (sshBanner != null) 'sshBanner': sshBanner,
    if (tlsCertSubject != null) 'tlsCertSubject': tlsCertSubject,
    if (firmwareVersion != null) 'firmwareVersion': firmwareVersion,
    if (serviceVersions.isNotEmpty)
      'serviceVersions': serviceVersions.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
    if (smbOsVersion != null) 'smbOsVersion': smbOsVersion,
    if (productImageUrl != null) 'productImageUrl': productImageUrl,
    if (productName != null) 'productName': productName,
    if (ttlValue != null) 'ttl': ttlValue,
    if (dhcpHostname != null) 'dhcpHostname': dhcpHostname,
    if (portFingerprint.isNotEmpty) 'portFingerprint': portFingerprint,
    if (brandGuess != null) 'brandGuess': brandGuess,
    if (osGuess != null) 'osGuess': osGuess,
    if (fingerprintReasoning.isNotEmpty)
      'fingerprintReasoning': fingerprintReasoning,
  };

  WifiDevice copyWithEnrichment({
    String? manufacturer,
    String? hostname,
    String? modelNumber,
    String? serialNumber,
    String? deviceName,
    String? macAddress,
    String? deviceCategory,
    IconCategory? iconCategory,
    int? confidenceScore,
    Map<String, dynamic>? backendData,
    String? httpBanner,
    String? htmlTitle,
    String? osHint,
    String? sshBanner,
    String? tlsCertSubject,
    String? firmwareVersion,
    Map<int, String>? serviceVersions,
    String? smbOsVersion,
    String? productImageUrl,
    String? productName,
    int? ttlValue,
    String? dhcpHostname,
    List<String>? portFingerprint,
    String? brandGuess,
    String? osGuess,
    List<String>? fingerprintReasoning,
  }) {
    return WifiDevice(
      ipAddress: ipAddress,
      macAddress: macAddress ?? this.macAddress,
      manufacturer: manufacturer ?? this.manufacturer,
      deviceName: deviceName ?? this.deviceName,
      hostname: hostname ?? this.hostname,
      modelNumber: modelNumber ?? this.modelNumber,
      serialNumber: serialNumber ?? this.serialNumber,
      deviceTypeRaw: deviceTypeRaw,
      deviceCategory: deviceCategory ?? this.deviceCategory,
      iconCategory: iconCategory ?? this.iconCategory,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      discoveryMethod: discoveryMethod,
      openPorts: openPorts,
      backendData: backendData ?? this.backendData,
      httpBanner: httpBanner ?? this.httpBanner,
      htmlTitle: htmlTitle ?? this.htmlTitle,
      osHint: osHint ?? this.osHint,
      sshBanner: sshBanner ?? this.sshBanner,
      tlsCertSubject: tlsCertSubject ?? this.tlsCertSubject,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      serviceVersions: serviceVersions ?? this.serviceVersions,
      smbOsVersion: smbOsVersion ?? this.smbOsVersion,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      productName: productName ?? this.productName,
      ttlValue: ttlValue ?? this.ttlValue,
      dhcpHostname: dhcpHostname ?? this.dhcpHostname,
      portFingerprint: portFingerprint ?? this.portFingerprint,
      brandGuess: brandGuess ?? this.brandGuess,
      osGuess: osGuess ?? this.osGuess,
      fingerprintReasoning: fingerprintReasoning ?? this.fingerprintReasoning,
    );
  }

  @override
  String toString() =>
      'WifiDevice($deviceName, $manufacturer, model=$modelNumber, ip=$ipAddress, via=$discoveryMethod)';
}

enum IconCategory {
  tv,
  speaker,
  printer,
  router,
  camera,
  smartPlug,
  lightBulb,
  thermostat,
  computer,
  phone,
  tablet,
  gameConsole,
  appliance,   // home appliances: washer, dryer, fridge, dishwasher, oven, AC, etc.
  generic,
}

/// Result container returned by [WifiDiscoveryService.startDiscovery]
class WifiDiscoveryResult {
  final List<WifiDevice> devices;
  final String? networkName;
  final String? localIp;
  final String? gatewayIp;
  final String? error;
  final List<DiscoveryLogEntry> logs;

  const WifiDiscoveryResult({
    required this.devices,
    this.networkName,
    this.localIp,
    this.gatewayIp,
    this.error,
    this.logs = const [],
  });

  bool get hasDevices => devices.isNotEmpty;
  bool get hasError => error != null;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Main Service
// ═══════════════════════════════════════════════════════════════════════════════

class WifiDiscoveryService {
  static const _platform = MethodChannel('com.301io.homeiq/wifi');

  /// Devices found by Layer 0 (ARP/ping sweep), shared so Layer 2 (mDNS)
  /// can match hostnames to IPs when A records are missing.
  List<WifiDevice> _layer0Devices = [];

  // UPnP config
  static const String _ssdpMulticast = '239.255.255.250';
  static const int _ssdpPort = 1900;
  static const Duration _ssdpTimeout = Duration(seconds: 2); // FAST: 5s → 2s
  static const Duration _httpTimeout = Duration(seconds: 1); // FAST: 3s → 1s

  // M-SEARCH packet
  static const String _msearchPacket =
      'M-SEARCH * HTTP/1.1\r\n'
      'HOST: 239.255.255.250:1900\r\n'
      'MAN: "ssdp:discover"\r\n'
      'MX: 3\r\n'
      'ST: ssdp:all\r\n'
      '\r\n';

  // UPnP sub-device types that are virtual WAN adapters, not physical devices.
  // These are duplicate XML entries within a router's UPnP tree — the router
  // itself already shows up via ARP. We skip these technical sub-entries only.
  static const _skipDeviceTypes = [
    'internetgatewaydevice',
    'wandevice',
    'wanconnectiondevice',
  ];

  // mDNS service types to look for
  static const List<_MdnsServiceType> _mdnsServiceTypes = [
    _MdnsServiceType('_airplay._tcp', 'Apple Device', IconCategory.computer),
    // iPhone/iPad-exclusive services — highest-confidence mobile signals
    _MdnsServiceType(
      '_apple-mobdev2._tcp',
      'iPhone / iPad',
      IconCategory.phone,
    ),
    _MdnsServiceType(
      '_rdlink._tcp',
      'iPhone / iPad (AirDrop)',
      IconCategory.phone,
    ),
    _MdnsServiceType(
      '_device-info._tcp',
      'Apple Device Info',
      IconCategory.generic,
    ),
    _MdnsServiceType(
      '_googlecast._tcp',
      'Chromecast / Google TV',
      IconCategory.tv,
    ),
    _MdnsServiceType('_sonos._tcp', 'Sonos Speaker', IconCategory.speaker),
    _MdnsServiceType(
      '_spotify-connect._tcp',
      'Spotify Device',
      IconCategory.speaker,
    ),
    _MdnsServiceType('_raop._tcp', 'AirPlay Audio', IconCategory.speaker),
    _MdnsServiceType('_ipp._tcp', 'Network Printer', IconCategory.printer),
    _MdnsServiceType('_printer._tcp', 'Printer', IconCategory.printer),
    _MdnsServiceType('_hap._tcp', 'HomeKit Device', IconCategory.generic),
    _MdnsServiceType('_hue._tcp', 'Philips Hue', IconCategory.lightBulb),
    _MdnsServiceType(
      '_smartenergy._tcp',
      'Smart Energy Device',
      IconCategory.smartPlug,
    ),
    _MdnsServiceType('_http._tcp', 'Web Device', IconCategory.generic),
    _MdnsServiceType('_smb._tcp', 'Network Storage', IconCategory.generic),
    // GAP fixes: additional service types
    _MdnsServiceType(
      '_daap._tcp',
      'iTunes Library (Mac)',
      IconCategory.generic,
    ),
    _MdnsServiceType(
      '_afpovertcp._tcp',
      'Mac / NAS (AFP)',
      IconCategory.generic,
    ),
    _MdnsServiceType(
      '_workstation._tcp',
      'Linux / Mac Computer',
      IconCategory.computer,
    ),
    _MdnsServiceType(
      '_companion-link._tcp',
      'iPhone / iPad (Continuity)',
      IconCategory.phone,
    ),
    // Additional iPhone/iPad-exclusive mDNS services
    _MdnsServiceType('_apple-mobdev._tcp', 'iPhone / iPad', IconCategory.phone),
    _MdnsServiceType(
      '_apple-pairable._tcp',
      'iPhone / iPad (Pairing)',
      IconCategory.phone,
    ),
    _MdnsServiceType(
      '_continuity._tcp',
      'iPhone / iPad (Continuity)',
      IconCategory.phone,
    ),
    _MdnsServiceType(
      '_matter._tcp',
      'Matter Smart Home Device',
      IconCategory.smartPlug,
    ),
    // ── Home Appliances ───────────────────────────────────────────────────────
    _MdnsServiceType('_thinq._tcp',         'LG ThinQ Appliance',   IconCategory.appliance),
    _MdnsServiceType('_thinq2._tcp',        'LG ThinQ Appliance',   IconCategory.appliance),
    _MdnsServiceType('_lge-tv._tcp',        'LG Smart TV',          IconCategory.tv),
    _MdnsServiceType('_home-connect._tcp',  'BSH Appliance',        IconCategory.appliance),
    _MdnsServiceType('_homeconnect._tcp',   'BSH Appliance',        IconCategory.appliance),
    _MdnsServiceType('_ge-appliance._tcp',  'GE Appliance',         IconCategory.appliance),
    _MdnsServiceType('_irobot._tcp',        'Robot Vacuum',         IconCategory.appliance),
    _MdnsServiceType('_robot._tcp',         'Robot Vacuum',         IconCategory.appliance),
    _MdnsServiceType('_roborock._tcp',      'Robot Vacuum',         IconCategory.appliance),
    _MdnsServiceType('_dyson_mqtt._tcp',    'Dyson Device',         IconCategory.appliance),
    _MdnsServiceType('_dyson._tcp',         'Dyson Device',         IconCategory.appliance),
    _MdnsServiceType('_miele._tcp',         'Miele Appliance',      IconCategory.appliance),
    _MdnsServiceType('_smartthings._tcp',   'SmartThings Hub',      IconCategory.generic),
    _MdnsServiceType('_ecobee._tcp',        'Smart Thermostat',     IconCategory.thermostat),
    _MdnsServiceType('_nest._tcp',          'Smart Thermostat',     IconCategory.thermostat),
    _MdnsServiceType('_sensibo._tcp',       'Air Conditioner',      IconCategory.appliance),
    _MdnsServiceType('_airassistant._tcp',  'Air Purifier',         IconCategory.appliance),
    // ── Additional appliances (unique entries, no duplicates) ──────────────
    _MdnsServiceType('_samsung-connect._tcp', 'Samsung Appliance',  IconCategory.appliance),
    _MdnsServiceType('_smarthq._tcp',         'GE Appliance',       IconCategory.appliance),
    _MdnsServiceType('_whirlpool._tcp',       'Whirlpool Appliance',IconCategory.appliance),
    _MdnsServiceType('_roomba._tcp',          'Robot Vacuum',       IconCategory.appliance),
    _MdnsServiceType('_econet._tcp',          'Water Heater',       IconCategory.appliance),
    _MdnsServiceType('_icomfort._tcp',        'HVAC System',        IconCategory.thermostat),
    _MdnsServiceType('_matter._udp',          'Matter Smart Device',IconCategory.smartPlug),
    _MdnsServiceType('_smartenergy._tcp',     'Smart Energy Device',IconCategory.smartPlug),
  ];

  // Subnet scan ports — common smart device ports
  // Each port maps to a specific device type for better identification:
  //   80/443    = Web interface (printers, cameras, routers, smart devices)
  //   23        = Telnet (many routers, IoT devices)
  //   445       = SMB/CIFS (NAS, Windows PCs)
  //   548       = AFP (Apple file sharing - Macs)
  //   554       = RTSP (IP cameras)
  //   631       = IPP printing protocol
  //   1400      = Sonos speakers
  //   1883      = MQTT broker (OpenHAB, Node-RED, smart hubs, Pi-hole)
  //   1900      = UPnP/SSDP
  //   2869      = UPnP NOTIFY (Windows / Philips Hue)
  //   3000      = Grafana / Gitea / misc dashboards
  //   5000      = UPnP HTTP (many smart devices)
  //   5001      = Synology NAS
  //   5060      = SIP/VoIP phones (Grandstream, Polycom, Cisco)
  //   7000      = AirPlay (Apple TV, Airport)
  //   8001      = Samsung Smart TV
  //   8008      = Chromecast / Google TV
  //   8060      = Roku
  //   8080      = Various IoT web UIs
  //   8096      = Jellyfin media server
  //   8123      = Home Assistant
  //   8443      = Chromecast secure
  //   8888      = Jupyter / misc dashboards
  //   9000      = Portainer / Unifi Video
  //   9100      = Raw printer (HP JetDirect)
  //   9197      = Printer (WSD)
  //   32400     = Plex Media Server
  //   49152     = UPnP (Philips Hue Bridge, Win UPnP)
  //   55443     = Eufy cameras (non-standard local API port)
  // FAST MODE: Reduced port list for faster scanning
  // Only scan essential ports for device identification — removes low-probability ports
  static const _scanPorts = [
    // ── Critical: Web interfaces (most devices listen here) ───────────
    80, 443, 8080, 8443,
    // ── Essential: Service identification ──────────────────────────
    22, 23, 445, 554, 1900, 5000, 8001, 8008, 8060, 8123,
    // ── Home Appliances (most common) ──────────────────────────────
    2878, 7677, 4999,
    // ── Mobile device detection (quick wins) ──────────────────────
    5555, 62078, // Android ADB + iOS Lockdown
  ];

  // Logs
  final List<DiscoveryLogEntry> _logs = [];

  // ─── Log severity helpers ──────────────────────────────────────────────
  static const _kLogBorder = '║';
  static const _kLogSepLight =
      '─────────────────────────────────────────────────────────────────';
  static const _kLogSepHeavy =
      '═════════════════════════════════════════════════════════════════';

  void _log(String layer, String message, [String? detail]) {
    final entry = DiscoveryLogEntry(
      timestamp: DateTime.now(),
      layer: layer,
      message: message,
      detail: detail,
    );
    _logs.add(entry);

    // ── Structured terminal output ───────────────────────────────────────
    // Format: [HH:MM:SS.mmm] [LAYER  ] message
    //         [HH:MM:SS.mmm] [LAYER  ]   ↳ detail (indented)
    final ts = entry.timestamp;
    final timeStr =
        '${ts.hour.toString().padLeft(2, '0')}:'
        '${ts.minute.toString().padLeft(2, '0')}:'
        '${ts.second.toString().padLeft(2, '0')}'
        '.${ts.millisecond.toString().padLeft(3, '0')}';

    // Pad layer tag to 6 chars for alignment
    final layerTag = layer.padRight(6).substring(0, 6);

    // Heavy separator lines get special box-drawing treatment
    if (message.startsWith('═')) {
      debugPrint('$_kLogBorder $timeStr [$layerTag] $_kLogSepHeavy');
      return;
    }
    if (message.startsWith('─')) {
      debugPrint('$_kLogBorder $timeStr [$layerTag] $_kLogSepLight');
      return;
    }

    debugPrint('$_kLogBorder $timeStr [$layerTag] $message');
    if (detail != null && detail.isNotEmpty) {
      debugPrint('$_kLogBorder $timeStr [$layerTag]   ↳ $detail');
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // PERMISSIONS
  // ═════════════════════════════════════════════════════════════════════════

  /// Requests location permission (required on Android 8+ to get WiFi SSID/IP).
  /// On Android 13+ with NEARBY_WIFI_DEVICES, location may not be needed,
  /// but we request it as a reliable fallback for all Android versions.
  /// On web this is a no-op (permission_handler does not support web).
  Future<bool> _ensureLocationPermission() async {
    // Web browsers cannot grant location-for-WiFi permissions via permission_handler
    if (kIsWeb) return true;

    // Check if already granted
    var status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;

    // Request the permission
    _log('SYSTEM', '📍 Requesting location permission...');
    status = await Permission.locationWhenInUse.request();

    if (status.isGranted) return true;

    // If permanently denied, we can't ask again
    if (status.isPermanentlyDenied) {
      _log(
        'SYSTEM',
        '❌ Location permanently denied — user must enable in Settings',
      );
    }

    return false;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═════════════════════════════════════════════════════════════════════════

  Future<WifiDiscoveryResult> startDiscovery({
    void Function(int progress, String message)? onProgress,
  }) async {
    _logs.clear();
    final allDevices = <WifiDevice>[];
    String? ssid;
    String? localIp;
    String? gatewayIp;

    // ── Web is not supported — browsers cannot scan local networks ──────
    if (kIsWeb) {
      return const WifiDiscoveryResult(
        devices: [],
        error:
            'WiFi scanning is not available on web.\n\nTo use this feature, run the HomeIQ app on your Android or iOS device.',
      );
    }

    try {
      _log('SYSTEM', '═══════════════════════════════════════════════════');
      _log('SYSTEM', '🚀 WiFi Asset Discovery STARTED');
      _log(
        'SYSTEM',
        '   Platform: ${Platform.isIOS
            ? 'iOS (TCP sweep, no ICMP/ARP/NetBIOS)'
            : Platform.isAndroid
            ? 'Android (full ICMP + ARP + NetBIOS)'
            : Platform.operatingSystem}',
      );
      _log('SYSTEM', '═══════════════════════════════════════════════════');

      // ── Step 0: Request location permission (required for WiFi info) ───
      onProgress?.call(1, 'Checking permissions...');
      final permissionGranted = await _ensureLocationPermission();
      if (!permissionGranted) {
        _log('SYSTEM', '❌ Location permission denied — cannot get WiFi info');
        return WifiDiscoveryResult(
          devices: const [],
          error:
              'Location permission is required to scan your WiFi network. '
              'Please grant location access in your device settings and try again.',
          logs: List.unmodifiable(_logs),
        );
      }
      _log('SYSTEM', '✅ Location permission granted');

      // ── Step 1: Get WiFi info ────────────────────────────────────────
      onProgress?.call(2, 'Getting network info...');
      try {
        final wifiInfo = await _platform.invokeMethod('getWifiInfo');
        if (wifiInfo is Map) {
          localIp = wifiInfo['ip'] as String?;
          gatewayIp = wifiInfo['gateway'] as String?;
          ssid = wifiInfo['ssid'] as String?;
          final prefix = wifiInfo['prefix'] ?? 24;
          _log('NET', '📶 Connected to WiFi: "$ssid"');
          _log('NET', '📱 Phone IP: $localIp');
          _log('NET', '🌐 Gateway: $gatewayIp (/$prefix)');
        }
      } on Object catch (e) {
        _log(
          'NET',
          '⚠️ Could not get WiFi info via platform channel',
          e.toString(),
        );
        // Fallback: try to find our IP from network interfaces
        try {
          for (final iface in await NetworkInterface.list(
            type: InternetAddressType.IPv4,
          )) {
            for (final addr in iface.addresses) {
              if (!addr.isLoopback &&
                  (addr.address.startsWith('192.168') ||
                      addr.address.startsWith('10.') ||
                      addr.address.startsWith('172.'))) {
                localIp = addr.address;
                break;
              }
            }
            if (localIp != null) break;
          }
          if (localIp != null) {
            _log('NET', '📱 Phone IP (from interface): $localIp');
            gatewayIp = '${localIp.substring(0, localIp.lastIndexOf('.'))}.1';
          }
        } on Object catch (_) {}
      }

      if (localIp == null || localIp == '0.0.0.0') {
        _log('SYSTEM', '❌ Not connected to WiFi!');
        return WifiDiscoveryResult(
          devices: const [],
          error:
              'Not connected to WiFi. Please connect to your WiFi network and try again.',
          logs: List.unmodifiable(_logs),
        );
      }

      // ── MulticastLock — REQUIRED for UPnP/mDNS ───────────────────────
      // Without this Android silently drops ALL multicast/broadcast UDP.
      // UPnP (M-SEARCH) and mDNS both rely on multicast — they find 0
      // devices without this lock held.
      onProgress?.call(5, 'Acquiring multicast lock...');
      bool hasMulticastLock = false;
      try {
        await _platform.invokeMethod('acquireMulticastLock');
        hasMulticastLock = true;
        if (Platform.isAndroid) {
          _log('SYSTEM', '🔓 Android MulticastLock ACQUIRED');
          _log(
            'SYSTEM',
            '   (Without this, Android drops ALL multicast packets!)',
          );
        } else {
          _log('SYSTEM', 'ℹ️ iOS: Multicast managed natively — no lock needed');
        }
      } on Object catch (e) {
        _log(
          'SYSTEM',
          '⚠️ MulticastLock failed — UPnP/mDNS may not work',
          e.toString(),
        );
      }

      try {
        // ── Run ALL 3 layers in parallel for maximum coverage + speed ──
        // Layer 0: ARP + ICMP ping sweep  → finds everything on subnet
        // Layer 1: UPnP/SSDP             → rich device data (name, model, serial)
        // Layer 2: mDNS/Bonjour          → Apple TV, Chromecast, Sonos, HomeKit
        onProgress?.call(8, 'Scanning all devices (parallel)...');
        _log('NET', '───────────────────────────────────────────────────');
        _log('NET', '🚀 Running ALL layers in parallel for maximum coverage');

        final results = await Future.wait([
          // Layer 0: subnet ARP scan
          _runSubnetScan(localIp, onProgress)
              .then((d) {
                _log(
                  'NET',
                  '✅ Layer 0 done: ${d.length} device(s) from subnet scan',
                );
                _layer0Devices = d;
                return d;
              })
              .catchError((e) {
                _log('NET', '⚠️ Layer 0 failed', e.toString());
                return <WifiDevice>[];
              }),

          // Layer 1: UPnP/SSDP
          () async {
            _log('UPnP', '───────────────────────────────────────────────────');
            _log('UPnP', '📡 LAYER 1: UPnP/SSDP Discovery');
            _log(
              'UPnP',
              '   Sending M-SEARCH broadcast x3 to $_ssdpMulticast:$_ssdpPort',
            );
            final d = await _runUpnpDiscovery(onProgress);
            _log('UPnP', '✅ Layer 1 done: ${d.length} device(s) via UPnP');
            return d;
          }().catchError((e) {
            _log('UPnP', '⚠️ Layer 1 failed', e.toString());
            return <WifiDevice>[];
          }),

          // Layer 2: mDNS/Bonjour
          () async {
            _log('mDNS', '───────────────────────────────────────────────────');
            _log('mDNS', '📢 LAYER 2: mDNS/Bonjour (DNS-SD)');
            _log(
              'mDNS',
              '   Querying ${_mdnsServiceTypes.length} service types',
            );
            final d = await _runMdnsDiscovery(onProgress);
            _log('mDNS', '✅ Layer 2 done: ${d.length} device(s) via mDNS');
            return d;
          }().catchError((e) {
            _log('mDNS', '⚠️ Layer 2 failed', e.toString());
            return <WifiDevice>[];
          }),
        ]);

        for (final layerDevices in results) {
          allDevices.addAll(layerDevices);
        }
        _log(
          'NET',
          '📊 Total raw devices across all layers: ${allDevices.length}',
        );

        // ── MERGE & FILTER ───────────────────────────────────────────
        onProgress?.call(85, 'Processing results...');
        _log('Filter', '───────────────────────────────────────────────────');
        _log('Filter', '🔄 Processing ${allDevices.length} discovered devices');

        final filtered = _filterAndRank(allDevices, localIp, gatewayIp);
        _log(
          'Filter',
          '✅ After filtering: ${filtered.length} unique device(s)',
        );

        // ── LAYER 4: SNMP scan (Android only) ─────────────────────────
        // FAST MODE: Skip SNMP to improve speed — most devices are already identified by UPnP/mDNS
        List<WifiDevice> snmpEnriched = filtered;
        // if (Platform.isAndroid) { // DISABLED FOR FAST MODE
        //   onProgress?.call(87, 'SNMP scanning devices...');
        //   try {
        //     final ipsToQuery = filtered
        //         .where((d) => d.ipAddress != 'mDNS')
        //         .map((d) => d.ipAddress)
        //         .toList();
        //     if (ipsToQuery.isNotEmpty) {
        //       final snmpData = await _runSnmpScan(ipsToQuery);
        //       if (snmpData.isNotEmpty) {
        //         snmpEnriched = _applySnmpData(filtered, snmpData);
        //       }
        //     }
        //   } on Object catch (e) {
        //     _log('SNMP', '⚠️ SNMP scan failed (non-critical)', e.toString());
        //   }
        // }

        // ── LAYER 3: Backend Enrichment ───────────────────────────────
        onProgress?.call(90, 'Enriching via backend...');
        List<WifiDevice> enriched;
        try {
          enriched = await _enrichViaBackend(snmpEnriched);
          _log(
            'Enrich',
            '✅ Backend enrichment done: ${enriched.length} device(s)',
          );
        } on Object catch (e) {
          _log('Enrich', '⚠️ Backend enrichment skipped', e.toString());
          enriched = snmpEnriched;
        }

        // ── LAYER 5: Advanced API & HTTP Banner Probing ───────────────
        // FAST MODE: Skip advanced probing to improve speed significantly
        // The UPnP + mDNS discovery is sufficient for most devices
        onProgress?.call(95, 'Finalizing results...');
        List<WifiDevice> finalDevices = enriched;
        // try {
        //   finalDevices = await _runAdvancedProbeLayer(enriched);
        //   _log('L5', '✅ Layer 5 done: ${finalDevices.length} device(s)');
        // } on Object catch (e) {
        //   _log('L5', '⚠️ Layer 5 skipped', e.toString());
        //   finalDevices = enriched;
        // }

        // ── DONE ─────────────────────────────────────────────────────
        onProgress?.call(100, 'Done! Found ${finalDevices.length} device(s)');
        _log('SYSTEM', '═══════════════════════════════════════════════════');
        _log(
          'SYSTEM',
          '✅ DISCOVERY COMPLETE: ${finalDevices.length} device(s)',
        );
        for (final d in finalDevices) {
          _log(
            'SYSTEM',
            '   📦 ${d.displayTitle} — ${d.deviceCategory} @ ${d.ipAddress}',
            'Brand: ${d.manufacturer}, Model: ${d.modelNumber ?? "N/A"}, '
                'MAC: ${d.macAddress ?? "N/A"}, Hostname: ${d.hostname ?? "N/A"}, '
                'Serial: ${d.serialNumber ?? "N/A"}, Score: ${d.confidenceScore}'
                '${d.httpBanner != null ? ", Banner: ${d.httpBanner}" : ""}',
          );
        }
        _log('SYSTEM', '═══════════════════════════════════════════════════');

        // Register scan to backend for history tracking (fire-and-forget)
        unawaited(
          _registerScanToBackend(
            finalDevices,
            ssid: ssid,
            localIp: localIp,
            gatewayIp: gatewayIp,
          ),
        );

        return WifiDiscoveryResult(
          devices: finalDevices,
          networkName: ssid,
          localIp: localIp,
          gatewayIp: gatewayIp,
          logs: List.unmodifiable(_logs),
        );
      } finally {
        if (hasMulticastLock) {
          try {
            await _platform.invokeMethod('releaseMulticastLock');
            _log('SYSTEM', '🔒 MulticastLock released');
          } on Object catch (_) {}
        }
      }
    } on SocketException catch (e) {
      _log('SYSTEM', '❌ Socket error', e.toString());
      return WifiDiscoveryResult(
        devices: const [],
        error: _friendlySocketError(e),
        logs: List.unmodifiable(_logs),
      );
    } on Object catch (e) {
      _log('SYSTEM', '❌ Unexpected error', e.toString());
      return WifiDiscoveryResult(
        devices: const [],
        error: 'Scan failed: $e',
        logs: List.unmodifiable(_logs),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 0 — ARP-First Discovery
  //
  // Strategy: Ping sweep → ARP table → TCP port probes on live hosts
  //
  // Why ARP-first?
  // TCP port scanning only finds devices with OPEN ports (servers, routers,
  // smart TVs). But phones, tablets, laptops, IoT sensors etc. have ZERO
  // open ports — they are completely invisible to TCP probes.
  //
  // The ARP table contains the MAC address of EVERY device that recently
  // communicated on the local network. By pinging all IPs first, we force
  // every device to respond (even if briefly), populating the ARP cache.
  // Then we read the ARP table to find ALL devices on the network.
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<WifiDevice>> _runSubnetScan(
    String localIp,
    void Function(int, String)? onProgress,
  ) async {
    final devices = <WifiDevice>[];
    final subnet = localIp.substring(0, localIp.lastIndexOf('.'));

    // ── PHASE 1: Pre-seed ARP (existing cache entries) ─────────────────
    // Read what the kernel already knows BEFORE we sweep — devices the
    // phone has recently talked to are already in the ARP cache.
    _log('NET', '📋 Phase 1a: Pre-seeding from existing ARP cache...');
    final existingArp = await _readArpTable();
    _log(
      'NET',
      '📋 Pre-seed: ${existingArp.length} device(s) already in ARP cache',
    );

    // ── PHASE 1b: Dual-probe sweep ───────────────────────────────────────
    // Android: fires ICMP ping + TCP connect → every live IP ends up in ARP table.
    // iOS:     fires TCP connect only (no raw ICMP) → finds devices by port response.
    if (Platform.isIOS) {
      _log(
        'NET',
        '📡 Phase 1b: TCP connect sweep (iOS — no ICMP) on $subnet.0/24...',
      );
      _log('NET', '   Probing 9 ports × 254 IPs. ECONNREFUSED = host alive.');
    } else {
      _log(
        'NET',
        '📡 Phase 1b: Dual-probe sweep (ICMP + TCP) on $subnet.0/24...',
      );
    }
    onProgress?.call(8, 'Scanning all devices on network...');

    List<String> pingResponders = [];
    final pingTtlMap = <String, int>{}; // ip → TTL (FIX 5: OS detection)
    try {
      final result = await _platform.invokeMethod('pingSweep', {
        'subnet': subnet,
        // timeout param no longer used by native (fixed 1 s ICMP + 600 ms TCP)
        // kept for backwards compat
        'timeout': 600,
      });
      if (result is List) {
        pingResponders = result.cast<String>();
      } else if (result is Map) {
        // New format returned by updated native code: {'ips': [...], 'ttls': {...}}
        final ips = result['ips'];
        final ttls = result['ttls'];
        if (ips is List) pingResponders = ips.cast<String>();
        if (ttls is Map) {
          ttls.forEach((k, v) {
            if (k is String && v is int) pingTtlMap[k] = v;
          });
        }
      }
      _log(
        'NET',
        '✅ Dual-probe sweep: ${pingResponders.length} host(s) responded',
      );
    } on Object catch (e) {
      _log(
        'NET',
        '⚠️ Native ping sweep failed, falling back to TCP scan',
        e.toString(),
      );
    }

    onProgress?.call(
      50,
      '${pingResponders.length} devices found, reading ARP...',
    );

    // ── PHASE 2: Read ARP table (fully populated by the dual-probe sweep) ──
    // The dual-probe (ICMP + TCP) forced an ARP exchange for every live IP,
    // so the kernel ARP table now contains the MAC of EVERY device on the
    // network — including phones/tablets with all ports closed.
    _log('NET', '📋 Phase 2: Reading ARP table post-sweep...');
    final postArp = await _readArpTable();
    _log('NET', '📋 Post-sweep ARP: ${postArp.length} MAC address(es)');

    // Merge pre-seed + post-sweep ARP (post wins on conflict — more current)
    final arpTable = <String, String>{...existingArp, ...postArp};
    _log('NET', '📋 Final ARP table: ${arpTable.length} unique device(s)');

    if (arpTable.isNotEmpty) {
      for (final entry in arpTable.entries) {
        _log('NET', '   ${entry.key} → ${entry.value}');
      }
    }

    // ── Combine: probe responders + entire ARP table ───────────────────
    // Three sources of truth, union of all:
    //   1. pingResponders  — IPs that replied to ICMP or TCP (multi-probe sweep)
    //   2. arpTable        — ALL IPs the kernel saw ARP traffic from
    //   3. existingArp     — already merged into arpTable above
    final allLiveIps = <String>{};
    allLiveIps.addAll(pingResponders);
    allLiveIps.addAll(arpTable.keys);
    // Remove our own IP — we know that's us
    allLiveIps.remove(localIp);

    _log(
      'NET',
      '🔍 Total unique live hosts (pre-port-scan): ${allLiveIps.length}',
    );
    onProgress?.call(
      55,
      'Found ${allLiveIps.length} devices, scanning ports...',
    );

    // ── PHASE 3: TCP port probe on live hosts only ─────────────────────
    // Identifies what KIND of device each IP is (TV, printer, camera…).
    // Devices with no open ports are kept — they're real devices (phones/tablets
    // with all ports closed). They show under their MAC-derived manufacturer name.
    _log(
      'NET',
      '🔌 Phase 3: TCP port scan on ${allLiveIps.length} live host(s)...',
    );
    final liveHosts = <String, List<int>>{}; // ip → open ports

    final ipsToProbe = allLiveIps.toList();
    for (int batch = 0; batch < ipsToProbe.length; batch += 100) { // FAST: 40 → 100
      final end = (batch + 100).clamp(0, ipsToProbe.length);
      final batchIps = ipsToProbe.sublist(batch, end);

      final futures = <Future<void>>[];
      for (final ip in batchIps) {
        futures.add(
          _probeHost(ip).then((openPorts) {
            liveHosts[ip] = openPorts;
          }),
        );
      }

      await Future.wait(futures);

      final pct = 55 + ((batch / ipsToProbe.length) * 25).round();
      onProgress?.call(
        pct,
        'Scanning ports... ${batch + batchIps.length}/${ipsToProbe.length}',
      );
    }

    // ── PHASE 3.5: Second ARP read — catch late-arriving devices ───────
    // Phones in Android Doze / iOS low-power mode can take 1–3 seconds to
    // respond to ARP after the initial sweep. By the time port-scanning
    // finishes those ARP entries have arrived but we haven't read them yet.
    // Reading again here is the single most effective way to find phones.
    _log(
      'NET',
      '📋 Phase 3.5: Re-reading ARP table to catch late responders...',
    );
    final lateArp = await _readArpTable();
    int lateAdded = 0;
    for (final entry in lateArp.entries) {
      // Update MAC if we now have a better (non-null) entry
      if (!arpTable.containsKey(entry.key) || arpTable[entry.key] == null) {
        arpTable[entry.key] = entry.value;
      }
      if (!allLiveIps.contains(entry.key) && entry.key != localIp) {
        allLiveIps.add(entry.key);
        liveHosts[entry.key] =
            []; // no port data yet — will show as unknown device
        lateAdded++;
      }
    }
    if (lateAdded > 0) {
      _log(
        'NET',
        '📋 Late ARP: +$lateAdded new device(s) found after port scan',
      );
    }
    _log('NET', '🔍 Total unique live hosts (final): ${allLiveIps.length}');

    final withPorts = liveHosts.entries.where((e) => e.value.isNotEmpty).length;
    _log(
      'NET',
      '✅ Port scan done: $withPorts device(s) have open ports out of ${liveHosts.length} total',
    );

    // ── PHASE 4: Resolve hostnames — reverse-DNS + NetBIOS in parallel ──
    // Run both in parallel:
    //  • reverse-DNS   → works for all devices registered with the router (DHCP names)
    //  • NetBIOS UDP 137 → gives real Windows computer names even behind firewall
    onProgress?.call(80, 'Resolving device names...');
    _log(
      'NET',
      '🏷️ Phase 4: Hostname Resolution (SKIPPED for performance)',
    );
    
    // FAST MODE: Skip hostname resolution to improve speed (saves 30-60 seconds!)
    // Devices are already identified via UPnP/mDNS/ports, so hostnames are optional.
    final hostnameMap = <String, String>{}; // FAST: empty map, skip DNS
    final netBiosMap = <String, String>{}; // FAST: empty map, skip NetBIOS

    // Merge: NetBIOS name wins over reverse-DNS for Windows PCs
    // (DNS often returns the router-assigned DHCP name like "android-xyz",
    //  while NetBIOS gives the real computer name like "JOHNS-LAPTOP")
    final mergedHostnameMap = <String, String>{
      ...hostnameMap, // DNS first (broader coverage)
      ...netBiosMap, // NetBIOS overwrites when available (more accurate for Windows)
    };

    if (mergedHostnameMap.isNotEmpty) {
      _log(
        'NET',
        '🏷️ Total names resolved: ${mergedHostnameMap.length} '
            '(DNS: ${hostnameMap.length}, NetBIOS: ${netBiosMap.length})',
      );
    }

    // ── PHASE 5: Build device list with all info ───────────────────────
    onProgress?.call(68, 'Identifying ${allLiveIps.length} devices...');
    _log('NET', '🔍 Phase 5: Identifying devices...');

    for (final ip in allLiveIps) {
      final ports = liveHosts[ip] ?? [];

      String deviceName = '';
      String manufacturer = 'Unknown';
      String? modelNumber;
      String? serialNumber;
      String? macAddress = arpTable[ip];
      String? hostname = mergedHostnameMap[ip];

      // Validate hostname — discard if it's just an IP, IP segment, or empty
      // Bug: some resolvers return the IP itself or just the first octet ("192")
      if (hostname != null) {
        final hn = hostname.trim();
        if (hn.isEmpty ||
            hn == ip ||
            RegExp(r'^\d+$').hasMatch(hn) ||
            RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(hn)) {
          _log('NET', '  ⚠️ Discarding invalid hostname "$hostname" for $ip');
          hostname = null;
        }
      }

      String category = ports.isNotEmpty
          ? _guessCategoryFromPorts(ports)
          : 'Network Device';
      IconCategory icon = ports.isNotEmpty
          ? _guessCategoryIconFromPorts(ports)
          : IconCategory.generic;
      int score = 15;
      String deviceType = 'arp-scan';
      bool identified = false;

      // ── FIX 5: TTL-based OS hint ─────────────────────────────────
      String? osHint;
      final ttl = pingTtlMap[ip];
      if (ttl != null && ttl > 0) {
        if (ttl >= 60 && ttl <= 65) {
          osHint = 'Linux / macOS / Android / iOS';
        } else if (ttl >= 125 && ttl <= 130) {
          osHint = 'Windows';
        } else if (ttl == 255) {
          osHint = 'Network equipment (Cisco/router)';
        } else if (ttl >= 30 && ttl <= 35) {
          osHint = 'Legacy Windows';
        }
      }
      // ─────────────────────────────────────────────────────────────

      // Use MAC address for manufacturer identification
      if (macAddress != null) {
        final macVendor = _lookupMacVendor(macAddress);
        if (macVendor != 'Unknown') {
          manufacturer = macVendor;
          score = 30;
        }
        _log('NET', '  📋 $ip → MAC: $macAddress → Vendor: $manufacturer');
      }

      // Use resolved hostname for device identification
      if (hostname != null) {
        _log('NET', '  🏷️ $ip → Hostname: $hostname');
        final hnLower = hostname.toLowerCase();
        if (manufacturer == 'Unknown') {
          if (hnLower.contains('asus')) {
            manufacturer = 'ASUS';
          } else if (hnLower.contains('samsung') ||
              hnLower.contains('galaxy')) {
            manufacturer = 'Samsung';
          } else if (hnLower.contains('apple') ||
              hnLower.contains('iphone') ||
              hnLower.contains('ipad') ||
              hnLower.contains('macbook') ||
              hnLower.contains('imac') ||
              hnLower.contains('airpods') ||
              hnLower.contains('homepod') ||
              hnLower.contains('apple-tv')) {
            manufacturer = 'Apple';
          } else if (hnLower.contains('dell')) {
            manufacturer = 'Dell';
          } else if (hnLower.contains('hp') || hnLower.contains('hewlett')) {
            manufacturer = 'HP';
          } else if (hnLower.contains('lenovo') ||
              hnLower.contains('thinkpad') ||
              hnLower.contains('ideapad')) {
            manufacturer = 'Lenovo';
          } else if (hnLower.contains('google') ||
              hnLower.contains('nest') ||
              hnLower.contains('chromecast') ||
              hnLower.contains('pixel')) {
            manufacturer = 'Google';
          } else if (hnLower.contains('amazon') ||
              hnLower.contains('kindle') ||
              hnLower.contains('echo') ||
              hnLower.contains('fire-tv') ||
              hnLower.contains('firetv')) {
            manufacturer = 'Amazon';
          } else if (hnLower.contains('sony') || hnLower.contains('bravia')) {
            manufacturer = 'Sony';
          } else if (hnLower.contains('lg-') ||
              hnLower.contains('lgwebos') ||
              hnLower.startsWith('lg')) {
            manufacturer = 'LG';
          } else if (hnLower.contains('xbox') || hnLower.contains('surface')) {
            manufacturer = 'Microsoft';
          } else if (hnLower.contains('playstation') ||
              hnLower.contains('ps5') ||
              hnLower.contains('ps4')) {
            manufacturer = 'Sony';
          } else if (hnLower.contains('roku')) {
            manufacturer = 'Roku';
          } else if (hnLower.contains('sonos')) {
            manufacturer = 'Sonos';
          } else if (hnLower.contains('xiaomi') ||
              hnLower.contains('redmi') ||
              hnLower.contains('roborock')) {
            manufacturer = 'Xiaomi';
          } else if (hnLower.contains('oneplus')) {
            manufacturer = 'OnePlus';
          } else if (hnLower.contains('ring-') || hnLower.contains('ring ')) {
            manufacturer = 'Ring';
          } else if (hnLower.contains('wyze')) {
            manufacturer = 'Wyze';
          } else if (hnLower.contains('epson')) {
            manufacturer = 'Epson';
          } else if (hnLower.contains('brother')) {
            manufacturer = 'Brother';
          } else if (hnLower.contains('canon')) {
            manufacturer = 'Canon';
          } else if (hnLower.contains('tplink') ||
              hnLower.contains('tp-link') ||
              hnLower.contains('deco') ||
              hnLower.contains('archer')) {
            manufacturer = 'TP-Link';
          } else if (hnLower.contains('netgear') ||
              hnLower.contains('orbi') ||
              hnLower.contains('nighthawk')) {
            manufacturer = 'Netgear';
          } else if (hnLower.contains('ubiquiti') ||
              hnLower.contains('unifi')) {
            manufacturer = 'Ubiquiti';
          }
          // ── Home Appliance Brand Extraction ──────────────────────────
          if (hnLower.startsWith('thinq') || hnLower.contains('lg-thinq') || hnLower.contains('lgthinq')) {
            manufacturer = 'LG';
            category = 'LG ThinQ Appliance';
            icon = IconCategory.appliance;
          } else if (hnLower.startsWith('roomba') || hnLower.contains('irobot')) {
            manufacturer = 'iRobot';
            category = 'Robot Vacuum';
            icon = IconCategory.appliance;
          } else if (hnLower.startsWith('roborock')) {
            manufacturer = 'Roborock';
            category = 'Robot Vacuum';
            icon = IconCategory.appliance;
          } else if (hnLower.startsWith('dyson')) {
            manufacturer = 'Dyson';
            category = 'Dyson Device';
            icon = IconCategory.appliance;
          } else if (hnLower.startsWith('ecobee')) {
            manufacturer = 'Ecobee';
            category = 'Smart Thermostat';
            icon = IconCategory.thermostat;
          } else if (hnLower.startsWith('honeywell')) {
            manufacturer = 'Honeywell';
            category = 'Smart Thermostat';
            icon = IconCategory.thermostat;
          } else if (hnLower.startsWith('whirlpool')) {
            manufacturer = 'Whirlpool';
            category = 'Whirlpool Appliance';
            icon = IconCategory.appliance;
          } else if (hnLower.startsWith('maytag')) {
            manufacturer = 'Maytag';
            category = 'Maytag Appliance';
            icon = IconCategory.appliance;
          } else if (hnLower.startsWith('kitchenaid')) {
            manufacturer = 'KitchenAid';
            category = 'KitchenAid Appliance';
            icon = IconCategory.appliance;
          } else if (hnLower.startsWith('gea-') || hnLower.contains('ge-appliance')) {
            manufacturer = 'GE Appliances';
            category = 'GE Appliance';
            icon = IconCategory.appliance;
          } else if (hnLower.startsWith('bosch') || hnLower.contains('home-connect')) {
            manufacturer = 'Bosch';
            category = 'Bosch Appliance';
            icon = IconCategory.appliance;
          } else if (hnLower.startsWith('miele')) {
            manufacturer = 'Miele';
            category = 'Miele Appliance';
            icon = IconCategory.appliance;
          } else if (RegExp(r'^(wf|ww)\d', caseSensitive: false).hasMatch(hnLower)) {
            if (manufacturer == 'Unknown') manufacturer = 'Samsung';
            category = 'Washing Machine';
            icon = IconCategory.appliance;
          } else if (RegExp(r'^dv\d', caseSensitive: false).hasMatch(hnLower) && manufacturer == 'Samsung') {
            category = 'Dryer';
            icon = IconCategory.appliance;
          } else if (RegExp(r'^(rf|rt)\d', caseSensitive: false).hasMatch(hnLower) && manufacturer == 'Samsung') {
            category = 'Refrigerator';
            icon = IconCategory.appliance;
          }
        }
        if (deviceName.isEmpty) {
          deviceName = hostname;
        }
      }

      // Guess device type from MAC vendor when no hostname available
      if (category == 'Network Device' && manufacturer != 'Unknown') {
        final mfr = manufacturer.toLowerCase();
        if (mfr == 'apple') {
          category = 'Apple Device';
          icon = IconCategory.computer;
          score = 35;
        } else if (mfr == 'samsung') {
          category = 'Samsung Device';
          icon = IconCategory.generic;
          score = 35;
        } else if (mfr == 'google') {
          category = 'Google/Nest Device';
          icon = IconCategory.generic;
          score = 35;
        } else if (mfr == 'amazon') {
          category = 'Amazon Device';
          icon = IconCategory.speaker;
          score = 35;
        } else if (mfr == 'intel' ||
            mfr == 'dell' ||
            mfr == 'hp' ||
            mfr == 'lenovo' ||
            mfr == 'microsoft') {
          category = 'Computer';
          icon = IconCategory.computer;
          score = 35;
        } else if (mfr == 'tp-link' ||
            mfr == 'netgear' ||
            mfr == 'linksys' ||
            mfr == 'ubiquiti') {
          category = 'Network Equipment';
          icon = IconCategory.router;
          score = 35;
        } else if (mfr == 'asus') {
          // ASUS makes both routers AND laptops (ROG, ZenBook, VivoBook).
          // Routers always respond on port 80/443/23; laptops typically have none.
          if (ports.contains(80) || ports.contains(443) || ports.contains(23)) {
            category = 'Network Equipment';
            icon = IconCategory.router;
          } else {
            category = 'Computer';
            icon = IconCategory.computer;
          }
          score = 35;
        } else if (mfr == 'sonos') {
          category = 'Smart Speaker';
          icon = IconCategory.speaker;
          score = 35;
        } else if (mfr == 'roku') {
          category = 'Streaming Device';
          icon = IconCategory.tv;
          score = 35;
        } else if (mfr == 'philips hue') {
          category = 'Smart Lighting';
          icon = IconCategory.lightBulb;
          score = 35;
        } else if (mfr == 'xiaomi') {
          category = 'Smart Device';
          icon = IconCategory.generic;
          score = 35;
        } else if (mfr == 'wyze' || mfr == 'ring') {
          category = 'Smart Home';
          icon = IconCategory.camera;
          score = 35;
        } else if (mfr == 'ecobee' || mfr == 'honeywell') {
          category = 'Thermostat';
          icon = IconCategory.thermostat;
          score = 35;
        } else if (mfr == 'lg electronics') {
          // LG makes both phones AND appliances — we can't tell without more data
          category = 'LG Smart Device';
          icon = IconCategory.appliance;
          score = 30;
        } else if (mfr == 'whirlpool' || mfr == 'maytag' || mfr == 'kitchenaid') {
          category = '${mfr[0].toUpperCase()}${mfr.substring(1)} Appliance';
          icon = IconCategory.appliance;
          score = 35;
        } else if (mfr == 'irobot') {
          category = 'Robot Vacuum';
          icon = IconCategory.appliance;
          score = 38;
        } else if (mfr == 'dyson') {
          category = 'Dyson Device';
          icon = IconCategory.appliance;
          score = 35;
        } else if (mfr == 'nest labs') {
          category = 'Smart Thermostat';
          icon = IconCategory.thermostat;
          score = 35;
        } else if (mfr == 'ge appliances' || mfr == 'haier') {
          category = '${mfr == 'haier' ? 'Haier' : 'GE'} Appliance';
          icon = IconCategory.appliance;
          score = 35;
        } else if (mfr == 'bosch') {
          category = 'Bosch Appliance';
          icon = IconCategory.appliance;
          score = 35;
        } else if (mfr == 'miele') {
          category = 'Miele Appliance';
          icon = IconCategory.appliance;
          score = 35;
        } else if (mfr == 'shark') {
          category = 'Robot Vacuum';
          icon = IconCategory.appliance;
          score = 35;
        } else if (mfr == 'ring') {
          category = 'Smart Doorbell / Camera';
          icon = IconCategory.camera;
          score = 35;
        } else if (mfr == 'belkin') {
          category = 'Smart Plug / Switch';
          icon = IconCategory.smartPlug;
          score = 32;
        }
      }

      // ── Passive device confidence boost ─────────────────────────────
      // Phones, tablets, and IoT devices rarely have open ports, so probe-
      // based identification never fires. Combine MAC vendor + hostname +
      // TTL OS hint + randomized-MAC detection to classify these devices.
      //
      // KEY CHANGE: hostname pattern checks run even when manufacturer is
      // 'Unknown' — which happens when iOS/Android randomize their MAC
      // address (iOS 14+, Android 10+). The locally-administered bit in
      // the MAC is a reliable signal that the device is a modern phone.
      if (ports.isEmpty) {
        int passiveBonus = 0;

        // ── Randomized MAC detection ──────────────────────────────────
        // When bit 1 of the first octet is set, the MAC is locally
        // administered (i.e. randomized). Only phones/tablets do this.
        if (macAddress != null && _isRandomizedMac(macAddress)) {
          if (manufacturer == 'Unknown') {
            manufacturer = 'Mobile Device';
            category = 'Phone';
            icon = IconCategory.phone;
            passiveBonus += 8;
            _log(
              'NET',
              '  📱 $ip → randomized MAC → likely modern phone/tablet',
            );
          }
        }

        // Hostname confirms the known brand → +8 (only when brand is known)
        if (manufacturer != 'Unknown' &&
            manufacturer != 'Mobile Device' &&
            hostname != null &&
            hostname.toLowerCase().contains(manufacturer.toLowerCase())) {
          passiveBonus += 8;
        }
        // TTL-based OS hint available → +5
        if (osHint != null && osHint.isNotEmpty) {
          passiveBonus += 5;
        }

        // Device-specific hostname patterns → +10 (strong signal)
        // Runs unconditionally — overrides Unknown/randomized manufacturer
        if (hostname != null) {
          final hn = hostname.toLowerCase();
          if (hn.contains('iphone') || hn == 'iphone') {
            category = 'Phone';
            icon = IconCategory.phone;
            if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
              manufacturer = 'Apple';
            }
            passiveBonus += 10;
          } else if (hn.contains('ipad') || hn == 'ipad') {
            category = 'Tablet';
            icon = IconCategory.tablet;
            if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
              manufacturer = 'Apple';
            }
            passiveBonus += 10;
          } else if (hn.contains('galaxy') ||
              hn.contains('android') ||
              hn.startsWith('android-') ||
              RegExp(r'^samsung-sm-').hasMatch(hn)) {
            category = 'Phone';
            icon = IconCategory.phone;
            if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
              manufacturer = 'Samsung';
            }
            passiveBonus += 10;
          } else if (hn.contains('macbook') || hn.contains('imac')) {
            category = 'Computer';
            icon = IconCategory.computer;
            if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
              manufacturer = 'Apple';
            }
            passiveBonus += 10;
          } else if (hn.startsWith('pixel') ||
              hn.contains('pixel-') ||
              hn.contains('pixel_')) {
            category = 'Phone';
            icon = IconCategory.phone;
            if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
              manufacturer = 'Google';
            }
            passiveBonus += 10;
          } else if (hn.contains('oneplus') || hn.startsWith('oneplus-')) {
            category = 'Phone';
            icon = IconCategory.phone;
            if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
              manufacturer = 'OnePlus';
            }
            passiveBonus += 10;
          } else if (hn.contains('xiaomi') ||
              hn.contains('redmi') ||
              hn.startsWith('mi-') ||
              hn.startsWith('poco')) {
            category = 'Phone';
            icon = IconCategory.phone;
            if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
              manufacturer = 'Xiaomi';
            }
            passiveBonus += 10;
          } else if (hn.contains('kindle') || hn.contains('fire-hd')) {
            category = 'Tablet';
            icon = IconCategory.tablet;
            if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
              manufacturer = 'Amazon';
            }
            passiveBonus += 10;
          } else if (hn.contains('oppo') || hn.startsWith('oppo-')) {
            category = 'Phone';
            icon = IconCategory.phone;
            if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
              manufacturer = 'OPPO';
            }
            passiveBonus += 10;
          } else if (hn.contains('vivo') || hn.startsWith('vivo-')) {
            category = 'Phone';
            icon = IconCategory.phone;
            if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
              manufacturer = 'Vivo';
            }
            passiveBonus += 10;
          } else if (hn.contains('realme') || hn.startsWith('realme-')) {
            category = 'Phone';
            icon = IconCategory.phone;
            if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
              manufacturer = 'Realme';
            }
            passiveBonus += 10;
          } else if (hn.startsWith('moto') || hn.contains('moto-')) {
            category = 'Phone';
            icon = IconCategory.phone;
            if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
              manufacturer = 'Motorola';
            }
            passiveBonus += 10;
          } else if (hn.contains('honor') || hn.startsWith('honor-')) {
            category = 'Phone';
            icon = IconCategory.phone;
            if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
              manufacturer = 'Honor';
            }
            passiveBonus += 10;
          } else if (hn.contains('huawei') || hn.startsWith('huawei-')) {
            category = 'Phone';
            icon = IconCategory.phone;
            if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
              manufacturer = 'Huawei';
            }
            passiveBonus += 10;
          } else if (hn.contains('nokia-') || hn.startsWith('nokia-')) {
            category = 'Phone';
            icon = IconCategory.phone;
            if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
              manufacturer = 'Nokia';
            }
            passiveBonus += 10;
            // Samsung phone models: SM-A (Galaxy A), SM-G (Galaxy S/Note core),
            // SM-F (Galaxy Z Fold/Flip), SM-S (Galaxy S Ultra)
          } else if (RegExp(r'^samsung-sm-[agfs]').hasMatch(hn) ||
              RegExp(r'^sm-[agfs]\d').hasMatch(hn)) {
            category = 'Phone';
            icon = IconCategory.phone;
            if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
              manufacturer = 'Samsung';
            }
            passiveBonus += 10;
            // Samsung tablet models: SM-T (Galaxy Tab), SM-X (Galaxy Tab S8/S9)
          } else if (RegExp(r'^samsung-sm-[tx]').hasMatch(hn) ||
              RegExp(r'^sm-[tx]\d').hasMatch(hn)) {
            category = 'Tablet';
            icon = IconCategory.tablet;
            if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
              manufacturer = 'Samsung';
            }
            passiveBonus += 10;
          } else if (hn.contains('echo') || hn.contains('alexa')) {
            category = 'Smart Speaker';
            icon = IconCategory.speaker;
            if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
              manufacturer = 'Amazon';
            }
            passiveBonus += 10;
          } else if (hn.contains('nest') || hn.contains('chromecast')) {
            category = 'Smart Device';
            icon = IconCategory.tv;
            if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
              manufacturer = 'Google';
            }
            passiveBonus += 10;
          } else if (hn.contains('playstation') ||
              hn.contains('ps5') ||
              hn.contains('ps4') ||
              hn.contains('xbox')) {
            category = 'Game Console';
            icon = IconCategory.gameConsole;
            passiveBonus += 10;
          } else if (hn.contains('fire-tv') ||
              hn.contains('firetv') ||
              hn.contains('roku')) {
            category = 'Streaming Device';
            icon = IconCategory.tv;
            passiveBonus += 10;
          }
        }

        // MAC vendor alone is a decent signal for well-known consumer brands
        if (passiveBonus == 0 &&
            macAddress != null &&
            manufacturer != 'Unknown' &&
            manufacturer != 'Mobile Device') {
          final mfr = manufacturer.toLowerCase();
          if (mfr == 'apple' ||
              mfr == 'samsung' ||
              mfr == 'google' ||
              mfr == 'oneplus' ||
              mfr == 'xiaomi') {
            passiveBonus += 5;
          }
        }
        if (passiveBonus > 0) {
          score = (score + passiveBonus).clamp(0, 75);
          _log(
            'NET',
            '  📱 Passive boost for $ip: +$passiveBonus → score=$score',
          );
        }
      }

      // ═══════════════════════════════════════════════════════════════
      // DEVICE-SPECIFIC API PROBES (only for devices with open ports)
      // ═══════════════════════════════════════════════════════════════

      if (ports.isNotEmpty) {
        // ── Probe: iOS Lockdown (port 62078) ─────────────────────────
        // Port 62078 is exclusive to iPhone/iPad — it's the libimobiledevice
        // / iTunes pairing daemon. No other device type opens this port.
        if (!identified && ports.contains(62078)) {
          if (manufacturer == 'Unknown' || manufacturer == 'Mobile Device') {
            manufacturer = 'Apple';
          }
          category = 'iPhone / iPad';
          icon = IconCategory.phone;
          deviceType = 'ios-lockdown';
          if (deviceName.isEmpty) deviceName = hostname ?? 'iPhone / iPad';
          score = 75;
          identified = true;
          _log('NET', '  📱 $ip → iOS Lockdown port 62078 → iPhone / iPad');
        }

        // ── Probe: Android Wireless ADB (port 5555) ──────────────────
        // Port 5555 is the Android Wireless ADB debug port.
        // A phone must have "Wireless debugging" explicitly enabled, so
        // not every Android phone will expose it — but when open it's a
        // definitive Android signal. No router/NAS/printer uses port 5555.
        if (!identified && ports.contains(5555)) {
          category = 'Android Phone / Tablet';
          icon = IconCategory.phone;
          deviceType = 'android-adb';
          if (deviceName.isEmpty) deviceName = hostname ?? 'Android Device';
          score = 75;
          identified = true;
          _log(
            'NET',
            '  📱 $ip → Android ADB port 5555 → Android Phone/Tablet',
          );
        }

        // ── Probe: Chromecast / Google TV (port 8008) ────────────────
        if (!identified && ports.contains(8008)) {
          try {
            final resp = await http
                .get(
                  Uri.parse('http://$ip:8008/setup/eureka_info?options=detail'),
                )
                .timeout(const Duration(seconds: 2));
            if (resp.statusCode == 200) {
              final info = jsonDecode(resp.body) as Map<String, dynamic>;
              deviceName = (info['name'] as String?) ?? 'Chromecast';
              manufacturer = 'Google';
              modelNumber = info['model_name'] as String?;
              macAddress ??= info['mac_address'] as String?;
              category = 'Smart TV / Streaming';
              icon = IconCategory.tv;
              deviceType = 'chromecast';
              score = 90;
              identified = true;
              _log('NET', '  🎯 $ip → Chromecast: "$deviceName"');
            }
          } on Object catch (_) {}
        }

        // ── Probe: Roku (port 8060) ──────────────────────────────────
        if (!identified && ports.contains(8060)) {
          try {
            final resp = await http
                .get(Uri.parse('http://$ip:8060/query/device-info'))
                .timeout(const Duration(seconds: 2));
            if (resp.statusCode == 200) {
              final xml = resp.body;
              deviceName =
                  _xmlValue(xml, 'user-device-name') ??
                  _xmlValue(xml, 'friendly-device-name') ??
                  'Roku';
              manufacturer = 'Roku';
              modelNumber = _xmlValue(xml, 'friendly-model-name');
              serialNumber = _xmlValue(xml, 'serial-number');
              macAddress ??= _xmlValue(xml, 'wifi-mac');
              category = 'Smart TV / Streaming';
              icon = IconCategory.tv;
              deviceType = 'roku';
              score = 95;
              identified = true;
              _log('NET', '  🎯 $ip → Roku: "$deviceName"');
            }
          } on Object catch (_) {}
        }

        // ── Probe: Samsung Smart TV (port 8001) ──────────────────────
        if (!identified && ports.contains(8001)) {
          try {
            final resp = await http
                .get(Uri.parse('http://$ip:8001/api/v2/'))
                .timeout(const Duration(seconds: 2));
            if (resp.statusCode == 200) {
              final info = jsonDecode(resp.body) as Map<String, dynamic>;
              final device = info['device'] as Map<String, dynamic>? ?? info;
              deviceName = (device['name'] as String?) ?? 'Samsung TV';
              deviceName = Uri.decodeFull(
                deviceName,
              ).replaceAll('[TV]', '').trim();
              manufacturer = 'Samsung';
              modelNumber = device['modelName'] as String?;
              macAddress ??= device['wifiMac'] as String?;
              category = 'Smart TV';
              icon = IconCategory.tv;
              deviceType = 'samsung-tv';
              score = 95;
              identified = true;
              _log('NET', '  🎯 $ip → Samsung TV: "$deviceName"');
            }
          } on Object catch (_) {}
        }

        // ── Probe: Sonos (port 1400) ─────────────────────────────────
        if (!identified && ports.contains(1400)) {
          try {
            final resp = await http
                .get(Uri.parse('http://$ip:1400/xml/device_description.xml'))
                .timeout(const Duration(seconds: 2));
            if (resp.statusCode == 200) {
              final xml = resp.body;
              deviceName =
                  _xmlValue(xml, 'roomName') ??
                  _xmlValue(xml, 'friendlyName') ??
                  'Sonos Speaker';
              manufacturer = 'Sonos';
              modelNumber = _xmlValue(xml, 'modelName');
              serialNumber = _xmlValue(xml, 'serialNum');
              category = 'Smart Speaker';
              icon = IconCategory.speaker;
              deviceType = 'sonos';
              score = 95;
              identified = true;
              _log('NET', '  🎯 $ip → Sonos: "$deviceName"');
            }
          } on Object catch (_) {}
        }

        // ── Probe: Philips Hue Bridge (port 80) ──────────────────────
        if (!identified && ports.contains(80)) {
          try {
            final resp = await http
                .get(Uri.parse('http://$ip/api/config'))
                .timeout(const Duration(seconds: 2));
            if (resp.statusCode == 200 && resp.body.contains('bridgeid')) {
              final info = jsonDecode(resp.body) as Map<String, dynamic>;
              deviceName = (info['name'] as String?) ?? 'Hue Bridge';
              manufacturer = 'Philips';
              modelNumber = info['modelid'] as String?;
              macAddress ??= info['mac'] as String?;
              category = 'Smart Light Hub';
              icon = IconCategory.lightBulb;
              deviceType = 'hue-bridge';
              score = 95;
              identified = true;
              _log('NET', '  🎯 $ip → Hue Bridge: "$deviceName"');
            }
          } on Object catch (_) {}
        }

        // ── Probe: Printer (ports 631, 9100, 9197) ──────────────────
        if (!identified &&
            (ports.contains(631) ||
                ports.contains(9100) ||
                ports.contains(9197))) {
          category = 'Printer';
          icon = IconCategory.printer;
          score = 40;
          if (ports.contains(80)) {
            try {
              var resp = await http
                  .get(Uri.parse('http://$ip/DevMgmt/ProductConfigDyn.xml'))
                  .timeout(const Duration(seconds: 2));
              if (resp.statusCode == 200 &&
                  resp.body.contains('ProductInformation')) {
                deviceName =
                    _xmlValue(resp.body, 'MakeAndModel') ?? 'HP Printer';
                serialNumber = _xmlValue(resp.body, 'SerialNumber');
                manufacturer = 'HP';
                score = 90;
                identified = true;
              }
            } on Object catch (_) {}
            if (!identified) {
              try {
                final resp = await http
                    .get(
                      Uri.parse(
                        'http://$ip/PRESENTATION/HTML/TOP/PRTINFO.HTML',
                      ),
                    )
                    .timeout(const Duration(seconds: 2));
                if (resp.statusCode == 200 &&
                    resp.body.toLowerCase().contains('epson')) {
                  manufacturer = 'Epson';
                  deviceName = 'Epson Printer';
                  score = 80;
                  identified = true;
                }
              } on Object catch (_) {}
            }
            if (!identified) {
              try {
                final resp = await http
                    .get(Uri.parse('http://$ip/general/information.html'))
                    .timeout(const Duration(seconds: 2));
                if (resp.statusCode == 200 &&
                    resp.body.toLowerCase().contains('brother')) {
                  manufacturer = 'Brother';
                  deviceName = 'Brother Printer';
                  score = 80;
                  identified = true;
                }
              } on Object catch (_) {}
            }
          }
          if (!identified) {
            deviceName = deviceName.isEmpty ? 'Network Printer' : deviceName;
          }
        }

        // ── Probe: IP Camera (port 554 — RTSP) ──────────────────────
        if (!identified && ports.contains(554)) {
          category = 'IP Camera';
          icon = IconCategory.camera;
          score = 40;
          deviceName = deviceName.isEmpty ? 'IP Camera' : deviceName;
        }

        // ── Probe: Router (port 80 — web UI fingerprint) ────────────
        if (!identified && ports.contains(80)) {
          try {
            final resp = await http
                .get(Uri.parse('http://$ip/'))
                .timeout(const Duration(seconds: 2));
            final bodyLower = resp.body.toLowerCase();
            final titleMatch = RegExp(
              r'<title[^>]*>([^<]+)</title>',
              caseSensitive: false,
            ).firstMatch(resp.body);
            final title = titleMatch?.group(1)?.trim() ?? '';
            final combined = '$bodyLower $title'.toLowerCase();

            if (combined.contains('asus') ||
                combined.contains('asuswrt') ||
                combined.contains('rt-') ||
                combined.contains('gt-ax')) {
              manufacturer = 'ASUS';
              deviceName = title.isNotEmpty && title.length < 60
                  ? title
                  : 'ASUS Router';
              final modelMatch = RegExp(
                r'((?:RT|GT|ZenWiFi|TUF)-?[A-Z0-9]+[A-Za-z0-9-]*)',
                caseSensitive: false,
              ).firstMatch(resp.body);
              if (modelMatch != null) {
                modelNumber = modelMatch.group(1);
                deviceName = 'ASUS $modelNumber';
              }
              category = 'Router / Gateway';
              icon = IconCategory.router;
              score = 90;
              identified = true;
            } else if (combined.contains('netgear') ||
                combined.contains('nighthawk') ||
                combined.contains('orbi')) {
              manufacturer = 'Netgear';
              deviceName = title.isNotEmpty && title.length < 60
                  ? title
                  : 'Netgear Router';
              category = 'Router / Gateway';
              icon = IconCategory.router;
              score = 90;
              identified = true;
            } else if (combined.contains('tp-link') ||
                combined.contains('tplink') ||
                combined.contains('archer') ||
                combined.contains('deco')) {
              manufacturer = 'TP-Link';
              deviceName = title.isNotEmpty && title.length < 60
                  ? title
                  : 'TP-Link Router';
              category = 'Router / Gateway';
              icon = IconCategory.router;
              score = 90;
              identified = true;
            } else if (combined.contains('linksys')) {
              manufacturer = 'Linksys';
              deviceName = 'Linksys Router';
              category = 'Router / Gateway';
              icon = IconCategory.router;
              score = 90;
              identified = true;
            } else if (combined.contains('ubiquiti') ||
                combined.contains('unifi')) {
              manufacturer = 'Ubiquiti';
              deviceName = 'UniFi Device';
              category = 'Network Equipment';
              icon = IconCategory.router;
              score = 85;
              identified = true;
            }

            // Generic HTTP fingerprint (computer detection)
            if (!identified &&
                _isLikelyComputer(
                  resp.headers['server'] ?? '',
                  title,
                  bodyLower,
                )) {
              final server = (resp.headers['server'] ?? '').toLowerCase();
              if (server.contains('iis')) {
                manufacturer = 'Microsoft';
                category = 'Windows PC';
                // Extract IIS version → infer Windows version
                final iisMatch = RegExp(
                  r'iis[/ ]*(\d+(?:\.\d+)?)',
                ).firstMatch(server);
                if (iisMatch != null) {
                  final ver = iisMatch.group(1) ?? '';
                  deviceName = 'Windows PC (IIS $ver)';
                  // IIS 10 = Win10/Server2016+, IIS 8.5 = Win8.1/2012R2, etc.
                  if (ver.startsWith('10')) {
                    osHint ??= 'Windows 10 / Server 2016+';
                  } else if (ver.startsWith('8')) {
                    osHint ??= 'Windows 8.x / Server 2012';
                  } else if (ver.startsWith('7')) {
                    osHint ??= 'Windows 7 / Server 2008R2';
                  }
                } else {
                  deviceName = 'Windows PC';
                }
                score = 70;
              } else if (server.contains('apache')) {
                deviceName = 'Computer (Apache)';
                score = 55;
              } else if (server.contains('nginx')) {
                deviceName = 'Computer (Nginx)';
                score = 55;
              } else {
                deviceName = 'Computer / Server';
                score = 45;
              }
              category = 'Computer';
              icon = IconCategory.computer;
              identified = true;
            }

            if (!identified && manufacturer == 'Unknown') {
              manufacturer = _detectBrandFromText(combined);
            }
          } on Object catch (_) {}
        }

        // ── Probe: WSD / Windows Service Discovery (port 5357) ──────
        // Windows publishes a device-info XML at http://ip:5357/ even when
        // the Windows Firewall is active on a "Private" or "Work" network.
        // The response is a SOAP envelope with <wsd:ThisDevice> / <wsd:ThisModel>
        // elements that give us the computer name and model.
        if (!identified && ports.contains(5357)) {
          try {
            final resp = await http
                .get(Uri.parse('http://$ip:5357/'))
                .timeout(const Duration(seconds: 2));
            if (resp.statusCode == 200) {
              final body = resp.body;
              // Extract <wsd:FriendlyName> or <wsdis:FriendlyName>
              final friendlyMatch = RegExp(
                r'<(?:wsd[^:]*:)?FriendlyName[^>]*>([^<]+)</(?:wsd[^:]*:)?FriendlyName>',
                caseSensitive: false,
              ).firstMatch(body);
              // Extract <wsd:Manufacturer>
              final mfrMatch = RegExp(
                r'<(?:wsd[^:]*:)?Manufacturer[^>]*>([^<]+)</(?:wsd[^:]*:)?Manufacturer>',
                caseSensitive: false,
              ).firstMatch(body);
              // Extract <wsd:ModelName> or <wsdis:ModelName>
              final modelMatch = RegExp(
                r'<(?:wsd[^:]*:)?ModelName[^>]*>([^<]+)</(?:wsd[^:]*:)?ModelName>',
                caseSensitive: false,
              ).firstMatch(body);

              final wsdName = friendlyMatch?.group(1)?.trim();
              final wsdMfr = mfrMatch?.group(1)?.trim();
              final wsdModel = modelMatch?.group(1)?.trim();

              if (wsdName != null && wsdName.isNotEmpty) {
                deviceName = wsdName;
              }
              if (wsdMfr != null && wsdMfr.isNotEmpty) {
                manufacturer = wsdMfr;
              }
              if (wsdModel != null && wsdModel.isNotEmpty) {
                modelNumber = wsdModel;
              }

              category = 'Windows PC';
              icon = IconCategory.computer;
              deviceType = 'wsd-windows';
              score = 75;
              identified = true;
              _log('NET', '  🖥️ $ip → WSD: "$deviceName" ($manufacturer)');
            }
          } on Object catch (_) {}
        }

        // ── Probe: SSH banner (port 22) — Linux / macOS ─────────────
        // The SSH daemon sends a plain-text banner as the first bytes of the
        // connection (before any authentication).  e.g.:
        //   "SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.6"
        //   "SSH-2.0-OpenSSH_9.0 Darwin"
        //   "SSH-2.0-dropbear_2022.83"
        // We can use this to distinguish Linux from macOS and identify the OS.
        if (!identified && ports.contains(22)) {
          try {
            final socket = await Socket.connect(
              ip,
              22,
              timeout: const Duration(seconds: 2),
            );
            final buffer = StringBuffer();
            await socket.first.timeout(const Duration(seconds: 1)).then((data) {
              buffer.write(String.fromCharCodes(data).trim());
            });
            socket.destroy();
            final banner = buffer.toString().toLowerCase();
            if (banner.startsWith('ssh-')) {
              if (banner.contains('darwin') || banner.contains('macos')) {
                category = 'Mac / Apple Device';
                manufacturer = manufacturer == 'Unknown'
                    ? 'Apple'
                    : manufacturer;
                deviceType = 'ssh-macos';
                icon = IconCategory.computer;
                score = 65;
              } else if (banner.contains('ubuntu') ||
                  banner.contains('debian') ||
                  banner.contains('fedora') ||
                  banner.contains('centos') ||
                  banner.contains('linux') ||
                  banner.contains('arch') ||
                  banner.contains('openssh') ||
                  banner.contains('dropbear')) {
                category = 'Linux Computer';
                deviceType = 'ssh-linux';
                icon = IconCategory.computer;
                score = 65;
              } else {
                category = 'Computer';
                deviceType = 'ssh-device';
                icon = IconCategory.computer;
                score = 55;
              }
              if (deviceName.isEmpty) {
                deviceName = hostname ?? 'Computer at $ip';
              }
              identified = true;
              _log('NET', '  🖥️ $ip → SSH banner: "$banner" → $category');
            }
          } on Object catch (_) {}
        }

        // ── Probe: Windows SMB / RPC fallback ───────────────────────
        // If we see Windows-only ports (135 RPC, 139 NetBIOS-SSN) or RDP (3389)
        // but WSD and SSH probes didn't identify the device, it's still a Windows
        // machine — just without a reachable WSD endpoint on this interface.
        if (!identified &&
            (ports.contains(135) ||
                ports.contains(139) ||
                ports.contains(3389))) {
          category = 'Windows PC';
          icon = IconCategory.computer;
          deviceType = 'smb-windows';
          if (manufacturer == 'Unknown') manufacturer = 'Windows PC';
          if (deviceName.isEmpty) deviceName = hostname ?? 'Windows PC';
          score = 55;
          identified = true;
          _log('NET', '  🖥️ $ip → Windows fingerprint via RPC/SMB ports');
        }
      } // end if (ports.isNotEmpty)

      // ── Final fallback: use hostname or MAC vendor for device name ──
      if (deviceName.isEmpty || deviceName == 'Device at $ip') {
        if (hostname != null && hostname.isNotEmpty) {
          deviceName = hostname;
        } else if (manufacturer != 'Unknown') {
          deviceName = '$manufacturer Device';
        } else {
          deviceName = 'Device at $ip';
        }
      }

      _log(
        'NET',
        '  ✅ $ip — $category: "$deviceName"',
        'Brand: $manufacturer, Model: ${modelNumber ?? "N/A"}, '
            'MAC: ${macAddress ?? "N/A"}, Hostname: ${hostname ?? "N/A"}, '
            'Score: $score, Ports: ${ports.isNotEmpty ? ports.join(",") : "none"}',
      );

      // ── Fingerprint Engine — local identification ────────────────────
      // Run the client-side fingerprint engine to populate brandGuess,
      // osGuess, and reasoning. Does NOT override category/manufacturer
      // which are already computed by the scan pipeline.
      final normalizedHostname = fp_engine.normalizeDhcpHostname(hostname);
      final portLabels = fp_engine.generatePortFingerprints(ports);
      final fpResult = fp_engine.fingerprintDevice(
        manufacturer: manufacturer,
        hostname: normalizedHostname ?? hostname,
        openPorts: ports,
        ttl: ttl,
        httpBanner: null, // populated later in Layer 5
        currentCategory: category,
      );

      devices.add(
        WifiDevice(
          ipAddress: ip,
          macAddress: macAddress,
          manufacturer: manufacturer,
          deviceName: deviceName,
          hostname: hostname,
          modelNumber: _sanitizeModelNumber(modelNumber),
          serialNumber: _sanitizeSerial(serialNumber),
          deviceTypeRaw: deviceType,
          deviceCategory: category,
          iconCategory: icon,
          confidenceScore: score,
          discoveryMethod: 'subnet',
          openPorts: ports,
          osHint: osHint,
          ttlValue: ttl,
          dhcpHostname: normalizedHostname,
          portFingerprint: portLabels,
          brandGuess: fpResult.brandGuess.isNotEmpty
              ? fpResult.brandGuess
              : null,
          osGuess: fpResult.osGuess.isNotEmpty ? fpResult.osGuess : null,
          fingerprintReasoning: fpResult.reasoning,
        ),
      );
    }

    return devices;
  }

  /// Tries connecting to common ports on a host. Returns list of open ports.
  Future<List<int>> _probeHost(String ip) async {
    final openPorts = <int>[];

    final futures = _scanPorts.map((port) async {
      try {
        final socket = await Socket.connect(
          ip,
          port,
          timeout: const Duration(milliseconds: 200),
        );
        openPorts.add(port);
        socket.destroy();
      } on Object catch (_) {
        // Port closed or host unreachable — expected for most IPs
      }
    });

    await Future.wait(futures);
    return openPorts;
  }

  String _guessCategoryFromPorts(List<int> ports) {
    // ── Mobile devices — highest confidence ──────────────────────────
    if (ports.contains(62078)) return 'iPhone / iPad';
    if (ports.contains(5555)) return 'Android Phone / Tablet';
    // ── High-confidence device-specific ports ─────────────────────────
    if (ports.contains(9197) ||
        ports.contains(9100) ||
        ports.contains(631) ||
        ports.contains(515)) {
      return 'Printer';
    }
    if (ports.contains(554)) return 'IP Camera';
    if (ports.contains(8060)) return 'Roku';
    if (ports.contains(8001)) return 'Samsung TV';
    if (ports.contains(8008) || ports.contains(8443)) {
      return 'Smart TV / Streaming';
    }
    if (ports.contains(7000)) return 'Apple AirPlay Device';
    if (ports.contains(1400)) return 'Sonos Speaker';
    if (ports.contains(8123)) return 'Home Assistant';
    if (ports.contains(8291)) return 'Router';
    if (ports.contains(32400)) return 'Media Server';
    if (ports.contains(8096)) return 'Media Server';
    // ── Windows PC — SMB/RPC ports take priority over NAS ─────────────
    if (ports.contains(135) || ports.contains(139) || ports.contains(3389)) {
      return 'Windows PC';
    }
    if (ports.contains(5357)) return 'Windows PC';
    // ── Remote desktop / VNC ──────────────────────────────────────────
    if (ports.contains(5900)) return 'Computer';
    // ── NAS / Storage ─────────────────────────────────────────────────
    if (ports.contains(5001) || ports.contains(2049)) return 'NAS / Storage';
    if (ports.contains(445) && !ports.contains(135)) return 'NAS / Storage';
    // ── DNS server (Pi-hole, router) ──────────────────────────────────
    if (ports.contains(53) && ports.contains(80)) return 'Router';
    // ── Home Appliances ───────────────────────────────────────────────
    if (ports.contains(2878) || ports.contains(7677)) return 'LG ThinQ Appliance';
    if (ports.contains(7676)) return 'LG Smart Device';
    if (ports.contains(55000)) return 'GE Appliance';
    if (ports.contains(8900)) return 'Smart Appliance';
    if (ports.contains(4999)) return 'Robot Vacuum';
    // ── Database / Infrastructure servers ─────────────────────────────
    if (ports.contains(3306) ||
        ports.contains(5432) ||
        ports.contains(6379) ||
        ports.contains(9200) ||
        ports.contains(27017)) {
      return 'Computer';
    }
    if (ports.contains(10000)) return 'Computer';
    if (ports.contains(9090) && ports.contains(22)) return 'Computer';
    // ── Apple / Mac ───────────────────────────────────────────────────
    if (ports.contains(548)) return 'Mac / Apple Device';
    if (ports.contains(22) || ports.contains(3689)) return 'Computer';
    // ── VoIP / SIP ────────────────────────────────────────────────────
    if (ports.contains(5060)) return 'VoIP Phone';
    // ── Smart Home / IoT ──────────────────────────────────────────────
    if (ports.contains(1883)) return 'Smart Device';
    if (ports.contains(49152) || ports.contains(2869) || ports.contains(5000)) {
      return 'Smart Device';
    }
    if (ports.contains(8080)) return 'Smart Device';
    if (ports.contains(1900)) return 'UPnP Device';
    if (ports.contains(80) || ports.contains(443)) return 'Network Device';
    return 'Smart Device';
  }

  IconCategory _guessCategoryIconFromPorts(List<int> ports) {
    if (ports.contains(62078)) return IconCategory.phone;
    if (ports.contains(5555)) return IconCategory.phone;
    if (ports.contains(9197) ||
        ports.contains(9100) ||
        ports.contains(631) ||
        ports.contains(515)) {
      return IconCategory.printer;
    }
    if (ports.contains(554)) return IconCategory.camera;
    if (ports.contains(8060) || ports.contains(8001)) return IconCategory.tv;
    if (ports.contains(8008) || ports.contains(8443)) return IconCategory.tv;
    if (ports.contains(7000)) return IconCategory.tv;
    if (ports.contains(1400)) return IconCategory.speaker;
    if (ports.contains(8291) || ports.contains(8123) || ports.contains(10000)) {
      return IconCategory.router;
    }
    // ── Home appliance ports → appliance icon ─────────────────────────
    if (ports.contains(2878) || ports.contains(7677) || ports.contains(7676)) {
      return IconCategory.appliance;
    }
    if (ports.contains(55000) || ports.contains(8900) || ports.contains(4999)) {
      return IconCategory.appliance;
    }
    // Windows, Linux, VNC, Mac, remote desktop → computer icon
    if (ports.contains(135) ||
        ports.contains(139) ||
        ports.contains(3389) ||
        ports.contains(5357) ||
        ports.contains(5900) ||
        ports.contains(22) ||
        ports.contains(3689) ||
        ports.contains(548)) {
      return IconCategory.computer;
    }
    if (ports.contains(5001) || ports.contains(445) || ports.contains(2049)) {
      return IconCategory.generic;
    }
    // Database/infrastructure servers → computer
    if (ports.contains(3306) ||
        ports.contains(5432) ||
        ports.contains(6379) ||
        ports.contains(27017)) {
      return IconCategory.computer;
    }
    return IconCategory.generic;
  }

  /// Checks if an HTTP response looks like a regular computer/server
  /// (not a smart home device). Used to label PCs/laptops correctly.
  bool _isLikelyComputer(String server, String title, String bodyLower) {
    final s = server.toLowerCase();
    final t = title.toLowerCase();

    // IIS = Windows computer/server
    if (s.contains('microsoft-iis') || s.contains('iis')) return true;

    // Generic web server titles that are NOT device names
    const genericTitles = [
      'iis windows',
      'welcome to iis',
      'apache2',
      'it works',
      'test page',
      'index of',
      'login',
      'sign in',
      'log in',
      'service unavailable',
      '404',
      'not found',
      'forbidden',
      'under construction',
      'coming soon',
      'welcome to nginx',
      'default page',
      'home page',
      'dashboard',
    ];
    for (final g in genericTitles) {
      if (t.contains(g)) return true;
    }

    // Apache or Nginx with generic content (no device-specific keywords)
    if ((s.contains('apache') || s.contains('nginx')) &&
        !bodyLower.contains('printer') &&
        !bodyLower.contains('camera') &&
        !bodyLower.contains('smart') &&
        !bodyLower.contains('device')) {
      return true;
    }

    return false;
  }

  /// Reads the ARP cache via native platform channel.
  /// Android: uses /proc/net/arp + `ip neigh`.
  /// iOS: returns empty (ARP table is a privileged kernel API — not exposed to apps).
  Future<Map<String, String>> _readArpTable() async {
    if (Platform.isIOS) {
      _log(
        'NET',
        'ℹ️ iOS: ARP table not available — MAC addresses cannot be read on iOS',
      );
      _log(
        'NET',
        '   Devices will show by IP + hostname. Manufacturer from DNS/mDNS data only.',
      );
      return {};
    }
    try {
      final result = await _platform.invokeMethod('getArpTable');
      if (result is Map) {
        final arpMap = <String, String>{};
        result.forEach((key, value) {
          if (key is String && value is String) {
            arpMap[key] = value.toUpperCase();
          }
        });
        if (arpMap.isNotEmpty) return arpMap;
      }
    } on Object catch (e) {
      _log(
        'NET',
        '⚠️ Native ARP table failed, trying /proc fallback',
        e.toString(),
      );
    }
    // Fallback 1: try /proc/net/arp directly (works on older Android)
    final arpMap = <String, String>{};
    try {
      final file = File('/proc/net/arp');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        for (int i = 1; i < lines.length; i++) {
          final parts = lines[i].split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            final ip = parts[0];
            final mac = parts[3].toUpperCase();
            if (mac != '00:00:00:00:00:00' && mac.contains(':')) {
              arpMap[ip] = mac;
            }
          }
        }
      }
    } on Object catch (_) {}
    if (arpMap.isNotEmpty) {
      _log('NET', '📋 /proc/net/arp fallback: ${arpMap.length} MAC(s)');
      return arpMap;
    }

    // Fallback 2: Run `ip neigh show` via Process.run
    // On Android 10+, /proc/net/arp is restricted by SELinux but `ip neigh`
    // usually still works. This catches cases where the native channel
    // returned empty despite the kernel having ARP entries.
    try {
      final result = await Process.run('ip', ['neigh', 'show']);
      if (result.exitCode == 0) {
        final lines = (result.stdout as String).split('\n');
        for (final line in lines) {
          final parts = line.trim().split(RegExp(r'\s+'));
          final llIdx = parts.indexOf('lladdr');
          if (llIdx != -1 && llIdx + 1 < parts.length) {
            final ip = parts[0];
            final mac = parts[llIdx + 1].toUpperCase();
            final state = parts.last;
            if (mac != '00:00:00:00:00:00' &&
                mac.contains(':') &&
                state != 'FAILED' &&
                state != 'INCOMPLETE') {
              arpMap[ip] = mac;
            }
          }
        }
        if (arpMap.isNotEmpty) {
          _log(
            'NET',
            '📋 Process.run ip-neigh fallback: ${arpMap.length} MAC(s)',
          );
          return arpMap;
        }
      }
    } on Object catch (_) {}

    // Fallback 3: `cat /proc/net/arp` via shell — sometimes cat works when
    // Dart's File API is blocked by SELinux
    try {
      final result = await Process.run('cat', ['/proc/net/arp']);
      if (result.exitCode == 0) {
        final lines = (result.stdout as String).split('\n');
        for (int i = 1; i < lines.length; i++) {
          final parts = lines[i].trim().split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            final ip = parts[0];
            final mac = parts[3].toUpperCase();
            if (mac != '00:00:00:00:00:00' && mac.contains(':')) {
              arpMap[ip] = mac;
            }
          }
        }
        if (arpMap.isNotEmpty) {
          _log('NET', '📋 cat /proc/net/arp fallback: ${arpMap.length} MAC(s)');
        }
      }
    } on Object catch (_) {}
    return arpMap;
  }

  /// Resolves hostnames for a list of IPs via native reverse-DNS.
  // ignore: unused_element
  // Disabled for performance: DNS hostname resolution removed (saves 30-60 seconds!)
  Future<Map<String, String>> _resolveHostnames(List<String> ips) async {
    if (ips.isEmpty) return {};
    try {
      final result = await _platform.invokeMethod('resolveHostnames', {
        'ips': ips,
      });
      if (result is Map) {
        final hostMap = <String, String>{};
        result.forEach((key, value) {
          if (key is String && value is String) {
            hostMap[key] = value;
          }
        });
        return hostMap;
      }
    } on Object catch (e) {
      _log('NET', '⚠️ Hostname resolution failed', e.toString());
    }
    return {};
  }

  /// Queries NetBIOS Node Status (UDP 137) for each IP.
  /// Returns `Map<ip, windowsComputerName>` — works even when ICMP is blocked.
  /// iOS: returns empty — UDP 137 is blocked by the iOS App Sandbox.
  // ignore: unused_element
  // Disabled for performance: NetBIOS name resolution removed (saves 30-60 seconds!)
  Future<Map<String, String>> _resolveNetBiosNames(List<String> ips) async {
    if (ips.isEmpty) return {};
    if (Platform.isIOS) {
      _log(
        'NET',
        'ℹ️ iOS: NetBIOS (UDP 137) not available — Windows names via DNS only',
      );
      return {};
    }
    try {
      final result = await _platform.invokeMethod('queryNetBiosNames', {
        'ips': ips,
      });
      if (result is Map) {
        final nameMap = <String, String>{};
        result.forEach((key, value) {
          if (key is String && value is String && value.trim().isNotEmpty) {
            nameMap[key] = value.trim();
          }
        });
        if (nameMap.isNotEmpty) {
          _log('NET', '🖥️ NetBIOS resolved ${nameMap.length} Windows name(s)');
          for (final e in nameMap.entries) {
            _log('NET', '   ${e.key} → ${e.value}');
          }
        }
        return nameMap;
      }
    } on Object catch (e) {
      _log('NET', '⚠️ NetBIOS name query failed (non-critical)', e.toString());
    }
    return {};
  }

  /// Local MAC address prefix -> manufacturer lookup (IEEE OUI subset).
  /// Covers the most common smart home / consumer device manufacturers.
  static String _lookupMacVendor(String mac) {
    final prefix = mac.toUpperCase();
    if (prefix.length < 8) return 'Unknown';
    final oui = prefix.substring(0, 8); // "AA:BB:CC"

    const vendorMap = <String, String>{
      // Samsung
      '00:07:AB': 'Samsung', '00:16:DB': 'Samsung', '00:1A:8A': 'Samsung',
      '00:1E:E1': 'Samsung', '08:D4:2B': 'Samsung', '10:1D:C0': 'Samsung',
      '14:49:E0': 'Samsung', '18:3A:2D': 'Samsung', '2C:AE:2B': 'Samsung',
      '30:CD:A7': 'Samsung', '34:23:BA': 'Samsung', '38:01:97': 'Samsung',
      '40:0E:85': 'Samsung', '44:78:3E': 'Samsung', '50:01:BB': 'Samsung',
      '54:92:BE': 'Samsung', '5C:3C:27': 'Samsung', '64:B8:53': 'Samsung',
      '6C:B7:49': 'Samsung', '78:1F:DB': 'Samsung', '84:38:35': 'Samsung',
      '8C:71:F8': 'Samsung', '94:01:C2': 'Samsung', 'A0:82:1F': 'Samsung',
      'A8:06:00': 'Samsung', 'B4:3A:28': 'Samsung', 'BC:44:86': 'Samsung',
      'C0:97:27': 'Samsung', 'D0:22:BE': 'Samsung', 'D8:90:E8': 'Samsung',
      'E4:7D:BD': 'Samsung', 'EC:1F:72': 'Samsung', 'F0:25:B7': 'Samsung',
      // LG
      '00:1C:62': 'LG', '00:1E:75': 'LG', '00:22:A9': 'LG', '10:68:3F': 'LG',
      '20:21:A5': 'LG', '28:A1:83': 'LG', '30:B4:9E': 'LG', '34:4D:F7': 'LG',
      '3C:BD:D8': 'LG', '40:B0:FA': 'LG', '58:A2:B5': 'LG', '64:89:9A': 'LG',
      '78:F8:82': 'LG', '88:C9:D0': 'LG', 'A8:23:FE': 'LG', 'AC:F1:08': 'LG',
      'C4:36:6C': 'LG', 'D0:D0:03': 'LG', 'E8:F2:E2': 'LG',
      // Sony
      '00:04:1F': 'Sony', '00:13:A9': 'Sony', '00:1A:80': 'Sony',
      '00:24:BE': 'Sony', '04:5D:4B': 'Sony', '28:3F:69': 'Sony',
      '40:B8:37': 'Sony', '54:42:49': 'Sony', '78:84:3C': 'Sony',
      'AC:9B:0A': 'Sony', 'B4:52:7D': 'Sony', 'FC:0F:E6': 'Sony',
      // Google / Nest / Chromecast
      '18:D6:C7': 'Google', '30:FD:38': 'Google', '3C:5A:B4': 'Google',
      '54:60:09': 'Google', '6C:AD:F8': 'Google', 'A4:77:33': 'Google',
      'D4:F5:47': 'Google', 'F4:F5:D8': 'Google', 'F4:F5:E8': 'Google',
      '48:D6:D5': 'Google', '64:16:66': 'Google', '18:B4:30': 'Google',
      // Apple
      '00:03:93': 'Apple', '00:0A:27': 'Apple', '00:0A:95': 'Apple',
      '00:11:24': 'Apple', '00:14:51': 'Apple', '00:1B:63': 'Apple',
      '04:0C:CE': 'Apple', '14:5A:05': 'Apple', '20:C9:D0': 'Apple',
      '24:A0:74': 'Apple', '28:6A:B8': 'Apple', '34:36:3B': 'Apple',
      '3C:15:C2': 'Apple', '40:33:1A': 'Apple', '44:D8:84': 'Apple',
      '5C:8D:4E': 'Apple', '60:FA:CD': 'Apple', '68:FE:F7': 'Apple',
      '70:56:81': 'Apple', '78:CA:39': 'Apple', '84:FC:FE': 'Apple',
      'A4:D1:D2': 'Apple', 'AC:FD:EC': 'Apple', 'B0:65:BD': 'Apple',
      'BC:52:B7': 'Apple', 'D0:03:DF': 'Apple', 'F0:B4:79': 'Apple',
      // Amazon / Ring / Echo
      '00:FC:8B': 'Amazon', '0C:47:C9': 'Amazon', '10:CE:A9': 'Amazon',
      '14:91:38': 'Amazon', '18:74:2E': 'Amazon', '34:D2:70': 'Amazon',
      '40:A2:DB': 'Amazon', '44:65:0D': 'Amazon', '50:DC:E7': 'Amazon',
      '68:54:FD': 'Amazon', '74:C2:46': 'Amazon', '84:D6:D0': 'Amazon',
      'A0:02:DC': 'Amazon', 'AC:63:BE': 'Amazon', 'B4:7C:9C': 'Amazon',
      'CC:93:4A': 'Amazon', 'F0:72:EA': 'Amazon',
      // Sonos
      '00:0E:58': 'Sonos', '5C:AA:FD': 'Sonos', '78:28:CA': 'Sonos',
      '94:9F:3E': 'Sonos', 'B8:E9:37': 'Sonos', '34:7E:5C': 'Sonos',
      '48:A6:B8': 'Sonos', '54:2A:1B': 'Sonos',
      // Roku
      '00:0D:4B': 'Roku', '08:05:81': 'Roku', 'AC:3A:7A': 'Roku',
      'B0:A7:37': 'Roku', 'BC:D7:D4': 'Roku', 'C8:3A:6B': 'Roku',
      'D0:4D:2C': 'Roku', 'DC:3A:5E': 'Roku',
      // HP
      '00:1A:73': 'HP', '00:17:A4': 'HP', '00:1B:78': 'HP',
      '00:21:5A': 'HP', '00:23:7D': 'HP', '10:1F:74': 'HP',
      '14:58:D0': 'HP', '28:80:23': 'HP', '3C:D9:2B': 'HP',
      '48:0F:CF': 'HP', '58:20:B1': 'HP', '64:51:06': 'HP',
      '78:AC:C0': 'HP', '80:CE:62': 'HP', '94:57:A5': 'HP',
      // Canon
      '00:1E:8F': 'Canon', '18:0C:AC': 'Canon', '30:22:CE': 'Canon',
      '58:67:1A': 'Canon', '88:87:17': 'Canon', 'C4:36:55': 'Canon',
      // Epson
      '00:1B:09': 'Epson', '00:26:AB': 'Epson', '60:76:88': 'Epson',
      '6C:C2:17': 'Epson', 'A4:EE:57': 'Epson', 'BC:5C:4C': 'Epson',
      // TP-Link
      '00:27:19': 'TP-Link', '14:CC:20': 'TP-Link', '2C:4D:54': 'TP-Link',
      '30:DE:4B': 'TP-Link', '50:C7:BF': 'TP-Link', '54:AF:97': 'TP-Link',
      '60:32:B1': 'TP-Link', '64:6E:97': 'TP-Link', '78:44:76': 'TP-Link',
      '98:DA:C4': 'TP-Link', 'B0:BE:76': 'TP-Link', 'C0:06:C3': 'TP-Link',
      'D8:07:B6': 'TP-Link', 'EC:08:6B': 'TP-Link',
      // Netgear
      '00:09:5B': 'Netgear', '00:0F:B5': 'Netgear', '00:14:6C': 'Netgear',
      '00:1B:2F': 'Netgear', '00:1E:2A': 'Netgear', '00:1F:33': 'Netgear',
      '04:A1:51': 'Netgear', '08:02:8E': 'Netgear', '10:0C:6B': 'Netgear',
      '20:0C:C8': 'Netgear', '2C:B0:5D': 'Netgear', '30:46:9A': 'Netgear',
      '44:94:FC': 'Netgear', '6C:B0:CE': 'Netgear', '84:1B:5E': 'Netgear',
      'A0:04:60': 'Netgear', 'B0:7F:B9': 'Netgear', 'C0:3F:0E': 'Netgear',
      'C4:04:15': 'Netgear', 'E0:46:9A': 'Netgear',
      // ASUS
      '00:0C:6E': 'ASUS', '00:0E:A6': 'ASUS', '00:11:2F': 'ASUS',
      '00:13:D4': 'ASUS', '00:15:F2': 'ASUS', '00:17:31': 'ASUS',
      '00:1A:92': 'ASUS', '00:1D:60': 'ASUS', '00:1E:8C': 'ASUS',
      '00:22:15': 'ASUS', '00:23:54': 'ASUS', '00:24:8C': 'ASUS',
      '00:25:22': 'ASUS', '00:26:18': 'ASUS', '04:92:26': 'ASUS',
      '08:60:6E': 'ASUS', '0C:9D:92': 'ASUS', '10:BF:48': 'ASUS',
      '14:DA:E9': 'ASUS', '1C:87:2C': 'ASUS', '20:CF:30': 'ASUS',
      '24:4B:FE': 'ASUS', '2C:56:DC': 'ASUS', '30:5A:3A': 'ASUS',
      '34:97:F6': 'ASUS', '38:D5:47': 'ASUS', '40:B0:76': 'ASUS',
      '48:5B:39': 'ASUS', '50:46:5D': 'ASUS', '54:04:A6': 'ASUS',
      '60:45:CB': 'ASUS', '6C:F3:7F': 'ASUS', '70:8B:CD': 'ASUS',
      '74:D0:2B': 'ASUS', '78:24:AF': 'ASUS', '88:D7:F6': 'ASUS',
      'AC:22:0B': 'ASUS', 'B0:6E:BF': 'ASUS', 'BC:EE:7B': 'ASUS',
      'C8:60:00': 'ASUS', 'D4:5D:64': 'ASUS', 'E0:3F:49': 'ASUS',
      'F4:6D:04': 'ASUS', 'F8:32:E4': 'ASUS',
      // Linksys
      '00:04:5A': 'Linksys', '00:06:25': 'Linksys', '00:0C:41': 'Linksys',
      '00:0E:08': 'Linksys', '00:14:BF': 'Linksys', '00:16:B6': 'Linksys',
      '00:18:39': 'Linksys', '20:AA:4B': 'Linksys', '58:6D:8F': 'Linksys',
      'C0:56:27': 'Linksys',
      // Philips Hue
      '00:17:88': 'Philips Hue', 'EC:B5:FA': 'Philips Hue',
      // Ubiquiti
      '00:27:22': 'Ubiquiti', '04:18:D6': 'Ubiquiti', '18:E8:29': 'Ubiquiti',
      '24:5A:4C': 'Ubiquiti', '44:D9:E7': 'Ubiquiti', '68:72:51': 'Ubiquiti',
      '78:8A:20': 'Ubiquiti', '80:2A:A8': 'Ubiquiti', 'B4:FB:E4': 'Ubiquiti',
      'DC:9F:DB': 'Ubiquiti', 'F0:9F:C2': 'Ubiquiti', 'FC:EC:DA': 'Ubiquiti',
      // Vizio
      '9C:D6:43': 'Vizio',
      // Intel (common in laptops)
      '00:02:B3': 'Intel', '00:03:47': 'Intel', '00:0E:35': 'Intel',
      '00:13:02': 'Intel', '00:13:CE': 'Intel', '00:16:6F': 'Intel',
      '00:16:76': 'Intel', '00:18:DE': 'Intel', '00:1B:21': 'Intel',
      '00:1C:BF': 'Intel', '00:1D:E0': 'Intel', '00:1E:64': 'Intel',
      '00:1F:3B': 'Intel', '00:21:5C': 'Intel', '00:22:FA': 'Intel',
      '00:24:D6': 'Intel', '00:26:C6': 'Intel', '08:11:96': 'Intel',
      '28:C6:3F': 'Intel', '34:02:86': 'Intel', '48:51:B7': 'Intel',
      '5C:87:9C': 'Intel', '7C:5C:F8': 'Intel', 'A4:34:D9': 'Intel',
      'B4:96:91': 'Intel', 'CC:3D:82': 'Intel', 'F8:63:3F': 'Intel',
      // Microsoft
      '28:18:78': 'Microsoft', '7C:1E:52': 'Microsoft', 'DC:53:60': 'Microsoft',
      // Xiaomi
      '00:9E:C8': 'Xiaomi', '0C:1D:AF': 'Xiaomi', '10:2A:B3': 'Xiaomi',
      '14:F6:5A': 'Xiaomi', '28:6C:07': 'Xiaomi', '34:80:B3': 'Xiaomi',
      '50:64:2B': 'Xiaomi', '64:09:80': 'Xiaomi', '74:23:44': 'Xiaomi',
      '78:02:F8': 'Xiaomi', '8C:F7:10': 'Xiaomi',
      // Dell
      '00:06:5B': 'Dell', '00:08:74': 'Dell', '00:0B:DB': 'Dell',
      '00:11:43': 'Dell', '00:14:22': 'Dell', '00:16:F0': 'Dell',
      '00:18:8B': 'Dell', '00:1A:A0': 'Dell', '00:1E:4F': 'Dell',
      '00:21:70': 'Dell', '00:24:E8': 'Dell', '14:18:77': 'Dell',
      '18:A9:9B': 'Dell', '24:6E:96': 'Dell', '34:17:EB': 'Dell',
      '44:A8:42': 'Dell', '5C:F9:DD': 'Dell', '78:45:C4': 'Dell',
      'B8:AC:6F': 'Dell', 'D0:94:66': 'Dell', 'F8:BC:12': 'Dell',
      // Wyze
      '2C:AA:8E': 'Wyze', '7C:78:B2': 'Wyze',
      // ecobee
      '44:61:32': 'ecobee',
      // Honeywell
      '00:D0:2D': 'Honeywell',
      // TCL
      'CC:A1:2B': 'TCL', 'F0:2F:74': 'TCL',
      // Hisense
      '00:0F:E2': 'Hisense', 'B4:6B:FC': 'Hisense',
      // Brother
      '00:1B:A9': 'Brother', '00:80:77': 'Brother', '30:05:5C': 'Brother',
      // Ring (Amazon subsidiary — CC:93:4A already under Amazon)
    };

    return vendorMap[oui] ?? 'Unknown';
  }

  /// Detects brand name from combined HTTP text.
  String _detectBrandFromText(String combined) {
    const brands = [
      'Samsung',
      'LG',
      'Sony',
      'Vizio',
      'TCL',
      'Hisense',
      'Philips',
      'Sonos',
      'Bose',
      'JBL',
      'Denon',
      'Yamaha',
      'Harman Kardon',
      'HP',
      'Canon',
      'Epson',
      'Brother',
      'Lexmark',
      'Xerox',
      'Google',
      'Amazon',
      'Apple',
      'Nest',
      'Ring',
      'Roku',
      'TP-Link',
      'Netgear',
      'Linksys',
      'Asus',
      'Belkin',
      'Ubiquiti',
      'Ecobee',
      'Honeywell',
      'Lutron',
      'Wemo',
      'Meross',
      'Govee',
      'Hikvision',
      'Dahua',
      'Wyze',
      'Reolink',
      'Amcrest',
      'Eufy',
      'Synology',
      'QNAP',
      'Western Digital',
      'Whirlpool',
      'GE Appliances',
      'Frigidaire',
      'Bosch',
      'Miele',
      'Dyson',
      'iRobot',
      'Roomba',
      'Shark',
    ];
    for (final brand in brands) {
      if (combined.contains(brand.toLowerCase())) return brand;
    }
    return 'Unknown';
  }

  /// Returns true when the MAC address is locally-administered (randomized).
  ///
  /// IEEE 802 defines bit 1 of the first octet as the locally-administered
  /// (LA) bit. When set to 1 the address was assigned by software, not the
  /// hardware vendor. iOS 14+ and Android 10+ always set this bit for the
  /// per-network randomized MAC they broadcast — no consumer router, printer,
  /// NAS, or smart-home device does this. So: LA bit = 1 → phone / tablet.
  static bool _isRandomizedMac(String mac) {
    if (mac.length < 2) return false;
    final firstByte = int.tryParse(mac.substring(0, 2), radix: 16) ?? 0;
    return (firstByte & 0x02) != 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 1 — UPnP/SSDP Discovery
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<WifiDevice>> _runUpnpDiscovery(
    void Function(int, String)? onProgress,
  ) async {
    final rawResponses = <String>{};
    final devices = <WifiDevice>[];

    // Bind UDP socket
    _log('UPnP', 'Binding UDP socket...');
    RawDatagramSocket socket;
    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
        reusePort: false,
        ttl: 4,
      );
    } on Object catch (e) {
      _log('UPnP', '❌ Failed to bind UDP socket', e.toString());
      return devices;
    }

    // Enable broadcast and join SSDP multicast group for better response reception.
    // On some Android devices, the WiFi driver drops multicast responses unless
    // the socket has explicitly joined the group.
    socket.broadcastEnabled = true;
    try {
      socket.joinMulticast(InternetAddress(_ssdpMulticast));
      _log('UPnP', '✅ Joined SSDP multicast group $_ssdpMulticast');
    } on Object catch (e) {
      _log('UPnP', '⚠️ Could not join multicast group', e.toString());
    }

    // Send M-SEARCH 3 times (UDP is unreliable, packets may get lost)
    final packet = _msearchPacket.codeUnits;
    for (int i = 1; i <= 3; i++) {
      socket.send(packet, InternetAddress(_ssdpMulticast), _ssdpPort);
      _log('UPnP', '📤 M-SEARCH broadcast #$i sent');
      if (i < 3) await Future.delayed(const Duration(milliseconds: 500));
    }

    onProgress?.call(45, 'Listening for UPnP responses...');
    _log('UPnP', 'Waiting ${_ssdpTimeout.inSeconds}s for device responses...');

    // Collect responses
    final completer = Completer<void>();
    final timer = Timer(_ssdpTimeout, () {
      if (!completer.isCompleted) completer.complete();
    });

    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = socket.receive();
        if (datagram != null) {
          rawResponses.add(String.fromCharCodes(datagram.data).trim());
        }
      }
    });

    await completer.future;
    timer.cancel();
    socket.close();

    _log('UPnP', '📥 Received ${rawResponses.length} raw SSDP responses');

    // Extract LOCATION URLs
    final locationUrls = <String>{};
    for (final response in rawResponses) {
      final url = _extractLocationUrl(response);
      if (url != null) {
        locationUrls.add(url);
      }
    }

    _log(
      'UPnP',
      '🔗 ${locationUrls.length} unique device descriptor URLs found',
    );
    for (final url in locationUrls) {
      _log('UPnP', '   → $url');
    }

    // Fetch XML descriptors in parallel
    onProgress?.call(50, 'Loading ${locationUrls.length} device details...');
    final futures = locationUrls.map((url) => _fetchDeviceInfo(url)).toList();
    final results = await Future.wait(futures, eagerError: false);

    for (final device in results) {
      if (device != null) {
        devices.add(device);
        _log(
          'UPnP',
          '📦 ${device.deviceName}',
          'Brand: ${device.manufacturer}, Model: ${device.modelNumber ?? "N/A"}, '
              'Serial: ${device.serialNumber ?? "N/A"}, IP: ${device.ipAddress}',
        );
      }
    }

    return devices;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 2 — mDNS/Bonjour Discovery
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<WifiDevice>> _runMdnsDiscovery(
    void Function(int, String)? onProgress,
  ) async {
    final devices = <WifiDevice>[];

    for (final svc in _mdnsServiceTypes) {
      try {
        final found = await _queryMdnsService(svc);
        if (found.isNotEmpty) {
          devices.addAll(found);
          _log(
            'mDNS',
            '   ${svc.type}: ${found.map((d) => d.deviceName).join(", ")}',
          );
        }
      } on Object catch (e) {
        _log(
          'mDNS',
          '   ${svc.type}: error — ${e.toString().split('\n').first}',
        );
      }
    }

    onProgress?.call(75, 'mDNS done. ${devices.length} device(s).');
    return devices;
  }

  Future<List<WifiDevice>> _queryMdnsService(
    _MdnsServiceType serviceType,
  ) async {
    final devices = <WifiDevice>[];

    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
        reusePort: false,
      );

      final queryPacket = _buildDnsQuery('${serviceType.type}.local');
      socket.send(queryPacket, InternetAddress('224.0.0.251'), 5353);

      // FIX 1 + 6: collect fully parsed records (IP + TXT)
      final records = <_MdnsFullRecord>[];
      final completer = Completer<void>();
      final timer = Timer(const Duration(seconds: 2), () {
        if (!completer.isCompleted) completer.complete();
      });

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final parsed = _parseMdnsFullResponse(
              datagram.data,
              serviceType.type,
            );
            records.addAll(parsed);
          }
        }
      });

      await completer.future;
      timer.cancel();
      socket.close();

      // Deduplicate by instanceName (multiple datagrams can repeat same device)
      final seen = <String>{};
      for (final r in records) {
        if (!seen.add(r.instanceName.toLowerCase())) continue;

        // ── Resolve IP: A record → DNS lookup → Layer 0 hostname match ──
        String resolvedIp = r.ipAddress ?? 'mDNS';
        if (r.ipAddress == null && r.hostname != null) {
          // Strip trailing dot for lookup
          final lookupHost = r.hostname!.replaceAll(RegExp(r'\.$'), '');
          // Attempt a standard DNS A record lookup on the .local hostname
          try {
            final addresses = await InternetAddress.lookup(
              lookupHost,
            ).timeout(const Duration(seconds: 2));
            final v4 = addresses.firstWhere(
              (a) => a.type == InternetAddressType.IPv4,
              orElse: () => addresses.first,
            );
            resolvedIp = v4.address;
            _log('mDNS', '   DNS lookup $lookupHost → $resolvedIp');
          } on Object catch (_) {
            // DNS lookup failed — try matching hostname against Layer 0 devices
            final shortHost = lookupHost.replaceAll('.local', '').toLowerCase();
            for (final d in _layer0Devices) {
              final dHost = (d.hostname ?? d.dhcpHostname ?? '')
                  .replaceAll('.local', '')
                  .toLowerCase();
              if (dHost.isNotEmpty && dHost == shortHost) {
                resolvedIp = d.ipAddress;
                _log(
                  'mDNS',
                  '   Hostname match $shortHost → $resolvedIp (Layer 0)',
                );
                break;
              }
            }
          }
        }

        // Infer manufacturer from mDNS service type before falling back to name parsing
        final mfr = _mdnsManufacturer(
          serviceType.type,
          r.friendlyName ?? r.instanceName,
        );
        // Filter garbage model numbers (internal board IDs, version strings, placeholders)
        final mdl = _sanitizeModelNumber(r.model);
        // Filter garbage serials (MAC addresses, pure hex, UUIDs, placeholders)
        final ser = _sanitizeSerial(r.deviceId);
        devices.add(
          WifiDevice(
            ipAddress: resolvedIp,
            manufacturer: mfr,
            // FIX 6: prefer TXT fn= (friendly name) over raw instance name
            deviceName: r.friendlyName ?? r.instanceName,
            // FIX 6: propagate TXT md= as model number
            modelNumber: mdl,
            // Propagate TXT deviceId as serial number
            serialNumber: ser,
            deviceTypeRaw: serviceType.type,
            deviceCategory: serviceType.humanCategory,
            iconCategory: serviceType.defaultIcon,
            // Higher confidence when we resolved a real IP
            confidenceScore: resolvedIp != 'mDNS' ? 65 : 50,
            discoveryMethod: 'mdns',
            // Propagate TXT osvers= as OS hint
            osHint: r.osVersion,
          ),
        );
      }
    } on Object catch (_) {}

    return devices;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FIX 1 + 6: Full mDNS response parser
  //
  // Parses ALL record types (PTR, A, SRV, TXT) from a single mDNS datagram,
  // then correlates them using DNS pointer chains:
  //   PTR → instance name
  //   SRV → instance name → target hostname
  //   A   → hostname → IPv4
  //   TXT → instance name → {key: value} (model, friendly name, OS version…)
  // ─────────────────────────────────────────────────────────────────────────

  List<_MdnsFullRecord> _parseMdnsFullResponse(
    List<int> data,
    String serviceType,
  ) {
    if (data.length < 12) return [];

    final questionCount = (data[4] << 8) | data[5];
    final answerCount = (data[6] << 8) | data[7];
    final authorityCount = (data[8] << 8) | data[9];
    final additionalCount = (data[10] << 8) | data[11];

    int offset = 12;

    // ── Skip questions section ──────────────────────────────────────────
    for (int q = 0; q < questionCount && offset < data.length; q++) {
      offset = _skipDnsName(data, offset);
      offset += 4; // type(2) + class(2)
    }

    // ── Correlation maps ────────────────────────────────────────────────
    final aMap = <String, String>{}; // hostname        → IPv4
    final srvMap = <String, String>{}; // instance name   → target hostname
    final txtMap =
        <String, Map<String, String>>{}; // instance name   → TXT key-value
    final ptrTargets = <String>[]; // PTR RDATA values (instance names)

    final totalRR = answerCount + authorityCount + additionalCount;
    for (int i = 0; i < totalRR && offset < data.length - 10; i++) {
      final nameOffset = offset;
      offset = _skipDnsName(data, offset);
      if (offset + 10 > data.length) break;

      final rType = (data[offset] << 8) | data[offset + 1];
      // skip class(2) + TTL(4) = 6 bytes, then read rdlength(2)
      final rdLength = (data[offset + 8] << 8) | data[offset + 9];
      offset += 10;

      if (offset + rdLength > data.length) break;
      final rdataOffset = offset;
      final name = _decodeDnsName(data, nameOffset);

      switch (rType) {
        case 1: // A record → 4 bytes = IPv4
          if (rdLength == 4) {
            final ip =
                '${data[rdataOffset]}.${data[rdataOffset + 1]}'
                '.${data[rdataOffset + 2]}.${data[rdataOffset + 3]}';
            if (ip != '0.0.0.0') aMap[name] = ip;
          }
          break;
        case 12: // PTR → DNS name for the service instance
          final target = _decodeDnsName(data, rdataOffset);
          if (target.isNotEmpty) ptrTargets.add(target);
          break;
        case 16: // TXT → length-prefixed "key=value" strings
          final txt = _decodeTxtRecord(data, rdataOffset, rdLength);
          if (txt.isNotEmpty) txtMap[name] = txt;
          break;
        case 33: // SRV → priority(2)+weight(2)+port(2)+target DNS name
          if (rdLength >= 7) {
            final targetName = _decodeDnsName(data, rdataOffset + 6);
            if (targetName.isNotEmpty) srvMap[name] = targetName;
          }
          break;
      }
      offset += rdLength;
    }

    // ── Correlate PTR targets to full records ───────────────────────────
    final result = <_MdnsFullRecord>[];
    for (final instanceFull in ptrTargets) {
      // Strip the service type + .local suffix to get the human-readable name
      String cleaned = instanceFull
          .replaceAll('.$serviceType.local.', '')
          .replaceAll('.$serviceType.local', '')
          .replaceAll('.local.', '')
          .replaceAll('.local', '')
          .trim();
      // Strip 12-char hex MAC prefix used in AirPlay/RAOP instance names
      // e.g. "9A4EE5FF67BB@Kishan's MacBook Air" → "Kishan's MacBook Air"
      cleaned = cleaned.replaceFirst(RegExp(r'^[0-9A-Fa-f]{12}@'), '');
      if (cleaned.isEmpty || cleaned == serviceType) continue;

      // Resolve IP: instance → hostname (via SRV) → IP (via A)
      String? ip;
      final srvTarget = srvMap[instanceFull];
      if (srvTarget != null) {
        ip = aMap[srvTarget] ?? aMap[srvTarget.replaceAll(RegExp(r'\.$'), '')];
      }

      // TXT record fields
      final txt = txtMap[instanceFull] ?? {};
      final model = txt['md'] ?? txt['model'];
      final fn = txt['fn'];
      final osVersion = txt['osvers'] ?? txt['os_version'];
      final deviceId = txt['id'] ?? txt['deviceid'] ?? txt['serialnumber'];

      result.add(
        _MdnsFullRecord(
          instanceName: cleaned,
          ipAddress: (ip != null && ip.isNotEmpty) ? ip : null,
          hostname: srvTarget,
          model: model,
          friendlyName: fn,
          osVersion: osVersion,
          deviceId: deviceId,
        ),
      );
    }
    return result;
  }

  /// Decode TXT record RDATA: a series of length-prefixed "key=value" strings.
  Map<String, String> _decodeTxtRecord(List<int> data, int offset, int length) {
    final result = <String, String>{};
    final end = offset + length;
    while (offset < end && offset < data.length) {
      final len = data[offset++];
      if (len == 0 || offset + len > data.length) break;
      final str = utf8.decode(
        data.sublist(offset, offset + len),
        allowMalformed: true,
      );
      offset += len;
      final eq = str.indexOf('=');
      if (eq > 0) {
        result[str.substring(0, eq).toLowerCase()] = str.substring(eq + 1);
      }
    }
    return result;
  }

  /// Skip a DNS name field (handles compression pointers), returning the
  /// offset of the first byte AFTER the name.
  int _skipDnsName(List<int> data, int offset) {
    while (offset < data.length) {
      if (data[offset] == 0) return offset + 1;
      if ((data[offset] & 0xC0) == 0xC0) return offset + 2;
      offset += data[offset] + 1;
    }
    return offset;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 5 — Advanced API & HTTP Banner Probing
  //
  // Runs AFTER layers 0–3 on the fully merged + enriched device list.
  // Only targets devices that are still "Unknown" or have confidence < 85.
  //
  // New probes added here (on top of what Layer 0 already does):
  //   • Home Assistant  port 8123  /api/         → version + "API running"
  //   • Tasmota         port 80    /cm?cmnd=...  → JSON with DeviceName
  //   • Shelly Gen1/2   port 80    /shelly / /rpc/Shelly.GetDeviceInfo
  //   • Synology NAS    port 5000/5001            → title "DiskStation"
  //   • QNAP NAS        port 8080                 → title "QNAP"
  //   • Hikvision cam   port 80    /ISAPI/System/deviceInfo
  //   • Dahua cam       port 80    /cgi-bin/magicBox.cgi
  //   • ONVIF           port 80    SOAP probe
  //   • Generic banner  all HTTP ports → Server: header + <title>
  //     Fingerprints: FRITZ!Box, D-Link, OpenWrt, MikroTik, DD-WRT,
  //                   Huawei, Pi-hole, Plex, Jellyfin, Emby, Tasmota...
  // ═══════════════════════════════════════════════════════════════════════════

  static const _bannerHttpPorts = [
    80,
    8080,
    8443,
    443,
    81,
    8081,
    8181,
    8888,
    8096,
    9000,
    9090,
    10000,
    3000,
    32400,
  ];

  // ignore: unused_element
  // Disabled for performance: Layer 5 probing removed to reduce scan time
  Future<List<WifiDevice>> _runAdvancedProbeLayer(
    List<WifiDevice> devices,
  ) async {
    _log('L5', '───────────────────────────────────────────────────');
    _log('L5', '🔬 LAYER 5: Advanced API & HTTP Banner Probing');
    _log(
      'L5',
      '   Targeting devices with confidence < 85 or unknown manufacturer',
    );

    final improved = <WifiDevice>[];
    int probeCount = 0;

    for (final device in devices) {
      // mDNS-only entries have no IP to probe
      if (device.ipAddress == 'mDNS') {
        improved.add(device);
        continue;
      }

      // Skip already well-identified devices
      if (_isWellIdentified(device)) {
        improved.add(device);
        continue;
      }

      WifiDevice updated = device;
      final ports = device.openPorts;

      // ── Home Assistant (port 8123) ──────────────────────────────────
      if (!_isWellIdentified(updated) && ports.contains(8123)) {
        final ha = await _probeHomeAssistant(device.ipAddress);
        if (ha != null) {
          updated = _applyProbeResult(device, ha);
          probeCount++;
        }
      }

      // ── Tasmota (port 80) ───────────────────────────────────────────
      if (!_isWellIdentified(updated) && ports.contains(80)) {
        final tmota = await _probeTasmota(device.ipAddress);
        if (tmota != null) {
          updated = _applyProbeResult(device, tmota);
          probeCount++;
        }
      }

      // ── Shelly Gen1/Gen2 (port 80) ──────────────────────────────────
      if (!_isWellIdentified(updated) && ports.contains(80)) {
        final shelly = await _probeShelly(device.ipAddress);
        if (shelly != null) {
          updated = _applyProbeResult(device, shelly);
          probeCount++;
        }
      }

      // ── Synology NAS (port 5000 or 5001) ───────────────────────────
      if (!_isWellIdentified(updated) &&
          (ports.contains(5000) || ports.contains(5001))) {
        final nas = await _probeSynology(device.ipAddress, ports);
        if (nas != null) {
          updated = _applyProbeResult(device, nas);
          probeCount++;
        }
      }

      // ── QNAP NAS (port 8080) ────────────────────────────────────────
      if (!_isWellIdentified(updated) && ports.contains(8080)) {
        final qnap = await _probeQnap(device.ipAddress);
        if (qnap != null) {
          updated = _applyProbeResult(device, qnap);
          probeCount++;
        }
      }

      // ── Hikvision / Dahua / ONVIF Camera (port 80) ─────────────────
      if (!_isWellIdentified(updated) &&
          ports.contains(80) &&
          (updated.deviceCategory.toLowerCase().contains('camera') ||
              updated.iconCategory == IconCategory.camera ||
              updated.confidenceScore < 35)) {
        final cam = await _probeIpCamera(device.ipAddress);
        if (cam != null) {
          updated = _applyProbeResult(device, cam);
          probeCount++;
        }
      }

      // ── WSD/DPWS (port 5357) — Windows PCs + certain printers ──────
      // Port 5357 is Windows Web Services on Devices. When open, a GET to
      // the device description endpoint returns an XML/HTML page that
      // often contains the PC name, manufacturer, and model. This is the
      // fastest reliable way to identify Windows machines.
      if (!_isWellIdentified(updated) && ports.contains(5357)) {
        final wsd = await _probeWsd(device.ipAddress);
        if (wsd != null) {
          updated = _applyProbeResult(device, wsd);
          probeCount++;
        }
      }

      // ── Plex Media Server (port 32400) ──────────────────────────────
      if (!_isWellIdentified(updated) && ports.contains(32400)) {
        try {
          final resp = await http
              .get(Uri.parse('http://${device.ipAddress}:32400/identity'))
              .timeout(const Duration(milliseconds: 1200));
          if (resp.statusCode == 200 && resp.body.contains('Plex')) {
            final versionMatch = RegExp(
              r'version="([^"]+)"',
              caseSensitive: false,
            ).firstMatch(resp.body);
            updated = _applyProbeResult(
              updated,
              WifiDevice(
                ipAddress: device.ipAddress,
                manufacturer: 'Plex',
                deviceName: 'Plex Media Server',
                firmwareVersion: versionMatch?.group(1),
                deviceTypeRaw: 'plex',
                deviceCategory: 'Media Server',
                iconCategory: IconCategory.generic,
                confidenceScore: 92,
                httpBanner: 'Plex Media Server',
              ),
            );
            probeCount++;
          }
        } on Object catch (_) {}
      }

      // ── Jellyfin Media Server (port 8096) ───────────────────────────
      if (!_isWellIdentified(updated) && ports.contains(8096)) {
        try {
          final resp = await http
              .get(
                Uri.parse('http://${device.ipAddress}:8096/System/Info/Public'),
              )
              .timeout(const Duration(milliseconds: 1200));
          if (resp.statusCode == 200) {
            final j = jsonDecode(resp.body) as Map<String, dynamic>;
            if (j['ProductName'] != null || j['ServerName'] != null) {
              updated = _applyProbeResult(
                updated,
                WifiDevice(
                  ipAddress: device.ipAddress,
                  manufacturer: 'Jellyfin',
                  deviceName: j['ServerName']?.toString() ?? 'Jellyfin Server',
                  firmwareVersion: j['Version']?.toString(),
                  deviceTypeRaw: 'jellyfin',
                  deviceCategory: 'Media Server',
                  iconCategory: IconCategory.generic,
                  confidenceScore: 92,
                  httpBanner: 'Jellyfin',
                ),
              );
              probeCount++;
            }
          }
        } on Object catch (_) {}
      }

      // ── MQTT Broker (port 1883) ─────────────────────────────────────
      // Port 1883 open = MQTT broker (OpenHAB, Node-RED, Mosquitto, Home Hub).
      // No HTTP API — just flag it as smart hub from port presence alone.
      if (!_isWellIdentified(updated) && ports.contains(1883)) {
        final mqttName = updated.hostname ?? updated.deviceName;
        updated = _applyProbeResult(
          updated,
          WifiDevice(
            ipAddress: device.ipAddress,
            manufacturer: updated.manufacturer != 'Unknown'
                ? updated.manufacturer
                : 'MQTT Hub',
            deviceName: mqttName.startsWith('Device at')
                ? 'Smart Home Hub (MQTT)'
                : mqttName,
            deviceTypeRaw: 'mqtt-broker',
            deviceCategory: 'Smart Hub',
            iconCategory: IconCategory.generic,
            confidenceScore: updated.confidenceScore + 15,
            httpBanner: 'MQTT:1883',
          ),
        );
        probeCount++;
      }

      // ── FIX 3: 12 additional vendor-specific probes ─────────────────

      // TP-Link Kasa (port 80, /api/v1/device/info)
      if (!_isWellIdentified(updated) && ports.contains(80)) {
        try {
          final resp = await http
              .get(Uri.parse('http://${device.ipAddress}/api/v1/device/info'))
              .timeout(const Duration(milliseconds: 1000));
          if (resp.statusCode == 200 &&
              resp.body.toLowerCase().contains('tp-link')) {
            final j = jsonDecode(resp.body) as Map<String, dynamic>;
            final data = j['data'] as Map<String, dynamic>? ?? j;
            updated = _applyProbeResult(
              updated,
              WifiDevice(
                ipAddress: device.ipAddress,
                manufacturer: 'TP-Link',
                deviceName:
                    data['alias']?.toString() ??
                    data['device_name']?.toString() ??
                    'TP-Link Kasa',
                modelNumber: data['model']?.toString(),
                deviceTypeRaw: 'tplink-kasa',
                deviceCategory: 'Smart Plug',
                iconCategory: IconCategory.smartPlug,
                confidenceScore: 88,
                httpBanner: 'TP-Link',
              ),
            );
            probeCount++;
          }
        } on Object catch (_) {}
      }

      // Tuya / SmartLife (port 80, /gw.json)
      if (!_isWellIdentified(updated) && ports.contains(80)) {
        try {
          final resp = await http
              .get(Uri.parse('http://${device.ipAddress}/gw.json'))
              .timeout(const Duration(milliseconds: 1000));
          if (resp.statusCode == 200 &&
              resp.body.toLowerCase().contains('tuya')) {
            final j = jsonDecode(resp.body) as Map<String, dynamic>;
            updated = _applyProbeResult(
              updated,
              WifiDevice(
                ipAddress: device.ipAddress,
                manufacturer: 'Tuya',
                deviceName:
                    j['devAttribute']?.toString() ??
                    j['name']?.toString() ??
                    'Tuya Device',
                deviceTypeRaw: 'tuya',
                deviceCategory: 'Smart Device',
                iconCategory: IconCategory.smartPlug,
                confidenceScore: 82,
                httpBanner: 'Tuya',
              ),
            );
            probeCount++;
          }
        } on Object catch (_) {}
      }

      // Ubiquiti UniFi (port 443, /api/self)
      if (!_isWellIdentified(updated) &&
          (ports.contains(443) || ports.contains(80))) {
        try {
          final port = ports.contains(443) ? 443 : 80;
          final scheme = port == 443 ? 'https' : 'http';
          final resp = await http
              .get(Uri.parse('$scheme://${device.ipAddress}/api/self'))
              .timeout(const Duration(milliseconds: 1000));
          if (resp.statusCode == 200 &&
              resp.body.toLowerCase().contains('ubnt')) {
            final j = jsonDecode(resp.body) as Map<String, dynamic>;
            final d = j['data'] as Map<String, dynamic>? ?? j;
            updated = _applyProbeResult(
              updated,
              WifiDevice(
                ipAddress: device.ipAddress,
                manufacturer: 'Ubiquiti',
                deviceName: d['name']?.toString() ?? 'UniFi Device',
                modelNumber: d['model']?.toString(),
                deviceTypeRaw: 'ubiquiti-unifi',
                deviceCategory: 'Network Equipment',
                iconCategory: IconCategory.router,
                confidenceScore: 90,
                httpBanner: 'Ubiquiti UniFi',
              ),
            );
            probeCount++;
          }
        } on Object catch (_) {}
      }

      // Reolink camera (port 80, /api.cgi?cmd=GetDevInfo)
      if (!_isWellIdentified(updated) && ports.contains(80)) {
        try {
          final resp = await http
              .get(
                Uri.parse('http://${device.ipAddress}/api.cgi?cmd=GetDevInfo'),
              )
              .timeout(const Duration(milliseconds: 1000));
          if (resp.statusCode == 200 &&
              resp.body.toLowerCase().contains('reolink')) {
            final j = jsonDecode(resp.body);
            final info =
                (j is List<dynamic> ? j.first : j) as Map<String, dynamic>;
            final val = info['value'] as Map<String, dynamic>? ?? {};
            final devInfo = val['DevInfo'] as Map<String, dynamic>? ?? {};
            updated = _applyProbeResult(
              updated,
              WifiDevice(
                ipAddress: device.ipAddress,
                manufacturer: 'Reolink',
                deviceName: devInfo['name']?.toString() ?? 'Reolink Camera',
                modelNumber:
                    devInfo['model']?.toString() ??
                    devInfo['hardVer']?.toString(),
                serialNumber: devInfo['serial']?.toString(),
                deviceTypeRaw: 'reolink-camera',
                deviceCategory: 'IP Camera',
                iconCategory: IconCategory.camera,
                confidenceScore: 92,
                httpBanner: 'Reolink',
              ),
            );
            probeCount++;
          }
        } on Object catch (_) {}
      }

      // D-Link / HNAP (port 80, /HNAP1/)
      if (!_isWellIdentified(updated) && ports.contains(80)) {
        try {
          final resp = await http
              .get(Uri.parse('http://${device.ipAddress}/HNAP1/'))
              .timeout(const Duration(milliseconds: 1000));
          if (resp.statusCode == 200 &&
              resp.body.toLowerCase().contains('hnap')) {
            final nameMatch = RegExp(
              r'<ModelName>([^<]+)</ModelName>',
              caseSensitive: false,
            ).firstMatch(resp.body);
            final mfrMatch = RegExp(
              r'<VendorName>([^<]+)</VendorName>',
              caseSensitive: false,
            ).firstMatch(resp.body);
            updated = _applyProbeResult(
              updated,
              WifiDevice(
                ipAddress: device.ipAddress,
                manufacturer: mfrMatch?.group(1)?.trim() ?? 'D-Link',
                deviceName: nameMatch?.group(1)?.trim() ?? 'D-Link Device',
                modelNumber: nameMatch?.group(1)?.trim(),
                deviceTypeRaw: 'dlink-hnap',
                deviceCategory: 'Router / Gateway',
                iconCategory: IconCategory.router,
                confidenceScore: 88,
                httpBanner: 'HNAP',
              ),
            );
            probeCount++;
          }
        } on Object catch (_) {}
      }

      // Meross (port 80, /device/info)
      if (!_isWellIdentified(updated) && ports.contains(80)) {
        try {
          final resp = await http
              .get(Uri.parse('http://${device.ipAddress}/device/info'))
              .timeout(const Duration(milliseconds: 1000));
          if (resp.statusCode == 200 &&
              resp.body.toLowerCase().contains('meross')) {
            final j = jsonDecode(resp.body) as Map<String, dynamic>;
            updated = _applyProbeResult(
              updated,
              WifiDevice(
                ipAddress: device.ipAddress,
                manufacturer: 'Meross',
                deviceName:
                    j['friendlyName']?.toString() ??
                    j['devName']?.toString() ??
                    'Meross Device',
                modelNumber: j['model']?.toString(),
                deviceTypeRaw: 'meross',
                deviceCategory: 'Smart Plug',
                iconCategory: IconCategory.smartPlug,
                confidenceScore: 86,
                httpBanner: 'Meross',
              ),
            );
            probeCount++;
          }
        } on Object catch (_) {}
      }

      // Wyze (port 80, /api/v1/device/list)
      if (!_isWellIdentified(updated) && ports.contains(80)) {
        try {
          final resp = await http
              .get(Uri.parse('http://${device.ipAddress}/api/v1/device/list'))
              .timeout(const Duration(milliseconds: 1000));
          if (resp.statusCode == 200 &&
              resp.body.toLowerCase().contains('wyze')) {
            updated = _applyProbeResult(
              updated,
              WifiDevice(
                ipAddress: device.ipAddress,
                manufacturer: 'Wyze',
                deviceName: 'Wyze Device',
                deviceTypeRaw: 'wyze',
                deviceCategory: 'Smart Home',
                iconCategory: IconCategory.camera,
                confidenceScore: 84,
                httpBanner: 'Wyze',
              ),
            );
            probeCount++;
          }
        } on Object catch (_) {}
      }

      // Eufy (port 55443, /app/api/v1/info)
      if (!_isWellIdentified(updated)) {
        try {
          final resp = await http
              .get(
                Uri.parse('http://${device.ipAddress}:55443/app/api/v1/info'),
              )
              .timeout(const Duration(milliseconds: 1000));
          if (resp.statusCode == 200 &&
              resp.body.toLowerCase().contains('eufy')) {
            final j = jsonDecode(resp.body) as Map<String, dynamic>;
            updated = _applyProbeResult(
              updated,
              WifiDevice(
                ipAddress: device.ipAddress,
                manufacturer: 'Eufy',
                deviceName: j['deviceName']?.toString() ?? 'Eufy Device',
                modelNumber: j['model']?.toString(),
                deviceTypeRaw: 'eufy',
                deviceCategory: 'Smart Home',
                iconCategory: IconCategory.camera,
                confidenceScore: 88,
                httpBanner: 'Eufy',
              ),
            );
            probeCount++;
          }
        } on Object catch (_) {}
      }

      // Ezviz (port 80, /api/device/info)
      if (!_isWellIdentified(updated) && ports.contains(80)) {
        try {
          final resp = await http
              .get(Uri.parse('http://${device.ipAddress}/api/device/info'))
              .timeout(const Duration(milliseconds: 1000));
          if (resp.statusCode == 200 &&
              resp.body.toLowerCase().contains('ezviz')) {
            final j = jsonDecode(resp.body) as Map<String, dynamic>;
            updated = _applyProbeResult(
              updated,
              WifiDevice(
                ipAddress: device.ipAddress,
                manufacturer: 'Ezviz',
                deviceName: j['deviceName']?.toString() ?? 'Ezviz Camera',
                modelNumber: j['model']?.toString(),
                serialNumber: j['serial']?.toString(),
                deviceTypeRaw: 'ezviz',
                deviceCategory: 'IP Camera',
                iconCategory: IconCategory.camera,
                confidenceScore: 88,
                httpBanner: 'Ezviz',
              ),
            );
            probeCount++;
          }
        } on Object catch (_) {}
      }

      // Generic /info endpoint (any HTTP port)
      if (!_isWellIdentified(updated) && ports.contains(80)) {
        try {
          final resp = await http
              .get(Uri.parse('http://${device.ipAddress}/info'))
              .timeout(const Duration(milliseconds: 1000));
          if (resp.statusCode == 200 && resp.body.isNotEmpty) {
            try {
              final j = jsonDecode(resp.body) as Map<String, dynamic>;
              final mfr =
                  j['manufacturer']?.toString() ??
                  j['vendor']?.toString() ??
                  j['brand']?.toString();
              final name =
                  j['device_name']?.toString() ??
                  j['name']?.toString() ??
                  j['model']?.toString();
              final mod = j['model']?.toString() ?? j['model_name']?.toString();
              final ser =
                  j['serial']?.toString() ?? j['serial_number']?.toString();
              if (mfr != null || name != null) {
                updated = _applyProbeResult(
                  updated,
                  WifiDevice(
                    ipAddress: device.ipAddress,
                    manufacturer: mfr ?? updated.manufacturer,
                    deviceName: name ?? updated.deviceName,
                    modelNumber: mod,
                    serialNumber: ser,
                    deviceTypeRaw: 'generic-info',
                    deviceCategory: updated.deviceCategory,
                    iconCategory: updated.iconCategory,
                    confidenceScore: updated.confidenceScore + 10,
                  ),
                );
                probeCount++;
              }
            } on Object catch (_) {}
          }
        } on Object catch (_) {}
      }

      // Generic /status.json endpoint
      if (!_isWellIdentified(updated) && ports.contains(80)) {
        try {
          final resp = await http
              .get(Uri.parse('http://${device.ipAddress}/status.json'))
              .timeout(const Duration(milliseconds: 1000));
          if (resp.statusCode == 200 && resp.body.isNotEmpty) {
            try {
              final j = jsonDecode(resp.body) as Map<String, dynamic>;
              final mfr =
                  j['manufacturer']?.toString() ?? j['vendor']?.toString();
              final name =
                  j['device_name']?.toString() ?? j['name']?.toString();
              final mod = j['model']?.toString();
              if (mfr != null || name != null) {
                updated = _applyProbeResult(
                  updated,
                  WifiDevice(
                    ipAddress: device.ipAddress,
                    manufacturer: mfr ?? updated.manufacturer,
                    deviceName: name ?? updated.deviceName,
                    modelNumber: mod,
                    deviceTypeRaw: 'generic-status',
                    deviceCategory: updated.deviceCategory,
                    iconCategory: updated.iconCategory,
                    confidenceScore: updated.confidenceScore + 8,
                  ),
                );
                probeCount++;
              }
            } on Object catch (_) {}
          }
        } on Object catch (_) {}
      }

      // Generic /device/properties endpoint
      if (!_isWellIdentified(updated) && ports.contains(80)) {
        try {
          final resp = await http
              .get(Uri.parse('http://${device.ipAddress}/device/properties'))
              .timeout(const Duration(milliseconds: 1000));
          if (resp.statusCode == 200 && resp.body.isNotEmpty) {
            try {
              final j = jsonDecode(resp.body) as Map<String, dynamic>;
              final mfr =
                  j['manufacturer']?.toString() ?? j['vendor']?.toString();
              final name =
                  j['device_name']?.toString() ?? j['friendlyName']?.toString();
              final mod =
                  j['model']?.toString() ?? j['modelNumber']?.toString();
              final ser =
                  j['serialNumber']?.toString() ?? j['serial']?.toString();
              if (mfr != null || name != null) {
                updated = _applyProbeResult(
                  updated,
                  WifiDevice(
                    ipAddress: device.ipAddress,
                    manufacturer: mfr ?? updated.manufacturer,
                    deviceName: name ?? updated.deviceName,
                    modelNumber: mod,
                    serialNumber: ser,
                    deviceTypeRaw: 'generic-props',
                    deviceCategory: updated.deviceCategory,
                    iconCategory: updated.iconCategory,
                    confidenceScore: updated.confidenceScore + 10,
                  ),
                );
                probeCount++;
              }
            } on Object catch (_) {}
          }
        } on Object catch (_) {}
      }

      // ── NETLIB Phase 3: Service Version Detection ──────────────────
      // SSH banner (port 22) — reveals OS, distribution, device type
      if (ports.contains(22)) {
        final ssh = await _probeSSHBanner(device.ipAddress);
        if (ssh != null) {
          updated = updated.copyWithEnrichment(
            sshBanner: ssh,
            serviceVersions: {...updated.serviceVersions, 22: ssh},
          );
          final sshId = _identifyFromSSH(ssh);
          if (sshId != null && !_isWellIdentified(updated)) {
            updated = _applyProbeResult(
              updated,
              sshId.copyWithEnrichment(sshBanner: ssh),
            );
            probeCount++;
          }
        }
      }

      // FTP banner (port 21) — reveals NAS, camera, printer type
      if (ports.contains(21)) {
        final ftp = await _probeServiceBanner(device.ipAddress, 21, 'FTP');
        if (ftp != null) {
          updated = updated.copyWithEnrichment(
            serviceVersions: {...updated.serviceVersions, 21: ftp},
          );
          final ftpId = _identifyFromFTP(ftp, device.ipAddress);
          if (ftpId != null && !_isWellIdentified(updated)) {
            updated = _applyProbeResult(updated, ftpId);
            probeCount++;
          }
        }
      }

      // Telnet banner (port 23) — reveals routers, IoT firmware
      if (ports.contains(23)) {
        final telnet = await _probeServiceBanner(
          device.ipAddress,
          23,
          'Telnet',
        );
        if (telnet != null) {
          updated = updated.copyWithEnrichment(
            serviceVersions: {...updated.serviceVersions, 23: telnet},
          );
          final telnetId = _identifyFromTelnet(telnet, device.ipAddress);
          if (telnetId != null && !_isWellIdentified(updated)) {
            updated = _applyProbeResult(updated, telnetId);
            probeCount++;
          }
        }
      }

      // SMTP banner (port 25) — identifies mail servers
      if (ports.contains(25)) {
        final smtp = await _probeServiceBanner(device.ipAddress, 25, 'SMTP');
        if (smtp != null) {
          updated = updated.copyWithEnrichment(
            serviceVersions: {...updated.serviceVersions, 25: smtp},
          );
        }
      }

      // RTSP OPTIONS (port 554) — IP cameras, NVRs
      if (ports.contains(554)) {
        final rtsp = await _probeRTSP(device.ipAddress);
        if (rtsp != null) {
          updated = updated.copyWithEnrichment(
            serviceVersions: {...updated.serviceVersions, 554: rtsp},
          );
          if (!_isWellIdentified(updated)) {
            updated = _applyProbeResult(
              updated,
              WifiDevice(
                ipAddress: device.ipAddress,
                manufacturer: _extractMfrFromRTSP(rtsp) ?? updated.manufacturer,
                deviceName: 'IP Camera',
                deviceTypeRaw: 'rtsp-camera',
                deviceCategory: 'IP Camera',
                iconCategory: IconCategory.camera,
                confidenceScore: 75,
                httpBanner: 'RTSP: $rtsp',
              ),
            );
            probeCount++;
          }
        }
      }

      // ── NETLIB Phase 9: TLS Certificate Extraction ──────────────────
      // Connect to port 443 and read the TLS cert Subject/Issuer.
      // Devices like printers, NAS, routers often put brand+model in CN.
      if (ports.contains(443)) {
        final cert = await _probeTlsCert(device.ipAddress, 443);
        if (cert != null) {
          updated = updated.copyWithEnrichment(tlsCertSubject: cert.$1);
          final certId = _identifyFromTlsCert(
            cert.$1,
            cert.$2,
            device.ipAddress,
          );
          if (certId != null && !_isWellIdentified(updated)) {
            updated = _applyProbeResult(updated, certId);
            probeCount++;
          }
        }
      }
      // Also check port 8443 for alt-HTTPS
      if (ports.contains(8443) && updated.tlsCertSubject == null) {
        final cert = await _probeTlsCert(device.ipAddress, 8443);
        if (cert != null) {
          updated = updated.copyWithEnrichment(tlsCertSubject: cert.$1);
          final certId = _identifyFromTlsCert(
            cert.$1,
            cert.$2,
            device.ipAddress,
          );
          if (certId != null && !_isWellIdentified(updated)) {
            updated = _applyProbeResult(updated, certId);
            probeCount++;
          }
        }
      }

      // ── NETLIB Phase 7: SMB Negotiation ─────────────────────────────
      // Send SMB negotiate to port 445 → get OS version, domain, hostname
      if (ports.contains(445) && !_isWellIdentified(updated)) {
        final smb = await _probeSMB(device.ipAddress);
        if (smb != null) {
          updated = updated.copyWithEnrichment(
            smbOsVersion: smb['os'],
            hostname: updated.hostname ?? smb['computer'],
          );
          final smbId = _identifyFromSMB(smb, device.ipAddress);
          if (smbId != null) {
            updated = _applyProbeResult(updated, smbId);
            probeCount++;
          }
        }
      }

      // ── NETLIB Phase 8: Additional HTTP Endpoints ───────────────────
      // /admin, /cgi-bin/, /webui, /setup.cgi, /login.asp discovery
      if (!_isWellIdentified(updated) && ports.contains(80)) {
        for (final ep in _additionalHttpEndpoints) {
          final result = await _probeHttpEndpoint(
            device.ipAddress,
            ep.$1,
            ep.$2,
          );
          if (result != null) {
            updated = _applyProbeResult(updated, result);
            probeCount++;
            if (_isWellIdentified(updated)) break;
          }
        }
      }

      // ── Generic HTTP banner (Server: header + <title>) ──────────────
      // Runs for any device still unidentified — catches FRITZ!Box, D-Link,
      // OpenWrt, MikroTik, Plex, Home Assistant, Tasmota, Pi-hole, etc.
      if (!_isWellIdentified(updated)) {
        for (final port in ports) {
          if (!_bannerHttpPorts.contains(port)) continue;
          final banner = await _extractHttpBanner(device.ipAddress, port);
          if (banner != null) {
            final candidate = _applyBannerToDevice(
              updated,
              banner.$1,
              banner.$2,
              port,
            );
            if (candidate.confidenceScore > updated.confidenceScore) {
              updated = candidate;
              probeCount++;
            }
            if (_isWellIdentified(updated)) break;
          }
        }
      }

      // ── NETLIB-style Multi-Factor Confidence Boost ──────────────────
      // When multiple independent signals corroborate each other, boost
      // the confidence score. Each signal adds a bonus if it contributes
      // identification data the device didn't have from Layer 0 alone.
      updated = _applyMultiFactorConfidenceBoost(updated);

      if (updated.confidenceScore != device.confidenceScore ||
          updated.manufacturer != device.manufacturer) {
        _log(
          'L5',
          '  ✅ Enhanced ${device.ipAddress}: '
              '"${updated.deviceName}" (${updated.manufacturer}) '
              'score ${device.confidenceScore}→${updated.confidenceScore}'
              '${updated.httpBanner != null ? " [${updated.httpBanner}]" : ""}',
        );
      }

      improved.add(updated);
    }

    _log('L5', '✅ Layer 5 complete — $probeCount device(s) enhanced');
    return improved;
  }

  bool _isWellIdentified(WifiDevice d) =>
      d.confidenceScore >= 85 && d.manufacturer != 'Unknown';

  /// NETLIB-style multi-factor confidence scoring.
  /// Each independent signal that contributed device identification adds a
  /// bonus. When multiple probes agree, the score rises above what any
  /// single probe would give.
  WifiDevice _applyMultiFactorConfidenceBoost(WifiDevice d) {
    if (d.manufacturer == 'Unknown') return d;

    int bonus = 0;

    // Signal 1: MAC vendor matches manufacturer (independent OUI confirmation)
    if (d.macAddress != null) {
      final macVendor = _lookupMacVendor(d.macAddress!).toLowerCase();
      if (macVendor != 'unknown' &&
          d.manufacturer.toLowerCase().contains(macVendor)) {
        bonus += 5; // Two independent sources agree
      }
    }

    // Signal 2: SNMP data present (active protocol-level identification)
    if (d.httpBanner != null && d.httpBanner!.startsWith('SNMP:')) {
      bonus += 5;
    }

    // Signal 3: TLS certificate confirmed the device
    if (d.tlsCertSubject != null && d.tlsCertSubject!.isNotEmpty) {
      bonus += 4;
    }

    // Signal 4: SSH banner contributed identification
    if (d.sshBanner != null && d.sshBanner!.isNotEmpty) {
      bonus += 3;
    }

    // Signal 5: SMB OS version detected
    if (d.smbOsVersion != null && d.smbOsVersion!.isNotEmpty) {
      bonus += 4;
    }

    // Signal 6: Model number known (strong identification)
    if (d.modelNumber != null && d.modelNumber!.isNotEmpty) {
      bonus += 3;
    }

    // Signal 7: Serial number known (unique identification)
    if (d.serialNumber != null && d.serialNumber!.isNotEmpty) {
      bonus += 3;
    }

    // Signal 8: Firmware version extracted
    if (d.firmwareVersion != null && d.firmwareVersion!.isNotEmpty) {
      bonus += 2;
    }

    // Signal 9: Multiple service versions detected (rich fingerprint)
    if (d.serviceVersions.length >= 2) {
      bonus += 3;
    }

    // Signal 10: mDNS + another source agree
    if (d.discoveryMethod.contains('mdns') && d.discoveryMethod.contains('+')) {
      bonus += 3;
    }

    if (bonus == 0) return d;

    // Cap the total score at 98 (100 means "physically verified")
    final newScore = (d.confidenceScore + bonus).clamp(0, 98);
    if (newScore <= d.confidenceScore) return d;

    return d.copyWithEnrichment(confidenceScore: newScore);
  }

  /// Merge a probe result back onto the original device, keeping all
  /// existing fields (MAC, hostname, openPorts, discoveryMethod) while
  /// upgrading the identification fields from the probe.
  WifiDevice _applyProbeResult(WifiDevice original, WifiDevice probe) {
    final better = probe.confidenceScore > original.confidenceScore;
    return WifiDevice(
      ipAddress: original.ipAddress,
      macAddress: original.macAddress ?? probe.macAddress,
      manufacturer: better && probe.manufacturer != 'Unknown'
          ? probe.manufacturer
          : original.manufacturer,
      deviceName:
          better &&
              probe.deviceName.isNotEmpty &&
              !probe.deviceName.startsWith('Device at')
          ? probe.deviceName
          : original.deviceName,
      hostname: original.hostname ?? probe.hostname,
      modelNumber:
          _sanitizeModelNumber(probe.modelNumber) ??
          _sanitizeModelNumber(original.modelNumber),
      serialNumber: probe.serialNumber ?? original.serialNumber,
      deviceTypeRaw: better ? probe.deviceTypeRaw : original.deviceTypeRaw,
      deviceCategory: better ? probe.deviceCategory : original.deviceCategory,
      iconCategory: better && probe.iconCategory != IconCategory.generic
          ? probe.iconCategory
          : original.iconCategory,
      confidenceScore: better
          ? probe.confidenceScore
          : original.confidenceScore,
      discoveryMethod: '${original.discoveryMethod}+probe',
      openPorts: original.openPorts,
      httpBanner: probe.httpBanner ?? original.httpBanner,
      htmlTitle: probe.htmlTitle ?? original.htmlTitle,
      osHint: original.osHint,
      sshBanner: probe.sshBanner ?? original.sshBanner,
      tlsCertSubject: probe.tlsCertSubject ?? original.tlsCertSubject,
      firmwareVersion: probe.firmwareVersion ?? original.firmwareVersion,
      serviceVersions: {...original.serviceVersions, ...probe.serviceVersions},
      smbOsVersion: probe.smbOsVersion ?? original.smbOsVersion,
    );
  }

  // ── Probe: WSD / DPWS (port 5357) ────────────────────────────────────────
  // Windows Web Services on Devices. Windows PCs and some printers publish
  // device info at /DeviceDescription (XML). Returns name + manufacturer if
  // the doc is present and machine-readable.
  Future<WifiDevice?> _probeWsd(String ip) async {
    // Try multiple WSD endpoints — not all Windows versions serve the same path
    final endpoints = [
      'http://$ip:5357/DeviceDescription',
      'http://$ip:5357/',
      'http://$ip:5357/wsd',
    ];
    for (final url in endpoints) {
      try {
        final resp = await http
            .get(Uri.parse(url))
            .timeout(const Duration(milliseconds: 1500));
        if (resp.statusCode != 200 || resp.body.isEmpty) continue;
        final body = resp.body;

        String? friendlyName;
        String? manufacturer;
        String? model;

        final fnMatch = RegExp(
          r'<(?:wsdp:)?FriendlyName>([^<]+)</(?:wsdp:)?FriendlyName>',
          caseSensitive: false,
        ).firstMatch(body);
        if (fnMatch != null) friendlyName = fnMatch.group(1)?.trim();

        final mfrMatch = RegExp(
          r'<(?:wsdp:)?Manufacturer>([^<]+)</(?:wsdp:)?Manufacturer>',
          caseSensitive: false,
        ).firstMatch(body);
        if (mfrMatch != null) manufacturer = mfrMatch.group(1)?.trim();

        final modelMatch = RegExp(
          r'<(?:wsdp:)?ModelName>([^<]+)</(?:wsdp:)?ModelName>',
          caseSensitive: false,
        ).firstMatch(body);
        if (modelMatch != null) model = modelMatch.group(1)?.trim();

        if (friendlyName == null && manufacturer == null) return null;

        // Determine category from port context
        String category = 'Computer';
        IconCategory icon = IconCategory.generic;
        if (model != null &&
            (model.toLowerCase().contains('printer') ||
                model.toLowerCase().contains('laserjet') ||
                model.toLowerCase().contains('officejet'))) {
          category = 'Printer';
          icon = IconCategory.printer;
        }

        return WifiDevice(
          ipAddress: ip,
          manufacturer: manufacturer ?? 'Windows Device',
          deviceName: friendlyName ?? model ?? 'Windows PC',
          modelNumber: model,
          deviceTypeRaw: 'wsd',
          deviceCategory: category,
          iconCategory: icon,
          confidenceScore: 85,
          httpBanner: 'WSD:5357',
        );
      } on Object catch (_) {}
    }
    return null;
  }

  // ── Probe: Home Assistant ─────────────────────────────────────────────────
  Future<WifiDevice?> _probeHomeAssistant(String ip) async {
    try {
      final resp = await http
          .get(Uri.parse('http://$ip:8123/api/'))
          .timeout(const Duration(seconds: 2));
      if (resp.statusCode == 200 &&
          (resp.body.contains('API running') ||
              resp.body.contains('ha_version'))) {
        String version = '';
        try {
          final j = jsonDecode(resp.body) as Map<String, dynamic>;
          version = (j['ha_version'] ?? j['version'] ?? '') as String;
        } on Object catch (_) {}
        return WifiDevice(
          ipAddress: ip,
          manufacturer: 'Home Assistant',
          deviceName: 'Home Assistant${version.isNotEmpty ? " $version" : ""}',
          deviceTypeRaw: 'home-assistant',
          deviceCategory: 'Smart Hub',
          iconCategory: IconCategory.generic,
          confidenceScore: 92,
          httpBanner: 'Home Assistant',
        );
      }
    } on Object catch (_) {}
    // Fallback: parse login page title
    try {
      final resp = await http
          .get(Uri.parse('http://$ip:8123/'))
          .timeout(const Duration(seconds: 2));
      if (resp.statusCode == 200 &&
          resp.body.toLowerCase().contains('home assistant')) {
        return WifiDevice(
          ipAddress: ip,
          manufacturer: 'Home Assistant',
          deviceName: 'Home Assistant Hub',
          deviceTypeRaw: 'home-assistant',
          deviceCategory: 'Smart Hub',
          iconCategory: IconCategory.generic,
          confidenceScore: 80,
          httpBanner: 'Home Assistant',
        );
      }
    } on Object catch (_) {}
    return null;
  }

  // ── Probe: Tasmota smart device ───────────────────────────────────────────
  Future<WifiDevice?> _probeTasmota(String ip) async {
    try {
      final resp = await http
          .get(Uri.parse('http://$ip/cm?cmnd=Status%200'))
          .timeout(const Duration(seconds: 2));
      if (resp.statusCode == 200 && resp.body.contains('Status')) {
        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        final status = j['Status'] as Map<String, dynamic>? ?? j;
        final name =
            (status['DeviceName'] ??
                    status['FriendlyName']?.toString() ??
                    'Tasmota Device')
                as String;
        final module = status['Module']?.toString();
        return WifiDevice(
          ipAddress: ip,
          manufacturer: 'Tasmota',
          deviceName: name,
          modelNumber: module,
          deviceTypeRaw: 'tasmota',
          deviceCategory: 'Smart Plug',
          iconCategory: IconCategory.smartPlug,
          confidenceScore: 92,
          httpBanner: 'Tasmota',
        );
      }
    } on Object catch (_) {}
    // Fallback: main page title contains "Tasmota"
    try {
      final resp = await http
          .get(Uri.parse('http://$ip/'))
          .timeout(const Duration(seconds: 2));
      if (resp.statusCode == 200 &&
          resp.body.toLowerCase().contains('tasmota')) {
        final titleMatch = RegExp(
          r'<title[^>]*>([^<]+)</title>',
          caseSensitive: false,
        ).firstMatch(resp.body);
        final title = titleMatch?.group(1)?.trim() ?? 'Tasmota Device';
        return WifiDevice(
          ipAddress: ip,
          manufacturer: 'Tasmota',
          deviceName: title.length < 60 ? title : 'Tasmota Device',
          deviceTypeRaw: 'tasmota',
          deviceCategory: 'Smart Plug',
          iconCategory: IconCategory.smartPlug,
          confidenceScore: 78,
          httpBanner: 'Tasmota',
        );
      }
    } on Object catch (_) {}
    return null;
  }

  // ── Probe: Shelly Gen1 + Gen2 ─────────────────────────────────────────────
  Future<WifiDevice?> _probeShelly(String ip) async {
    // Gen1: GET /shelly
    try {
      final resp = await http
          .get(Uri.parse('http://$ip/shelly'))
          .timeout(const Duration(seconds: 2));
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        final type = (j['type'] ?? j['model'] ?? 'Shelly Device') as String;
        final appName = (j['app'] ?? j['name']) as String?;
        return WifiDevice(
          ipAddress: ip,
          manufacturer: 'Shelly',
          deviceName: appName ?? type,
          modelNumber: type.isNotEmpty ? type : null,
          deviceTypeRaw: 'shelly',
          deviceCategory: _shellyCategory(type),
          iconCategory: _shellyIcon(type),
          confidenceScore: 92,
          httpBanner: 'Shelly/$type',
        );
      }
    } on Object catch (_) {}
    // Gen2: GET /rpc/Shelly.GetDeviceInfo
    try {
      final resp = await http
          .get(Uri.parse('http://$ip/rpc/Shelly.GetDeviceInfo'))
          .timeout(const Duration(seconds: 2));
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        final model = (j['model'] ?? j['type'] ?? 'Shelly Gen2') as String;
        final name = j['name'] as String?;
        return WifiDevice(
          ipAddress: ip,
          manufacturer: 'Shelly',
          deviceName: name ?? model,
          modelNumber: model,
          deviceTypeRaw: 'shelly-gen2',
          deviceCategory: _shellyCategory(model),
          iconCategory: _shellyIcon(model),
          confidenceScore: 93,
          httpBanner: 'Shelly/$model',
        );
      }
    } on Object catch (_) {}
    return null;
  }

  String _shellyCategory(String type) {
    final t = type.toLowerCase();
    if (t.contains('plug') || t.contains('pm')) return 'Smart Plug';
    if (t.contains('dim') ||
        t.contains('bulb') ||
        t.contains('rgbw') ||
        t.contains('light')) {
      return 'Smart Light';
    }
    if (t.contains('door') ||
        t.contains('window') ||
        t.contains('flood') ||
        t.contains('motion')) {
      return 'Smart Sensor';
    }
    if (t.contains('cam')) return 'IP Camera';
    return 'Smart Switch';
  }

  IconCategory _shellyIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('plug') || t.contains('pm')) return IconCategory.smartPlug;
    if (t.contains('dim') ||
        t.contains('bulb') ||
        t.contains('rgbw') ||
        t.contains('light')) {
      return IconCategory.lightBulb;
    }
    if (t.contains('cam')) return IconCategory.camera;
    return IconCategory.smartPlug;
  }

  // ── Probe: Synology NAS ───────────────────────────────────────────────────
  Future<WifiDevice?> _probeSynology(String ip, List<int> ports) async {
    // Synology DSM uses port 5001 (HTTPS) or 5000 (HTTP)
    for (final port in [5001, 5000]) {
      if (!ports.contains(port)) continue;
      final scheme = port == 5001 ? 'https' : 'http';
      try {
        final resp = await http
            .get(Uri.parse('$scheme://$ip:$port/'))
            .timeout(const Duration(seconds: 3));
        final body = resp.body.toLowerCase();
        if (body.contains('synology') ||
            body.contains('diskstation') ||
            body.contains('dsm')) {
          final titleMatch = RegExp(
            r'<title[^>]*>([^<]+)</title>',
            caseSensitive: false,
          ).firstMatch(resp.body);
          final title = titleMatch?.group(1)?.trim() ?? 'Synology NAS';
          return WifiDevice(
            ipAddress: ip,
            manufacturer: 'Synology',
            deviceName: title.length < 60 ? title : 'Synology DiskStation',
            deviceTypeRaw: 'synology-nas',
            deviceCategory: 'NAS / Storage',
            iconCategory: IconCategory.generic,
            confidenceScore: 90,
            httpBanner: 'Synology DSM',
          );
        }
      } on Object catch (_) {}
    }
    return null;
  }

  // ── Probe: QNAP NAS ───────────────────────────────────────────────────────
  Future<WifiDevice?> _probeQnap(String ip) async {
    try {
      final resp = await http
          .get(Uri.parse('http://$ip:8080/'))
          .timeout(const Duration(seconds: 2));
      final body = resp.body.toLowerCase();
      if (body.contains('qnap') ||
          body.contains('qts') ||
          body.contains('turbonas')) {
        final titleMatch = RegExp(
          r'<title[^>]*>([^<]+)</title>',
          caseSensitive: false,
        ).firstMatch(resp.body);
        final title = titleMatch?.group(1)?.trim() ?? 'QNAP NAS';
        return WifiDevice(
          ipAddress: ip,
          manufacturer: 'QNAP',
          deviceName: title.length < 60 ? title : 'QNAP NAS',
          deviceTypeRaw: 'qnap-nas',
          deviceCategory: 'NAS / Storage',
          iconCategory: IconCategory.generic,
          confidenceScore: 88,
          httpBanner: 'QNAP',
        );
      }
    } on Object catch (_) {}
    return null;
  }

  // ── Probe: IP Camera (Hikvision / Dahua / ONVIF) ─────────────────────────
  Future<WifiDevice?> _probeIpCamera(String ip) async {
    // Hikvision: ISAPI REST endpoint
    try {
      final resp = await http
          .get(Uri.parse('http://$ip/ISAPI/System/deviceInfo'))
          .timeout(const Duration(seconds: 2));
      if (resp.statusCode == 200 && resp.body.contains('deviceName')) {
        final name = _xmlValue(resp.body, 'deviceName') ?? 'Hikvision Camera';
        final model = _xmlValue(resp.body, 'model');
        final serial = _xmlValue(resp.body, 'serialNumber');
        return WifiDevice(
          ipAddress: ip,
          manufacturer: 'Hikvision',
          deviceName: name,
          modelNumber: model,
          serialNumber: serial,
          deviceTypeRaw: 'hikvision-camera',
          deviceCategory: 'IP Camera',
          iconCategory: IconCategory.camera,
          confidenceScore: 93,
          httpBanner: 'Hikvision/ISAPI',
        );
      }
    } on Object catch (_) {}

    // Dahua: magicBox CGI
    try {
      final resp = await http
          .get(
            Uri.parse('http://$ip/cgi-bin/magicBox.cgi?action=getDeviceType'),
          )
          .timeout(const Duration(seconds: 2));
      if (resp.statusCode == 200 && resp.body.contains('type=')) {
        final typeMatch = RegExp(r'type=(.+)').firstMatch(resp.body);
        final model = typeMatch?.group(1)?.trim();
        return WifiDevice(
          ipAddress: ip,
          manufacturer: 'Dahua',
          deviceName: model != null ? 'Dahua $model' : 'Dahua Camera',
          modelNumber: model,
          deviceTypeRaw: 'dahua-camera',
          deviceCategory: 'IP Camera',
          iconCategory: IconCategory.camera,
          confidenceScore: 90,
          httpBanner: 'Dahua/magicBox',
        );
      }
    } on Object catch (_) {}

    // Generic ONVIF SOAP probe
    try {
      const onvifBody =
          '<?xml version="1.0" encoding="UTF-8"?>'
          '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">'
          '<s:Body>'
          '<tds:GetDeviceInformation xmlns:tds="http://www.onvif.org/ver10/device/wsdl"/>'
          '</s:Body></s:Envelope>';
      final resp = await http
          .post(
            Uri.parse('http://$ip/onvif/device_service'),
            headers: {'Content-Type': 'application/soap+xml; charset=utf-8'},
            body: onvifBody,
          )
          .timeout(const Duration(seconds: 2));
      if (resp.statusCode == 200 &&
          (resp.body.contains('Manufacturer') ||
              resp.body.contains('tds:GetDeviceInformationResponse'))) {
        final mfr =
            _xmlValue(resp.body, 'tds:Manufacturer') ??
            _xmlValue(resp.body, 'tt:Manufacturer') ??
            'IP Camera';
        final model =
            _xmlValue(resp.body, 'tds:Model') ??
            _xmlValue(resp.body, 'tt:Model');
        return WifiDevice(
          ipAddress: ip,
          manufacturer: mfr,
          deviceName: model != null ? '$mfr $model' : '$mfr Camera',
          modelNumber: model,
          deviceTypeRaw: 'onvif-camera',
          deviceCategory: 'IP Camera',
          iconCategory: IconCategory.camera,
          confidenceScore: 82,
          httpBanner: 'ONVIF',
        );
      }
    } on Object catch (_) {}

    return null;
  }

  // ── Generic HTTP Banner Harvesting ────────────────────────────────────────
  /// GET the given port, return (Server header, HTML title) record or null.
  Future<(String, String)?> _extractHttpBanner(String ip, int port) async {
    final scheme = (port == 443 || port == 8443) ? 'https' : 'http';
    try {
      final resp = await http
          .get(Uri.parse('$scheme://$ip:$port/'))
          .timeout(const Duration(seconds: 2));
      final server = resp.headers['server'] ?? '';
      final titleMatch = RegExp(
        r'<title[^>]*>([^<]*)</title>',
        caseSensitive: false,
      ).firstMatch(resp.body);
      final title = titleMatch?.group(1)?.trim() ?? '';
      if (server.isEmpty && title.isEmpty) return null;
      return (server, title);
    } on Object catch (_) {}
    return null;
  }

  /// Apply (serverHeader, htmlTitle) to an unidentified device.
  /// Returns a new WifiDevice if a known fingerprint matches, else the original.
  WifiDevice _applyBannerToDevice(
    WifiDevice d,
    String server,
    String title,
    int port,
  ) {
    final s = server.toLowerCase();
    final t = title.toLowerCase();
    final combined = '$s $t';

    String? newName;
    String? newMfr;
    String? newModel;
    String newCategory = d.deviceCategory;
    IconCategory newIcon = d.iconCategory;
    int newScore = d.confidenceScore;

    // ── Server: header fingerprints ──────────────────────────────────
    if (s.startsWith('roku/')) {
      final parts = server.split('/');
      newMfr = 'Roku';
      newModel = parts.length > 1 ? parts[1] : null;
      newName = 'Roku Device';
      newCategory = 'Streaming Device';
      newIcon = IconCategory.tv;
      newScore = 78;
    } else if (s.contains('avm') ||
        s.contains('fritzos') ||
        s.contains('fritz!')) {
      newMfr = 'AVM';
      newName = title.isNotEmpty && title.length < 60 ? title : 'FRITZ!Box';
      newCategory = 'Router / Gateway';
      newIcon = IconCategory.router;
      newScore = 85;
    } else if (s.contains('synology')) {
      newMfr = 'Synology';
      newName = 'Synology NAS';
      newCategory = 'NAS / Storage';
      newIcon = IconCategory.generic;
      newScore = 82;
    } else if (s.contains('hikvision')) {
      newMfr = 'Hikvision';
      newName = 'Hikvision Camera';
      newCategory = 'IP Camera';
      newIcon = IconCategory.camera;
      newScore = 87;
    } else if (s.contains('dahua')) {
      newMfr = 'Dahua';
      newName = 'Dahua Camera';
      newCategory = 'IP Camera';
      newIcon = IconCategory.camera;
      newScore = 87;
    } else if (s.contains('mikrotik') || s.contains('routeros')) {
      newMfr = 'MikroTik';
      newName = title.isNotEmpty ? title : 'MikroTik Router';
      newCategory = 'Router / Gateway';
      newIcon = IconCategory.router;
      newScore = 87;
    } else if ((s.contains('shelly') ||
        s.contains('armkeil') ||
        (s.contains('lighttpd') && t.contains('shelly')))) {
      newMfr = 'Shelly';
      newName = title.isNotEmpty && title.length < 50 ? title : 'Shelly Device';
      newCategory = 'Smart Switch';
      newIcon = IconCategory.smartPlug;
      newScore = 80;
    } else if (s.contains('cisco') || s.contains('linksys')) {
      newMfr = combined.contains('linksys') ? 'Linksys' : 'Cisco';
      newName = title.isNotEmpty ? title : '$newMfr Router';
      newCategory = 'Router / Gateway';
      newIcon = IconCategory.router;
      newScore = 80;
    } else if (s.contains('ubiquiti') ||
        s.contains('ubnt') ||
        s.contains('unifi')) {
      newMfr = 'Ubiquiti';
      newName = 'UniFi Device';
      newCategory = 'Network Equipment';
      newIcon = IconCategory.router;
      newScore = 82;
    } else if (s.contains('netgear')) {
      newMfr = 'Netgear';
      newName = 'Netgear Device';
      newCategory = 'Router / Gateway';
      newIcon = IconCategory.router;
      newScore = 78;
    } else if (s.contains('tp-link')) {
      newMfr = 'TP-Link';
      newName = 'TP-Link Device';
      newCategory = 'Router / Gateway';
      newIcon = IconCategory.router;
      newScore = 78;
    } else if (s.contains('asus')) {
      newMfr = 'ASUS';
      newName = 'ASUS Device';
      newCategory = 'Router / Gateway';
      newIcon = IconCategory.router;
      newScore = 78;
    } else if (s.contains('axis') &&
        (s.contains('camera') || s.contains('video'))) {
      newMfr = 'Axis';
      newName = 'Axis Camera';
      newCategory = 'IP Camera';
      newIcon = IconCategory.camera;
      newScore = 87;
    } else if (s.contains('vivotek')) {
      newMfr = 'Vivotek';
      newName = 'Vivotek Camera';
      newCategory = 'IP Camera';
      newIcon = IconCategory.camera;
      newScore = 85;
    } else if (s.contains('foscam')) {
      newMfr = 'Foscam';
      newName = 'Foscam Camera';
      newCategory = 'IP Camera';
      newIcon = IconCategory.camera;
      newScore = 85;
    } else if (s.contains('hp-httpserver') || s.contains('hp http')) {
      newMfr = 'HP';
      newName = 'HP Printer';
      newCategory = 'Printer';
      newIcon = IconCategory.printer;
      newScore = 82;
    } else if (s.contains('epson_linux')) {
      newMfr = 'Epson';
      newName = 'Epson Printer';
      newCategory = 'Printer';
      newIcon = IconCategory.printer;
      newScore = 82;
    } else if (s.contains('brother') || s.contains('brsvc')) {
      newMfr = 'Brother';
      newName = 'Brother Printer';
      newCategory = 'Printer';
      newIcon = IconCategory.printer;
      newScore = 82;
    } else if (s.contains('canon http') || s.contains('kssip')) {
      newMfr = 'Canon';
      newName = 'Canon Printer';
      newCategory = 'Printer';
      newIcon = IconCategory.printer;
      newScore = 82;
    } else if (s.contains('miniserv') || s.contains('webmin')) {
      newMfr = 'Webmin';
      newName = 'Webmin Server';
      newCategory = 'Computer';
      newIcon = IconCategory.computer;
      newScore = 78;
    } else if (s.contains('nginx')) {
      // nginx alone is generic but still useful for version fingerprinting
      final v = _extractVersion(server);
      if (v != null) {
        newMfr = 'Linux';
        newName = 'Linux Server (nginx)';
        newCategory = 'Computer';
        newIcon = IconCategory.computer;
        newScore = 40;
        newModel = 'nginx/$v';
      }
    } else if (s.contains('apache')) {
      final v = _extractVersion(server);
      if (v != null) {
        newMfr = 'Linux';
        newName = 'Linux Server (Apache)';
        newCategory = 'Computer';
        newIcon = IconCategory.computer;
        newScore = 40;
        newModel = 'Apache/$v';
      }
    } else if (s.contains('iis') || s.contains('microsoft')) {
      newMfr = 'Microsoft';
      newName = 'Windows Server (IIS)';
      newCategory = 'Computer';
      newIcon = IconCategory.computer;
      newScore = 60;
    }

    // ── HTML <title> fingerprints (runs when Server: didn't match) ───
    if (newMfr == null) {
      if (t.contains('fritz!box') ||
          (t.contains('fritz') && t.contains('box'))) {
        newMfr = 'AVM';
        newName = title.length < 60 ? title : 'FRITZ!Box Router';
        newCategory = 'Router / Gateway';
        newIcon = IconCategory.router;
        newScore = 82;
      } else if (t.contains('d-link') || t.contains('dlink')) {
        newMfr = 'D-Link';
        newName = title.length < 60 && title.isNotEmpty
            ? title
            : 'D-Link Router';
        newCategory = 'Router / Gateway';
        newIcon = IconCategory.router;
        newScore = 78;
      } else if (t.contains('openwrt') ||
          t.contains('luci') ||
          combined.contains('/cgi-bin/luci')) {
        newMfr = 'OpenWrt';
        newName = 'OpenWrt Router';
        newCategory = 'Router / Gateway';
        newIcon = IconCategory.router;
        newScore = 82;
      } else if (t.contains('routeros') || t.contains('mikrotik')) {
        newMfr = 'MikroTik';
        newName = title.length < 60 ? title : 'MikroTik Router';
        newCategory = 'Router / Gateway';
        newIcon = IconCategory.router;
        newScore = 82;
      } else if (t.contains('dd-wrt')) {
        newMfr = 'DD-WRT';
        newName = 'DD-WRT Router';
        newCategory = 'Router / Gateway';
        newIcon = IconCategory.router;
        newScore = 78;
      } else if (combined.contains('huawei') &&
          (t.contains('router') || t.contains('modem') || t.contains('home'))) {
        newMfr = 'Huawei';
        newName = title.length < 60 ? title : 'Huawei Router';
        newCategory = 'Router / Gateway';
        newIcon = IconCategory.router;
        newScore = 80;
      } else if (t.contains('home assistant')) {
        newMfr = 'Home Assistant';
        newName = 'Home Assistant Hub';
        newCategory = 'Smart Hub';
        newIcon = IconCategory.generic;
        newScore = 82;
      } else if (t.contains('synology') || t.contains('diskstation')) {
        newMfr = 'Synology';
        newName = title.length < 60 ? title : 'Synology NAS';
        newCategory = 'NAS / Storage';
        newIcon = IconCategory.generic;
        newScore = 82;
      } else if (t.contains('qnap') ||
          t.contains('qts') ||
          t.contains('turbonas')) {
        newMfr = 'QNAP';
        newName = title.length < 60 ? title : 'QNAP NAS';
        newCategory = 'NAS / Storage';
        newIcon = IconCategory.generic;
        newScore = 82;
      } else if (t.contains('tasmota')) {
        newMfr = 'Tasmota';
        newName = title.length < 60 ? title : 'Tasmota Device';
        newCategory = 'Smart Plug';
        newIcon = IconCategory.smartPlug;
        newScore = 80;
      } else if (t.contains('pihole') || t.contains('pi-hole')) {
        newMfr = 'Raspberry Pi';
        newName = 'Pi-hole DNS Filter';
        newCategory = 'Smart Hub';
        newIcon = IconCategory.generic;
        newScore = 87;
      } else if (t.contains('plex media') || t.contains('plex/web')) {
        newMfr = 'Plex';
        newName = 'Plex Media Server';
        newCategory = 'Media Server';
        newIcon = IconCategory.tv;
        newScore = 85;
      } else if (t.contains('jellyfin')) {
        newMfr = 'Jellyfin';
        newName = 'Jellyfin Media Server';
        newCategory = 'Media Server';
        newIcon = IconCategory.tv;
        newScore = 85;
      } else if (t.contains('emby')) {
        newMfr = 'Emby';
        newName = 'Emby Media Server';
        newCategory = 'Media Server';
        newIcon = IconCategory.tv;
        newScore = 85;
      } else if (t.contains('proxmox')) {
        newMfr = 'Proxmox';
        newName = 'Proxmox VE Server';
        newCategory = 'Computer';
        newIcon = IconCategory.computer;
        newScore = 85;
      } else if (combined.contains('samsung') &&
          (combined.contains('tv') || combined.contains('smart'))) {
        newMfr = 'Samsung';
        newName = title.isNotEmpty ? title : 'Samsung Smart TV';
        newCategory = 'Smart TV';
        newIcon = IconCategory.tv;
        newScore = 74;
      } else if (t.contains('eero') || s.contains('eero')) {
        newMfr = 'Amazon (eero)';
        newName = 'eero Router';
        newCategory = 'Router / Gateway';
        newIcon = IconCategory.router;
        newScore = 82;
      } else if (t.contains('orbi') || combined.contains('netgear orbi')) {
        newMfr = 'Netgear';
        newName = 'Netgear Orbi';
        newCategory = 'Router / Gateway';
        newIcon = IconCategory.router;
        newScore = 82;
      }
      // ── NETLIB expanded fingerprint database ────────────────────────
      // Additional brands that NETLIB recognizes from Server/Title headers
      else if (t.contains('tp-link') ||
          t.contains('tplink') ||
          s.contains('tp-link')) {
        newMfr = 'TP-Link';
        newName = title.isNotEmpty && title.length < 60
            ? title
            : 'TP-Link Router';
        newCategory = 'Router / Gateway';
        newIcon = IconCategory.router;
        newScore = 82;
      } else if (t.contains('zyxel') || s.contains('zyxel')) {
        newMfr = 'ZyXEL';
        newName = title.isNotEmpty && title.length < 60
            ? title
            : 'ZyXEL Router';
        newCategory = 'Router / Gateway';
        newIcon = IconCategory.router;
        newScore = 82;
      } else if (t.contains('tenda') || s.contains('tenda')) {
        newMfr = 'Tenda';
        newName = 'Tenda Router';
        newCategory = 'Router / Gateway';
        newIcon = IconCategory.router;
        newScore = 78;
      } else if (t.contains('arris') || s.contains('arris')) {
        newMfr = 'Arris';
        newName = 'Arris Modem/Router';
        newCategory = 'Router / Gateway';
        newIcon = IconCategory.router;
        newScore = 80;
      } else if (t.contains('buffalo') || s.contains('buffalo')) {
        newMfr = 'Buffalo';
        newName = 'Buffalo Router';
        newCategory = 'Router / Gateway';
        newIcon = IconCategory.router;
        newScore = 78;
      } else if (t.contains('amplifi') || s.contains('amplifi')) {
        newMfr = 'Ubiquiti';
        newName = 'AmpliFi Router';
        newCategory = 'Router / Gateway';
        newIcon = IconCategory.router;
        newScore = 82;
      } else if (t.contains('peplink') || s.contains('peplink')) {
        newMfr = 'Peplink';
        newName = 'Peplink Router';
        newCategory = 'Router / Gateway';
        newIcon = IconCategory.router;
        newScore = 82;
      } else if ((t.contains('sophos') || s.contains('sophos'))) {
        newMfr = 'Sophos';
        newName = 'Sophos Firewall';
        newCategory = 'Network Equipment';
        newIcon = IconCategory.router;
        newScore = 85;
      } else if (t.contains('pfsense') || s.contains('pfsense')) {
        newMfr = 'pfSense';
        newName = 'pfSense Firewall';
        newCategory = 'Router / Gateway';
        newIcon = IconCategory.router;
        newScore = 85;
      } else if (t.contains('opnsense') || s.contains('opnsense')) {
        newMfr = 'OPNsense';
        newName = 'OPNsense Firewall';
        newCategory = 'Router / Gateway';
        newIcon = IconCategory.router;
        newScore = 85;
      } else if (t.contains('fortinet') ||
          t.contains('fortigate') ||
          s.contains('fortios')) {
        newMfr = 'Fortinet';
        newName = 'FortiGate Firewall';
        newCategory = 'Network Equipment';
        newIcon = IconCategory.router;
        newScore = 88;
      } else if (combined.contains('xerox')) {
        newMfr = 'Xerox';
        newName = 'Xerox Printer';
        newCategory = 'Printer';
        newIcon = IconCategory.printer;
        newScore = 82;
      } else if (combined.contains('lexmark')) {
        newMfr = 'Lexmark';
        newName = 'Lexmark Printer';
        newCategory = 'Printer';
        newIcon = IconCategory.printer;
        newScore = 82;
      } else if (combined.contains('ricoh')) {
        newMfr = 'Ricoh';
        newName = 'Ricoh Printer';
        newCategory = 'Printer';
        newIcon = IconCategory.printer;
        newScore = 82;
      } else if (combined.contains('konica') || combined.contains('minolta')) {
        newMfr = 'Konica Minolta';
        newName = 'Konica Minolta Printer';
        newCategory = 'Printer';
        newIcon = IconCategory.printer;
        newScore = 82;
      } else if (combined.contains('kyocera')) {
        newMfr = 'Kyocera';
        newName = 'Kyocera Printer';
        newCategory = 'Printer';
        newIcon = IconCategory.printer;
        newScore = 82;
      } else if (t.contains('webmin') || s.contains('miniserv')) {
        newMfr = 'Webmin';
        newName = 'Webmin Server';
        newCategory = 'Computer';
        newIcon = IconCategory.computer;
        newScore = 82;
      } else if (t.contains('cockpit') || t.contains('web console')) {
        newMfr = 'Linux';
        newName = 'Linux Server (Cockpit)';
        newCategory = 'Computer';
        newIcon = IconCategory.computer;
        newScore = 78;
      } else if (t.contains('grafana') || s.contains('grafana')) {
        newMfr = 'Grafana';
        newName = 'Grafana Dashboard';
        newCategory = 'Computer';
        newIcon = IconCategory.computer;
        newScore = 82;
      } else if (t.contains('portainer') || s.contains('portainer')) {
        newMfr = 'Portainer';
        newName = 'Portainer Server';
        newCategory = 'Computer';
        newIcon = IconCategory.computer;
        newScore = 82;
      } else if (t.contains('unraid') || s.contains('unraid')) {
        newMfr = 'Unraid';
        newName = 'Unraid Server';
        newCategory = 'NAS / Storage';
        newIcon = IconCategory.generic;
        newScore = 85;
      } else if (t.contains('openmediavault') || t.contains('omv')) {
        newMfr = 'OpenMediaVault';
        newName = 'OpenMediaVault NAS';
        newCategory = 'NAS / Storage';
        newIcon = IconCategory.generic;
        newScore = 82;
      } else if (t.contains('adguard') || s.contains('adguard')) {
        newMfr = 'AdGuard';
        newName = 'AdGuard DNS Filter';
        newCategory = 'Smart Hub';
        newIcon = IconCategory.generic;
        newScore = 85;
      } else if (combined.contains('axis') &&
          (combined.contains('camera') || combined.contains('live view'))) {
        newMfr = 'Axis';
        newName = 'Axis Camera';
        newCategory = 'IP Camera';
        newIcon = IconCategory.camera;
        newScore = 85;
      } else if (combined.contains('vivotek')) {
        newMfr = 'Vivotek';
        newName = 'Vivotek Camera';
        newCategory = 'IP Camera';
        newIcon = IconCategory.camera;
        newScore = 85;
      } else if (combined.contains('foscam')) {
        newMfr = 'Foscam';
        newName = 'Foscam Camera';
        newCategory = 'IP Camera';
        newIcon = IconCategory.camera;
        newScore = 85;
      } else if (t.contains('google') &&
          (t.contains('home') || t.contains('nest'))) {
        newMfr = 'Google';
        newName = 'Google Nest Device';
        newCategory = 'Smart Hub';
        newIcon = IconCategory.generic;
        newScore = 78;
      } else if (combined.contains('wemo') || combined.contains('belkin')) {
        newMfr = 'Belkin';
        newName = 'WeMo Smart Device';
        newCategory = 'Smart Plug';
        newIcon = IconCategory.smartPlug;
        newScore = 80;
      } else if (combined.contains('lutron')) {
        newMfr = 'Lutron';
        newName = 'Lutron Smart Bridge';
        newCategory = 'Smart Hub';
        newIcon = IconCategory.lightBulb;
        newScore = 82;
      } else if (combined.contains('ecobee')) {
        newMfr = 'ecobee';
        newName = 'ecobee Thermostat';
        newCategory = 'Thermostat';
        newIcon = IconCategory.thermostat;
        newScore = 85;
      } else if (combined.contains('honeywell') &&
          (combined.contains('therm') ||
              combined.contains('lyric') ||
              combined.contains('t6'))) {
        newMfr = 'Honeywell';
        newName = 'Honeywell Thermostat';
        newCategory = 'Thermostat';
        newIcon = IconCategory.thermostat;
        newScore = 82;
      } else if (combined.contains('ring') && combined.contains('doorbell')) {
        newMfr = 'Ring';
        newName = 'Ring Doorbell';
        newCategory = 'IP Camera';
        newIcon = IconCategory.camera;
        newScore = 82;
      } else if (t.contains('vmware') ||
          t.contains('esxi') ||
          s.contains('vmware')) {
        newMfr = 'VMware';
        newName = 'VMware ESXi Server';
        newCategory = 'Computer';
        newIcon = IconCategory.computer;
        newScore = 85;
      } else if (t.contains('truenas') || t.contains('freenas')) {
        newMfr = 'TrueNAS';
        newName = 'TrueNAS Server';
        newCategory = 'NAS / Storage';
        newIcon = IconCategory.generic;
        newScore = 85;
      } else if (combined.contains('netgear') && !combined.contains('orbi')) {
        newMfr = 'Netgear';
        newName = title.isNotEmpty && title.length < 60
            ? title
            : 'Netgear Router';
        newCategory = 'Router / Gateway';
        newIcon = IconCategory.router;
        newScore = 78;
      } else if (combined.contains('asus') &&
          (combined.contains('router') ||
              combined.contains('rt-') ||
              combined.contains('asuswrt'))) {
        newMfr = 'ASUS';
        newName = title.isNotEmpty && title.length < 60 ? title : 'ASUS Router';
        newCategory = 'Router / Gateway';
        newIcon = IconCategory.router;
        newScore = 82;
      }
    }

    // Nothing matched — return the device unchanged
    if (newMfr == null) return d;

    return WifiDevice(
      ipAddress: d.ipAddress,
      macAddress: d.macAddress,
      manufacturer: newMfr,
      deviceName: newName ?? d.deviceName,
      hostname: d.hostname,
      modelNumber: newModel ?? d.modelNumber,
      serialNumber: d.serialNumber,
      deviceTypeRaw: d.deviceTypeRaw,
      deviceCategory: newCategory,
      iconCategory: newIcon,
      confidenceScore: newScore,
      discoveryMethod: d.discoveryMethod,
      openPorts: d.openPorts,
      httpBanner: server.isNotEmpty ? server : d.httpBanner,
      htmlTitle: title.isNotEmpty ? title : d.htmlTitle,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NETLIB — Service Version Detection (Phase 3)
  //
  // For each open port, connect and read the service banner to identify
  // the exact service name + version. NETLIB does this for every open port.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Read SSH version banner from port 22.
  /// SSH servers send their version string immediately upon connection.
  /// Example: "SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.4"
  Future<String?> _probeSSHBanner(String ip) async {
    try {
      final socket = await Socket.connect(
        ip,
        22,
        timeout: const Duration(milliseconds: 1500),
      );
      final completer = Completer<String?>();
      Timer? timer;
      timer = Timer(const Duration(milliseconds: 1200), () {
        if (!completer.isCompleted) completer.complete(null);
        socket.destroy();
      });
      socket.listen(
        (data) {
          timer?.cancel();
          final banner = String.fromCharCodes(data).trim();
          if (!completer.isCompleted) {
            completer.complete(banner.isNotEmpty ? banner : null);
          }
          socket.destroy();
        },
        onError: (_) {
          timer?.cancel();
          if (!completer.isCompleted) completer.complete(null);
          socket.destroy();
        },
        onDone: () {
          timer?.cancel();
          if (!completer.isCompleted) completer.complete(null);
        },
      );
      final result = await completer.future;
      _log('L5', '  🔑 SSH $ip: ${result ?? "(no banner)"}');
      return result;
    } on Object catch (e) {
      if (e is SocketException) {
        _log('L5', '  ⚠️ SSH $ip: ${e.message}');
      }
    }
    return null;
  }

  /// Identify device from SSH banner string.
  WifiDevice? _identifyFromSSH(String banner) {
    final b = banner.toLowerCase();
    String mfr;
    String name;
    String? firmware;
    String category = 'Computer';
    IconCategory icon = IconCategory.computer;
    int score = 65;

    if (b.contains('dropbear')) {
      // Dropbear = embedded Linux (routers, NAS, IoT)
      if (b.contains('mikrotik') || b.contains('routeros')) {
        mfr = 'MikroTik';
        name = 'MikroTik Router';
        category = 'Router / Gateway';
        icon = IconCategory.router;
        score = 85;
      } else if (b.contains('ubnt') || b.contains('ubiquiti')) {
        mfr = 'Ubiquiti';
        name = 'Ubiquiti Device';
        category = 'Network Equipment';
        icon = IconCategory.router;
        score = 82;
      } else {
        mfr = 'Embedded Linux';
        name = 'Embedded Device';
        category = 'Network Equipment';
        icon = IconCategory.router;
        score = 55;
      }
    } else if (b.contains('openssh')) {
      if (b.contains('ubuntu')) {
        mfr = 'Linux';
        name = 'Ubuntu Server';
        firmware = _extractVersion(b);
      } else if (b.contains('debian')) {
        mfr = 'Linux';
        name = 'Debian Server';
        firmware = _extractVersion(b);
      } else if (b.contains('raspbian') || b.contains('raspberry')) {
        mfr = 'Raspberry Pi';
        name = 'Raspberry Pi';
        icon = IconCategory.generic;
        score = 78;
      } else if (b.contains('freebsd')) {
        mfr = 'FreeBSD';
        name = 'FreeBSD Server';
      } else {
        mfr = 'Linux/Unix';
        name = 'SSH Server';
        firmware = _extractVersion(b);
      }
    } else if (b.contains('cisco')) {
      mfr = 'Cisco';
      name = 'Cisco Device';
      category = 'Network Equipment';
      icon = IconCategory.router;
      score = 82;
    } else if (b.contains('fortigate') || b.contains('fortios')) {
      mfr = 'Fortinet';
      name = 'FortiGate Firewall';
      category = 'Network Equipment';
      icon = IconCategory.router;
      score = 85;
    } else {
      return null; // Unknown SSH, don't override
    }

    return WifiDevice(
      ipAddress: '',
      manufacturer: mfr,
      deviceName: name,
      deviceTypeRaw: 'ssh-device',
      deviceCategory: category,
      iconCategory: icon,
      confidenceScore: score,
      firmwareVersion: firmware,
      sshBanner: banner,
    );
  }

  /// Generic service banner reader for FTP (21), Telnet (23), SMTP (25), etc.
  /// Connects and reads the first line the server sends.
  Future<String?> _probeServiceBanner(String ip, int port, String label) async {
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(milliseconds: 1500),
      );
      final completer = Completer<String?>();
      Timer? timer;
      timer = Timer(const Duration(milliseconds: 1200), () {
        if (!completer.isCompleted) completer.complete(null);
        socket.destroy();
      });
      socket.listen(
        (data) {
          timer?.cancel();
          final banner = String.fromCharCodes(data).trim();
          // Take first line only
          final firstLine = banner.split('\n').first.trim();
          if (!completer.isCompleted) {
            completer.complete(firstLine.isNotEmpty ? firstLine : null);
          }
          socket.destroy();
        },
        onError: (_) {
          timer?.cancel();
          if (!completer.isCompleted) completer.complete(null);
          socket.destroy();
        },
        onDone: () {
          timer?.cancel();
          if (!completer.isCompleted) completer.complete(null);
        },
      );
      final result = await completer.future;
      if (result != null) _log('L5', '  📡 $label $ip:$port → $result');
      return result;
    } on Object catch (e) {
      if (e is SocketException) {
        _log('L5', '  ⚠️ $label $ip:$port: ${e.message}');
      }
    }
    return null;
  }

  /// Identify device from FTP banner.
  WifiDevice? _identifyFromFTP(String banner, String ip) {
    final b = banner.toLowerCase();
    if (b.contains('synology')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Synology',
        deviceName: 'Synology NAS',
        deviceTypeRaw: 'synology-ftp',
        deviceCategory: 'NAS / Storage',
        iconCategory: IconCategory.generic,
        confidenceScore: 85,
        httpBanner: 'FTP: $banner',
      );
    }
    if (b.contains('qnap')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'QNAP',
        deviceName: 'QNAP NAS',
        deviceTypeRaw: 'qnap-ftp',
        deviceCategory: 'NAS / Storage',
        iconCategory: IconCategory.generic,
        confidenceScore: 85,
        httpBanner: 'FTP: $banner',
      );
    }
    if (b.contains('proftpd') ||
        b.contains('vsftpd') ||
        b.contains('pure-ftpd')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Linux',
        deviceName: 'Linux Server (FTP)',
        deviceTypeRaw: 'ftp-server',
        deviceCategory: 'Computer',
        iconCategory: IconCategory.computer,
        confidenceScore: 55,
        httpBanner: 'FTP: $banner',
      );
    }
    if (b.contains('filezilla')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Windows',
        deviceName: 'Windows Server (FTP)',
        deviceTypeRaw: 'ftp-server',
        deviceCategory: 'Computer',
        iconCategory: IconCategory.computer,
        confidenceScore: 55,
        httpBanner: 'FTP: $banner',
      );
    }
    if (b.contains('iis') || b.contains('microsoft')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Microsoft',
        deviceName: 'Windows Server (IIS FTP)',
        deviceTypeRaw: 'iis-ftp',
        deviceCategory: 'Computer',
        iconCategory: IconCategory.computer,
        confidenceScore: 60,
        httpBanner: 'FTP: $banner',
      );
    }
    if (b.contains('netgear')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Netgear',
        deviceName: 'Netgear Device',
        deviceTypeRaw: 'netgear-ftp',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 78,
        httpBanner: 'FTP: $banner',
      );
    }
    return null;
  }

  /// Identify device from Telnet banner.
  WifiDevice? _identifyFromTelnet(String banner, String ip) {
    final b = banner.toLowerCase();
    if (b.contains('mikrotik') || b.contains('routeros')) {
      final vMatch = RegExp(r'(\d+\.\d+[\.\d]*)').firstMatch(banner);
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'MikroTik',
        deviceName: 'MikroTik Router',
        modelNumber: vMatch?.group(1),
        deviceTypeRaw: 'mikrotik-telnet',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 90,
        httpBanner: 'Telnet: $banner',
      );
    }
    if (b.contains('cisco')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Cisco',
        deviceName: 'Cisco Device',
        deviceTypeRaw: 'cisco-telnet',
        deviceCategory: 'Network Equipment',
        iconCategory: IconCategory.router,
        confidenceScore: 85,
        httpBanner: 'Telnet: $banner',
      );
    }
    if (b.contains('zyxel')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'ZyXEL',
        deviceName: 'ZyXEL Router',
        deviceTypeRaw: 'zyxel-telnet',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 82,
        httpBanner: 'Telnet: $banner',
      );
    }
    if (b.contains('tp-link') || b.contains('tplink')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'TP-Link',
        deviceName: 'TP-Link Router',
        deviceTypeRaw: 'tplink-telnet',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 82,
        httpBanner: 'Telnet: $banner',
      );
    }
    if (b.contains('dlink') || b.contains('d-link')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'D-Link',
        deviceName: 'D-Link Router',
        deviceTypeRaw: 'dlink-telnet',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 82,
        httpBanner: 'Telnet: $banner',
      );
    }
    if (b.contains('netgear')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Netgear',
        deviceName: 'Netgear Router',
        deviceTypeRaw: 'netgear-telnet',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 82,
        httpBanner: 'Telnet: $banner',
      );
    }
    if (b.contains('asus')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'ASUS',
        deviceName: 'ASUS Router',
        deviceTypeRaw: 'asus-telnet',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 82,
        httpBanner: 'Telnet: $banner',
      );
    }
    if (b.contains('hikvision')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Hikvision',
        deviceName: 'Hikvision Camera',
        deviceTypeRaw: 'hikvision-telnet',
        deviceCategory: 'IP Camera',
        iconCategory: IconCategory.camera,
        confidenceScore: 85,
        httpBanner: 'Telnet: $banner',
      );
    }
    if (b.contains('dahua') || b.contains('amcrest')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: b.contains('amcrest') ? 'Amcrest' : 'Dahua',
        deviceName: b.contains('amcrest') ? 'Amcrest Camera' : 'Dahua Camera',
        deviceTypeRaw: 'dahua-telnet',
        deviceCategory: 'IP Camera',
        iconCategory: IconCategory.camera,
        confidenceScore: 85,
        httpBanner: 'Telnet: $banner',
      );
    }
    if (b.contains('busybox') || b.contains('login:')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Embedded Linux',
        deviceName: 'Embedded Device',
        deviceTypeRaw: 'busybox-telnet',
        deviceCategory: 'Network Equipment',
        iconCategory: IconCategory.generic,
        confidenceScore: 40,
        httpBanner: 'Telnet: $banner',
      );
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NETLIB — RTSP Probe (Phase 3 — streaming service detection)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Send RTSP OPTIONS request to port 554 and read the Server header.
  Future<String?> _probeRTSP(String ip) async {
    try {
      final socket = await Socket.connect(
        ip,
        554,
        timeout: const Duration(milliseconds: 1500),
      );
      socket.add(
        utf8.encode('OPTIONS rtsp://$ip/ RTSP/1.0\r\nCSeq: 1\r\n\r\n'),
      );
      final completer = Completer<String?>();
      Timer? timer;
      timer = Timer(const Duration(milliseconds: 1200), () {
        if (!completer.isCompleted) completer.complete(null);
        socket.destroy();
      });
      socket.listen(
        (data) {
          timer?.cancel();
          final resp = String.fromCharCodes(data);
          // Extract Server: header
          final serverMatch = RegExp(
            r'Server:\s*(.+)',
            caseSensitive: false,
          ).firstMatch(resp);
          if (!completer.isCompleted) {
            completer.complete(serverMatch?.group(1)?.trim());
          }
          socket.destroy();
        },
        onError: (_) {
          timer?.cancel();
          if (!completer.isCompleted) completer.complete(null);
          socket.destroy();
        },
        onDone: () {
          timer?.cancel();
          if (!completer.isCompleted) completer.complete(null);
        },
      );
      final result = await completer.future;
      if (result != null) _log('L5', '  📹 RTSP $ip → $result');
      return result;
    } on Object catch (e) {
      if (e is SocketException) {
        _log('L5', '  ⚠️ RTSP $ip: ${e.message}');
      }
    }
    return null;
  }

  String? _extractMfrFromRTSP(String server) {
    final s = server.toLowerCase();
    if (s.contains('hikvision')) return 'Hikvision';
    if (s.contains('dahua')) return 'Dahua';
    if (s.contains('amcrest')) return 'Amcrest';
    if (s.contains('reolink')) return 'Reolink';
    if (s.contains('axis')) return 'Axis';
    if (s.contains('vivotek')) return 'Vivotek';
    if (s.contains('foscam')) return 'Foscam';
    if (s.contains('ubiquiti') || s.contains('ubnt')) return 'Ubiquiti';
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NETLIB — TLS Certificate Extraction (Phase 9)
  //
  // Connect to port 443 (or 8443) and read the X.509 certificate Subject CN
  // and Issuer. Many devices (printers, NAS, routers) put their brand/model
  // in the certificate CN field, e.g. "CN=HP LaserJet M404n".
  // ═══════════════════════════════════════════════════════════════════════════

  /// Extract TLS certificate (subject, issuer) from a given port.
  Future<(String, String)?> _probeTlsCert(String ip, int port) async {
    try {
      final socket = await SecureSocket.connect(
        ip,
        port,
        timeout: const Duration(milliseconds: 2000),
        onBadCertificate: (_) => true, // Accept self-signed certs
      );
      final cert = socket.peerCertificate;
      socket.destroy();
      if (cert == null) return null;
      final subject = cert.subject.toString();
      final issuer = cert.issuer.toString();
      _log('L5', '  🔒 TLS $ip:$port Subject=$subject Issuer=$issuer');
      return (subject, issuer);
    } on Object catch (e) {
      if (e is SocketException || e is HandshakeException) {
        _log('L5', '  ⚠️ TLS $ip:$port: ${e.toString().split('\n').first}');
      }
    }
    return null;
  }

  /// Identify a device from its TLS certificate Subject and Issuer fields.
  WifiDevice? _identifyFromTlsCert(String subject, String issuer, String ip) {
    final s = subject.toLowerCase();
    final i = issuer.toLowerCase();
    final combined = '$s $i';

    // Printer brands in CN
    if (combined.contains('hp') &&
        (combined.contains('laserjet') ||
            combined.contains('officejet') ||
            combined.contains('envy') ||
            combined.contains('deskjet'))) {
      final modelMatch = RegExp(
        r'CN=([^,/]+)',
        caseSensitive: false,
      ).firstMatch(subject);
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'HP',
        deviceName: modelMatch?.group(1)?.trim() ?? 'HP Printer',
        modelNumber: modelMatch?.group(1)?.trim(),
        deviceTypeRaw: 'hp-tls',
        deviceCategory: 'Printer',
        iconCategory: IconCategory.printer,
        confidenceScore: 88,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('brother')) {
      final modelMatch = RegExp(
        r'CN=([^,/]+)',
        caseSensitive: false,
      ).firstMatch(subject);
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Brother',
        deviceName: modelMatch?.group(1)?.trim() ?? 'Brother Printer',
        modelNumber: modelMatch?.group(1)?.trim(),
        deviceTypeRaw: 'brother-tls',
        deviceCategory: 'Printer',
        iconCategory: IconCategory.printer,
        confidenceScore: 88,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('canon') &&
        (combined.contains('printer') ||
            combined.contains('mf') ||
            combined.contains('lbp'))) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Canon',
        deviceName: 'Canon Printer',
        deviceTypeRaw: 'canon-tls',
        deviceCategory: 'Printer',
        iconCategory: IconCategory.printer,
        confidenceScore: 85,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('epson')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Epson',
        deviceName: 'Epson Printer',
        deviceTypeRaw: 'epson-tls',
        deviceCategory: 'Printer',
        iconCategory: IconCategory.printer,
        confidenceScore: 85,
        tlsCertSubject: subject,
      );
    }

    // NAS brands in cert
    if (combined.contains('synology') || combined.contains('diskstation')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Synology',
        deviceName: 'Synology NAS',
        deviceTypeRaw: 'synology-tls',
        deviceCategory: 'NAS / Storage',
        iconCategory: IconCategory.generic,
        confidenceScore: 85,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('qnap') || combined.contains('qts')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'QNAP',
        deviceName: 'QNAP NAS',
        deviceTypeRaw: 'qnap-tls',
        deviceCategory: 'NAS / Storage',
        iconCategory: IconCategory.generic,
        confidenceScore: 85,
        tlsCertSubject: subject,
      );
    }

    // Router / firewall brands
    if (combined.contains('ubiquiti') ||
        combined.contains('ubnt') ||
        combined.contains('unifi')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Ubiquiti',
        deviceName: 'Ubiquiti Device',
        deviceTypeRaw: 'ubiquiti-tls',
        deviceCategory: 'Network Equipment',
        iconCategory: IconCategory.router,
        confidenceScore: 82,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('fortinet') || combined.contains('fortigate')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Fortinet',
        deviceName: 'FortiGate Firewall',
        deviceTypeRaw: 'fortigate-tls',
        deviceCategory: 'Network Equipment',
        iconCategory: IconCategory.router,
        confidenceScore: 88,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('pfsense')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'pfSense',
        deviceName: 'pfSense Firewall',
        deviceTypeRaw: 'pfsense-tls',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 85,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('opnsense')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'OPNsense',
        deviceName: 'OPNsense Firewall',
        deviceTypeRaw: 'opnsense-tls',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 85,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('sophos')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Sophos',
        deviceName: 'Sophos Firewall',
        deviceTypeRaw: 'sophos-tls',
        deviceCategory: 'Network Equipment',
        iconCategory: IconCategory.router,
        confidenceScore: 85,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('netgear')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Netgear',
        deviceName: 'Netgear Device',
        deviceTypeRaw: 'netgear-tls',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 78,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('asus') &&
        (combined.contains('router') || combined.contains('rt-'))) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'ASUS',
        deviceName: 'ASUS Router',
        deviceTypeRaw: 'asus-tls',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 82,
        tlsCertSubject: subject,
      );
    }

    // Cameras in cert
    if (combined.contains('hikvision')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Hikvision',
        deviceName: 'Hikvision Camera',
        deviceTypeRaw: 'hikvision-tls',
        deviceCategory: 'IP Camera',
        iconCategory: IconCategory.camera,
        confidenceScore: 88,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('dahua')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Dahua',
        deviceName: 'Dahua Camera',
        deviceTypeRaw: 'dahua-tls',
        deviceCategory: 'IP Camera',
        iconCategory: IconCategory.camera,
        confidenceScore: 88,
        tlsCertSubject: subject,
      );
    }

    // ISP / Telecom router brands — commonly found on GPON/fiber gateways
    if (combined.contains('zte')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'ZTE',
        deviceName: 'ZTE Router',
        deviceTypeRaw: 'zte-tls',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 80,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('huawei')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Huawei',
        deviceName: 'Huawei Router',
        deviceTypeRaw: 'huawei-tls',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 80,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('nokia')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Nokia',
        deviceName: 'Nokia Gateway',
        deviceTypeRaw: 'nokia-tls',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 78,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('fiberhome')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'FiberHome',
        deviceName: 'FiberHome Router',
        deviceTypeRaw: 'fiberhome-tls',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 78,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('calix')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Calix',
        deviceName: 'Calix Gateway',
        deviceTypeRaw: 'calix-tls',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 78,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('tp-link') || combined.contains('tplink')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'TP-Link',
        deviceName: 'TP-Link Router',
        deviceTypeRaw: 'tplink-tls',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 80,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('mikrotik') || combined.contains('routeros')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'MikroTik',
        deviceName: 'MikroTik Router',
        deviceTypeRaw: 'mikrotik-tls',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 85,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('linksys')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Linksys',
        deviceName: 'Linksys Router',
        deviceTypeRaw: 'linksys-tls',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 80,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('arris')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Arris',
        deviceName: 'Arris Gateway',
        deviceTypeRaw: 'arris-tls',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 78,
        tlsCertSubject: subject,
      );
    }
    if (combined.contains('sagemcom')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Sagemcom',
        deviceName: 'Sagemcom Router',
        deviceTypeRaw: 'sagemcom-tls',
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        confidenceScore: 78,
        tlsCertSubject: subject,
      );
    }

    // Also try to extract O= (Organization) from the certificate for manufacturer
    final orgMatch = RegExp(
      r'O=([^,/]+)',
      caseSensitive: false,
    ).firstMatch(subject);
    final issuerOrgMatch = RegExp(
      r'O=([^,/]+)',
      caseSensitive: false,
    ).firstMatch(issuer);
    final org = orgMatch?.group(1)?.trim() ?? issuerOrgMatch?.group(1)?.trim();
    if (org != null && org.length > 2) {
      final orgLower = org.toLowerCase();
      // Check if org matches any known router/device brand
      final orgBrands = {
        'zte': ('ZTE', 'Router / Gateway'),
        'huawei': ('Huawei', 'Router / Gateway'),
        'nokia': ('Nokia', 'Router / Gateway'),
        'tp-link': ('TP-Link', 'Router / Gateway'),
        'netgear': ('Netgear', 'Router / Gateway'),
        'asus': ('ASUS', 'Router / Gateway'),
        'linksys': ('Linksys', 'Router / Gateway'),
        'cisco': ('Cisco', 'Network Equipment'),
        'arris': ('Arris', 'Router / Gateway'),
        'samsung': ('Samsung', 'Smart Device'),
        'lg': ('LG', 'Smart TV'),
        'sony': ('Sony', 'Smart TV'),
        'apple': ('Apple', 'Apple Device'),
        'google': ('Google', 'Smart Device'),
        'amazon': ('Amazon', 'Smart Device'),
        'dell': ('Dell', 'Computer'),
        'hp': ('HP', 'Computer'),
        'lenovo': ('Lenovo', 'Computer'),
        'brother': ('Brother', 'Printer'),
        'canon': ('Canon', 'Printer'),
        'epson': ('Epson', 'Printer'),
        'xerox': ('Xerox', 'Printer'),
      };
      for (final entry in orgBrands.entries) {
        if (orgLower.contains(entry.key)) {
          final isRouter =
              entry.value.$2 == 'Router / Gateway' ||
              entry.value.$2 == 'Network Equipment';
          return WifiDevice(
            ipAddress: ip,
            manufacturer: entry.value.$1,
            deviceName: '${entry.value.$1} Device',
            deviceTypeRaw: '${entry.key}-tls-org',
            deviceCategory: entry.value.$2,
            iconCategory: isRouter ? IconCategory.router : IconCategory.generic,
            confidenceScore: 72,
            tlsCertSubject: subject,
          );
        }
      }
    }

    // If CN contains something meaningful but unrecognized, extract it
    final cnMatch = RegExp(
      r'CN=([^,/]+)',
      caseSensitive: false,
    ).firstMatch(subject);
    if (cnMatch != null) {
      final cn = cnMatch.group(1)!.trim();
      // Only use if it's not a generic hostname pattern
      if (cn.length > 3 && !cn.contains('localhost') && !cn.contains('*')) {
        _log('L5', '  🔒 TLS CN "$cn" — unmatched, storing for enrichment');
      }
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NETLIB — SMB Negotiation Probe (Phase 7)
  //
  // Send an SMB1 negotiate request to port 445. The server responds with
  // OS version, domain name, and computer name in the NegotiateProtocol
  // response. This is how NETLIB identifies Windows PCs and Samba servers.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Probe SMB port 445 and extract OS version + computer name.
  Future<Map<String, String>?> _probeSMB(String ip) async {
    try {
      final socket = await Socket.connect(
        ip,
        445,
        timeout: const Duration(milliseconds: 2000),
      );
      // SMB1 Negotiate Protocol Request — minimal packet
      // NetBIOS Session Service header + SMB1 Negotiate
      final negotiate = <int>[
        // NetBIOS header: type=0x00 (session message), length placeholder
        0x00, 0x00, 0x00, 0x00,
        // SMB header: \xFFSMB
        0xFF, 0x53, 0x4D, 0x42,
        // Command: Negotiate (0x72)
        0x72,
        // Status: 0
        0x00, 0x00, 0x00, 0x00,
        // Flags
        0x18,
        // Flags2
        0x53, 0xC8,
        // Padding (12 bytes)
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        // TID, PID, UID, MID
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        // Word count: 0
        0x00,
        // Byte count placeholder (will be set below)
        0x00, 0x00,
        // Dialect: NT LM 0.12
        0x02, // buffer format
        ...utf8.encode('NT LM 0.12'), 0x00,
      ];
      // Fix lengths
      final smbLen = negotiate.length - 4;
      negotiate[2] = (smbLen >> 8) & 0xFF;
      negotiate[3] = smbLen & 0xFF;
      const dialectLen = 2 + 'NT LM 0.12'.length + 1;
      negotiate[negotiate.length - dialectLen - 2] = dialectLen & 0xFF;
      negotiate[negotiate.length - dialectLen - 1] = (dialectLen >> 8) & 0xFF;

      socket.add(negotiate);

      final completer = Completer<Map<String, String>?>();
      final buffer = <int>[];
      Timer? timer;
      timer = Timer(const Duration(milliseconds: 2000), () {
        if (!completer.isCompleted) completer.complete(null);
        socket.destroy();
      });
      socket.listen(
        (data) {
          buffer.addAll(data);
          // Wait until we have enough data (at least 70 bytes for SMB negotiate response)
          if (buffer.length < 70) return;
          timer?.cancel();
          final result = _parseSmbNegotiateResponse(buffer);
          if (!completer.isCompleted) completer.complete(result);
          socket.destroy();
        },
        onError: (_) {
          timer?.cancel();
          if (!completer.isCompleted) completer.complete(null);
          socket.destroy();
        },
        onDone: () {
          timer?.cancel();
          if (!completer.isCompleted) completer.complete(null);
        },
      );

      final result = await completer.future;
      if (result != null) {
        _log(
          'L5',
          '  🖥️ SMB $ip → OS: ${result["os"]}, Computer: ${result["computer"]}',
        );
      }
      return result;
    } on Object catch (e) {
      if (e is SocketException) {
        _log('L5', '  ⚠️ SMB $ip: ${e.message}');
      }
    }
    return null;
  }

  /// Parse SMB1 NegotiateProtocol response to extract OS version and computer name.
  Map<String, String>? _parseSmbNegotiateResponse(List<int> data) {
    try {
      // Skip NetBIOS header (4 bytes) + SMB header (32 bytes) = offset 36
      // Then skip word count + words to get to the byte data
      if (data.length < 40) return null;
      // Verify SMB signature
      if (data[4] != 0xFF ||
          data[5] != 0x53 ||
          data[6] != 0x4D ||
          data[7] != 0x42) {
        return null;
      }

      final wordCount = data[36];
      final byteOffset = 37 + (wordCount * 2);
      if (byteOffset + 2 > data.length) return null;
      final blobStart = byteOffset + 2;
      if (blobStart >= data.length) return null;

      // The byte data after words contains:
      // - Security blob (variable)
      // - OsVersion (null-terminated UTF-16LE string)
      // - LanmanVersion (null-terminated UTF-16LE string)
      // - Domain (null-terminated UTF-16LE string)
      // Try to find UTF-16LE strings after the security blob
      final result = <String, String>{};
      final strings = _extractUTF16Strings(data, blobStart, data.length);
      if (strings.isNotEmpty) {
        result['os'] = strings[0];
        if (strings.length > 1) result['lanman'] = strings[1];
        if (strings.length > 2) result['domain'] = strings[2];
      }

      // Try to get computer name from a session setup if available
      // For negotiate, it may not be present, but OS version is enough
      if (result.isEmpty) return null;
      // Derive computer name from hostname if SMB doesn't give it directly
      return result;
    } on Object catch (_) {}
    return null;
  }

  /// Extract null-terminated UTF-16LE strings from a buffer.
  List<String> _extractUTF16Strings(List<int> data, int start, int end) {
    final strings = <String>[];
    var i = start;
    // Skip non-string content (security blob) by looking for readable patterns
    // Search for the first likely UTF-16LE string start (a printable ASCII char followed by 0x00)
    while (i + 1 < end) {
      if (data[i] >= 0x20 && data[i] < 0x7F && data[i + 1] == 0x00) break;
      i++;
    }
    while (i + 1 < end && strings.length < 4) {
      final strStart = i;
      // Find null terminator (0x00 0x00)
      while (i + 1 < end && !(data[i] == 0x00 && data[i + 1] == 0x00)) {
        i += 2;
      }
      if (i > strStart) {
        final chars = <int>[];
        for (var j = strStart; j + 1 <= i; j += 2) {
          chars.add(data[j] | (data[j + 1] << 8));
        }
        final str = String.fromCharCodes(chars).trim();
        if (str.isNotEmpty) strings.add(str);
      }
      i += 2; // Skip null terminator
    }
    return strings;
  }

  /// Identify device from SMB negotiate response.
  WifiDevice? _identifyFromSMB(Map<String, String> smb, String ip) {
    final os = (smb['os'] ?? '').toLowerCase();
    final lanman = (smb['lanman'] ?? '').toLowerCase();
    final domain = smb['domain'];

    if (os.contains('windows')) {
      final vMatch = RegExp(
        r'windows\s+([^\s]+(?:\s+\d+)?)',
        caseSensitive: false,
      ).firstMatch(smb['os'] ?? '');
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Microsoft',
        deviceName: 'Windows PC${domain != null ? " ($domain)" : ""}',
        firmwareVersion: vMatch?.group(1),
        deviceTypeRaw: 'windows-smb',
        deviceCategory: 'Computer',
        iconCategory: IconCategory.computer,
        confidenceScore: 75,
        smbOsVersion: smb['os'],
        httpBanner: 'SMB: ${smb["os"]}',
      );
    }
    if (os.contains('samba') || lanman.contains('samba')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Linux',
        deviceName: 'Linux Server (Samba)',
        deviceTypeRaw: 'samba-smb',
        deviceCategory: 'Computer',
        iconCategory: IconCategory.computer,
        confidenceScore: 65,
        smbOsVersion: smb['os'],
        httpBanner: 'SMB: ${smb["os"]}',
      );
    }
    if (os.contains('synology')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'Synology',
        deviceName: 'Synology NAS',
        deviceTypeRaw: 'synology-smb',
        deviceCategory: 'NAS / Storage',
        iconCategory: IconCategory.generic,
        confidenceScore: 85,
        smbOsVersion: smb['os'],
      );
    }
    if (os.contains('qnap')) {
      return WifiDevice(
        ipAddress: ip,
        manufacturer: 'QNAP',
        deviceName: 'QNAP NAS',
        deviceTypeRaw: 'qnap-smb',
        deviceCategory: 'NAS / Storage',
        iconCategory: IconCategory.generic,
        confidenceScore: 85,
        smbOsVersion: smb['os'],
      );
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NETLIB — Additional HTTP Endpoint Probes (Phase 8)
  // ═══════════════════════════════════════════════════════════════════════════

  /// HTTP endpoints to probe for device identification, matching NETLIB Phase 8.
  static const _additionalHttpEndpoints = [
    // (path, description)
    ('/admin/', 'Admin panel'),
    ('/cgi-bin/', 'CGI directory'),
    ('/webui/', 'WebUI panel'),
    ('/setup.cgi', 'Setup CGI'),
    ('/login.asp', 'ASP login'),
    ('/login.html', 'HTML login'),
    ('/api/', 'Generic API'),
    ('/api/v1/', 'API v1'),
    ('/device.xml', 'Device XML'),
    ('/UPnP/description.xml', 'UPnP Description'),
    ('/description.xml', 'UPnP alt'),
    ('/common/info.cgi', 'Printer info CGI'),
  ];

  /// Probe a single HTTP endpoint and try to identify the device from the response.
  Future<WifiDevice?> _probeHttpEndpoint(
    String ip,
    String path,
    String label,
  ) async {
    try {
      final resp = await http
          .get(Uri.parse('http://$ip$path'))
          .timeout(const Duration(milliseconds: 1200));
      if (resp.statusCode != 200 || resp.body.isEmpty) return null;

      final server = (resp.headers['server'] ?? '').toLowerCase();
      final body = resp.body;
      final bodyLower = body.toLowerCase();
      final titleMatch = RegExp(
        r'<title[^>]*>([^<]+)</title>',
        caseSensitive: false,
      ).firstMatch(body);
      final title = (titleMatch?.group(1)?.trim() ?? '').toLowerCase();

      // Try to identify from response
      String? mfr;
      String? name;
      String? model;
      String category = 'Smart Device';
      IconCategory icon = IconCategory.generic;
      int score = 70;

      // Router admin panels
      if (title.contains('netgear') || server.contains('netgear')) {
        mfr = 'Netgear';
        name = 'Netgear Router';
        category = 'Router / Gateway';
        icon = IconCategory.router;
        score = 80;
      } else if (title.contains('asus') ||
          server.contains('asus') ||
          title.contains('rt-') ||
          title.contains('asuswrt')) {
        mfr = 'ASUS';
        name = 'ASUS Router';
        category = 'Router / Gateway';
        icon = IconCategory.router;
        score = 82;
      } else if (title.contains('linksys') || server.contains('linksys')) {
        mfr = 'Linksys';
        name = 'Linksys Router';
        category = 'Router / Gateway';
        icon = IconCategory.router;
        score = 80;
      } else if (title.contains('tp-link') ||
          title.contains('tplink') ||
          server.contains('tp-link')) {
        mfr = 'TP-Link';
        name = 'TP-Link Router';
        category = 'Router / Gateway';
        icon = IconCategory.router;
        score = 80;
      } else if (title.contains('tenda') || server.contains('tenda')) {
        mfr = 'Tenda';
        name = 'Tenda Router';
        category = 'Router / Gateway';
        icon = IconCategory.router;
        score = 78;
      } else if (title.contains('zyxel') || server.contains('zyxel')) {
        mfr = 'ZyXEL';
        name = 'ZyXEL Router';
        category = 'Router / Gateway';
        icon = IconCategory.router;
        score = 80;
      } else if (title.contains('arris') || server.contains('arris')) {
        mfr = 'Arris';
        name = 'Arris Modem/Router';
        category = 'Router / Gateway';
        icon = IconCategory.router;
        score = 80;
      } else if (title.contains('motorola') &&
          (title.contains('router') ||
              title.contains('modem') ||
              title.contains('cable'))) {
        mfr = 'Motorola';
        name = 'Motorola Router';
        category = 'Router / Gateway';
        icon = IconCategory.router;
        score = 78;
      }

      // Printer admin panels
      if (mfr == null) {
        if (bodyLower.contains('hp ') &&
            (bodyLower.contains('printer') ||
                bodyLower.contains('laserjet') ||
                bodyLower.contains('officejet'))) {
          mfr = 'HP';
          name = 'HP Printer';
          category = 'Printer';
          icon = IconCategory.printer;
          score = 82;
          final modelMatch = RegExp(
            r'(LaserJet|OfficeJet|DeskJet|ENVY)\s*\S+',
            caseSensitive: false,
          ).firstMatch(body);
          if (modelMatch != null) {
            model = modelMatch.group(0);
            name = 'HP $model';
            score = 88;
          }
        } else if (bodyLower.contains('canon') &&
            (bodyLower.contains('printer') ||
                bodyLower.contains('remote ui'))) {
          mfr = 'Canon';
          name = 'Canon Printer';
          category = 'Printer';
          icon = IconCategory.printer;
          score = 82;
        } else if (bodyLower.contains('xerox')) {
          mfr = 'Xerox';
          name = 'Xerox Printer';
          category = 'Printer';
          icon = IconCategory.printer;
          score = 82;
        } else if (bodyLower.contains('lexmark')) {
          mfr = 'Lexmark';
          name = 'Lexmark Printer';
          category = 'Printer';
          icon = IconCategory.printer;
          score = 82;
        } else if (bodyLower.contains('ricoh')) {
          mfr = 'Ricoh';
          name = 'Ricoh Printer';
          category = 'Printer';
          icon = IconCategory.printer;
          score = 82;
        } else if (bodyLower.contains('konica') ||
            bodyLower.contains('minolta')) {
          mfr = 'Konica Minolta';
          name = 'Konica Minolta Printer';
          category = 'Printer';
          icon = IconCategory.printer;
          score = 82;
        }
      }

      // UPnP description XML
      if (mfr == null && path.contains('.xml')) {
        final xmlMfr = _xmlValue(body, 'manufacturer');
        final xmlModel =
            _xmlValue(body, 'modelName') ?? _xmlValue(body, 'modelNumber');
        final xmlFriendly = _xmlValue(body, 'friendlyName');
        if (xmlMfr != null || xmlFriendly != null) {
          mfr = xmlMfr;
          name = xmlFriendly ?? xmlModel;
          model = xmlModel;
          score = 78;
        }
      }

      if (mfr == null) return null;

      _log('L5', '  🌐 HTTP $ip$path → $mfr $name');
      return WifiDevice(
        ipAddress: ip,
        manufacturer: mfr,
        deviceName: name ?? '$mfr Device',
        modelNumber: model,
        deviceTypeRaw: 'http-$label',
        deviceCategory: category,
        iconCategory: icon,
        confidenceScore: score,
        httpBanner: 'HTTP $path',
      );
    } on Object catch (_) {}
    return null;
  }

  /// Extract a version string from a banner.
  String? _extractVersion(String banner) {
    final match = RegExp(r'(\d+\.\d+[\w.\-]*)').firstMatch(banner);
    return match?.group(1);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 4 — SNMP (Android only)
  //
  // Queries each discovered device's IP on UDP port 161 using SNMPv2c.
  // This gives us the device's self-reported system description and hostname —
  // the single most reliable way to identify routers, NAS boxes, managed
  // switches, printers, and Linux servers.
  //
  // iOS: the UDP socket is blocked by the iOS App Sandbox — returns {}.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Invoke the native Android SNMPv2c scanner for a list of IPs.
  /// Returns a map of IP → {"sysDescr": "…", "sysName": "…"}.
  // ignore: unused_element
  // Disabled for performance: SNMP scanning removed to reduce scan time
  Future<Map<String, Map<String, String>>> _runSnmpScan(
    List<String> ips,
  ) async {
    _log('SNMP', '───────────────────────────────────────────────────');
    _log('SNMP', '📡 LAYER 4: SNMP v2c Scan (${ips.length} IPs)');
    try {
      final result = await _platform.invokeMethod('snmpScan', {'ips': ips});
      if (result is Map) {
        final snmpMap = <String, Map<String, String>>{};
        result.forEach((ip, data) {
          if (ip is String && data is Map) {
            final d = <String, String>{};
            data.forEach((k, v) {
              if (k is String && v is String && v.isNotEmpty) d[k] = v;
            });
            if (d.isNotEmpty) snmpMap[ip] = d;
          }
        });
        if (snmpMap.isNotEmpty) {
          _log(
            'SNMP',
            '✅ SNMP: ${snmpMap.length} device(s) responded via UDP 161',
          );
          for (final e in snmpMap.entries) {
            _log(
              'SNMP',
              '   ${e.key}',
              'descr=${e.value['sysDescr']?.substring(0, e.value['sysDescr']!.length.clamp(0, 60))} '
                  '| name=${e.value['sysName']}',
            );
          }
        } else {
          _log('SNMP', 'ℹ️ No devices responded on UDP 161 (SNMP disabled)');
        }
        return snmpMap;
      }
    } on Object catch (e) {
      _log('SNMP', '⚠️ SNMP platform invocation failed', e.toString());
    }
    return {};
  }

  /// Merge SNMP sysDescr/sysName data into discovered devices.
  /// Only upgrades devices where SNMP provides genuinely better data.
  // ignore: unused_element
  // Disabled for performance: SNMP data mapping removed to reduce scan time
  List<WifiDevice> _applySnmpData(
    List<WifiDevice> devices,
    Map<String, Map<String, String>> snmpData,
  ) {
    return devices.map((device) {
      final data = snmpData[device.ipAddress];
      if (data == null || data.isEmpty) return device;

      final sysDescr = data['sysDescr'];
      final sysName = data['sysName'];
      final sysLocation = data['sysLocation'];
      final hrDeviceDescr = data['hrDeviceDescr'];
      final prtName = data['prtName'];
      final prtSerial = data['prtSerial'];
      final ifDescr = data['ifDescr'];
      if (sysDescr == null &&
          sysName == null &&
          prtName == null &&
          hrDeviceDescr == null) {
        return device;
      }

      String newMfr = device.manufacturer;
      String newName = device.deviceName;
      String? newModel = device.modelNumber;
      String? newSerial = device.serialNumber;
      String? newCategory;
      IconCategory? newIcon;
      int newScore = device.confidenceScore;

      if (sysDescr != null && sysDescr.isNotEmpty) {
        final d = sysDescr.toLowerCase();
        if (d.contains('synology')) {
          newMfr = 'Synology';
          newCategory = 'NAS / Storage';
          newIcon = IconCategory.generic;
          newScore = _snmpScore(newScore, 88);
        } else if (d.contains('qnap') || d.contains('qts')) {
          newMfr = 'QNAP';
          newCategory = 'NAS / Storage';
          newIcon = IconCategory.generic;
          newScore = _snmpScore(newScore, 88);
        } else if (d.contains('cisco ios') || d.contains('cisco adaptive')) {
          newMfr = 'Cisco';
          newCategory = 'Network Equipment';
          newIcon = IconCategory.router;
          newScore = _snmpScore(newScore, 90);
        } else if (d.contains('ubiquiti') ||
            d.contains('airmax') ||
            d.contains('unifi')) {
          newMfr = 'Ubiquiti';
          newCategory = 'Network Equipment';
          newIcon = IconCategory.router;
          newScore = _snmpScore(newScore, 88);
        } else if (d.contains('mikrotik') || d.contains('routeros')) {
          newMfr = 'MikroTik';
          newCategory = 'Router / Gateway';
          newIcon = IconCategory.router;
          newScore = _snmpScore(newScore, 88);
        } else if (d.contains('juniper')) {
          newMfr = 'Juniper';
          newCategory = 'Network Equipment';
          newIcon = IconCategory.router;
          newScore = _snmpScore(newScore, 88);
        } else if (d.contains('hp') &&
            (d.contains('jetdirect') || d.contains('printer'))) {
          newMfr = 'HP';
          newCategory = 'Printer';
          newIcon = IconCategory.printer;
          newScore = _snmpScore(newScore, 88);
        } else if (d.contains('netgear')) {
          newMfr = 'Netgear';
          newCategory = 'Router / Gateway';
          newIcon = IconCategory.router;
          newScore = _snmpScore(newScore, 82);
        } else if (d.contains('raspberry pi') ||
            d.contains('raspbian') ||
            d.contains('raspios')) {
          newMfr = 'Raspberry Pi';
          newCategory = 'Computer';
          newIcon = IconCategory.computer;
          newScore = _snmpScore(newScore, 82);
        } else if (d.contains('freenas') || d.contains('truenas')) {
          newMfr = 'TrueNAS';
          newCategory = 'NAS / Storage';
          newIcon = IconCategory.generic;
          newScore = _snmpScore(newScore, 88);
        } else if (d.contains('pfsense') || d.contains('opnsense')) {
          newMfr = d.contains('opnsense') ? 'OPNsense' : 'pfSense';
          newCategory = 'Router / Gateway';
          newIcon = IconCategory.router;
          newScore = _snmpScore(newScore, 88);
        } else if (d.contains('brother') && d.contains('nc-')) {
          newMfr = 'Brother';
          newCategory = 'Printer';
          newIcon = IconCategory.printer;
          newScore = _snmpScore(newScore, 88);
        } else if (d.contains('epson')) {
          newMfr = 'Epson';
          newCategory = 'Printer';
          newIcon = IconCategory.printer;
          newScore = _snmpScore(newScore, 82);
        } else if (device.manufacturer == 'Unknown') {
          if (d.contains('linux')) {
            newMfr = 'Linux Device';
            newScore = _snmpScore(newScore, 35);
          } else if (d.contains('windows')) {
            newMfr = 'Windows Device';
            newScore = _snmpScore(newScore, 35);
          }
        }
        // Try to parse model number from sysDescr
        if (newModel == null) {
          final modelMatch = RegExp(
            r'(?:model[:\s]+|hw[:]\s*)([A-Za-z0-9][A-Za-z0-9\-_]{1,20})',
            caseSensitive: false,
          ).firstMatch(sysDescr);
          newModel = modelMatch?.group(1);
        }
      }

      // ── SNMP Printer-MIB: printer name + serial number ──────────────
      if (prtName != null && prtName.isNotEmpty) {
        if (newCategory == null || newCategory != 'Printer') {
          newCategory = 'Printer';
          newIcon = IconCategory.printer;
        }
        if (newName.startsWith('Device at') || newName == device.deviceName) {
          newName = prtName;
        }
        newScore = _snmpScore(newScore, 88);
      }
      if (prtSerial != null && prtSerial.isNotEmpty) {
        newSerial = prtSerial;
        newScore = _snmpScore(newScore, 90);
      }

      // ── HOST-RESOURCES-MIB: device description ──────────────────────
      if (hrDeviceDescr != null && hrDeviceDescr.isNotEmpty) {
        newModel ??= hrDeviceDescr;
        // hrDeviceDescr often contains the physical device model
        final hd = hrDeviceDescr.toLowerCase();
        if (hd.contains('printer') && newCategory == null) {
          newCategory = 'Printer';
          newIcon = IconCategory.printer;
        }
      }

      // ── IF-MIB: interface description for hints ─────────────────────
      if (ifDescr != null && newMfr == 'Unknown') {
        final ifd = ifDescr.toLowerCase();
        if (ifd.contains('intel')) {
          newMfr = 'Intel-based PC';
        } else if (ifd.contains('realtek')) {
          newMfr = 'Realtek-based Device';
        } else if (ifd.contains('broadcom')) {
          newMfr = 'Broadcom-based Device';
        }
      }

      // sysName is the device's configured hostname — use it when we have none
      if (sysName != null && sysName.isNotEmpty) {
        if (device.hostname == null &&
            device.deviceName.startsWith('Device at')) {
          newName = sysName;
          if (newScore < 50) newScore = 50;
        }
      }

      // Only apply changes if we actually have improvements
      if (newMfr == device.manufacturer &&
          newName == device.deviceName &&
          newModel == device.modelNumber &&
          newSerial == device.serialNumber &&
          newScore == device.confidenceScore) {
        return device;
      }

      _log(
        'SNMP',
        '  🔍 ${device.ipAddress} enriched via SNMP:',
        '"$newName" ($newMfr) — score ${device.confidenceScore}→$newScore'
            '${newSerial != null ? ", serial=$newSerial" : ""}'
            '${sysLocation != null ? ", location=$sysLocation" : ""}',
      );

      return device.copyWithEnrichment(
        manufacturer: newMfr != device.manufacturer ? newMfr : null,
        deviceName: newName != device.deviceName ? newName : null,
        modelNumber: newModel,
        serialNumber: newSerial,
        deviceCategory: newCategory,
        iconCategory: newIcon,
        confidenceScore: newScore > device.confidenceScore ? newScore : null,
      );
    }).toList();
  }

  /// Returns the higher of [current] and [snmpBase] confidence scores.
  int _snmpScore(int current, int snmpBase) =>
      current > snmpBase ? current : snmpBase;

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 3 — Backend Enrichment
  // ═══════════════════════════════════════════════════════════════════════════

  final _apiClient = ApiClient();

  Future<List<WifiDevice>> _enrichViaBackend(List<WifiDevice> devices) async {
    if (devices.isEmpty) return devices;

    _log('Enrich', '───────────────────────────────────────────────────');
    _log('Enrich', '🌐 LAYER 3: Backend Enrichment');
    _log(
      'Enrich',
      '   Sending ${devices.length} device(s) to POST /discovery/enrich',
    );

    try {
      final response = await _apiClient.post(
        '/discovery/enrich',
        body: {
          'devices': devices
              .map(
                (d) => {
                  ...d.toJson(),
                  // Include banner fields so backend can apply its fingerprint DB
                  if (d.httpBanner != null) 'httpBanner': d.httpBanner,
                  if (d.htmlTitle != null) 'htmlTitle': d.htmlTitle,
                  if (d.hostname != null) 'hostname': d.hostname,
                },
              )
              .toList(),
        },
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      _log(
        'Enrich',
        '📥 Backend responded: ${response.statusCode}',
        const JsonEncoder.withIndent('  ').convert(body),
      );

      if (response.statusCode == 200 && body['success'] == true) {
        final enrichedList = body['data'] as List? ?? [];
        // Build a lookup map by IP and MAC for robust matching
        final enrichMap = <String, Map<String, dynamic>>{};
        for (final item in enrichedList) {
          if (item is Map<String, dynamic>) {
            final ip = item['ipAddress']?.toString();
            final mac = item['macAddress']?.toString().toUpperCase();
            if (ip != null && ip.isNotEmpty) enrichMap['ip:$ip'] = item;
            if (mac != null && mac.isNotEmpty) enrichMap['mac:$mac'] = item;
          }
        }

        final result = <WifiDevice>[];
        for (final orig in devices) {
          // Match by IP first, then MAC
          final e =
              enrichMap['ip:${orig.ipAddress}'] ??
              (orig.macAddress != null
                  ? enrichMap['mac:${orig.macAddress!.toUpperCase()}']
                  : null);

          if (e != null) {
            result.add(
              orig.copyWithEnrichment(
                manufacturer: e['manufacturer'] ?? orig.manufacturer,
                modelNumber: e['modelNumber'] ?? orig.modelNumber,
                serialNumber: e['serialNumber'] ?? orig.serialNumber,
                deviceCategory: e['deviceCategory'] ?? orig.deviceCategory,
                confidenceScore: e['confidenceScore'] ?? orig.confidenceScore,
                backendData: e,
                hostname: e['hostname'] ?? orig.hostname,
                osHint: e['osHint'] ?? orig.osHint,
                productImageUrl: e['productImageUrl'] as String?,
                productName: e['productName'] as String?,
                brandGuess: e['brandGuess'] as String?,
                osGuess: e['osGuess'] as String?,
                fingerprintReasoning:
                    (e['fingerprintReasoning'] as List?)
                        ?.map((s) => s.toString())
                        .toList() ??
                    orig.fingerprintReasoning,
              ),
            );
          } else {
            result.add(orig);
          }
        }

        _log('Enrich', '✅ ${enrichedList.length} device(s) enriched');
        return result;
      }
    } on Object catch (e) {
      _log(
        'Enrich',
        '⚠️ Backend enrichment failed (using local data)',
        e.toString(),
      );
    }

    return devices;
  }

  /// After the full scan completes, registers the scan session to the backend
  /// so device history is tracked over time.
  Future<void> _registerScanToBackend(
    List<WifiDevice> devices, {
    String? ssid,
    String? localIp,
    String? gatewayIp,
    int? scanDurationMs,
  }) async {
    if (devices.isEmpty) return;
    try {
      _log('Enrich', '💾 Registering scan session to backend...');
      final response = await _apiClient.post(
        '/discovery/register-scan',
        body: {
          'devices': devices
              .map(
                (d) => {
                  ...d.toJson(),
                  if (d.httpBanner != null) 'httpBanner': d.httpBanner,
                  if (d.htmlTitle != null) 'htmlTitle': d.htmlTitle,
                  if (d.hostname != null) 'hostname': d.hostname,
                },
              )
              .toList(),
          'ssid': ?ssid,
          'localIp': ?localIp,
          'gatewayIp': ?gatewayIp,
          'scanDurationMs': ?scanDurationMs,
        },
      );
      if (response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>? ?? {};
        _log(
          'Enrich',
          '✅ Scan registered: scanId=${data["scanId"]}, '
              'saved=${data["savedCount"]}/${devices.length}',
        );
      }
    } on Object catch (e) {
      _log('Enrich', '⚠️ register-scan failed (non-critical)', e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  String? _extractLocationUrl(String response) {
    for (final line in response.split('\n')) {
      if (line.trim().toLowerCase().startsWith('location:')) {
        final url = line.substring(line.indexOf(':') + 1).trim();
        if (url.startsWith('http')) return url;
      }
    }
    return null;
  }

  Future<WifiDevice?> _fetchDeviceInfo(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(_httpTimeout);
      if (response.statusCode != 200) return null;

      final xml = response.body;
      final ip = Uri.parse(url).host;

      final manufacturer = _xmlValue(xml, 'manufacturer') ?? 'Unknown';
      final modelName = _xmlValue(xml, 'modelName');
      final modelNumber = _xmlValue(xml, 'modelNumber');
      final serialNumber = _xmlValue(xml, 'serialNumber');
      final friendlyName = _xmlValue(xml, 'friendlyName') ?? '';
      final deviceType = _xmlValue(xml, 'deviceType') ?? '';

      // Skip virtual WAN sub-device entries (not physical devices — they're
      // sub-components of the router's UPnP tree). Everything else is kept.
      final dtLower = deviceType.toLowerCase();
      for (final skip in _skipDeviceTypes) {
        if (dtLower.contains(skip)) return null;
      }

      final rawModel =
          (modelNumber?.isNotEmpty == true ? modelNumber : modelName) ?? '';
      final cleanModel = _sanitizeModelNumber(
        rawModel.isNotEmpty ? rawModel : null,
      );
      final cleanSerial = _sanitizeSerial(serialNumber);

      int score = 30;
      if (manufacturer != 'Unknown') score += 20;
      if (friendlyName.isNotEmpty) score += 15;
      if (cleanModel != null) score += 20;
      if (cleanSerial != null) score += 15;

      return WifiDevice(
        ipAddress: ip,
        manufacturer: _cleanManufacturer(manufacturer),
        deviceName: friendlyName.isNotEmpty ? friendlyName : manufacturer,
        modelNumber: cleanModel,
        serialNumber: cleanSerial,
        deviceTypeRaw: deviceType,
        deviceCategory: _humanCategory(deviceType, friendlyName),
        iconCategory: _resolveIcon(deviceType, friendlyName),
        confidenceScore: score.clamp(0, 100),
        discoveryMethod: 'upnp',
      );
    } on Object catch (_) {
      return null;
    }
  }

  String? _xmlValue(String xml, String tag) {
    final open = '<$tag>';
    final close = '</$tag>';
    final start = xml.indexOf(open);
    if (start == -1) return null;
    final end = xml.indexOf(close, start);
    if (end == -1) return null;
    return _decodeHtmlEntities(xml.substring(start + open.length, end).trim());
  }

  /// Decode XML/HTML character references and named entities.
  /// Handles &#NNN; (decimal), &#xHH; (hex), and the 5 named entities.
  String _decodeHtmlEntities(String s) {
    return s
        .replaceAllMapped(
          RegExp(r'&#x([0-9A-Fa-f]+);'),
          (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)),
        )
        .replaceAllMapped(
          RegExp(r'&#([0-9]+);'),
          (m) => String.fromCharCode(int.parse(m[1]!)),
        )
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }

  String _cleanManufacturer(String raw) {
    return raw
        .replaceAll(
          RegExp(
            r'\s+(Electronics|Corporation|Corp\.?|Inc\.?|Co\.?|Ltd\.?|GmbH|LLC)',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  String _humanCategory(String dt, String fn) {
    final d = dt.toLowerCase();
    final f = fn.toLowerCase();
    if (d.contains('mediarenderer') ||
        f.contains('tv') ||
        f.contains('television')) {
      return 'Smart TV';
    }
    if (d.contains('mediasrv') || d.contains('mediaserver')) {
      return 'Media Server';
    }
    if (f.contains('speaker') || f.contains('sonos') || f.contains('bose')) {
      return 'Smart Speaker';
    }
    if (f.contains('printer') || d.contains('printer')) return 'Printer';
    if (f.contains('camera') || d.contains('camera')) return 'Camera';
    if (f.contains('plug') ||
        f.contains('switch') ||
        d.contains('binarylight')) {
      return 'Smart Plug';
    }
    if (f.contains('bulb') || f.contains('light') || f.contains('hue')) {
      return 'Smart Light';
    }
    if (f.contains('therm') || f.contains('nest') || f.contains('ecobee')) {
      return 'Thermostat';
    }
    if (d.contains('router') || d.contains('gateway')) return 'Router';
    return 'Smart Device';
  }

  IconCategory _resolveIcon(String dt, String fn) {
    final d = dt.toLowerCase();
    final f = fn.toLowerCase();
    if (d.contains('mediarenderer') || f.contains('tv')) return IconCategory.tv;
    if (f.contains('speaker') || f.contains('sonos') || f.contains('bose')) {
      return IconCategory.speaker;
    }
    if (f.contains('printer') || d.contains('printer')) {
      return IconCategory.printer;
    }
    if (f.contains('camera') || d.contains('camera')) {
      return IconCategory.camera;
    }
    if (f.contains('plug') || f.contains('switch')) {
      return IconCategory.smartPlug;
    }
    if (f.contains('bulb') || f.contains('light') || f.contains('hue')) {
      return IconCategory.lightBulb;
    }
    if (f.contains('therm') || f.contains('nest') || f.contains('ecobee')) {
      return IconCategory.thermostat;
    }
    if (d.contains('router') || d.contains('gateway')) {
      return IconCategory.router;
    }
    return IconCategory.generic;
  }

  /// Infer manufacturer from the mDNS service type, then fall back to name.
  String _mdnsManufacturer(String serviceType, String name) {
    const serviceManufacturers = <String, String>{
      '_airplay._tcp': 'Apple',
      '_raop._tcp': 'Apple',
      '_apple-mobdev2._tcp': 'Apple',
      '_rdlink._tcp': 'Apple',
      '_device-info._tcp': 'Apple',
      '_googlecast._tcp': 'Google',
      '_sonos._tcp': 'Sonos',
      '_spotify-connect._tcp': 'Spotify',
      '_hue._tcp': 'Philips',
    };
    final knownMfr = serviceManufacturers[serviceType];
    if (knownMfr != null) return knownMfr;
    return _extractManufacturerFromName(name);
  }

  // ── Data quality sanitizers ───────────────────────────────────────────────

  /// Returns null when [s] looks like a garbage serial number:
  /// raw MAC address, pure hex hardware ID, UUID, all-same-char pattern,
  /// firmware version, or generic placeholder text.
  String? _sanitizeSerial(String? s) {
    if (s == null) return null;
    final t = s.trim();
    if (t.length < 3) return null;
    // Bare MAC (12 hex, no separators)
    if (RegExp(r'^[0-9A-Fa-f]{12}$').hasMatch(t)) return null;
    // MAC with colons or dashes
    if (RegExp(r'^([0-9A-Fa-f]{2}[:\-]){5}[0-9A-Fa-f]{2}$').hasMatch(t)) {
      return null;
    }
    // UUID / GUID
    if (RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(t)) {
      return null;
    }
    // All same character (e.g. "00000000", "FFFFFFFF")
    if (t.split('').toSet().length == 1) return null;
    // Pure hex string ≥8 chars — hardware IDs like "A1B2C3D4"
    if (t.length >= 8 && RegExp(r'^[0-9A-Fa-f]+$').hasMatch(t)) return null;
    // IP address
    if (RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(t)) {
      return null;
    }
    // Pure firmware/version string (e.g. "1.0.0", "2.4.1")
    if (RegExp(r'^\d+\.\d+(\.\d+)*$').hasMatch(t)) return null;
    // Generic placeholder words
    const badSerials = {
      'unknown',
      'none',
      'null',
      'n/a',
      'na',
      'default',
      '0',
      '00',
      '1',
      'not set',
      'not available',
      'unavailable',
      'serial',
      'serialnumber',
      'undefined',
      'empty',
      'fake',
      'test',
      'demo',
    };
    if (badSerials.contains(t.toLowerCase())) return null;
    return t;
  }

  // ── Apple device model ID → human-readable name ─────────────────────────
  // Apple broadcasts internal board IDs via mDNS TXT (e.g. "iPhone15,2").
  // Translate these to friendly product names before display.
  static const Map<String, String> _appleModelMap = {
    // ─── iPhone 16 series (2024) ────────────────────────────────────────
    'iPhone17,1': 'iPhone 16 Pro',
    'iPhone17,2': 'iPhone 16 Pro Max',
    'iPhone17,3': 'iPhone 16',
    'iPhone17,4': 'iPhone 16 Plus',
    // ─── iPhone 15 series (2023) ────────────────────────────────────────
    'iPhone16,1': 'iPhone 15 Pro',
    'iPhone16,2': 'iPhone 15 Pro Max',
    'iPhone15,4': 'iPhone 15',
    'iPhone15,5': 'iPhone 15 Plus',
    // ─── iPhone 14 series (2022) ────────────────────────────────────────
    'iPhone15,2': 'iPhone 14 Pro',
    'iPhone15,3': 'iPhone 14 Pro Max',
    'iPhone14,7': 'iPhone 14',
    'iPhone14,8': 'iPhone 14 Plus',
    'iPhone14,6': 'iPhone SE (3rd gen)',
    // ─── iPhone 13 series (2021) ────────────────────────────────────────
    'iPhone14,2': 'iPhone 13 Pro',
    'iPhone14,3': 'iPhone 13 Pro Max',
    'iPhone14,4': 'iPhone 13 Mini',
    'iPhone14,5': 'iPhone 13',
    // ─── iPhone 12 series (2020) ────────────────────────────────────────
    'iPhone13,1': 'iPhone 12 Mini',
    'iPhone13,2': 'iPhone 12',
    'iPhone13,3': 'iPhone 12 Pro',
    'iPhone13,4': 'iPhone 12 Pro Max',
    'iPhone12,8': 'iPhone SE (2nd gen)',
    // ─── iPhone 11 series (2019) ────────────────────────────────────────
    'iPhone12,1': 'iPhone 11',
    'iPhone12,3': 'iPhone 11 Pro',
    'iPhone12,5': 'iPhone 11 Pro Max',
    // ─── iPhone XS / XR (2018) ──────────────────────────────────────────
    'iPhone11,2': 'iPhone XS',
    'iPhone11,4': 'iPhone XS Max',
    'iPhone11,6': 'iPhone XS Max',
    'iPhone11,8': 'iPhone XR',
    // ─── iPhone X / 8 (2017) ────────────────────────────────────────────
    'iPhone10,3': 'iPhone X',
    'iPhone10,6': 'iPhone X',
    'iPhone10,1': 'iPhone 8',
    'iPhone10,2': 'iPhone 8 Plus',
    'iPhone10,4': 'iPhone 8',
    'iPhone10,5': 'iPhone 8 Plus',
    // ─── iPad Pro M4 (2024) ─────────────────────────────────────────────
    'iPad16,3': 'iPad Pro 11" M4',
    'iPad16,4': 'iPad Pro 11" M4',
    'iPad16,5': 'iPad Pro 13" M4',
    'iPad16,6': 'iPad Pro 13" M4',
    // ─── iPad Air M2 (2024) ─────────────────────────────────────────────
    'iPad14,8': 'iPad Air 11" M2',
    'iPad14,9': 'iPad Air 11" M2',
    'iPad14,10': 'iPad Air 13" M2',
    'iPad14,11': 'iPad Air 13" M2',
    // ─── iPad Pro M2 (2022) ─────────────────────────────────────────────
    'iPad14,3': 'iPad Pro 11" M2',
    'iPad14,4': 'iPad Pro 11" M2',
    'iPad14,5': 'iPad Pro 12.9" M2',
    'iPad14,6': 'iPad Pro 12.9" M2',
    // ─── iPad Mini 6th gen (2021) ───────────────────────────────────────
    'iPad14,1': 'iPad Mini (6th gen)',
    'iPad14,2': 'iPad Mini (6th gen)',
    // ─── iPad 10th gen (2022) ───────────────────────────────────────────
    'iPad13,18': 'iPad (10th gen)',
    'iPad13,19': 'iPad (10th gen)',
    // ─── iPad Air M1 (2022) ─────────────────────────────────────────────
    'iPad13,16': 'iPad Air M1',
    'iPad13,17': 'iPad Air M1',
    // ─── iPad Pro M1 (2021) ─────────────────────────────────────────────
    'iPad13,4': 'iPad Pro 11" M1',
    'iPad13,5': 'iPad Pro 11" M1',
    'iPad13,6': 'iPad Pro 11" M1',
    'iPad13,7': 'iPad Pro 11" M1',
    'iPad13,8': 'iPad Pro 12.9" M1',
    'iPad13,9': 'iPad Pro 12.9" M1',
    'iPad13,10': 'iPad Pro 12.9" M1',
    'iPad13,11': 'iPad Pro 12.9" M1',
    // ─── iPad 9th gen (2021) ────────────────────────────────────────────
    'iPad12,1': 'iPad (9th gen)',
    'iPad12,2': 'iPad (9th gen)',
    // ─── iPad Air 4th gen (2020) ────────────────────────────────────────
    'iPad13,1': 'iPad Air (4th gen)',
    'iPad13,2': 'iPad Air (4th gen)',
    // ─── iPad 8th gen (2020) ────────────────────────────────────────────
    'iPad11,6': 'iPad (8th gen)',
    'iPad11,7': 'iPad (8th gen)',
    // ─── iPad Mini 5th gen (2019) ───────────────────────────────────────
    'iPad11,1': 'iPad Mini (5th gen)',
    'iPad11,2': 'iPad Mini (5th gen)',
    // ─── iPad Air 3rd gen (2019) ────────────────────────────────────────
    'iPad11,3': 'iPad Air (3rd gen)',
    'iPad11,4': 'iPad Air (3rd gen)',
  };

  /// Returns null when [s] looks like a garbage model number:
  /// Apple internal board ID, firmware version string, UUID,
  /// all-same-char pattern, or generic placeholder text.
  String? _sanitizeModelNumber(String? s) {
    if (s == null) return null;
    final t = s.trim();
    if (t.length < 2) return null;
    // Apple internal board IDs (e.g. "Mac16,13", "iPhone15,2", "iPad14,3")
    // Translate to human-readable product names instead of discarding.
    if (RegExp(r'^(Mac|iPhone|iPad|iPod)\d+,\d+$').hasMatch(t)) {
      return _appleModelMap[t]; // null if not in map → silently dropped
    }
    // Pure firmware/version string (e.g. "1.0.0", "10.9.7.0", "1.29.2.6364-6d72b0cf6")
    if (RegExp(r'^\d+\.\d+[\d.]*(-[a-zA-Z0-9]+)*$').hasMatch(t)) return null;
    // UUID / GUID
    if (RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(t)) {
      return null;
    }
    // All same character
    if (t.split('').toSet().length == 1) return null;
    // Pure long hex string ≥12 chars — internal hardware identifier
    if (t.length >= 12 && RegExp(r'^[0-9A-Fa-f]+$').hasMatch(t)) return null;
    // Generic placeholder words
    const badModels = {
      'unknown',
      'none',
      'null',
      'n/a',
      'na',
      'default',
      '0',
      '1',
      'not set',
      'model',
      'model number',
      'undefined',
      'empty',
    };
    if (badModels.contains(t.toLowerCase())) return null;
    // Comma-separated short numbers (e.g. "0,1,2" from mDNS TXT records)
    if (RegExp(r'^[\d,\s]+$').hasMatch(t) && t.contains(',')) return null;
    // Very short strings that are just numbers (e.g. "01", "10")
    if (t.length <= 3 && RegExp(r'^\d+$').hasMatch(t)) return null;
    return t;
  }

  String _extractManufacturerFromName(String name) {
    const brands = [
      'Samsung',
      'LG',
      'Sony',
      'Vizio',
      'TCL',
      'Hisense',
      'Philips',
      'Sonos',
      'Bose',
      'JBL',
      'Denon',
      'Yamaha',
      'HP',
      'Canon',
      'Epson',
      'Brother',
      'Google',
      'Amazon',
      'Apple',
      'Nest',
      'Ring',
      'Roku',
      'TP-Link',
      'Netgear',
      'Linksys',
      'Asus',
      'Belkin',
      'Ecobee',
      'Honeywell',
      'Lutron',
      'Wemo',
    ];
    final lower = name.toLowerCase();
    for (final b in brands) {
      if (lower.contains(b.toLowerCase())) return b;
    }
    // Infer Apple from device name keywords
    if (lower.contains('macbook') ||
        lower.contains('imac') ||
        lower.contains('mac pro') ||
        lower.contains('mac mini') ||
        lower.contains('apple tv')) {
      return 'Apple';
    }
    final parts = name.split(RegExp(r'[\s\-_]'));
    // Don't use possessive names like "Kishan's" as a manufacturer
    if (parts.isNotEmpty &&
        parts.first.length >= 2 &&
        !parts.first.endsWith("'s") &&
        !parts.first.endsWith('\u2019s')) {
      return parts.first;
    }
    return 'Unknown';
  }

  /// Pick the better (non-empty / non-Unknown) value.
  String _best(String a, String b) {
    if (a.isEmpty || a == 'Unknown') return b;
    return a;
  }

  /// Merge two WifiDevice records for the same IP, combining the best fields.
  WifiDevice _mergeDevices(WifiDevice a, WifiDevice b) {
    // Decide which is the "primary" based on confidence
    final primary = a.confidenceScore >= b.confidenceScore ? a : b;
    final secondary = a.confidenceScore >= b.confidenceScore ? b : a;

    // Merge open-port lists
    final mergedPorts = {...primary.openPorts, ...secondary.openPorts}.toList()
      ..sort();

    // Combine discovery methods
    final methods = {primary.discoveryMethod, secondary.discoveryMethod};
    final methodStr = methods.length > 1 ? 'both' : methods.first;

    return WifiDevice(
      ipAddress: primary.ipAddress,
      macAddress: primary.macAddress ?? secondary.macAddress,
      manufacturer: _best(primary.manufacturer, secondary.manufacturer),
      deviceName: _best(primary.deviceName, secondary.deviceName),
      hostname: primary.hostname ?? secondary.hostname,
      modelNumber: primary.modelNumber ?? secondary.modelNumber,
      serialNumber: primary.serialNumber ?? secondary.serialNumber,
      deviceTypeRaw: _best(primary.deviceTypeRaw, secondary.deviceTypeRaw),
      deviceCategory: _best(primary.deviceCategory, secondary.deviceCategory),
      iconCategory: primary.iconCategory != IconCategory.generic
          ? primary.iconCategory
          : secondary.iconCategory,
      confidenceScore: primary.confidenceScore > secondary.confidenceScore
          ? primary.confidenceScore
          : secondary.confidenceScore,
      discoveryMethod: methodStr,
      openPorts: mergedPorts,
      httpBanner: primary.httpBanner ?? secondary.httpBanner,
      htmlTitle: primary.htmlTitle ?? secondary.htmlTitle,
      osHint: primary.osHint ?? secondary.osHint,
      sshBanner: primary.sshBanner ?? secondary.sshBanner,
      tlsCertSubject: primary.tlsCertSubject ?? secondary.tlsCertSubject,
      firmwareVersion: primary.firmwareVersion ?? secondary.firmwareVersion,
      serviceVersions: {
        ...secondary.serviceVersions,
        ...primary.serviceVersions,
      },
      smbOsVersion: primary.smbOsVersion ?? secondary.smbOsVersion,
    );
  }

  /// Merges devices from all layers, removes duplicates and noise.
  List<WifiDevice> _filterAndRank(
    List<WifiDevice> devices,
    String localIp,
    String? gatewayIp,
  ) {
    // Step 1: Merge by IP — combine data from different discovery layers
    // FIX 1: mDNS devices now may carry a real IP (from A records).
    //   • If ip != 'mDNS' → merge by IP as normal.
    //   • If ip == 'mDNS' → try hostname/manufacturer fuzzy-match with ARP
    //     entries before falling back to a 'mdns:name' key.
    final byIp = <String, WifiDevice>{};

    for (final d in devices) {
      String key;

      if (d.ipAddress == 'mDNS') {
        // Try to find an already-known ARP device to merge with
        String? matchedKey;
        final dn = d.deviceName.toLowerCase().replaceAll(
          RegExp(r"['\s\-_]"),
          '',
        );

        for (final existingKey in List.from(byIp.keys)) {
          if (existingKey.startsWith('mdns:')) continue;
          final ed = byIp[existingKey]!;
          final eh = (ed.hostname ?? '').toLowerCase().replaceAll(
            RegExp(r"['\s\-_]"),
            '',
          );
          final em = ed.manufacturer.toLowerCase();
          // Match if hostname substring overlaps OR manufacturer prefix overlaps
          final dnShort = dn.length > 3
              ? dn.substring(0, dn.length.clamp(0, 6))
              : dn;
          final emShort = em.length > 3
              ? em.substring(0, em.length.clamp(0, 5))
              : em;
          if ((eh.isNotEmpty && (dn.contains(eh) || eh.contains(dnShort))) ||
              (em != 'unknown' && em.length > 2 && dn.contains(emShort))) {
            matchedKey = existingKey;
            break;
          }
        }
        key = matchedKey ?? 'mdns:${d.deviceName.toLowerCase()}';
      } else {
        key = d.ipAddress;
      }

      if (byIp.containsKey(key)) {
        byIp[key] = _mergeDevices(byIp[key]!, d);
      } else {
        byIp[key] = d;
      }
    }

    // Step 2: Remove our own phone (keep the gateway — it's the router!)
    byIp.remove(localIp);

    // Step 2a: Deduplicate by MAC address (devices with multiple IPs)
    final byMac = <String, String>{}; // MAC → best IP key
    for (final entry in byIp.entries) {
      final mac = entry.value.macAddress;
      if (mac == null || mac.isEmpty) continue;
      final macKey = mac.toUpperCase();
      if (byMac.containsKey(macKey)) {
        final existingKey = byMac[macKey]!;
        final existing = byIp[existingKey]!;
        // Merge the duplicate into the one with the higher score
        if (entry.value.confidenceScore > existing.confidenceScore) {
          byIp[entry.key] = _mergeDevices(entry.value, existing);
          byIp.remove(existingKey);
          byMac[macKey] = entry.key;
        } else {
          byIp[existingKey] = _mergeDevices(existing, entry.value);
          byIp.remove(entry.key);
        }
      } else {
        byMac[macKey] = entry.key;
      }
    }

    // Step 2b: Tag the gateway as router if present
    // ALWAYS set category to "Router / Gateway" for the gateway IP — the
    // gateway is definitionally the router, even if port-based heuristics
    // assigned it a different category like "DNS Server" or "Web Server".
    if (gatewayIp != null && byIp.containsKey(gatewayIp)) {
      final gw = byIp[gatewayIp]!;
      final gwName =
          gw.deviceName.isEmpty ||
              gw.deviceName.startsWith('Device at') ||
              gw.deviceName == 'Unknown'
          ? '${gw.manufacturer != "Unknown" ? gw.manufacturer : "Network"} Router'
          : gw.deviceName;
      byIp[gatewayIp] = gw.copyWithEnrichment(
        deviceCategory: 'Router / Gateway',
        iconCategory: IconCategory.router,
        deviceName: gwName,
        confidenceScore: gw.confidenceScore < 50 ? 50 : gw.confidenceScore,
      );
    }

    // Step 3: Keep ALL discovered devices — let the user decide
    final result = byIp.values.toList();
    for (final d in result) {
      _log(
        'Filter',
        '   ✓ Keeping ${d.ipAddress} — ${d.deviceCategory}',
        'name: ${d.deviceName}, mfr: ${d.manufacturer}, model: ${d.modelNumber}, '
            'ports: ${d.openPorts.join(",")}, via: ${d.discoveryMethod}',
      );
    }

    // Sort by confidence score (best data first)
    result.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    return result;
  }

  // DNS packet builder for mDNS
  List<int> _buildDnsQuery(String serviceName) {
    final packet = <int>[];
    packet.addAll([0x00, 0x00]); // Transaction ID
    packet.addAll([0x00, 0x00]); // Flags
    packet.addAll([0x00, 0x01]); // Questions: 1
    packet.addAll([0x00, 0x00]); // Answer RRs: 0
    packet.addAll([0x00, 0x00]); // Authority RRs: 0
    packet.addAll([0x00, 0x00]); // Additional RRs: 0
    final parts = serviceName.split('.');
    for (final part in parts) {
      packet.add(part.length);
      packet.addAll(part.codeUnits);
    }
    packet.add(0x00);
    packet.addAll([0x00, 0x0C]); // Type: PTR
    packet.addAll([0x00, 0x01]); // Class: IN
    return packet;
  }

  String _decodeDnsName(List<int> data, int offset) {
    final parts = <String>[];
    int maxJumps = 10;
    while (offset < data.length && data[offset] != 0 && maxJumps > 0) {
      if ((data[offset] & 0xC0) == 0xC0) {
        if (offset + 1 >= data.length) break;
        offset = ((data[offset] & 0x3F) << 8) | data[offset + 1];
        maxJumps--;
        continue;
      }
      final len = data[offset];
      offset++;
      if (offset + len > data.length) break;
      parts.add(
        utf8.decode(data.sublist(offset, offset + len), allowMalformed: true),
      );
      offset += len;
    }
    return parts.join('.');
  }

  String _friendlySocketError(SocketException e) {
    if (e.message.contains('Network is unreachable') ||
        e.message.contains('No such device')) {
      return 'Not connected to WiFi. Please connect and try again.';
    }
    if (e.message.contains('Permission denied')) {
      return 'Network permission denied. Please check app permissions.';
    }
    return 'Network error: ${e.message}';
  }
}

class _MdnsServiceType {
  final String type;
  final String humanCategory;
  final IconCategory defaultIcon;
  const _MdnsServiceType(this.type, this.humanCategory, this.defaultIcon);
}

/// FIX 1 + 6: Fully correlated mDNS record — one per discovered service instance.
/// Combines PTR + SRV + A + TXT records from a single mDNS response datagram.
class _MdnsFullRecord {
  /// Human-readable instance name (e.g. "John's Apple TV")
  final String instanceName;

  /// Resolved IPv4 address from the mDNS A record (null if not present).
  final String? ipAddress;

  /// SRV target hostname (e.g. "Johns-MacBook-Air.local") for DNS fallback.
  final String? hostname;

  /// Device model from TXT `md=` or `model=` key.
  final String? model;

  /// Friendly name from TXT `fn=` key.
  final String? friendlyName;

  /// OS version from TXT `osvers=` key.
  final String? osVersion;

  /// Device identifier from TXT `id=`, `deviceid=`, or `serialnumber=` key.
  final String? deviceId;

  const _MdnsFullRecord({
    required this.instanceName,
    this.ipAddress,
    this.hostname,
    this.model,
    this.friendlyName,
    this.osVersion,
    this.deviceId,
  });
}
