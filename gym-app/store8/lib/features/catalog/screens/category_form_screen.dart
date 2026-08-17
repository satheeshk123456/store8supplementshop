// hide Category: collides with our own Category model (see catalog_provider.dart for why)
import 'package:flutter/material.dart' hide Category;
import 'package:provider/provider.dart';

import '../../../core/widgets.dart';
import '../catalog_models.dart';
import '../catalog_provider.dart';

class CategoryFormScreen extends StatefulWidget {
  final String? categoryId;
  const CategoryFormScreen({super.key, this.categoryId});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _tagline;
  late final TextEditingController _order;
  bool _active = true;
  bool _saving = false;

  Category? get _existing {
    if (widget.categoryId == null) return null;
    return context.read<CatalogProvider>().categoryById(widget.categoryId!);
  }

  @override
  void initState() {
    super.initState();
    final e = _existing;
    _name = TextEditingController(text: e?.name ?? '');
    _tagline = TextEditingController(text: e?.tagline ?? '');
    _order = TextEditingController(text: (e?.order ?? 0).toString());
    _active = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final category = Category(
        id: widget.categoryId ?? '',
        name: _name.text.trim(),
        tagline: _tagline.text.trim(),
        description: _tagline.text.trim(),
        icon: _existing?.icon ?? 'default',
        order: int.tryParse(_order.text) ?? 0,
        isActive: _active,
      );
      await context.read<CatalogProvider>().saveCategory(category, existingId: widget.categoryId);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryId == null ? 'New category' : 'Edit category')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name (e.g. Weight Gain)'),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _tagline,
              decoration: const InputDecoration(labelText: 'Tagline (shown under the name)'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _order,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Display order (lower shows first)'),
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: const Text('Visible on the storefront'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const CircularProgressIndicator(strokeWidth: 2) : const Text('Save category'),
            ),
          ],
        ),
      ),
    );
  }
}
