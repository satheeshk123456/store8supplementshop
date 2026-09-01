import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../offer_models.dart';
import '../offers_provider.dart';

class OfferFormScreen extends StatefulWidget {
  final String? offerId;
  const OfferFormScreen({super.key, this.offerId});

  @override
  State<OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends State<OfferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _link;
  late final TextEditingController _order;
  String _image = '';
  bool _active = true;
  bool _saving = false;
  bool _uploading = false;

  Offer? get _existing {
    if (widget.offerId == null) return null;
    return context.read<OffersProvider>().offerById(widget.offerId!);
  }

  @override
  void initState() {
    super.initState();
    final e = _existing;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _link = TextEditingController(text: e?.link ?? '');
    _order = TextEditingController(text: (e?.order ?? 0).toString());
    _image = e?.image ?? '';
    _active = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _link.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final url = await context.read<OffersProvider>().uploadImage(File(picked.path));
      setState(() => _image = url);
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
      final offer = Offer(
        id: widget.offerId ?? '',
        title: _title.text.trim(),
        description: _description.text.trim(),
        image: _image,
        link: _link.text.trim(),
        order: int.tryParse(_order.text) ?? 0,
        isActive: _active,
      );
      await context.read<OffersProvider>().saveOffer(offer, existingId: widget.offerId);
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
      appBar: AppBar(title: Text(widget.offerId == null ? 'New offer' : 'Edit offer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title (e.g. Diwali Combo Offer)'),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Enter a title' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g. Buy 2 get 1 free on select whey — ask us on WhatsApp',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _link,
              decoration: const InputDecoration(
                labelText: 'Link (optional)',
                hintText: 'e.g. a WhatsApp chat link or a product page URL',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _order,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Display order (lower shows first)'),
            ),
            const SizedBox(height: 20),
            const Text('Banner image (optional)', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                if (_image.isNotEmpty)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(imageUrl: _image, width: 100, height: 70, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: AppColors.danger, size: 20),
                          onPressed: () => setState(() => _image = ''),
                        ),
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: _uploading ? null : _pickImage,
                    child: Container(
                      width: 100,
                      height: 70,
                      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12)),
                      child: _uploading
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_a_photo_outlined, color: AppColors.textMuted),
                    ),
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
              child: _saving ? const CircularProgressIndicator(strokeWidth: 2) : const Text('Save offer'),
            ),
          ],
        ),
      ),
    );
  }
}
