
# WiFi Scan Feature — End-to-End Audit & Examples

## The 6-Layer Scan Pipeline

| Layer | What It Does | Runs When |
|-------|-------------|-----------|
| **Layer 0** | ARP sweep — pings all 254 IPs, reads MAC, scans ports, calls device APIs | Parallel |
| **Layer 1** | UPnP/SSDP — multicast discovery, fetches XML descriptors | Parallel |
| **Layer 2** | mDNS/Bonjour — queries 16 service types, parses DNS records | Parallel |
| **Layer 4** | SNMP — queries 8 OIDs per device (Android only) | After merge |
| **Layer 3** | Backend enrichment — MAC vendor lookup, fingerprinting, Fingerbank API | After SNMP |
| **Layer 5** | Advanced probes — SSH/FTP/TLS/SMB banners, 30+ device APIs, HTTP fingerprinting | Last |

---

## WifiDevice Class (26 Fields)

| Field | Layer(s) | Source | Required |
|-------|---------|--------|----------|
| `ipAddress` | 0,1,2 | ARP ping / UPnP LOCATION / mDNS A record | ✅ Always |
| `macAddress` | 0 | ARP table read | ❌ Null on iOS |
| `manufacturer` | 0,1,2,3,5 | MAC OUI / UPnP / mDNS / Backend / Device APIs | |
| `deviceName` | 0,1,2,5 | Hostname / UPnP friendlyName / mDNS PTR / HTTP title | ✅ Always |
| `hostname` | 0,5 | Reverse-DNS / NetBIOS (UDP 137) / WSD (5357) | |
| `modelNumber` | 1,2,5 | UPnP modelNumber / mDNS TXT md= / Device APIs | |
| `serialNumber` | 1,5 | UPnP serialNumber / SNMP OID / Device APIs | |
| `deviceTypeRaw` | 0,1,2,5 | Service detection ('arp-scan', 'chromecast', 'roku') | ✅ Always |
| `deviceCategory` | 0,1,2,3 | Port-guessing / UPnP deviceType / Backend mapping | ✅ Always |
| `iconCategory` | 0,1,2 | Port-guessing / UPnP type / Backend mapping | ✅ Always |
| `confidenceScore` | 0,1,2,3,5 | Cumulative scoring (0–98, capped) | ✅ Always |
| `discoveryMethod` | 0,1,2,5 | 'subnet','upnp','mdns','both' — updated with '+snmp','+probe' | ✅ Always |
| `openPorts` | 0,5 | TCP sweeps + service-specific probes | ✅ (may be empty) |
| `backendData` | 3 | Response from backend `/discovery/enrich` | ❌ Optional |
| `httpBanner` | 0,5 | Server: header from port 80/443/etc. | ❌ Optional |
| `htmlTitle` | 0,5 | `<title>` from HTTP GET | ❌ Optional |
| `osHint` | 0,4,5 | ICMP TTL fingerprint / SNMP sysDescr | ❌ Optional |
| `sshBanner` | 0,5 | SSH port 22 banner grab | ❌ Optional |
| `tlsCertSubject` | 5 | TLS certificate CN (port 443/8443) | ❌ Optional |
| `firmwareVersion` | 4,5 | SNMP sysDescr / Device API responses | ❌ Optional |
| `serviceVersions` | 5 | Map\<port, version\> from SSH/FTP/Telnet/RTSP banners | ❌ Optional |
| `smbOsVersion` | 5 | SMB port 445 negotiate response | ❌ Optional |

### Computed Getters

- **`detectedOS`**: Merger of `smbOsVersion` → `osHint` → SSH banner hints → best guess
- **`labeledPorts`**: Maps port numbers to service names ("22 (SSH)", "80 (HTTP)")
- **`displayTitle`**: Smart fallback: `deviceName` → `hostname` → `manufacturer` → IP
- **`displaySubtitle`**: Rich summary like "Samsung · UN55Q70A · 192.168.1.50 · AA:BB:CC:DD:EE:FF"
- **`assetType`**: Computed business label ("TV", "Printer", "Laptop", "Refrigerator")

