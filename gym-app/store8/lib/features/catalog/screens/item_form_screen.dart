import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../catalog_models.dart';
import '../catalog_provider.dart';
import '../widgets/variant_editor.dart';

class ItemFormScreen extends StatefulWidget {
  final String? itemId;
  final String? initialProductId;
  const ItemFormScreen({super.key, this.itemId, this.initialProductId});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _flavor;
  late final TextEditingController _description;
  late final TextEditingController _ingredients;
  late final TextEditingController _benefits;
  late final TextEditingController _usage;
  String? _productId;
  String? _brandId;
  List<String> _images = [];
  late List<VariantDraft> _variants;
  bool _active = true;
  bool _featured = false;
  bool _saving = false;
  bool _uploading = false;
  int _variantKeyCounter = 0;

  Item? get _existing => widget.itemId == null ? null : context.read<CatalogProvider>().items.where((i) => i.id == widget.itemId).firstOrNull;

  @override
  void initState() {
    super.initState();
    final e = _existing;
    _title = TextEditingController(text: e?.title ?? '');
    _flavor = TextEditingController(text: e?.flavor ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _ingredients = TextEditingController(text: e?.ingredients ?? '');
    _benefits = TextEditingController(text: e?.benefits ?? '');
    _usage = TextEditingController(text: e?.usage ?? '');
    _productId = e?.productId ?? widget.initialProductId;
    _brandId = e?.brandId;
    _images = List.from(e?.images ?? const []);
    _active = e?.isActive ?? true;
    _featured = e?.isFeatured ?? false;
    _variants = (e?.variants ?? const [])
        .map((v) => VariantDraft.fromVariant(v, 'v${_variantKeyCounter++}'))
        .toList();
  }

  @override
  void dispose() {
    _title.dispose();
    _flavor.dispose();
    _description.dispose();
    _ingredients.dispose();
    _benefits.dispose();
    _usage.dispose();
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  UnitKind _currentUnitKind(CatalogProvider catalog) {
    final product = _productId == null ? null : catalog.productById(_productId!);
    return product?.unitKind ?? UnitKind.weight;
  }

  void _addVariant() {
    setState(() => _variants.add(VariantDraft(localKey: 'v${_variantKeyCounter++}', unit: '')));
  }

  void _removeVariant(VariantDraft v) {
    setState(() {
      _variants.remove(v);
      v.dispose();
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final url = await context.read<CatalogProvider>().uploadImage('products', File(picked.path));
      setState(() => _images.add(url));
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (_productId == null) {
      showSnack(context, 'Select a product', isError: true);
      return;
    }
    if (_brandId == null) {
      showSnack(context, 'Select a brand', isError: true);
      return;
    }
    final variants = <Variant>[];
    for (final draft in _variants) {
      final v = draft.toVariant();
      if (v == null) {
        showSnack(context, 'Fill in amount and price for every size, or remove the empty row', isError: true);
        return;
      }
      variants.add(v);
    }
    if (variants.isEmpty) {
      showSnack(context, 'Add at least one size', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final item = Item(
        id: widget.itemId ?? '',
        productId: _productId!,
        brandId: _brandId!,
        title: _title.text.trim(),
        flavor: _flavor.text.trim(),
        description: _description.text.trim(),
        ingredients: _ingredients.text.trim(),
        benefits: _benefits.text.trim(),
        usage: _usage.text.trim(),
        images: _images,
        variants: variants,
        isActive: _active,
        isFeatured: _featured,
      );
      await context.read<CatalogProvider>().saveItem(item, existingId: widget.itemId);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final unitKind = _currentUnitKind(catalog);

    return Scaffold(
      appBar: AppBar(title: Text(widget.itemId == null ? 'New brand listing' : 'Edit listing')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _productId,
            decoration: const InputDecoration(labelText: 'Product'),
            items: [for (final p in catalog.products) DropdownMenuItem(value: p.id, child: Text(p.name))],
            onChanged: widget.itemId != null ? null : (v) => setState(() => _productId = v),
            validator: (v) => v == null ? 'Select a product' : null,
          ),
          if (widget.itemId != null)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Product cannot be changed after creation — delete and re-add if needed.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _brandId,
            decoration: const InputDecoration(labelText: 'Brand'),
            items: [for (final b in catalog.brands) DropdownMenuItem(value: b.id, child: Text(b.name))],
            onChanged: (v) => setState(() => _brandId = v),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title (optional, e.g. "Gold Standard 100% Whey")'),
          ),
          const SizedBox(height: 14),
          TextField(controller: _flavor, decoration: const InputDecoration(labelText: 'Flavor (optional)')),
          const SizedBox(height: 14),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description (optional)'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ingredients,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Ingredients (optional)'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _benefits,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Benefits (optional)'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _usage,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Usage / how to use (optional)'),
          ),
          const SizedBox(height: 20),
          const Text('Photos', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final url in _images)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: IconButton(
                        icon: const Icon(Icons.cancel, color: AppColors.danger, size: 20),
                        onPressed: () => setState(() => _images.remove(url)),
                      ),
                    ),
                  ],
                ),
              GestureDetector(
                onTap: _uploading ? null : _pickImage,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12)),
                  child: _uploading
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_a_photo_outlined, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          VariantEditor(
            unitKind: unitKind,
            variants: _variants,
            onAdd: _addVariant,
            onRemove: _removeVariant,
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: _active,
            onChanged: (v) => setState(() => _active = v),
            title: const Text('Visible on the storefront'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _featured,
            onChanged: (v) => setState(() => _featured = v),
            title: const Text('Featured'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const CircularProgressIndicator(strokeWidth: 2) : const Text('Save listing'),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
