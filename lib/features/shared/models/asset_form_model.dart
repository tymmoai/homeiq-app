import '../../../services/wifi_discovery_service.dart';

class AssetFormModel {
  // Step 1: Type Selection
  String? selectedCategory; // "Appliances", "Home Systems", "Electronics"
  String? selectedAssetType; // "Refrigerator", "Water Heater", etc.

  // Step 2: Identify
  String? identificationMethod; // "photo" or "manual"
  String? photoPath; // Image URL (from barcode API) or local file path
  String? brand;
  String?
  subCategory; // Sub-category (e.g., "Top Freezer", "Bottom Freezer", etc.)
  String? model;
  String? serial; // Barcode number or serial number

  // Scanned product data (populated by barcode scanning + ChatGPT enrichment)
  String? productTitle; // Full product title from API
  String? productDescription; // Product description from API
  String?
  productCategory; // Product category from API (e.g., "Electronics > TVs")
  String? manufacturer; // Manufacturer name from API
  String? manufacturedYear; // 4-digit manufacture year from label (e.g. "2021")
  String? madeIn; // Country of manufacture from label (e.g. "Korea")
  String? barcode; // Raw barcode/UPC/EAN number
  String? productImageUrl; // Product image URL from API
  String?
  productImageSource; // Image fetch status: 'serpapi' | 'quota_exceeded' | 'auth_error' | 'no_results' | 'timeout' | 'network_error'

  // ChatGPT enriched data
  String? productColor; // Color/finish from model number
  Map<String, String>? productSpecs; // Key specs (Capacity, Dimensions, etc.)
  Map<String, String>?
  warrantyDetails; // Warranty info (type, duration, coverage, url)
  String? supportUrl; // Manufacturer support page URL
  String? manualUrl; // Product manual/documentation URL
  String?
  enrichmentSource; // "barcode_api", "chatgpt", "merged" — tracks data source

  // Step 3: Details
  String? location; // "Kitchen", "Bedroom", "Living Room", "Other"
  String? purchaseYear;
  String? purchaseMonth; // 1-12 as string

  // Step 4: Documents
  List<String> documentPaths = []; // List of document file paths
  List<String> documentTypes =
      []; // Parallel list: type per doc (warranty, receipt, manual, photo, other)

  // WiFi Discovery metadata
  bool isWifiDiscovered = false; // true if asset was found via WiFi scan
  String? wifiDeviceIp; // IP address of the discovered device
  String? wifiDeviceName; // Friendly device name from WiFi scan
  String? wifiDeviceMac; // MAC address if available
  String? wifiHostname; // reverse-DNS / mDNS hostname
  List<int>? wifiOpenPorts; // Open TCP ports found during scan
  String? wifiFirmware; // Firmware version string
  String? wifiOsHint; // Detected OS (TTL, SMB, SSH)
  String? wifiSshBanner; // SSH identification string
  String? wifiTlsCert; // TLS certificate subject CN
  String? wifiSmbOs; // SMB negotiate OS version
  int? wifiConfidence; // Confidence score 0-100
  String? wifiDiscoveryMethod; // e.g. 'arp+mdns+snmp'
  String? wifiHttpBanner; // HTTP Server header
  String? wifiHtmlTitle; // HTML <title> from HTTP probe

  // Cached WiFi scan results — survives step navigation, cleared on flow exit
  List<WifiDevice> cachedWifiDevices = [];

  // Step 5: Success
  String? assetId; // Generated after successful creation

  // Validation methods
  bool isStep1Valid() {
    return selectedCategory != null && selectedAssetType != null;
  }

  bool isStep2Valid() {
    if (identificationMethod == 'photo') {
      // Scan mode: need both brand and model for identification
      return (brand != null && brand!.isNotEmpty) &&
          (model != null && model!.isNotEmpty);
    } else if (identificationMethod == 'manual') {
      return brand != null &&
          brand!.isNotEmpty &&
          model != null &&
          model!.isNotEmpty;
    } else if (identificationMethod == 'wifi') {
      // WiFi scan: need at least brand and model
      return brand != null &&
          brand!.isNotEmpty &&
          model != null &&
          model!.isNotEmpty;
    }
    return false;
  }

  bool isStep3Valid() {
    return location != null && location!.isNotEmpty;
  }

  bool isStep4Valid() {
    // Documents are optional, so always valid
    return true;
  }

  // Get asset name for display
  String getAssetName() {
    if (selectedAssetType != null && brand != null) {
      return '$brand $selectedAssetType';
    }
    return selectedAssetType ?? 'Asset';
  }

  // Reset form
  void reset() {
    selectedCategory = null;
    selectedAssetType = null;
    identificationMethod = null;
    photoPath = null;
    brand = null;
    subCategory = null;
    model = null;
    serial = null;
    productTitle = null;
    productDescription = null;
    productCategory = null;
    manufacturer = null;
    manufacturedYear = null;
    madeIn = null;
    barcode = null;
    productImageUrl = null;
    productImageSource = null;
    productColor = null;
    productSpecs = null;
    warrantyDetails = null;
    supportUrl = null;
    manualUrl = null;
    enrichmentSource = null;
    isWifiDiscovered = false;
    wifiDeviceIp = null;
    wifiDeviceName = null;
    wifiDeviceMac = null;
    wifiHostname = null;
    wifiOpenPorts = null;
    wifiFirmware = null;
    wifiOsHint = null;
    wifiSshBanner = null;
    wifiTlsCert = null;
    wifiSmbOs = null;
    wifiConfidence = null;
    wifiDiscoveryMethod = null;
    wifiHttpBanner = null;
    wifiHtmlTitle = null;
    cachedWifiDevices = [];
    location = null;
    purchaseYear = null;
    purchaseMonth = null;
    documentPaths.clear();
    documentTypes.clear();
    assetId = null;
  }

  // Convert to map for API submission
  Map<String, dynamic> toJson() {
    return {
      'category': selectedCategory,
      'type': selectedAssetType,
      'brand': brand,
      'subCategory': subCategory,
      'model': model,
      'serial': serial,
      'productTitle': productTitle,
      'productDescription': productDescription,
      'productCategory': productCategory,
      'manufacturer': manufacturer,
      'manufacturedYear': manufacturedYear,
      'madeIn': madeIn,
      'barcode': barcode,
      'productImageUrl': productImageUrl,
      'productColor': productColor,
      'productSpecs': productSpecs,
      'warrantyDetails': warrantyDetails,
      'supportUrl': supportUrl,
      'manualUrl': manualUrl,
      'enrichmentSource': enrichmentSource,
      'isWifiDiscovered': isWifiDiscovered,
      'wifiDeviceIp': wifiDeviceIp,
      'wifiDeviceName': wifiDeviceName,
      'wifiDeviceMac': wifiDeviceMac,
      'wifiHostname': wifiHostname,
      'wifiOpenPorts': wifiOpenPorts,
      'wifiFirmware': wifiFirmware,
      'wifiOsHint': wifiOsHint,
      'wifiSshBanner': wifiSshBanner,
      'wifiTlsCert': wifiTlsCert,
      'wifiSmbOs': wifiSmbOs,
      'wifiConfidence': wifiConfidence,
      'wifiDiscoveryMethod': wifiDiscoveryMethod,
      'wifiHttpBanner': wifiHttpBanner,
      'wifiHtmlTitle': wifiHtmlTitle,
      'location': location,
      'purchaseYear': purchaseYear,
      'purchaseMonth': purchaseMonth,
      'photoPath': photoPath,
      'documentPaths': documentPaths,
      'documentTypes': documentTypes,
    };
  }
}