---

## Layer-by-Layer Data Flow

### Layer 0: Subnet ARP/ICMP Sweep (Android + iOS)

**Orchestration:**
1. Pre-seed ARP — Read kernel ARP table for cached devices
2. Dual-probe sweep — Android: ICMP ping + TCP connect | iOS: TCP only
3. Port enumeration — TCP probes to ~100 ports on all responding IPs
4. Device-specific API probes — Call manufacturer endpoints for identification
5. Late ARP read — Catch slow responders in power-saving modes
6. DNS + NetBIOS resolution — Parallel reverse-DNS + Windows computer names (UDP 137)

**Device-Specific API Probes (Layer 0 sub-layer):**

| Device | Port | Endpoint | Fields Extracted |
|--------|------|----------|------------------|
| Chromecast | 8008 | `/setup/eureka_info?options=detail` | name, model, mac_address |
| Roku | 8060 | `/query/device-info` | device-name, model, serial, wifi-mac |
| Samsung TV | 8001 | `/api/v2/` | name, modelName, wifiMac |
| Sonos | 1400 | `/xml/device_description.xml` | roomName, modelName, serialNum |
| Philips Hue | 80 | `/api/config` | name, modelid, mac (score 95) |
| HP Printer | 631/9100/9197 | `/DevMgmt/ProductConfigDyn.xml` | MakeAndModel, SerialNumber (score 90) |
| Epson Printer | 80 | `/PRESENTATION/HTML/TOP/PRTINFO.HTML` | title contains "Epson" (score 80) |
| Brother Printer | 80 | `/general/information.html` | title contains "Brother" (score 80) |
| ASUS Router | 80 | `/` | HTML title fingerprinting (score 90) |
| Netgear Router | 80 | `/` | HTML title fingerprinting (score 90) |
| TP-Link Router | 80 | `/` | HTML title fingerprinting (score 90) |
| Ubiquiti UniFi | 80 | `/` | HTML title contains "UniFi" (score 85) |
| Windows PC | 5357 | `/DeviceDescription` | WSD XML FriendlyName, Manufacturer, ModelName (score 75) |
| Linux/SSH | 22 | Banner grab | OpenSSH_X.Xp sysName (score 65) |
| Windows RPC | 135/139 | Port presence | Windows PC detection (score 55) |
| IP Camera | 554 | RTSP presence | IP Camera (score 40) |

**MAC Vendor Database:** ~250 OUI prefixes covering Samsung, LG, Sony, Google, Apple, Amazon, Sonos, Roku, HP, Canon, Epson, TP-Link, Netgear, ASUS, Linksys, Ubiquiti, Intel, Xiaomi, Huawei, Wyze, Eufy, etc.

**Port → Category Mapping:**
- **Printers:** 9197, 9100, 631, 515
- **IP Camera:** 554 (RTSP)
- **Streaming:** 8060 (Roku), 8001 (Samsung), 8008 (Chromecast), 7000 (AirPlay)
- **Smart Speaker:** 1400 (Sonos)
- **Home Assistant:** 8123
- **Windows:** 135, 139, 3389, 5357
- **Linux/Mac:** 22 (SSH), 548 (AFP), 3689 (DAAP)
- **NAS:** 5001, 2049, 445 (SMB/CIFS)
- **Network:** 21 (FTP), 23 (Telnet), 25 (SMTP), 53 (DNS), 80/443 (HTTP), 1883 (MQTT)
- **Database Server:** 3306, 5432, 6379, 9200, 27017
- **MikroTik Router:** 8291
- **Plex:** 32400
- **Jellyfin:** 8096
- **VNC/Computer:** 5900
- **VoIP Phone:** 5060
- **IoT Hub/MQTT:** 1883

---

### Layer 1: UPnP/SSDP Discovery

