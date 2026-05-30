import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../shared/widgets/app_button.dart';
import '../services/lend_borrow_contract_service.dart';

/// Full-screen signature capture for lender or borrower.
class ContractSignatureView extends StatefulWidget {
  const ContractSignatureView({
    super.key,
    required this.contractId,
    required this.isLender,
  });

  final String contractId;
  final bool isLender;

  @override
  State<ContractSignatureView> createState() => _ContractSignatureViewState();
}

class _ContractSignatureViewState extends State<ContractSignatureView> {
  late final SignatureController _controller;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final userId = context.read<AuthController>().user?.uid;
    if (userId == null) return;

    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw your signature')),
      );
      return;
    }
    setState(() => _busy = true);
    final service = context.read<LendBorrowContractService>();
    try {
      final bytes = await _controller.toPngBytes();
      if (bytes == null) throw Exception('Could not export signature');
      if (widget.isLender) {
        await service.signAsLender(
          contractId: widget.contractId,
          userId: userId,
          signaturePng: bytes,
        );
      } else {
        await service.signAsBorrower(
          contractId: widget.contractId,
          userId: userId,
          signaturePng: bytes,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = widget.isLender ? 'lender' : 'borrower';

    return Scaffold(
      appBar: AppBar(
        title: Text('Sign as $role'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Draw your signature below to accept the agreement terms.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    color: Colors.white,
                  ),
                  child: Signature(
                    controller: _controller,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _controller.clear,
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    label: 'Confirm signature',
                    loading: _busy,
                    onPressed: _busy ? null : _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
