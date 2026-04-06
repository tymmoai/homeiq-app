import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';

/// Result from the barcode scanner containing the barcode value
/// and optionally the captured camera image.
class BarcodeScanResult {
  final String barcode;
  final Uint8List? capturedImage;

  BarcodeScanResult({required this.barcode, this.capturedImage});
}

/// Full-screen barcode/QR code scanner using the device camera.
///
/// Supports: UPC‑A, UPC‑E, EAN‑8, EAN‑13, Code 128, Code 39, QR Code,
/// Data Matrix, ITF, Codabar, and more (via Google ML Kit / Apple Vision).
///
/// Returns the scanned barcode string via `Navigator.pop(context, barcodeValue)`.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _hasScanned = false;
  bool _torchOn = false;
  bool _isProcessing = false; // true while showing post-scan loading overlay

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle camera lifecycle when app goes to background/foreground
    if (!_controller.value.hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _controller.stop();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned) return; // Prevent duplicate scans

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final value = barcode.rawValue;
    if (value == null || value.isEmpty) return;

    // Lock to prevent double-fire
    _hasScanned = true;

    // Haptic feedback on successful scan
    HapticFeedback.mediumImpact();

    // Show processing overlay so user knows the scan was caught and is being processed.
    // Keep the scanner open briefly instead of immediately closing.
    if (mounted) setState(() => _isProcessing = true);

    // After a brief moment (enough to see the feedback), return the result.
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        Navigator.of(
          context,
        ).pop(BarcodeScanResult(barcode: value, capturedImage: capture.image));
      }
    });
  }

  void _toggleTorch() {
    _controller.toggleTorch();
    setState(() {
      _torchOn = !_torchOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final scanAreaSize = screenSize.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera view
          MobileScanner(controller: _controller, onDetect: _onBarcodeDetected),

          // Dark overlay with transparent scan window
          _buildScanOverlay(screenSize, scanAreaSize),

          // Top bar (cancel + flash)
          _buildTopBar(),

          // Bottom instructions
          _buildBottomInstructions(screenSize, scanAreaSize),

          // Post-scan processing overlay — shown after a barcode is detected
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  /// Full-screen overlay shown after a barcode is detected.
  /// Gives users clear visual confirmation the scan succeeded and
  /// product lookup is now in progress — the scanner does not close
  /// until the brief delay elapses so the state is unmistakable.
  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.check_rounded, color: Colors.white, size: 46),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Barcode detected!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Looking up product details…',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanOverlay(Size screenSize, double scanAreaSize) {
    return CustomPaint(
      size: screenSize,
      painter: _ScanOverlayPainter(
        scanAreaSize: scanAreaSize,
        borderColor: AppColors.primary,
        overlayColor: Colors.black.withValues(alpha: 0.55),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Cancel button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
            // Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Scan Barcode',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Flash toggle
            GestureDetector(
              onTap: _toggleTorch,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _torchOn
                      ? AppColors.accent.withValues(alpha: 0.8)
                      : Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _torchOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInstructions(Size screenSize, double scanAreaSize) {
    // Position instructions below the scan area
    final scanAreaTop = (screenSize.height - scanAreaSize) / 2;
    final instructionTop = scanAreaTop + scanAreaSize + 32;

    return Positioned(
      top: instructionTop,
      left: 0,
      right: 0,
      child: Column(
        children: [
          const Text(
            'Point your camera at a barcode',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'UPC, EAN, QR Code, ISBN, and more',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          // Manual barcode entry option
          GestureDetector(
            onTap: () => _showManualEntryDialog(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.keyboard, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Enter barcode manually',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Enter Barcode'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. 012345678901',
              labelText: 'Barcode Number',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.of(ctx).pop(); // close dialog
                  Navigator.of(
                    context,
                  ).pop(BarcodeScanResult(barcode: value)); // return result
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Look Up',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Custom painter that draws a semi-transparent overlay with a clear scan window
/// and animated corner brackets.
class _ScanOverlayPainter extends CustomPainter {
  final double scanAreaSize;
  final Color borderColor;
  final Color overlayColor;

  _ScanOverlayPainter({
    required this.scanAreaSize,
    required this.borderColor,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scanRect = Rect.fromCenter(
      center: center,
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Draw dark overlay with a hole for the scan area
    final overlayPaint = Paint()..color = overlayColor;
    final holePath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(holePath, overlayPaint);

    // Draw corner brackets
    final bracketLength = scanAreaSize * 0.12;
    const bracketWidth = 4.0;
    final bracketPaint = Paint()
      ..color = borderColor
      ..strokeWidth = bracketWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final corners = [
      scanRect.topLeft,
      scanRect.topRight,
      scanRect.bottomLeft,
      scanRect.bottomRight,
    ];

    for (final corner in corners) {
      final isTop = corner.dy == scanRect.top;
      final isLeft = corner.dx == scanRect.left;

      final hDir = isLeft ? 1.0 : -1.0;
      final vDir = isTop ? 1.0 : -1.0;

      // Horizontal arm
      canvas.drawLine(
        Offset(corner.dx + (isLeft ? 8 : -8), corner.dy + vDir * 2),
        Offset(
          corner.dx + hDir * bracketLength + (isLeft ? 8 : -8),
          corner.dy + vDir * 2,
        ),
        bracketPaint,
      );

      // Vertical arm
      canvas.drawLine(
        Offset(corner.dx + hDir * 2, corner.dy + (isTop ? 8 : -8)),
        Offset(
          corner.dx + hDir * 2,
          corner.dy + vDir * bracketLength + (isTop ? 8 : -8),
        ),
        bracketPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) {
    return oldDelegate.scanAreaSize != scanAreaSize;
  }
}