**Orchestration:**
1. Bind UDP socket to port 1900
2. Send M-SEARCH packet 3× to broadcast 239.255.255.250:1900
3. Collect SSDP responses for 5 seconds
4. Extract LOCATION URLs from each response
5. HTTP GET each LOCATION URL (UPnP device descriptor XML)
6. Parse XML for device metadata
7. Skip virtual WAN adapters (internetgatewaydevice, wandevice, wanconnectiondevice)

**Fields Populated:**
- `ipAddress` ← Extracted from LOCATION URL hostname
- `manufacturer` ← UPnP `<manufacturer>` field
- `deviceName` ← UPnP `<friendlyName>` field
- `modelNumber` ← UPnP `<modelNumber>` field
- `serialNumber` ← UPnP `<serialNumber>` field
- `deviceTypeRaw` ← UPnP `<deviceType>`
- `deviceCategory` ← Mapped from deviceType
- `confidenceScore` ← 50–95 depending on data completeness
- `discoveryMethod` ← `'upnp'`

---

### Layer 2: mDNS/Bonjour Discovery

**DNS-SD Service Types (16 configured):**
- `_airplay._tcp` → Apple Device / TV
- `_googlecast._tcp` → Chromecast / Google TV
- `_sonos._tcp` → Sonos Speaker
- `_spotify-connect._tcp` → Spotify Device
- `_raop._tcp` → AirPlay Audio
- `_ipp._tcp`, `_printer._tcp` → Network Printer
- `_hap._tcp` → HomeKit Device
- `_hue._tcp` → Philips Hue
- `_smartenergy._tcp` → Smart Energy Device
- `_http._tcp` → Web Device
- `_smb._tcp` → Network Storage (Samba/NAS)
- `_daap._tcp` → iTunes Library (Mac)
- `_afpovertcp._tcp` → Mac / NAS (AFP)
- `_workstation._tcp` → Linux / Avahi
- `_companion-link._tcp` → Apple Continuity
- `_matter._tcp` → Matter Smart Home

**Data Extraction:**
1. **PTR Records** → Instance names ("Living Room Chromecast")
2. **A Records** → IPv4 addresses
3. **SRV Records** → Hostname mapping
4. **TXT Records** → Key-value metadata: `fn=` (name), `md=` (model), `osvers=`, `serialnumber=`

---

### Layer 4: SNMP Scan (Android Only)

**Custom Kotlin SNMPv2c Implementation** (Pure BER encoding/decoding, no external library)

**OIDs Queried:**
1. `1.3.6.1.2.1.1.1.0` → **sysDescr**
2. `1.3.6.1.2.1.1.5.0` → **sysName**
3. `1.3.6.1.2.1.1.4.0` → **sysContact**
4. `1.3.6.1.2.1.1.6.0` → **sysLocation**
5. `1.3.6.1.2.1.25.3.2.1.3.1` → **HOST-RESOURCES** device description
6. `1.3.6.1.2.1.43.5.1.1.16.1` → **Printer name** (Printer-MIB)
7. `1.3.6.1.2.1.43.5.1.1.17.1` → **Printer serial** (Printer-MIB)
8. `1.3.6.1.2.1.2.2.1.2.1` → **First interface description** (IF-MIB)

**Fields Populated:**
- `hostname` ← sysName OID
- `manufacturerHint` ← Extracted from sysDescr
- `modelNumber` ← Parsed from sysDescr
- `serialNumber` ← Printer-specific OIDs
- `firmwareVersion` ← Parsed from sysDescr
- `osHint` ← "Windows", "Linux", "Cisco OS", etc.
- `discoveryMethod` ← Appended with `'+snmp'`

**Persistence:** Results stored in `NetworkDevice.metadata` for future scans to reuse (SNMP cache)

---

### Layer 3: Backend Enrichment (POST /api/v1/discovery/enrich)

**Processing (6 Steps):**

