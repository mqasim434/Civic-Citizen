import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/services/profile_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/network_status.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import 'package:civic_citizen/shared/widgets/wave_header.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _nameController;
  bool _saving = false;
  File? _pickedFile;
  bool _removePhoto = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().user;
    _nameController = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _hasSavedPhoto(UserModel? user) =>
      !_removePhoto && (user?.photoUrl?.trim().isNotEmpty ?? false);

  bool _showsPhoto(UserModel? user) =>
      _pickedFile != null || _hasSavedPhoto(user);

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1080,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _pickedFile = File(picked.path);
      _removePhoto = false;
    });
  }

  Future<void> _openPhotoOptions(UserModel? user) async {
    final hasPhoto = _showsPhoto(user);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(hasPhoto ? 'Choose a new photo' : 'Choose from gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (hasPhoto)
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                title: Text(
                  'Remove photo',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _pickedFile = null;
                    _removePhoto = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthController>();
    final user = auth.user;
    if (user == null) return;

    final photoChanged = _pickedFile != null ||
        (_removePhoto && (user.photoUrl?.trim().isNotEmpty ?? false));
    final online = await NetworkStatus.isOnline;
    if (!mounted) return;
    if (!online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(NetworkStatus.offlineMessage)),
      );
      return;
    }

    setState(() => _saving = true);
    final authService = context.read<AuthService>();
    final profileService = context.read<ProfileService>();
    try {
      final name = _nameController.text.trim();
      await authService.updateDisplayName(name);
      await profileService.updateDisplayName(
        uid: user.uid,
        displayName: name,
      );
      if (photoChanged) {
        final String? photoUrl = _pickedFile == null
            ? null
            : await profileService.uploadProfilePhoto(
                uid: user.uid,
                image: _pickedFile!,
              );
        await authService.updatePhotoUrl(photoUrl);
        await profileService.updatePhotoUrl(
          uid: user.uid,
          photoUrl: photoUrl,
        );
      }
      await auth.refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            NetworkStatus.isOfflineError(e)
                ? NetworkStatus.offlineMessage
                : '$e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthController>().user;

    return Scaffold(
      appBar: AppBar(flexibleSpace: const WaveHeaderBackground(), title: const Text('Edit profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Update your photo and how your name appears on posts.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Center(child: _PhotoEditor(
                user: user,
                pickedFile: _pickedFile,
                showSavedPhoto: _hasSavedPhoto(user),
                onEdit: _saving ? null : () => _openPhotoOptions(user),
              )),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _saving ? null : () => _openPhotoOptions(user),
                  icon: Icon(
                    _showsPhoto(user)
                        ? Icons.edit_outlined
                        : Icons.add_a_photo_outlined,
                  ),
                  label: Text(_showsPhoto(user) ? 'Change photo' : 'Add photo'),
                ),
              ),
              if (_showsPhoto(user))
                Center(
                  child: TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                              _pickedFile = null;
                              _removePhoto = true;
                            }),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.error,
                    ),
                    label: Text(
                      'Remove photo',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _nameController,
                label: 'Display name',
                hint: 'Your name',
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter a display name';
                  }
                  if (v.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
                onSubmitted: (_) => _save(),
              ),
              if (user?.email != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Email',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  user!.email!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              AppButton(
                label: 'Save changes',
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoEditor extends StatelessWidget {
  const _PhotoEditor({
    required this.user,
    required this.pickedFile,
    required this.showSavedPhoto,
    required this.onEdit,
  });

  final UserModel? user;
  final File? pickedFile;
  final bool showSavedPhoto;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = (user?.displayName?.isNotEmpty == true
            ? user!.displayName![0]
            : user?.email?[0] ?? '?')
        .toUpperCase();
    ImageProvider? image;
    if (pickedFile != null) {
      image = FileImage(pickedFile!);
    } else if (showSavedPhoto) {
      image = NetworkImage(user!.photoUrl!);
    }

    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: AppTheme.colors(context).subtle,
            backgroundImage: image,
            child: image == null
                ? Text(
                    initial,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppTheme.colors(context).burgundyInk,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: AppTheme.burgundy,
              elevation: 2,
              shape: CircleBorder(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onEdit,
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.photo_camera_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
