import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../auth/controllers/auth_controller.dart';
import '../services/lost_found_claim_service.dart';

class ClaimScanView extends StatefulWidget {
  const ClaimScanView({super.key, required this.claimId});

  final String claimId;

  @override
  State<ClaimScanView> createState() => _ClaimScanViewState();
}

class _ClaimScanViewState extends State<ClaimScanView> {
  bool _processing = false;
  bool _done = false;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || _done) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null || raw.isEmpty) return;

    final service = context.read<LostFoundClaimService>();
    final parsed = service.parseQrPayload(raw);
    if (parsed == null) return;
    if (parsed.claimId != widget.claimId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This QR belongs to a different claim')),
        );
      }
      return;
    }

    final uid = context.read<AuthController>().user?.uid;
    if (uid == null) return;

    setState(() => _processing = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await service.completeHandshake(
        claimId: parsed.claimId,
        token: parsed.token,
        scannerUserId: uid,
      );
      if (!mounted) return;
      setState(() => _done = true);
      await _scannerController.stop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Recovery confirmed with GPS log')),
      );
      navigator.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Scan recovery QR')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black.withValues(alpha: 0.65),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Point the camera at the post author\'s QR code.\nYour location and time will be recorded.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                  if (_processing) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(color: Colors.white),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