1. **MAC Address Vendor Lookup** — ~200 vendor prefixes
2. **Manufacturer Name Cleanup** — Remove legal suffixes ("Electronics Co., Ltd" → clean name)
3. **Device Type / Category Mapping** — Refine broad categories to specific
4. **HTTP Banner Fingerprinting** — 20+ Server: header keywords + 20+ HTML `<title>` keywords
5. **Fingerbank Cloud API** — If confidence < 84 AND macAddress AND openPorts present
6. **SNMP Cache Merge** — Lookup stored records from previous scans

**Confidence Scoring Formula:**

```
base = 20

+10 macAddress present
+15 manufacturer known (not "Unknown")
+10 hostname resolved
+15 modelNumber present
+10 serialNumber present
+ 5 mDNS friendlyName present
+ 5 openPorts present
+ 5 httpBanner captured
+ 3 htmlTitle captured
+ 5 sshBanner present
+ 5 tlsCertSubject present
+ 5 smbOsVersion present
+ 3 firmwareVersion present
+ 3 serviceVersions (multiple)
+10 discoveryMethod is 'upnp'
+ 5 discoveryMethod is 'mdns'
+10 discoveryMethod is 'snmp'
+10 Fingerbank score > 80

-10 manufacturer is 'Unknown'

Final: clamp(0, 100)
```

---

### Layer 5: Advanced Probes

**30+ Device-Specific API Probes:**

| Device | Port | Endpoint |
|--------|------|----------|
| Home Assistant | 8123 | `/api/` |
| Tasmota | 80 | `/cm?cmnd=Status%200` |
| Shelly Gen1 | 80 | `/shelly` |
| Shelly Gen2 | 80 | `/rpc/Shelly.GetDeviceInfo` |
| Synology NAS | 5000/5001 | `/` |
| QNAP NAS | 8080 | `/` |
| Plex Media | 32400 | `/identity` |
| Jellyfin | 8096 | `/System/Info/Public` |
| TP-Link Kasa | 80 | `/api/v1/device/info` |
| Tuya/SmartLife | 80 | `/gw.json` |
| Ubiquiti UniFi | 80/443 | `/api/self` |
| Reolink Camera | 80 | `/api.cgi?cmd=GetDevInfo` |
| D-Link HNAP | 80 | `/HNAP1/` |
| Generic | 80 | `/info`, `/status.json`, `/device/properties` |

**Service Banner Grabs:**

| Service | Port | Data Extracted | Example |
|---------|------|----------------|---------|
| SSH | 22 | Banner string | "SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.6" |
| FTP | 21 | Banner string | "220 ProFTPD Server ..." |
| Telnet | 23 | Banner string | "Connected ... login: " |
| RTSP | 554 | OPTIONS response | "Server: ..." header |
| TLS | 443/8443 | Certificate Subject CN | "CN=HP LaserJet M404n" |
| SMB | 445 | Negotiate response | OS version, domain, computer name |

**Multi-Factor Confidence Boost (10 signals):**

```
+5  MAC vendor matches manufacturer name (dual confirmation)
+5  SNMP data present
+4  TLS certificate confirmed device
+3  SSH banner contributed
+4  SMB OS version detected
+3  model number known
+3  serial number known
+2  firmware version extracted
+3  multiple service versions present
+3  mDNS + another discovery source agree

Capped at 98 (leaves room for human verification)
```

---

## Data Flow Diagram

