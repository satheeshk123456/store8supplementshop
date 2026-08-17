import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../catalog_models.dart';
import '../catalog_provider.dart';

class ProductFormScreen extends StatefulWidget {
  final String? productId;
  final String? initialCategoryId;
  const ProductFormScreen({super.key, this.productId, this.initialCategoryId});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late Set<String> _categoryIds;
  late UnitKind _unitKind;
  bool _active = true;
  bool _saving = false;

  Product? get _existing =>
      widget.productId == null ? null : context.read<CatalogProvider>().productById(widget.productId!);

  @override
  void initState() {
    super.initState();
    final e = _existing;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _categoryIds = (e?.categoryIds ?? (widget.initialCategoryId != null ? [widget.initialCategoryId!] : []))
        .toSet();
    _unitKind = e?.unitKind ?? UnitKind.weight;
    _active = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryIds.isEmpty) {
      showSnack(context, 'Select at least one category', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final product = Product(
        id: widget.productId ?? '',
        name: _name.text.trim(),
        categoryIds: _categoryIds.toList(),
        description: _description.text.trim(),
        unitKind: _unitKind,
        isActive: _active,
      );
      await context.read<CatalogProvider>().saveProduct(product, existingId: widget.productId);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CatalogProvider>().categories;

    return Scaffold(
      appBar: AppBar(title: Text(widget.productId == null ? 'New product' : 'Edit product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Product name (e.g. Whey Protein)'),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Enter a product name' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 20),
            const Text('Sold by', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
              'Controls whether customers pick a size in kg/g, L/ml, or capsules/tablets.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            SegmentedButton<UnitKind>(
              segments: const [
                ButtonSegment(value: UnitKind.weight, label: Text('Weight (kg/g)')),
                ButtonSegment(value: UnitKind.volume, label: Text('Volume (L/ml)')),
                ButtonSegment(value: UnitKind.count, label: Text('Count (caps/tabs)')),
              ],
              selected: {_unitKind},
              onSelectionChanged: (s) => setState(() => _unitKind = s.first),
            ),
            const SizedBox(height: 22),
            const Text('Categories', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in categories)
                  FilterChip(
                    label: Text(c.name),
                    selected: _categoryIds.contains(c.id),
                    onSelected: (sel) => setState(() {
                      if (sel) {
                        _categoryIds.add(c.id);
                      } else {
                        _categoryIds.remove(c.id);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: const Text('Visible on the storefront'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const CircularProgressIndicator(strokeWidth: 2) : const Text('Save product'),
            ),
          ],
        ),
      ),
    );
  }
}
