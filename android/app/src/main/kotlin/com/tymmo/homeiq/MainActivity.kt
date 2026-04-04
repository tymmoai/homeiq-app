package com.tymmo.homeiq

import android.content.Context
import android.net.ConnectivityManager
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.Inet4Address
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.tymmo.homeiq/wifi"
    private var multicastLock: WifiManager.MulticastLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "acquireMulticastLock" -> {
                    try {
                        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                        multicastLock = wifiManager.createMulticastLock("homeiq_discovery")
                        multicastLock?.setReferenceCounted(true)
                        multicastLock?.acquire()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LOCK_ERROR", e.message, null)
                    }
                }
                "releaseMulticastLock" -> {
                    try {
                        if (multicastLock?.isHeld == true) {
                            multicastLock?.release()
                        }
                        multicastLock = null
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LOCK_ERROR", e.message, null)
                    }
                }
                "getWifiInfo" -> {
                    try {
                        // Modern approach: use ConnectivityManager (works on Android 12+)
                        // Fallback: use deprecated WifiManager.dhcpInfo for older Android
                        val connectivityManager = applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager

                        var ipStr = "0.0.0.0"
                        var gwStr = "0.0.0.0"
                        var prefix = 24

                        // Try modern API first (Android M+ / API 23+)
                        val activeNetwork = connectivityManager.activeNetwork
                        val linkProps = if (activeNetwork != null) connectivityManager.getLinkProperties(activeNetwork) else null

                        if (linkProps != null) {
                            // Get IP from LinkProperties
                            val v4Addr = linkProps.linkAddresses.firstOrNull { la ->
                                la.address is Inet4Address && !la.address.isLoopbackAddress
                            }
                            if (v4Addr != null) {
                                ipStr = v4Addr.address.hostAddress ?: "0.0.0.0"
                                prefix = v4Addr.prefixLength
                            }

                            // Get gateway from routes
                            val defaultRoute = linkProps.routes.firstOrNull { route ->
                                route.isDefaultRoute && route.gateway is Inet4Address
                            }
                            if (defaultRoute?.gateway != null) {
                                gwStr = defaultRoute.gateway!!.hostAddress ?: "0.0.0.0"
                            }
                        }

                        // Fallback: if modern API returned 0.0.0.0, try legacy WifiManager
                        if (ipStr == "0.0.0.0") {
                            try {
                                @Suppress("DEPRECATION")
                                val dhcpInfo = wifiManager.dhcpInfo
                                if (dhcpInfo != null) {
                                    val ip = dhcpInfo.ipAddress
                                    val gateway = dhcpInfo.gateway
                                    val netmask = dhcpInfo.netmask

                                    val legacyIp = "${ip and 0xFF}.${ip shr 8 and 0xFF}.${ip shr 16 and 0xFF}.${ip shr 24 and 0xFF}"
                                    if (legacyIp != "0.0.0.0") {
                                        ipStr = legacyIp
                                        gwStr = "${gateway and 0xFF}.${gateway shr 8 and 0xFF}.${gateway shr 16 and 0xFF}.${gateway shr 24 and 0xFF}"
                                        // Calculate prefix from netmask
                                        var p = 0
                                        var m = netmask
                                        while (m != 0) {
                                            p += m and 1
                                            m = m ushr 1
                                        }
                                        if (p > 0) prefix = p
                                    }
                                }
                            } catch (_: Exception) {}
                        }

                        // Get SSID — requires location permission on Android 8+
                        var ssid = "Unknown"
                        try {
                            @Suppress("DEPRECATION")
                            val wifiInfo = wifiManager.connectionInfo
                            val rawSsid = wifiInfo?.ssid?.replace("\"", "") ?: ""
                            if (rawSsid.isNotEmpty() && rawSsid != "<unknown ssid>") {
                                ssid = rawSsid
                            }
                        } catch (_: Exception) {}

                        result.success(mapOf(
                            "ip" to ipStr,
                            "gateway" to gwStr,
                            "prefix" to prefix,
                            "ssid" to ssid,
                            "bssid" to ""
                        ))
                    } catch (e: Exception) {
                        result.error("WIFI_ERROR", e.message, null)
                    }
                }
                "getArpTable" -> {
                    // Read ARP table via /proc/net/arp AND `ip neigh` — always merge both
                    // Returns Map<String(ip), String(mac)>
                    Thread {
                        try {
                            val arpMap = mutableMapOf<String, String>()

                            // Method 1: Read /proc/net/arp (works on most Android devices)
                            try {
                                val file = java.io.File("/proc/net/arp")
                                if (file.exists()) {
                                    file.readLines().drop(1).forEach { line ->
                                        val parts = line.trim().split(Regex("\\s+"))
                                        if (parts.size >= 4) {
                                            val ip = parts[0]
                                            val mac = parts[3].uppercase()
                                            if (mac != "00:00:00:00:00:00" && mac.contains(":")) {
                                                arpMap[ip] = mac
                                            }
                                        }
                                    }
                                }
                            } catch (_: Exception) {}

                            // Method 2: `ip neigh` command (Android 10+ — always run, merge with above)
                            // STALE = device was reachable recently, still useful. Only skip FAILED.
                            try {
                                val process = Runtime.getRuntime().exec("ip neigh")
                                val reader = BufferedReader(InputStreamReader(process.inputStream))
                                reader.forEachLine { line ->
                                    // Format: "192.168.1.1 dev wlan0 lladdr AA:BB:CC:DD:EE:FF REACHABLE"
                                    // States: REACHABLE, STALE, DELAY, PROBE, PERMANENT — all valid
                                    val parts = line.trim().split(Regex("\\s+"))
                                    val llIdx = parts.indexOf("lladdr")
                                    if (llIdx != -1 && llIdx + 1 < parts.size) {
                                        val ip = parts[0]
                                        val mac = parts[llIdx + 1].uppercase()
                                        val state = parts.lastOrNull() ?: ""
                                        // Include REACHABLE, STALE, DELAY, PROBE, PERMANENT — skip only FAILED/INCOMPLETE
                                        if (mac != "00:00:00:00:00:00" && mac.contains(":") &&
                                            state != "FAILED" && state != "INCOMPLETE") {
                                            arpMap[ip] = mac  // ip neigh preferred over /proc/net/arp
                                        }
                                    }
                                }
                                reader.close()
                                process.waitFor(2, java.util.concurrent.TimeUnit.SECONDS)
                                process.destroyForcibly()
                            } catch (_: Exception) {}

                            runOnUiThread { result.success(arpMap) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("ARP_ERROR", e.message, null) }
                        }
                    }.start()
                }
                "resolveHostnames" -> {
                    // Reverse-DNS lookup for a list of IPs
                    // Returns Map<String(ip), String(hostname)>
                    val ips = call.argument<List<String>>("ips") ?: emptyList()
                    Thread {
                        try {
                            val hostMap = mutableMapOf<String, String>()
                            for (ip in ips) {
                                try {
                                    val addr = InetAddress.getByName(ip)
                                    val hostname = addr.canonicalHostName
                                    // Only record if hostname differs from IP
                                    if (hostname != ip && hostname.isNotEmpty()) {
                                        hostMap[ip] = hostname
                                    }
                                } catch (_: Exception) {}
                            }
                            runOnUiThread { result.success(hostMap) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("DNS_ERROR", e.message, null) }
                        }
                    }.start()
                }
                "pingSweep" -> {
                    // MULTI-PORT DUAL-PROBE sweep: ICMP ping + TCP connect to multiple ports.
                    //
                    // Why multi-port TCP?
                    //  - Windows Firewall DROPS (no RST) port 80 by default, so a single
                    //    TCP probe to port 80 just times out and the laptop is missed.
                    //  - But Windows always has port 135 (RPC) and often 139/445 (SMB)
                    //    open to LOCAL network connections even with firewall ON.
                    //  - Linux/Mac usually have port 22 (SSH) open.
                    //  - Any ONE port responding (connect OR RST) = device is alive.
                    //    All attempts force an ARP exchange, so MAC goes into the table.
                    val subnet = call.argument<String>("subnet") ?: ""
                    if (subnet.isEmpty()) {
                        result.error("INVALID_ARGS", "subnet is required", null)
                        return@setMethodCallHandler
                    }
                    Thread {
                        try {
                            val liveSet = ConcurrentHashMap<String, Boolean>()
                            val ttlMap  = ConcurrentHashMap<String, Int>() // FIX 5: TTL for OS detection
                            // 254 IPs × (1 ICMP + 5 TCP) = 1524 tasks; pool of 200
                            val executor = Executors.newFixedThreadPool(220)
                            val latch = CountDownLatch(254 * 10) // 1 ICMP + 9 TCP = 10 probes per IP

                            // Ports to try TCP connect on per IP:
                            //   80   = HTTP (smart devices, routers, cameras)
                            //   22   = SSH  (Linux, Mac)
                            //   135  = Windows RPC — almost always open on Windows LAN
                            //   139  = NetBIOS Session (older Windows/Samba)
                            //   445  = SMB — Windows file sharing, open on LAN
                            //   443  = HTTPS (routers, NAS, cameras)
                            // Port strategy:
                            //  80   = HTTP (routers, smart devices)
                            //  22   = SSH (Linux / Mac)
                            //  135  = Windows RPC — open on Windows even with firewall
                            //  139  = NetBIOS Session (Windows / Samba)
                            //  445  = SMB (Windows file sharing)
                            //  443  = HTTPS (routers, NAS)
                            //  62078= iOS lockdown service — iPhone almost always replies with RST here
                            //  5000 = UPnP / various smart devices
                            //  8080 = HTTP alt
                            val probePorts = intArrayOf(80, 22, 135, 139, 445, 443, 62078, 5000, 8080)

                            for (i in 1..254) {
                                val ip = "$subnet.$i"

                                // ── Probe A: Real ICMP ping (no -q so we can capture TTL) ──
                                executor.submit {
                                    try {
                                        val proc = Runtime.getRuntime().exec(
                                            arrayOf("/system/bin/ping", "-c", "1", "-W", "1", ip)
                                        )
                                        val output = proc.inputStream.bufferedReader().readText()
                                        val exited = proc.waitFor(1500, TimeUnit.MILLISECONDS)
                                        if (exited && proc.exitValue() == 0) {
                                            liveSet[ip] = true
                                            // Parse TTL from ping output, e.g. "ttl=64"
                                            val ttlMatch = Regex("ttl=(\\d+)", RegexOption.IGNORE_CASE).find(output)
                                            ttlMatch?.groupValues?.get(1)?.toIntOrNull()?.let { ttlMap[ip] = it }
                                        }
                                        proc.destroyForcibly()
                                    } catch (_: Exception) {}
                                    finally { latch.countDown() }
                                }

                                // ── Probes B-G: TCP connect to multiple ports ───────────
                                for (port in probePorts) {
                                    executor.submit {
                                        try {
                                            val sock = Socket()
                                            sock.connect(InetSocketAddress(ip, port), 700)
                                            liveSet[ip] = true
                                            try { sock.close() } catch (_: Exception) {}
                                        } catch (e: java.net.ConnectException) {
                                            // RST = device IS up (port just closed)
                                            liveSet[ip] = true
                                        } catch (_: Exception) {
                                            // Timeout/no route = nothing at this IP
                                        } finally { latch.countDown() }
                                    }
                                }
                            }

                            latch.await(25, TimeUnit.SECONDS)
                            executor.shutdownNow()

                            // Give the kernel time to flush all ARP replies.
                            // Phones in doze mode can take 600-1000 ms to respond to ARP.
                            Thread.sleep(800)

                            // Return both IPs and TTL map so Flutter can do OS detection
                            runOnUiThread {
                                result.success(hashMapOf(
                                    "ips"  to liveSet.keys.toList(),
                                    "ttls" to HashMap(ttlMap)
                                ))
                            }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("PING_ERROR", e.message, null) }
                        }
                    }.start()
                }
                "queryNetBiosNames" -> {
                    // Send a NetBIOS Node Status Request (UDP port 137) to each IP.
                    // Returns Map<String(ip), String(computerName)>.
                    //
                    // This is how we get the actual Windows computer name (e.g. "JOHNS-LAPTOP")
                    // even when ICMP is blocked. NetBIOS operates below the Windows firewall
                    // on local network interfaces, so names are available even if the firewall
                    // is set to "block everything".
                    val ips = call.argument<List<String>>("ips") ?: emptyList()
                    Thread {
                        try {
                            val nameMap = ConcurrentHashMap<String, String>()
                            val executor = Executors.newFixedThreadPool(60)
                            val latch = CountDownLatch(ips.size)

                            // NBSTAT query packet — queries for node status of wildcard "*"
                            // This is the standard NetBIOS stat packet used by nbtscan / nmap
                            val nbstatQuery = byteArrayOf(
                                0x00, 0x00,                          // Transaction ID
                                0x00, 0x10,                          // Flags: standard query
                                0x00, 0x01,                          // Questions: 1
                                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Answers/Auth/Add: 0
                                0x20,                                // Name length (32)
                                // "*" encoded in NetBIOS format (wildcard stat request)
                                0x43, 0x4B, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41,
                                0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41,
                                0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41,
                                0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41,
                                0x00,                                // End of name
                                0x00, 0x21,                          // Type: NBSTAT
                                0x00, 0x01                           // Class: IN
                            )

                            for (ip in ips) {
                                executor.submit {
                                    try {
                                        val sock = java.net.DatagramSocket()
                                        sock.soTimeout = 600
                                        val addr = InetAddress.getByName(ip)
                                        val pkt = java.net.DatagramPacket(nbstatQuery, nbstatQuery.size, addr, 137)
                                        sock.send(pkt)
                                        val buf = ByteArray(1024)
                                        val resp = java.net.DatagramPacket(buf, buf.size)
                                        sock.receive(resp)
                                        sock.close()

                                        // Parse NBSTAT response name table
                                        // Response layout: 12-byte DNS header, then skipping
                                        // original question (varies), then Answer RR + RDATA.
                                        // Name table starts at a fixed offset of 56 in a
                                        // standard NBSTAT response.
                                        val data = resp.data
                                        val len = resp.length
                                        if (len >= 57) {
                                            val nameCount = data[56].toInt() and 0xFF
                                            for (n in 0 until nameCount) {
                                                val base = 57 + n * 18
                                                if (base + 18 > len) break
                                                val rawName = String(data, base, 15).trim()
                                                val typeCode = data[base + 15].toInt() and 0xFF
                                                val flags = ((data[base + 16].toInt() and 0xFF) shl 8) or
                                                            (data[base + 17].toInt() and 0xFF)
                                                val isGroup = (flags and 0x8000) != 0
                                                // Workstation name: type 0x00, unique (not group)
                                                if (typeCode == 0x00 && !isGroup && rawName.isNotBlank()) {
                                                    nameMap[ip] = rawName
                                                    break
                                                }
                                            }
                                        }
                                    } catch (_: Exception) {}
                                    finally { latch.countDown() }
                                }
                            }

                            latch.await(5, TimeUnit.SECONDS)
                            executor.shutdownNow()
                            runOnUiThread { result.success(nameMap) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("NETBIOS_ERROR", e.message, null) }
                        }
                    }.start()
                }
                "snmpScan" -> {
                    // Query SNMPv2c sysDescr + sysName for every IP in the list.
                    // Uses a pure-Kotlin BER encoder/decoder — no external library required.
                    // Returns Map<String(ip), Map<String, String>> where inner map has:
                    //   "sysDescr" → OS + firmware description ("Linux raspberrypi 5.15.0 …")
                    //   "sysName"  → configured device hostname  ("synology-nas")
                    val ips = call.argument<List<String>>("ips") ?: emptyList()
                    Thread {
                        try {
                            val snmpMap = ConcurrentHashMap<String, HashMap<String, String>>()
                            val executor = Executors.newFixedThreadPool(30)
                            val latch = CountDownLatch(ips.size)
                            for (ip in ips) {
                                executor.submit {
                                    try {
                                        val vals = snmpGet(ip)
                                        if (vals.isNotEmpty()) snmpMap[ip] = HashMap(vals)
                                    } catch (_: Exception) {}
                                    finally { latch.countDown() }
                                }
                            }
                            latch.await(15, TimeUnit.SECONDS)  // Increased: 2 community strings × 2.5s timeout
                            executor.shutdownNow()
                            runOnUiThread { result.success(HashMap(snmpMap)) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("SNMP_ERROR", e.message, null) }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        if (multicastLock?.isHeld == true) {
            multicastLock?.release()
        }
        super.onDestroy()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SNMP v2c implementation — pure Kotlin, no external libraries
    //
    // Sends a GetRequest for sysDescr + sysName over UDP port 161.
    // Implements a minimal but correct subset of ASN.1 BER encoding/decoding.
    // ─────────────────────────────────────────────────────────────────────────

    private fun snmpGet(ip: String): Map<String, String> {
        val OID_SYS_DESCR     = "1.3.6.1.2.1.1.1.0"   // sysDescr — OS + firmware description
        val OID_SYS_NAME      = "1.3.6.1.2.1.1.5.0"   // sysName — configured hostname
        val OID_SYS_CONTACT   = "1.3.6.1.2.1.1.4.0"   // sysContact — admin contact
        val OID_SYS_LOCATION  = "1.3.6.1.2.1.1.6.0"   // sysLocation — physical location
        val OID_HR_DEVICE     = "1.3.6.1.2.1.25.3.2.1.3.1"  // HOST-RESOURCES-MIB device description
        val OID_PRT_NAME      = "1.3.6.1.2.1.43.5.1.1.16.1" // Printer-MIB printer name
        val OID_PRT_SERIAL    = "1.3.6.1.2.1.43.5.1.1.17.1" // Printer-MIB serial number
        val OID_IF_DESCR      = "1.3.6.1.2.1.2.2.1.2.1"     // IF-MIB first interface description

        // Try multiple community strings — "public" is most common but some
        // devices use "private" or are configured with vendor defaults
        val communities = arrayOf("public", "private")
        for (community in communities) {
            try {
                val packet = buildSnmpGet(community,
                    OID_SYS_DESCR, OID_SYS_NAME, OID_SYS_CONTACT, OID_SYS_LOCATION,
                    OID_HR_DEVICE, OID_PRT_NAME, OID_PRT_SERIAL, OID_IF_DESCR)
                val sock = java.net.DatagramSocket()
                sock.soTimeout = 2500  // Increased from 1500ms — SNMP over WiFi can be slow
            try {
                val addr = InetAddress.getByName(ip)
                sock.send(DatagramPacket(packet, packet.size, addr, 161))
                val buf = ByteArray(4096)
                val resp = DatagramPacket(buf, buf.size)
                sock.receive(resp)
                val raw = parseSnmpResp(resp.data, resp.length)
                val friendly = mutableMapOf<String, String>()
                raw[OID_SYS_DESCR]?.let     { friendly["sysDescr"]      = it }
                raw[OID_SYS_NAME]?.let      { friendly["sysName"]       = it }
                raw[OID_SYS_CONTACT]?.let   { friendly["sysContact"]    = it }
                raw[OID_SYS_LOCATION]?.let  { friendly["sysLocation"]   = it }
                raw[OID_HR_DEVICE]?.let     { friendly["hrDeviceDescr"] = it }
                raw[OID_PRT_NAME]?.let      { friendly["prtName"]       = it }
                raw[OID_PRT_SERIAL]?.let    { friendly["prtSerial"]     = it }
                raw[OID_IF_DESCR]?.let      { friendly["ifDescr"]       = it }
                return friendly
            } finally { sock.close() }
            } catch (_: Exception) {
                // Try next community string
            }
        }
        return emptyMap()
    }

    /** Build an SNMPv2c GetRequest PDU for the given OIDs. */
    private fun buildSnmpGet(community: String, vararg oids: String): ByteArray {
        val varBinds = oids.map { oid ->
            berTLV(0x30, berOid(oid) + byteArrayOf(0x05, 0x00))
        }.fold(byteArrayOf()) { a, b -> a + b }
        val pdu = berTLV(0xA0,
            berInt(1) + berInt(0) + berInt(0) + berTLV(0x30, varBinds)
        )
        return berTLV(0x30, berInt(1) + berOctets(community) + pdu)
    }

    /** Parse an SNMPv2c GetResponse into a map of OID → value string. */
    private fun parseSnmpResp(data: ByteArray, len: Int): Map<String, String> {
        val result = mutableMapOf<String, String>()
        try {
            var off = 0
            if (off >= len || data[off] != 0x30.toByte()) return result
            off++; off += berLenBytes(data, off)
            off = berSkipTLV(data, off)  // version INTEGER
            off = berSkipTLV(data, off)  // community OCTET STRING
            if (off >= len || (data[off].toInt() and 0xFF) != 0xA2) return result
            off++; off += berLenBytes(data, off)
            repeat(3) { off = berSkipTLV(data, off) } // req-id, err-status, err-index
            if (off >= len || data[off] != 0x30.toByte()) return result
            off++; off += berLenBytes(data, off)
            while (off < len) {
                if (data[off] != 0x30.toByte()) break
                off++; off += berLenBytes(data, off)
                val oidStr = berDecodeOid(data, off) ?: break
                off = berSkipTLV(data, off)
                if (off >= len) break
                val valTag = data[off++].toInt() and 0xFF
                val valLen = berReadLen(data, off)
                off += berLenBytes(data, off)
                val value: String? = when (valTag) {
                    0x04 -> String(data, off, valLen, Charsets.UTF_8).trim()
                    0x02 -> berDecodeInt(data, off, valLen).toString()
                    else -> null
                }
                off += valLen
                if (value != null && value.isNotEmpty()) result[oidStr] = value
            }
        } catch (_: Exception) {}
        return result
    }

    // ── BER encode helpers ────────────────────────────────────────────────────

    private fun berTLV(type: Int, value: ByteArray): ByteArray {
        val lenBytes = when {
            value.size <= 127 -> byteArrayOf(value.size.toByte())
            value.size <= 255 -> byteArrayOf(0x81.toByte(), value.size.toByte())
            else -> byteArrayOf(0x82.toByte(), (value.size shr 8).toByte(), (value.size and 0xFF).toByte())
        }
        return byteArrayOf(type.toByte()) + lenBytes + value
    }

    private fun berInt(value: Int): ByteArray {
        val bytes = when {
            value == 0 -> byteArrayOf(0)
            value in 1..127 -> byteArrayOf(value.toByte())
            value < 0x8000 -> byteArrayOf((value shr 8).toByte(), (value and 0xFF).toByte())
            else -> byteArrayOf((value shr 24).toByte(), (value ushr 16 and 0xFF).toByte(), (value ushr 8 and 0xFF).toByte(), (value and 0xFF).toByte())
        }
        return berTLV(0x02, bytes)
    }

    private fun berOctets(s: String): ByteArray = berTLV(0x04, s.toByteArray(Charsets.UTF_8))

    private fun berOid(oid: String): ByteArray {
        val parts = oid.split(".").map { it.toLong() }
        if (parts.size < 2) return byteArrayOf()
        val encoded = mutableListOf<Byte>()
        encoded.addAll(encodeBase128(parts[0] * 40 + parts[1]))
        for (i in 2 until parts.size) encoded.addAll(encodeBase128(parts[i]))
        return berTLV(0x06, encoded.toByteArray())
    }

    private fun encodeBase128(value: Long): List<Byte> {
        if (value == 0L) return listOf(0)
        val bytes = mutableListOf<Byte>()
        var v = value
        bytes.add((v and 0x7F).toByte())
        v = v shr 7
        while (v > 0) {
            bytes.add(0, ((v and 0x7F) or 0x80).toByte())
            v = v shr 7
        }
        return bytes
    }

    // ── BER decode helpers ────────────────────────────────────────────────────

    /** Number of bytes the BER length field at `off` occupies (1, 2, or 3). */
    private fun berLenBytes(data: ByteArray, off: Int): Int =
        if (off >= data.size || data[off].toInt() and 0x80 == 0) 1
        else 1 + (data[off].toInt() and 0x7F)

    /** The actual length value encoded at `off`. */
    private fun berReadLen(data: ByteArray, off: Int): Int {
        if (off >= data.size) return 0
        val b = data[off].toInt() and 0xFF
        return when {
            b and 0x80 == 0 -> b
            b == 0x81 && off + 1 < data.size -> data[off + 1].toInt() and 0xFF
            b == 0x82 && off + 2 < data.size ->
                ((data[off + 1].toInt() and 0xFF) shl 8) or (data[off + 2].toInt() and 0xFF)
            else -> 0
        }
    }

    /** Skip past an entire TLV (type+length+value) starting at `off`. */
    private fun berSkipTLV(data: ByteArray, off: Int): Int {
        if (off >= data.size) return off
        val lenOff = off + 1
        return lenOff + berLenBytes(data, lenOff) + berReadLen(data, lenOff)
    }

    /** Decode an OID TLV at `off`, returning dotted-decimal string or null. */
    private fun berDecodeOid(data: ByteArray, off: Int): String? {
        if (off + 1 >= data.size || (data[off].toInt() and 0xFF) != 0x06) return null
        val lenOff = off + 1
        val lenSize = berLenBytes(data, lenOff)
        val oidLen = berReadLen(data, lenOff)
        val start = lenOff + lenSize
        if (start + oidLen > data.size || oidLen == 0) return null
        val parts = mutableListOf<Long>()
        val first = data[start].toLong() and 0xFF
        parts.add(first / 40); parts.add(first % 40)
        var i = start + 1
        while (i < start + oidLen) {
            var v = 0L
            while (i < start + oidLen) {
                val b = data[i++].toLong() and 0xFF
                v = (v shl 7) or (b and 0x7F)
                if (b and 0x80 == 0L) break
            }
            parts.add(v)
        }
        return parts.joinToString(".")
    }

    /** Decode an INTEGER value from `len` bytes at `off`. */
    private fun berDecodeInt(data: ByteArray, off: Int, len: Int): Long {
        var v = 0L
        for (i in 0 until len) v = (v shl 8) or (data[off + i].toLong() and 0xFF)
        return v
    }
}