```
START: User taps "WiFi Scan"
  ↓
[Check Permissions] → Location permission required
  ↓
[Get Network Info] → SSID, Local IP, Gateway IP
  ↓
[Acquire MulticastLock] → Android only
  ↓
┌──────────────────────────────────────────────┐
│  PARALLEL: Layer 0 + Layer 1 + Layer 2       │
│  ARP Sweep   UPnP/SSDP     mDNS/Bonjour     │
└──────────────────────────────────────────────┘
  ↓
[MERGE + FILTER + RANK] → Deduplicate by IP
  ↓
[Layer 4: SNMP Scan] → Android background
  ↓
[Layer 3: Backend Enrichment] → POST /discovery/enrich
  ├─ MAC vendor lookup
  ├─ Manufacturer cleanup
  ├─ Device type mapping
  ├─ HTTP banner fingerprinting
  ├─ Fingerbank API (if confidence < 84)
  ├─ SNMP cache merge
  └─ Auto-save to NetworkDevice table
  ↓
[Layer 5: Advanced Probes] → 30+ device APIs + banners
  ├─ SSH, FTP, Telnet, RTSP, TLS, SMB banner grabs
  ├─ HTTP banner fingerprinting (all HTTP ports)
  ├─ Multi-factor confidence boost
  └─ Final ranking
  ↓
[Register Scan] → POST /discovery/register-scan
  ↓
[UI: Display Device List] → _DeviceCard with all fields
  ↓
[User Taps Device] → _ConfirmDeviceDialog shows full details
  ↓
[User Confirms] → onDeviceSelected fills AssetFormModel
  ↓
[Form Submission] → Asset created with WiFi data pre-filled
```

---

## UI: What Gets Displayed

### Device Card (Scan Results List)

```
┌───────────────────────────────────────────────┐
│ [Icon]  assetType                      95% 🟢 │
│         displayTitle                          │
├───────────────────────────────────────────────┤
│ Brand:      manufacturer                      │
│ Hostname:   hostname                          │
│ IP Address: ipAddress                         │
│ MAC:        macAddress                        │
│ Model:      modelNumber                       │
│ Serial:     serialNumber                      │
│ OS:         detectedOS                        │
│ Firmware:   firmwareVersion                   │
│ Services:   labeledPorts (top 6)              │
│                                               │
│ via [discoveryMethod]                         │
└───────────────────────────────────────────────┘
```

### Confirm Dialog (When Device Tapped)

```
┌───────────────────────────────────────────────┐
│           [Device Icon]                       │
│        displayTitle                           │
│     [Category]  [Confidence %]                │
│                                               │
│  ── Identification ──                         │
│  Device / Brand / Model / Serial / Category   │
│                                               │
│  ── Network ──                                │
│  Hostname / IP / MAC / Open Ports             │
│                                               │
│  ── System Details ──                         │
│  OS / Firmware / SSH / TLS Cert / SMB OS /    │
│  Service Versions                             │
│                                               │
│  ── Detection Evidence ──                     │
│  Server Header / HTML Page Title              │
│                                               │
│  📶 Discovered on your WiFi network           │
│                                               │
│     [Cancel]        [Use This Device]         │
└───────────────────────────────────────────────┘
```

### Confidence Badge Colors

- 🟢 **Green** — ≥ 75% (high confidence)
- 🟡 **Orange** — ≥ 50% (medium confidence)
- 🔴 **Red** — < 50% (low confidence)

---

## Form Fields Saved (AssetFormModel)

| Field | Source |
|-------|--------|
| `brand` | device.manufacturer |
| `model` | device.modelNumber |
| `serial` | device.serialNumber |
| `manufacturer` | device.manufacturer |
| `productTitle` | device.displayTitle |
| `productCategory` | device.deviceCategory |
| `enrichmentSource` | `'wifi_discovery'` |
| `isWifiDiscovered` | `true` |
| `wifiDeviceIp` | device.ipAddress |
| `wifiDeviceName` | device.displayTitle |
| `wifiDeviceMac` | device.macAddress |
| `wifiHostname` | device.hostname |
| `wifiOpenPorts` | device.openPorts |
| `wifiFirmware` | device.firmwareVersion |
| `wifiOsHint` | device.detectedOS |
| `wifiSshBanner` | device.sshBanner |
| `wifiTlsCert` | device.tlsCertSubject |
| `wifiSmbOs` | device.smbOsVersion |
| `wifiConfidence` | device.confidenceScore |
| `wifiDiscoveryMethod` | device.discoveryMethod |

---

## Backend Persistence (NetworkDevice.metadata)

