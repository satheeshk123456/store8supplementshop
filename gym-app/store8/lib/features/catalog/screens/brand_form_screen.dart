import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../catalog_models.dart';
import '../catalog_provider.dart';

class BrandFormScreen extends StatefulWidget {
  final String? brandId;
  const BrandFormScreen({super.key, this.brandId});

  @override
  State<BrandFormScreen> createState() => _BrandFormScreenState();
}

class _BrandFormScreenState extends State<BrandFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  String _logoUrl = '';
  bool _active = true;
  bool _saving = false;
  bool _uploading = false;

  Brand? get _existing =>
      widget.brandId == null ? null : context.read<CatalogProvider>().brandById(widget.brandId!);

  @override
  void initState() {
    super.initState();
    final e = _existing;
    _name = TextEditingController(text: e?.name ?? '');
    _logoUrl = e?.logo ?? '';
    _active = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final url = await context.read<CatalogProvider>().uploadImage('brands', File(picked.path));
      setState(() => _logoUrl = url);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final brand = Brand(id: widget.brandId ?? '', name: _name.text.trim(), logo: _logoUrl, isActive: _active);
      await context.read<CatalogProvider>().saveBrand(brand, existingId: widget.brandId);
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
      appBar: AppBar(title: Text(widget.brandId == null ? 'New brand' : 'Edit brand')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Center(
              child: GestureDetector(
                onTap: _uploading ? null : _pickLogo,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _uploading
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                      : _logoUrl.isEmpty
                          ? const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textMuted)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(imageUrl: _logoUrl, fit: BoxFit.contain),
                            ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Brand name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a brand name' : null,
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
              child: _saving ? const CircularProgressIndicator(strokeWidth: 2) : const Text('Save brand'),
            ),
          ],
        ),
      ),
    );
  }
}
