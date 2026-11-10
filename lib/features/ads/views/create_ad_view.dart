import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../points/services/points_service.dart';
import '../services/ad_service.dart';
import 'package:civic_citizen/shared/widgets/wave_header.dart';

class CreateAdView extends StatefulWidget {
  const CreateAdView({super.key});

  @override
  State<CreateAdView> createState() => _CreateAdViewState();
}

class _CreateAdViewState extends State<CreateAdView> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _contact = TextEditingController();
  final _city = TextEditingController();
  final _picker = ImagePicker();
  File? _image;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _contact.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = context.read<AuthController>().user;
    if (user == null) return;

    final cost = await context.read<AdService>().getAdPointsCost();
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Run this ad?'),
        content: Text(
          'This costs $cost Civic Points and shows in the home feed '
          'as a sponsored post for ${AppConstants.adDurationDays} days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await context.read<AdService>().createAd(
            authorId: user.uid,
            authorName: user.displayName ?? user.email ?? 'Citizen',
            title: _title.text,
            description: _description.text,
            contactNumber: _contact.text,
            city: _city.text,
            imageFile: _image,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad is live on the home feed')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = context.watch<AuthController>().user?.uid;

    return Scaffold(
      appBar: AppBar(flexibleSpace: const WaveHeaderBackground(), title: const Text('Create ad')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (uid != null)
              StreamBuilder<int>(
                stream: context.read<AdService>().watchAdPointsCost(),
                builder: (context, costSnap) {
                  final cost =
                      costSnap.data ?? AppConstants.defaultAdPointsCost;
                  return StreamBuilder<int>(
                    stream: context.read<PointsService>().watchBalance(uid),
                    builder: (context, snap) {
                      final bal = snap.data ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Your balance: $bal pts  ·  Cost: $cost pts',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: bal < cost
                                ? theme.colorScheme.error
                                : theme.colorScheme.secondary,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            AppTextField(
              controller: _title,
              label: 'Title',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _description,
              label: 'Description',
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter a description'
                  : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _city,
              label: 'City (optional)',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _contact,
              label: 'Contact (optional)',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(_image!, height: 160, fit: BoxFit.cover),
              ),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(_image == null ? 'Add image' : 'Change image'),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Publish with points',
              loading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