```json
{
  "category": "Smart TV",
  "model": "UN55Q70A",
  "serial": "SERIAL123",
  "confidence": 95,
  "discoveryMethod": "arp+upnp+mdns",
  "httpBanner": "WebServer/2.0",
  "htmlTitle": "Samsung Smart TV",
  "osHint": "Linux",
  "sshBanner": "SSH-2.0-OpenSSH_8.9p1",
  "tlsCertSubject": "CN=Samsung Smart TV UN55Q70A",
  "smbOsVersion": null,
  "serviceVersions": { "22": "SSH-2.0-OpenSSH_8.9p1" },
  "firmwareVersion": "T-KTSU2DEUC-1301.5"
}
```

---

## Concrete Examples

### Example 1: Samsung Smart TV

```
Layer 0: IP 192.168.1.105, MAC B4:F2:E8:3A:7C:01 → "Samsung" (OUI)
         Ports: [8001, 9197, 443, 8443], OS Hint: Linux (TTL 64)
         Samsung TV API (port 8001) → name="Living Room TV", model="UN55Q70A"

Layer 1: UPnP friendlyName="Samsung Smart TV", manufacturer="Samsung Electronics",
         model="UN55Q70A", deviceType="urn:samsung-com:device:SmartTV:1"

Layer 2: mDNS _googlecast._tcp, TXT fn="Living Room TV"

Layer 4: SNMP — No response (TV doesn't run SNMP)

Layer 3: Manufacturer cleaned → "Samsung", Category → "Smart TV", Confidence → 88

Layer 5: TLS cert CN=Samsung Smart TV UN55Q70A
         HTTP banner: Server: WebServer/2.0
         Multi-factor boost: +5 (MAC confirms) +4 (TLS) +3 (model) → Confidence 95

FINAL CARD:
  Smart TV — Living Room TV — 95% 🟢
  Brand: Samsung | Model: UN55Q70A | IP: 192.168.1.105
  MAC: B4:F2:E8:3A:7C:01 | OS: Linux | TLS: CN=Samsung Smart TV UN55Q70A
  Ports: 443 (HTTPS), 8001 (Samsung TV), 8443 (HTTPS-Alt)
  via arp+upnp+mdns
```

### Example 2: HP LaserJet Printer

```
Layer 0: IP 192.168.1.42, MAC 3C:2A:F4:11:22:33 → "HP" (OUI)
         Ports: [22, 80, 443, 515, 631, 9100, 9197]
         HP Printer API → MakeAndModel="HP LaserJet M404n", Serial="CNFGH12345"

Layer 1: UPnP friendlyName="HP LaserJet M404n", manufacturer="HP"

Layer 4: SNMP sysDescr="HP LaserJet M404n", Printer-MIB serial="CNFGH12345"

Layer 3: Category → "Printer", Confidence → 90

Layer 5: SSH banner: SSH-2.0-HP_JetDirect
         FTP banner: 220 HP FTP Print Server
         TLS cert: CN=HP LaserJet M404n
         Multi-factor boost: +5 (MAC) +5 (SNMP) +4 (TLS) +3 (SSH) +3 (model) +3 (serial) → 92

FINAL CARD:
  Printer — HP LaserJet M404n — 92% 🟢
  Brand: HP | Model: HP LaserJet M404n | Serial: CNFGH12345
  IP: 192.168.1.42 | MAC: 3C:2A:F4:11:22:33
  Firmware: 2516057_000045
  SSH: SSH-2.0-HP_JetDirect | TLS: CN=HP LaserJet M404n
  Services: 22 (SSH), 80 (HTTP), 443 (HTTPS), 515 (LPD), 631 (IPP), 9100 (RAW Print)
  via arp+upnp+snmp
```

### Example 3: Synology NAS

