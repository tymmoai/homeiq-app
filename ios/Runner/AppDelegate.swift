import Flutter
import UIKit

// ─────────────────────────────────────────────────────────────────────────────
// AppDelegate — HomeIQ
//
// Platform channel: "com.301io.homeiq/wifi"
//
// Implements all 7 methods so iOS returns comparable results to Android:
//   • acquireMulticastLock   → no-op on iOS (always returns true)
//   • releaseMulticastLock   → no-op on iOS (always returns true)
//   • getWifiInfo            → uses getifaddrs() C API + sysctl routing for gateway
//   • pingSweep              → TCP connect sweep (no ICMP on iOS) — 9 ports × 254 IPs
//                              returns {"ips":[…], "ttls":{}} (TTL unavailable on iOS)
//   • getArpTable            → returns {} (ARP table is a privileged kernel API on iOS)
//   • resolveHostnames       → reverse DNS via getnameinfo() C API
//   • queryNetBiosNames      → returns {} (UDP 137 unreliable in iOS App Sandbox)
// ─────────────────────────────────────────────────────────────────────────────

@main
@objc class AppDelegate: FlutterAppDelegate {

    private let channelName = "com.301io.homeiq/wifi"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        let wifiChannel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: controller.binaryMessenger
        )

        wifiChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            switch call.method {

            // ── No-ops: iOS manages its own multicast power state ──────────
            case "acquireMulticastLock":
                NSLog("[WiFiChannel][iOS] acquireMulticastLock → no-op (iOS manages multicast natively)")
                result(true)

            case "releaseMulticastLock":
                NSLog("[WiFiChannel][iOS] releaseMulticastLock → no-op")
                result(true)

            // ── Wi-Fi device IP / gateway / prefix ─────────────────────────
            case "getWifiInfo":
                self.handleGetWifiInfo(result: result)

            // ── TCP-connect sweep (replaces ICMP on iOS) ──────────────────
            case "pingSweep":
                guard let args = call.arguments as? [String: Any],
                      let subnet = args["subnet"] as? String,
                      !subnet.isEmpty else {
                    result(FlutterError(code: "INVALID_ARGS", message: "subnet is required", details: nil))
                    return
                }
                self.handlePingSweep(subnet: subnet, result: result)

            // ── ARP table — not available on iOS ──────────────────────────
            case "getArpTable":
                NSLog("[WiFiChannel][iOS] getArpTable → not available (ARP is a privileged kernel API on iOS)")
                result([String: String]())

            // ── Reverse-DNS hostname resolution ───────────────────────────
            case "resolveHostnames":
                guard let args = call.arguments as? [String: Any],
                      let ips = args["ips"] as? [String] else {
                    result([String: String]())
                    return
                }
                self.handleResolveHostnames(ips: ips, result: result)

            // ── NetBIOS — unreliable in iOS App Sandbox ───────────────────
            case "queryNetBiosNames":
                NSLog("[WiFiChannel][iOS] queryNetBiosNames → not available (UDP 137 blocked in iOS sandbox)")
                result([String: String]())

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // getWifiInfo
    //
    // 1. Enumerates network interfaces via getifaddrs() to find the active IPv4
    //    address on en0 (Wi-Fi) or en1 as fallback.
    // 2. Derives the gateway via sysctl(NET_RT_FLAGS) routing table read.
    //    Falls back to replacing the last octet with .1 (covers 99%+ of home nets).
    // ─────────────────────────────────────────────────────────────────────────
    private func handleGetWifiInfo(result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async {
            var ipStr  = "0.0.0.0"
            var gwStr  = "0.0.0.0"
            var prefix = 24

            // Walk the interface list for an IPv4 Wi-Fi address
            var ifaList: UnsafeMutablePointer<ifaddrs>? = nil
            if getifaddrs(&ifaList) == 0, let firstIfa = ifaList {
                defer { freeifaddrs(firstIfa) }
                let preferred = ["en0", "en1", "en2"]
                var foundPreferred = false
                var ptr: UnsafeMutablePointer<ifaddrs>? = firstIfa

                while let ifa = ptr {
                    defer { ptr = ifa.pointee.ifa_next }
                    let name  = String(cString: ifa.pointee.ifa_name)
                    let flags = Int32(ifa.pointee.ifa_flags)
                    guard (flags & IFF_UP) != 0,
                          (flags & IFF_RUNNING) != 0,
                          (flags & IFF_LOOPBACK) == 0,
                          let sa = ifa.pointee.ifa_addr,
                          sa.pointee.sa_family == sa_family_t(AF_INET) else { continue }
                    if foundPreferred && !preferred.contains(name) { continue }

                    var hostBuf = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(sa, socklen_t(sa.pointee.sa_len),
                                   &hostBuf, socklen_t(NI_MAXHOST),
                                   nil, 0, NI_NUMERICHOST) == 0 {
                        let ip = String(cString: hostBuf)
                        guard ip != "0.0.0.0", ip != "127.0.0.1" else { continue }
                        ipStr = ip
                        if preferred.contains(name) { foundPreferred = true }
                        if let nm = ifa.pointee.ifa_netmask {
                            var maskBuf = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                            if getnameinfo(nm, socklen_t(nm.pointee.sa_len),
                                           &maskBuf, socklen_t(NI_MAXHOST),
                                           nil, 0, NI_NUMERICHOST) == 0 {
                                prefix = self.netmaskToPrefix(String(cString: maskBuf))
                            }
                        }
                    }
                }
            }

            gwStr = self.getDefaultGateway() ?? self.guessGateway(from: ipStr)
            NSLog("[WiFiChannel][iOS] getWifiInfo → ip=%@ gw=%@ prefix=%d", ipStr, gwStr, prefix)
            DispatchQueue.main.async {
                result([
                    "ip":      ipStr,
                    "gateway": gwStr,
                    "prefix":  prefix,
                    "ssid":    NSNull(),
                    "bssid":   ""
                ])
            }
        }
    }

    /// Read the default IPv4 gateway from the kernel routing table via sysctl.
    /// Same data source as `netstat -rn | grep default`.
    private func getDefaultGateway() -> String? {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, AF_INET, NET_RT_FLAGS, RTF_GATEWAY]
        var needed = 0
        guard sysctl(&mib, u_int(mib.count), nil, &needed, nil, 0) == 0, needed > 0 else {
            return nil
        }
        var buf = [UInt8](repeating: 0, count: needed)
        guard sysctl(&mib, u_int(mib.count), &buf, &needed, nil, 0) == 0 else { return nil }

        var offset = 0
        while offset < needed {
            guard offset + MemoryLayout<rt_msghdr>.size <= needed else { break }
            let hdr = buf.withUnsafeBytes { $0.load(fromByteOffset: offset, as: rt_msghdr.self) }
            let msgLen = Int(hdr.rtm_msglen)
            guard msgLen > 0, offset + msgLen <= needed else { break }

            if hdr.rtm_addrs & RTA_GATEWAY != 0 {
                var addrOff = offset + MemoryLayout<rt_msghdr>.size
                for bit in 0 ..< RTAX_MAX {
                    guard hdr.rtm_addrs & (1 << bit) != 0 else { continue }
                    guard addrOff + MemoryLayout<sockaddr>.size <= offset + msgLen else { break }
                    let sa = buf.withUnsafeBytes { $0.load(fromByteOffset: addrOff, as: sockaddr.self) }
                    let saLen = max(Int(sa.sa_len), MemoryLayout<sockaddr>.size)
                    if bit == RTAX_GATEWAY && sa.sa_family == sa_family_t(AF_INET) {
                        let sin = buf.withUnsafeBytes {
                            $0.load(fromByteOffset: addrOff, as: sockaddr_in.self)
                        }
                        var addr = sin.sin_addr
                        var ipBuf = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                        if inet_ntop(AF_INET, &addr, &ipBuf, socklen_t(INET_ADDRSTRLEN)) != nil {
                            let gw = String(cString: ipBuf)
                            if gw != "0.0.0.0" { return gw }
                        }
                    }
                    addrOff += (saLen + 3) & ~3
                }
            }
            offset += msgLen
        }
        return nil
    }

    /// Fallback: replace last octet with .1 (e.g. 192.168.1.42 → 192.168.1.1).
    private func guessGateway(from ip: String) -> String {
        let parts = ip.split(separator: ".").map(String.init)
        guard parts.count == 4 else { return "0.0.0.0" }
        return "\(parts[0]).\(parts[1]).\(parts[2]).1"
    }

    /// Convert dotted-decimal netmask string to CIDR prefix length.
    private func netmaskToPrefix(_ mask: String) -> Int {
        let octets = mask.split(separator: ".").compactMap { UInt8($0) }
        guard octets.count == 4 else { return 24 }
        return octets.reduce(0) { $0 + $1.nonzeroBitCount }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // pingSweep — TCP connect sweep
    //
    // Probes 254 host IPs × 9 ports, capped at 80 concurrent sockets.
    // Returns {"ips":[…], "ttls":{}} — TTL always empty on iOS.
    // ECONNREFUSED = host alive (kernel had to ARP-resolve it to refuse the port).
    // ─────────────────────────────────────────────────────────────────────────
    private func handlePingSweep(subnet: String, result: @escaping FlutterResult) {
        let probePorts = [80, 22, 135, 139, 445, 443, 62078, 5000, 8080]
        DispatchQueue.global(qos: .userInitiated).async {
            let liveSet = NSMutableSet()
            let lock    = NSLock()
            let group   = DispatchGroup()
            let sem     = DispatchSemaphore(value: 80)

            for i in 1...254 {
                let ip = "\(subnet).\(i)"
                for port in probePorts {
                    group.enter()
                    sem.wait()
                    DispatchQueue.global(qos: .background).async {
                        defer { sem.signal(); group.leave() }
                        if self.tcpProbe(host: ip, port: port, timeoutMs: 700) {
                            lock.lock(); liveSet.add(ip); lock.unlock()
                        }
                    }
                }
            }

            _ = group.wait(timeout: .now() + 30)
            NSLog("[WiFiChannel][iOS] pingSweep → %d live host(s) on %@.*", liveSet.count, subnet)
            DispatchQueue.main.async {
                result(["ips": liveSet.allObjects as! [String], "ttls": [String: Int]()])
            }
        }
    }

    /// Non-blocking TCP connect with select() timeout.
    /// Returns true for: successful connect OR ECONNREFUSED (closed port = live host).
    private func tcpProbe(host: String, port: Int, timeoutMs: Int) -> Bool {
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        guard fd >= 0 else { return false }
        defer { Darwin.close(fd) }

        let flags = fcntl(fd, F_GETFL, 0)
        _ = fcntl(fd, F_SETFL, flags | O_NONBLOCK)

        var addr        = sockaddr_in()
        addr.sin_len    = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port   = in_port_t(port).bigEndian
        _ = withUnsafeMutablePointer(to: &addr.sin_addr) {
            inet_pton(AF_INET, host, UnsafeMutableRawPointer($0))
        }

        let ret = withUnsafePointer(to: addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        if ret == 0            { return true }
        let err = errno
        if err == ECONNREFUSED { return true }
        if err != EINPROGRESS  { return false }

        var writefds = fd_set()
        fdZero(&writefds); fdSet(fd, &writefds)
        var tv = timeval(tv_sec: timeoutMs / 1000,
                         tv_usec: Int32((timeoutMs % 1000) * 1000))
        guard select(fd + 1, nil, &writefds, nil, &tv) > 0 else { return false }

        var soErr = Int32(0)
        var soErrLen = socklen_t(MemoryLayout<Int32>.size)
        getsockopt(fd, SOL_SOCKET, SO_ERROR, &soErr, &soErrLen)
        return soErr == 0 || soErr == ECONNREFUSED
    }

    // ─────────────────────────────────────────────────────────────────────────
    // resolveHostnames — concurrent reverse DNS via getnameinfo()
    // Max 50 concurrent lookups; total wait ≤ 5 s.
    // ─────────────────────────────────────────────────────────────────────────
    private func handleResolveHostnames(ips: [String], result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async {
            var hostMap = [String: String]()
            let lock    = NSLock()
            let group   = DispatchGroup()
            let sem     = DispatchSemaphore(value: 50)

            for ip in ips {
                group.enter(); sem.wait()
                DispatchQueue.global(qos: .background).async {
                    defer { sem.signal(); group.leave() }
                    var saddr        = sockaddr_in()
                    saddr.sin_len    = UInt8(MemoryLayout<sockaddr_in>.size)
                    saddr.sin_family = sa_family_t(AF_INET)
                    _ = withUnsafeMutablePointer(to: &saddr.sin_addr) {
                        inet_pton(AF_INET, ip, UnsafeMutableRawPointer($0))
                    }
                    var hostBuf = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    let ret = withUnsafePointer(to: saddr) {
                        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                            getnameinfo($0, socklen_t(MemoryLayout<sockaddr_in>.size),
                                        &hostBuf, socklen_t(NI_MAXHOST),
                                        nil, 0, NI_NAMEREQD)
                        }
                    }
                    if ret == 0 {
                        let hostname = String(cString: hostBuf)
                        if hostname != ip && !hostname.isEmpty {
                            lock.lock(); hostMap[ip] = hostname; lock.unlock()
                        }
                    }
                }
            }
            _ = group.wait(timeout: .now() + 5)
            NSLog("[WiFiChannel][iOS] resolveHostnames → %d/%d resolved", hostMap.count, ips.count)
            DispatchQueue.main.async { result(hostMap) }
        }
    }
}

// ── fd_set helpers (Swift doesn't expose FD_ZERO/FD_SET macros directly) ────
private func fdZero(_ set: inout fd_set) {
    set.fds_bits = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
}
private func fdSet(_ fd: Int32, _ set: inout fd_set) {
    let intOffset = Int(fd) / 32
    let bitOffset = Int(fd) % 32
    let mask      = Int32(1 << bitOffset)
    switch intOffset {
    case 0:  set.fds_bits.0  |= mask; case 1:  set.fds_bits.1  |= mask
    case 2:  set.fds_bits.2  |= mask; case 3:  set.fds_bits.3  |= mask
    case 4:  set.fds_bits.4  |= mask; case 5:  set.fds_bits.5  |= mask
    case 6:  set.fds_bits.6  |= mask; case 7:  set.fds_bits.7  |= mask
    case 8:  set.fds_bits.8  |= mask; case 9:  set.fds_bits.9  |= mask
    case 10: set.fds_bits.10 |= mask; case 11: set.fds_bits.11 |= mask
    case 12: set.fds_bits.12 |= mask; case 13: set.fds_bits.13 |= mask
    case 14: set.fds_bits.14 |= mask; case 15: set.fds_bits.15 |= mask
    default: break
    }
}
