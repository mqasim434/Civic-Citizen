import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/post_controller.dart';
import '../models/location_pick_result.dart';
import '../models/post_model.dart';
import 'location_picker_view.dart';

class CreatePostView extends StatefulWidget {
  const CreatePostView({super.key});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _contactController = TextEditingController();
  final _locationController = TextEditingController();
  final _categoryOtherController = TextEditingController();
  final _conditionController = TextEditingController();
  PostModule _module = PostModule.lost;
  String? _category;
  final List<File> _images = [];
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    _categoryOtherController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await context.read<PostController>().pickImage();
    if (file != null && mounted) setState(() => _images.add(file));
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    final user = auth.user;
    if (user == null) return;
    context.read<PostController>().clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }
    final loc = _locationController.text.trim();
    if (loc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location is required')),
      );
      return;
    }
    final id = await context.read<PostController>().createPost(
          module: _module,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          authorId: user.uid,
          authorName: user.displayName ?? user.email ?? 'User',
          contactNumber: _contactController.text.trim(),
          category: _category,
          categoryCustom: _category == 'Other'
              ? _categoryOtherController.text.trim().isEmpty
                  ? null
                  : _categoryOtherController.text.trim()
              : null,
          location: loc,
          latitude: _latitude,
          longitude: _longitude,
          itemCondition: _isLendBorrow(_module)
              ? (_conditionController.text.trim().isEmpty
                  ? null
                  : _conditionController.text.trim())
              : null,
          images: _images,
        );
    if (!mounted) return;
    if (id != null) {
      navigatorKey.currentState?.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _categoriesForModule(_module);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create post'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<PostModule>(
                value: _module,
                decoration: const InputDecoration(labelText: 'Module'),
                items: PostModule.values
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                    .toList(),
                onChanged: (m) => setState(() {
                  _module = m ?? PostModule.lost;
                  _category = null;
                  _categoryOtherController.clear();
                  if (!_isLendBorrow(_module)) _conditionController.clear();
                }),
              ),
              const SizedBox(height: 20),
              if (categories.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Select')),
                    ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (c) => setState(() {
                    _category = c;
                    if (c != 'Other') _categoryOtherController.clear();
                  }),
                ),
                if (_category == 'Other') ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _categoryOtherController,
                    label: 'Describe your category',
                    hint: 'e.g. Musical instruments',
                    validator: (v) {
                      if (_category != 'Other') return null;
                      if (v == null || v.trim().isEmpty) {
                        return 'Please describe the Other category';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 20),
              ],
              if (_isLendBorrow(_module)) ...[
                AppTextField(
                  controller: _conditionController,
                  label: 'Item condition',
                  hint: 'e.g. Good, Like new, Fair',
                ),
                const SizedBox(height: 20),
              ],
              AppTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'Brief title for your post',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _descController,
                label: 'Description',
                hint: 'Describe the item or request',
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _contactController,
                label: 'Contact number',
                hint: 'Your phone number',
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _locationController,
                label: 'Location',
                hint: 'Type address or pick on map',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Location is required' : null,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map_rounded),
                  tooltip: 'Pick on map',
                  onPressed: () async {
                    final result = await Navigator.of(context).push<LocationPickResult>(
                      MaterialPageRoute(
                        builder: (_) => const LocationPickerView(),
                      ),
                    );
                    if (result != null && mounted) {
                      setState(() {
                        _locationController.text = result.address;
                        _latitude = result.latitude;
                        _longitude = result.longitude;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Images (required - at least 1)',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._images.asMap().entries.map((e) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              e.value,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _images.removeAt(e.key)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )),
                  if (_images.length < 5)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Consumer<PostController>(
                builder: (_, pc, __) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (pc.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          pc.error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    AppButton(
                      label: 'Create post',
                      loading: pc.isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _categoriesForModule(PostModule m) {
    switch (m) {
      case PostModule.lost:
      case PostModule.found:
        return ['Keys', 'Wallet', 'Phone', 'Documents', 'Bag', 'Other'];
      case PostModule.charity:
        return ['Clothes', 'Books', 'Food', 'Furniture', 'Electronics', 'Other'];
      case PostModule.resources:
        return ['Conveyance', 'Study materials', 'Tools', 'Other'];
      case PostModule.lend:
      case PostModule.borrow:
        return ['Electronics', 'Books', 'Accessories', 'Tools', 'Other'];
    }
  }

  bool _isLendBorrow(PostModule m) =>
      m == PostModule.lend || m == PostModule.borrow;
}
