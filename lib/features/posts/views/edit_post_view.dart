import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../controllers/post_controller.dart';
import '../models/post_model.dart';
import 'location_picker_view.dart';

class EditPostView extends StatefulWidget {
  const EditPostView({super.key, required this.post});

  final PostModel post;

  @override
  State<EditPostView> createState() => _EditPostViewState();
}

class _EditPostViewState extends State<EditPostView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _contactController;
  late final TextEditingController _locationController;
  late PostModule _module;
  late String? _category;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _descController = TextEditingController(text: widget.post.description);
    _contactController = TextEditingController(text: widget.post.contactNumber);
    _locationController = TextEditingController(text: widget.post.location ?? '');
    _module = widget.post.module;
    _category = widget.post.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    context.read<PostController>().clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await context.read<PostController>().updatePost(
          id: widget.post.id,
          module: _module,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          contactNumber: _contactController.text.trim(),
          category: _category,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
        );
    if (!mounted) return;
    if (success) {
      navigatorKey.currentState?.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _categoriesForModule(_module);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit post'),
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
                  onChanged: (c) => setState(() => _category = c),
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
                label: 'Location (optional)',
                hint: 'Type address or pick on map',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map_rounded),
                  tooltip: 'Pick on map',
                  onPressed: () async {
                    final result = await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                        builder: (_) => const LocationPickerView(),
                      ),
                    );
                    if (result != null && mounted) {
                      setState(() => _locationController.text = result);
                    }
                  },
                ),
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
                      label: 'Save changes',
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
}