```
Layer 0: IP 192.168.1.10, MAC 00:11:32:AA:BB:CC → "Synology" (OUI)
         Ports: [22, 80, 443, 445, 5000, 5001]

Layer 1: UPnP — No response

Layer 2: mDNS _smb._tcp, _afpovertcp._tcp, _http._tcp
         hostname="synology-nas"

Layer 4: SNMP sysDescr="Linux synology 4.4.180+ DS920+", sysName="synology-nas"

Layer 3: Manufacturer → "Synology", Category → "NAS / Storage", Confidence → 82

Layer 5: SSH: SSH-2.0-OpenSSH_8.2p1
         SMB: Samba 4.15.13
         TLS cert: CN=synology-nas.local
         HTTP title: "DiskStation" → confirms Synology
         Multi-factor boost: +5 (MAC) +5 (SNMP) +4 (TLS) +3 (SSH) +4 (SMB) +3 (model) → 89

FINAL CARD:
  NAS / Storage — synology-nas — 89% 🟢
  Brand: Synology | Model: DS920+ | Hostname: synology-nas
  IP: 192.168.1.10 | MAC: 00:11:32:AA:BB:CC
  OS: Samba 4.15.13 | SSH: SSH-2.0-OpenSSH_8.2p1
  SMB OS: Samba 4.15.13 | TLS: CN=synology-nas.local
  Services: 22 (SSH), 80 (HTTP), 443 (HTTPS), 445 (SMB), 5000 (Synology), 5001 (Synology SSL)
  via arp+mdns+snmp
```

### Example 4: Unknown IoT Device (Low Confidence)

```
Layer 0: IP 192.168.1.200, MAC DC:4F:22:XX:XX:XX → "Espressif" (OUI)
         Ports: [80]

Layer 1: No UPnP response
Layer 2: No mDNS response
Layer 4: No SNMP response

Layer 3: Manufacturer → "Espressif" (ESP32/ESP8266 chip maker)
         Category → "IoT Device", Confidence → 40

Layer 5: HTTP banner: Server: esp-idf httpd
         HTML title: "Tasmota" → mapped to Smart Plug
         Tasmota API /cm?cmnd=Status → DeviceName="Kitchen Plug", Module="ESP8266"
         Multi-factor boost: +5 (MAC confirms Espressif) → 48

FINAL CARD:
  Smart Plug — Kitchen Plug — 48% 🔴
  Brand: Espressif | IP: 192.168.1.200
  MAC: DC:4F:22:XX:XX:XX
  Services: 80 (HTTP)
  Server: esp-idf httpd | Title: Tasmota
  via arp
```

---

## Data Loss Summary

**NO DATA IS LOST** — Every field is cumulative across all 6 layers:

- ✅ Layer 0 (ARP): openPorts, MAC, osHint preserved through all layers
- ✅ Layer 1 (UPnP): Model, Serial, Manufacturer preserved and merged
- ✅ Layer 2 (mDNS): Hostname, friendly name merged with other layers
- ✅ Layer 4 (SNMP): Cached in DB for future scan reuse
- ✅ Layer 3 (Backend): Non-destructive cleanup, only improves fields
- ✅ Layer 5 (Advanced): SSH, TLS, SMB banners accumulated, confidence only increases
- ✅ UI: Shows all non-null fields in device card and confirm dialog
- ✅ Form: Saves 20 WiFi fields to AssetFormModel
- ✅ Backend DB: All metadata persisted in NetworkDevice table

**Merge Strategy:** Prefer layer with higher discovery priority + data completeness. All independent signals (httpBanner, sshBanner, tlsCert, etc.) are preserved independently — never overwritten.

---

## Platform Limitations

| Feature | Android | iOS |
|---------|---------|-----|
| ARP table read | ✅ | ❌ (no /proc/net/arp) |
| ICMP ping | ✅ | ❌ (TCP-only) |
| NetBIOS (UDP 137) | ✅ | ❌ (blocked) |
| SNMP (UDP 161) | ✅ | ❌ (blocked) |
| MulticastLock | ✅ Required | N/A |
| UPnP/SSDP | ✅ | ✅ |
| mDNS/Bonjour | ✅ | ✅ |
| TCP port scanning | ✅ | ✅ |
| SSH/FTP/TLS/SMB banners | ✅ | ✅ |
| Device-specific APIs | ✅ | ✅ |
