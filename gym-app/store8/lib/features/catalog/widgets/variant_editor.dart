import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../catalog_models.dart';

/// Mutable, form-friendly draft of a Variant. The backend regenerates real ids on save (see
/// gym-backend/app/routers/items.py) — `localKey` here only keeps this row stable in the list
/// UI while the admin is editing (add/remove/reorder), it's never sent to the API.
class VariantDraft {
  final String localKey;
  String unit;
  final TextEditingController valueCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController mrpCtrl;
  final TextEditingController stockCtrl;
  final TextEditingController skuCtrl;
  bool isActive;

  VariantDraft({
    required this.localKey,
    required this.unit,
    String value = '',
    String price = '',
    String mrp = '',
    String stock = '0',
    String sku = '',
    this.isActive = true,
  })  : valueCtrl = TextEditingController(text: value),
        priceCtrl = TextEditingController(text: price),
        mrpCtrl = TextEditingController(text: mrp),
        stockCtrl = TextEditingController(text: stock),
        skuCtrl = TextEditingController(text: sku);

  factory VariantDraft.fromVariant(Variant v, String localKey) => VariantDraft(
        localKey: localKey,
        unit: v.unit,
        value: _trimNum(v.value),
        price: _trimNum(v.price),
        mrp: v.mrp == null ? '' : _trimNum(v.mrp!),
        stock: v.stockQty.toString(),
        sku: v.sku,
        isActive: v.isActive,
      );

  static String _trimNum(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  /// Returns null if the row isn't validly fillable yet (caller should block save).
  Variant? toVariant() {
    final value = num.tryParse(valueCtrl.text.trim());
    final price = double.tryParse(priceCtrl.text.trim());
    if (value == null || value <= 0 || price == null || price < 0) return null;
    return Variant(
      id: '',
      unit: unit,
      value: value,
      label: '',
      mrp: mrpCtrl.text.trim().isEmpty ? null : double.tryParse(mrpCtrl.text.trim()),
      price: price,
      stockQty: int.tryParse(stockCtrl.text.trim()) ?? 0,
      sku: skuCtrl.text.trim(),
      isActive: isActive,
    );
  }

  void dispose() {
    valueCtrl.dispose();
    priceCtrl.dispose();
    mrpCtrl.dispose();
    stockCtrl.dispose();
  }
}

class VariantEditor extends StatelessWidget {
  final UnitKind unitKind;
  final List<VariantDraft> variants;
  final VoidCallback onAdd;
  final ValueChanged<VariantDraft> onRemove;

  const VariantEditor({
    super.key,
    required this.unitKind,
    required this.variants,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final units = kUnitsByKind[unitKind]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Sizes / variants', style: TextStyle(fontWeight: FontWeight.w700)),
            TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 18), label: const Text('Add size')),
          ],
        ),
        if (variants.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Add at least one size (e.g. 1 kg, 500 ml, 60 capsules).',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
        for (final v in variants) _VariantRow(key: ValueKey(v.localKey), draft: v, units: units, onRemove: () => onRemove(v)),
      ],
    );
  }
}

class _VariantRow extends StatefulWidget {
  final VariantDraft draft;
  final List<String> units;
  final VoidCallback onRemove;
  const _VariantRow({super.key, required this.draft, required this.units, required this.onRemove});

  @override
  State<_VariantRow> createState() => _VariantRowState();
}

class _VariantRowState extends State<_VariantRow> {
  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    if (!widget.units.contains(d.unit)) d.unit = widget.units.first;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.surfaceAlt,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: d.valueCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: d.unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: [for (final u in widget.units) DropdownMenuItem(value: u, child: Text(u))],
                    onChanged: (v) => setState(() => d.unit = v ?? d.unit),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: d.priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Price (₹)'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: d.mrpCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'MRP (optional)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: d.stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock qty'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: d.skuCtrl,
                    decoration: const InputDecoration(labelText: 'SKU (optional)'),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: d.isActive,
              onChanged: (v) => setState(() => d.isActive = v),
              title: const Text('Available for sale', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
