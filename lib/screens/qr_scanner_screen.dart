import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'offline_weight_entry_screen.dart';

class QRScannerScreen extends StatefulWidget {
  final String? requestId;

  const QRScannerScreen({super.key, this.requestId});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        _isProcessing = true;
        _scannerController.stop();

        final data = barcode.rawValue!;
        
        // Expected format: "farmerId|farmerName"
        final parts = data.split('|');
        if (parts.length >= 2) {
          final farmerId = parts[0];
          final farmerName = parts[1];

          // Navigate to OfflineWeightEntryScreen
          if (!mounted) return;
          final result = await Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => OfflineWeightEntryScreen(
                farmerId: farmerId,
                farmerName: farmerName,
                requestId: widget.requestId, // Pass the request ID if provided
              ),
            ),
          );
        } else {
          // Invalid QR code format
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid QR Code. Please scan a valid Farmer ID.')),
          );
          await Future.delayed(const Duration(seconds: 2));
          _isProcessing = false;
          _scannerController.start();
        }
      }
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Farmer QR'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _scannerController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _scannerController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          // Overlay to guide the user
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Theme.of(context).colorScheme.primary,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.7,
              ),
            ),
          ),
          const Positioned(
            bottom: 50,
            child: Text(
              'Align the QR code within the frame',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                backgroundColor: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom shape for the overlay
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }
    return _getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..moveTo(rect.left + rect.width / 2.0, rect.top + rect.height / 2.0)
      ..addRect(Rect.fromCenter(
        center: Offset(rect.width / 2.0, rect.height / 2.0),
        width: cutOutSize,
        height: cutOutSize,
      ));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final _borderLength = borderLength > cutOutSize / 2 + borderOffset
        ? cutOutSize / 2 + borderOffset
        : borderLength;
    final _cutOutSize = cutOutSize < width ? cutOutSize : width - borderOffset;

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromCenter(
      center: Offset(width / 2, height / 2),
      width: _cutOutSize,
      height: _cutOutSize,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(
        rect,
        backgroundPaint,
      )
      // Draw the cutout
      ..drawRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(borderRadius),
        ),
        boxPaint,
      )
      ..restore();

    // Draw borders
    canvas
      // Top Left
      ..drawPath(
        Path()
          ..moveTo(cutOutRect.left, cutOutRect.top + _borderLength)
          ..lineTo(cutOutRect.left, cutOutRect.top + borderRadius)
          ..arcToPoint(
            Offset(cutOutRect.left + borderRadius, cutOutRect.top),
            radius: Radius.circular(borderRadius),
          )
          ..lineTo(cutOutRect.left + _borderLength, cutOutRect.top),
        borderPaint,
      )
      // Top Right
      ..drawPath(
        Path()
          ..moveTo(cutOutRect.right - _borderLength, cutOutRect.top)
          ..lineTo(cutOutRect.right - borderRadius, cutOutRect.top)
          ..arcToPoint(
            Offset(cutOutRect.right, cutOutRect.top + borderRadius),
            radius: Radius.circular(borderRadius),
          )
          ..lineTo(cutOutRect.right, cutOutRect.top + _borderLength),
        borderPaint,
      )
      // Bottom Right
      ..drawPath(
        Path()
          ..moveTo(cutOutRect.right, cutOutRect.bottom - _borderLength)
          ..lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius)
          ..arcToPoint(
            Offset(cutOutRect.right - borderRadius, cutOutRect.bottom),
            radius: Radius.circular(borderRadius),
          )
          ..lineTo(cutOutRect.right - _borderLength, cutOutRect.bottom),
        borderPaint,
      )
      // Bottom Left
      ..drawPath(
        Path()
          ..moveTo(cutOutRect.left + _borderLength, cutOutRect.bottom)
          ..lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom)
          ..arcToPoint(
            Offset(cutOutRect.left, cutOutRect.bottom - borderRadius),
            radius: Radius.circular(borderRadius),
          )
          ..lineTo(cutOutRect.left, cutOutRect.bottom - _borderLength),
        borderPaint,
      );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
    );
  }
}
