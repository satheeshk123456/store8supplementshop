import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../catalog/catalog_models.dart';
import '../../catalog/catalog_provider.dart';
import '../order_models.dart';
import '../orders_provider.dart';
import '../orders_service.dart';
import '../widgets/status_badge.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  Object? _error;
  bool _updating = false;
  final Set<String> _lineBusy = {};
  final _paymentLinkCtrl = TextEditingController();
  bool _settingPaymentLink = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _paymentLinkCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final order = await context.read<OrdersService>().get(widget.orderId);
      if (mounted) setState(() => _order = order);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _advanceStatus(String newStatus) async {
    setState(() => _updating = true);
    try {
      await context.read<OrdersProvider>().updateStatus(widget.orderId, newStatus);
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  String _lineKey(OrderLine line) => '${line.itemId}::${line.variantId}';

  /// Records the outcome of physically checking this line's stock — the reason the shop
  /// requires this step before confirming: website stock and physical-shop stock are the same
  /// limited pool, so a line that looked available at checkout can still be sold in person.
  Future<void> _setLineAvailability(OrderLine line, String availability) async {
    setState(() => _lineBusy.add(_lineKey(line)));
    try {
      final updated = await context
          .read<OrdersProvider>()
          .setLineAvailability(widget.orderId, line.itemId, line.variantId, availability);
      if (mounted) setState(() => _order = updated);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _lineBusy.remove(_lineKey(line)));
    }
  }

  Future<void> _sharePaymentLink() async {
    final link = _paymentLinkCtrl.text.trim();
    if (link.isEmpty) {
      showSnack(context, 'Paste the payment link first', isError: true);
      return;
    }
    setState(() => _settingPaymentLink = true);
    try {
      final updated = await context.read<OrdersProvider>().setPaymentLink(widget.orderId, link);
      if (mounted) setState(() => _order = updated);
      if (mounted) showSnack(context, 'Payment link saved — share it with the customer on WhatsApp');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _settingPaymentLink = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_order?.orderNumber ?? 'Order')),
      body: _error != null
          ? ErrorView(message: _error.toString(), onRetry: _load)
          : _order == null
              ? const LoadingView()
              : _buildBody(_order!),
    );
  }

  Widget _buildBody(Order order) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StatusBadge(status: order.status),
            if (!order.notified)
              const Tooltip(
                message: "The push notification for this order may not have been delivered",
                child: Icon(Icons.notifications_off_outlined, color: AppColors.warning, size: 20),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Customer',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.customer.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(order.customer.phone, style: const TextStyle(color: AppColors.textMuted)),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16, color: AppColors.textMuted),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: order.customer.phone));
                      showSnack(context, 'Phone number copied');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(order.customer.address, style: const TextStyle(color: AppColors.textMuted)),
              if (order.customer.city.isNotEmpty || order.customer.pincode.isNotEmpty)
                Text('${order.customer.city} ${order.customer.pincode}'.trim(),
                    style: const TextStyle(color: AppColors.textMuted)),
              if (order.customer.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Note: ${order.customer.note}', style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Items — confirm physical stock before confirming this order',
          child: Column(
            children: [
              for (final line in order.items) _OrderLineRow(line: line, order: order, screen: this),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.w800)),
                  Text(formatInr(order.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.goldLight)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (order.status != 'cancelled') _PaymentSection(order: order, screen: this),
        const SizedBox(height: 20),
        if (order.status != 'delivered' && order.status != 'cancelled') ...[
          const Text('Update status', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final s in _nextStatuses(order.status))
                OutlinedButton(
                  onPressed: _updating ? null : () => _advanceStatus(s),
                  child: Text('Mark ${s[0].toUpperCase()}${s.substring(1)}'),
                ),
              TextButton(
                onPressed: _updating ? null : () => _advanceStatus('cancelled'),
                child: const Text('Cancel order', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  List<String> _nextStatuses(String current) {
    final idx = kOrderStatuses.indexOf(current);
    if (idx == -1 || idx >= kOrderStatuses.length - 2) return [];
    return kOrderStatuses.sublist(idx + 1, kOrderStatuses.length - 1);
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

/// One order line plus the admin's physical-stock decision for it. Website stock and the
/// physical shop's stock are the same limited pool, so this is the step that actually
/// determines whether the order can be confirmed.
class _OrderLineRow extends StatelessWidget {
  final OrderLine line;
  final Order order;
  final _OrderDetailScreenState screen;
  const _OrderLineRow({required this.line, required this.order, required this.screen});

  @override
  Widget build(BuildContext context) {
    final busy = screen._lineBusy.contains(screen._lineKey(line));
    final unavailable = line.availability == 'unavailable';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${line.brandName} ${line.productName} (${line.variantLabel}) × ${line.qty}'),
              ),
              Text(formatInr(line.subtotal)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Available'),
                selected: !unavailable,
                onSelected: busy ? null : (_) => screen._setLineAvailability(line, 'available'),
                selectedColor: AppColors.success.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: !unavailable ? AppColors.success : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Unavailable'),
                selected: unavailable,
                onSelected: busy ? null : (_) => screen._setLineAvailability(line, 'unavailable'),
                selectedColor: AppColors.danger.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: unavailable ? AppColors.danger : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (busy) ...[
                const SizedBox(width: 10),
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ],
          ),
          if (unavailable) ...[
            const SizedBox(height: 6),
            Text(
              line.customerChoice == null
                  ? 'Waiting for the customer to choose Notify me / Suggest an alternative on the storefront.'
                  : line.customerChoice == 'notify_me'
                      ? 'Customer asked to be notified on WhatsApp when this is back in stock.'
                      : 'Customer asked for an alternative suggestion.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: line.customerChoice == null ? AppColors.warning : AppColors.goldLight,
              ),
            ),
          ],
          if (unavailable && line.customerChoice == 'suggest_alternative')
            _AlternativeSuggestionSection(line: line, order: order, screen: screen),
          const SizedBox(height: 6),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

/// The "Suggest a suitable alternative product with special offers" mini-section for one line
/// where the customer picked "Suggest an Alternative". Shows the current suggestion (if any)
/// and a way to open the picker / copy a WhatsApp-ready message.
class _AlternativeSuggestionSection extends StatelessWidget {
  final OrderLine line;
  final Order order;
  final _OrderDetailScreenState screen;
  const _AlternativeSuggestionSection({required this.line, required this.order, required this.screen});

  String _whatsAppMessage(OrderLineAlternative alt) {
    final offer = alt.specialOffer.trim().isEmpty ? '' : ' — ${alt.specialOffer.trim()}';
    return 'Hi ${order.customer.name}, the ${line.brandName} ${line.productName} (${line.variantLabel}) '
        'you ordered is currently unavailable. We\'d like to suggest instead: '
        '${alt.brandName} ${alt.productName} (${alt.variantLabel}) at ${formatInr(alt.finalPrice)}$offer. '
        'Reply to confirm and we\'ll share the payment link, order ${order.orderNumber}.';
  }

  @override
  Widget build(BuildContext context) {
    final alt = line.alternative;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (alt == null)
              OutlinedButton.icon(
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Suggest a suitable alternative product with special offers'),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => _AlternativePickerDialog(orderId: order.id, originalLine: line, screen: screen),
                ),
              )
            else ...[
              Text('Suggested: ${alt.brandName} ${alt.productName} (${alt.variantLabel})',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              if (alt.specialOffer.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('Offer: ${alt.specialOffer}',
                      style: const TextStyle(color: AppColors.goldLight, fontSize: 12)),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  alt.finalPrice < alt.price
                      ? '${formatInr(alt.finalPrice)} (normally ${formatInr(alt.price)})'
                      : formatInr(alt.finalPrice),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  alt.status == 'suggested'
                      ? 'Waiting for the customer to confirm on the storefront.'
                      : alt.status == 'customer_declined'
                          ? 'Customer declined this suggestion.'
                          : 'Customer confirmed this alternative.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: alt.status == 'customer_declined' ? AppColors.danger : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy, size: 15),
                    label: const Text('Copy WhatsApp message'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _whatsAppMessage(alt)));
                      showSnack(context, 'Message copied — paste it into WhatsApp');
                    },
                  ),
                  if (alt.status != 'customer_accepted')
                    TextButton(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) =>
                            _AlternativePickerDialog(orderId: order.id, originalLine: line, screen: screen),
                      ),
                      child: const Text('Change suggestion'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lets the admin pick a currently-available catalog product/brand/size to offer in place of
/// an unavailable line, with an optional one-off special offer for this order only.
class _AlternativePickerDialog extends StatefulWidget {
  final String orderId;
  final OrderLine originalLine;
  final _OrderDetailScreenState screen;
  const _AlternativePickerDialog({required this.orderId, required this.originalLine, required this.screen});

  @override
  State<_AlternativePickerDialog> createState() => _AlternativePickerDialogState();
}

class _AlternativePickerDialogState extends State<_AlternativePickerDialog> {
  String? _productId;
  String? _selectedItemId;
  String? _selectedVariantId;
  final _offerCtrl = TextEditingController();
  final _finalPriceCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Catalog data is cached app-wide after the first load; calling this again is a no-op if
    // it's already loaded, and covers the case where this screen was reached (e.g. via a push
    // notification) before any catalog screen ever loaded it.
    context.read<CatalogProvider>().loadAll();
  }

  @override
  void dispose() {
    _offerCtrl.dispose();
    _finalPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedItemId == null || _selectedVariantId == null) {
      showSnack(context, 'Choose a replacement product and size', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final finalPriceText = _finalPriceCtrl.text.trim();
      final updated = await context.read<OrdersProvider>().suggestAlternative(
            widget.orderId,
            widget.originalLine.itemId,
            widget.originalLine.variantId,
            altItemId: _selectedItemId!,
            altVariantId: _selectedVariantId!,
            specialOffer: _offerCtrl.text.trim(),
            finalPrice: finalPriceText.isEmpty ? null : double.tryParse(finalPriceText),
          );
      if (widget.screen.mounted) widget.screen.setState(() => widget.screen._order = updated);
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
    final itemsForProduct = _productId == null ? const <Item>[] : catalog.itemsForProduct(_productId!);
    Item? selectedItem;
    for (final i in itemsForProduct) {
      if (i.id == _selectedItemId) {
        selectedItem = i;
        break;
      }
    }
    final variants = selectedItem?.variants.where((v) => v.isActive).toList() ?? const <Variant>[];

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Suggest a suitable alternative product with special offers'),
      content: SizedBox(
        width: 360,
        child: catalog.loading && catalog.products.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer originally wanted: ${widget.originalLine.brandName} '
                      '${widget.originalLine.productName} (${widget.originalLine.variantLabel}) — currently unavailable.',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _productId,
                      decoration: const InputDecoration(labelText: 'Alternative product'),
                      items: [for (final p in catalog.products) DropdownMenuItem(value: p.id, child: Text(p.name))],
                      onChanged: (v) => setState(() {
                        _productId = v;
                        _selectedItemId = null;
                        _selectedVariantId = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedItemId,
                      decoration: const InputDecoration(labelText: 'Brand'),
                      items: [
                        for (final i in itemsForProduct)
                          DropdownMenuItem(
                            value: i.id,
                            child: Text(catalog.brandById(i.brandId)?.name ?? i.brandName ?? 'Brand'),
                          ),
                      ],
                      onChanged: _productId == null
                          ? null
                          : (v) => setState(() {
                                _selectedItemId = v;
                                _selectedVariantId = null;
                              }),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedVariantId,
                      decoration: const InputDecoration(labelText: 'Size'),
                      items: [
                        for (final v in variants)
                          DropdownMenuItem(value: v.id, child: Text('${v.label} · ${formatInr(v.price)}')),
                      ],
                      onChanged: _selectedItemId == null ? null : (v) => setState(() => _selectedVariantId = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _offerCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Special offer (optional)',
                        hintText: 'e.g. 10% off, free shaker, buy-1-get-1',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _finalPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Final price for this customer (optional)',
                        hintText: 'Leave blank to charge the normal Store 8 price',
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'This price applies only to this order — the storefront price everyone else '
                      'sees does not change.',
                      style: TextStyle(color: AppColors.warning, fontSize: 11),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save suggestion'),
        ),
      ],
    );
  }
}

/// Only reachable once every line is confirmed available — matches the required flow:
/// Website Order → Admin Physical Stock Check → Availability Confirm → Payment Link. The link
/// itself is shared with the customer over WhatsApp by the admin, outside this app.
class _PaymentSection extends StatelessWidget {
  final Order order;
  final _OrderDetailScreenState screen;
  const _PaymentSection({required this.order, required this.screen});

  @override
  Widget build(BuildContext context) {
    final canShare = !order.hasUnavailableLine;
    return _SectionCard(
      title: 'Payment link',
      child: order.paymentLink != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Shared with the customer:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: Text(order.paymentLink!, style: const TextStyle(color: AppColors.goldLight))),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16, color: AppColors.textMuted),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: order.paymentLink!));
                        showSnack(context, 'Payment link copied');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Send it to the customer on WhatsApp — this app does not send it automatically.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!canShare)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Mark every item "Available" above before sharing a payment link.',
                      style: TextStyle(color: AppColors.warning, fontSize: 12),
                    ),
                  ),
                TextField(
                  controller: screen._paymentLinkCtrl,
                  enabled: canShare,
                  decoration: const InputDecoration(labelText: 'Paste the payment link (UPI / Razorpay / etc.)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: !canShare || screen._settingPaymentLink ? null : screen._sharePaymentLink,
                  child: screen._settingPaymentLink
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save & confirm order'),
                ),
              ],
            ),
    );
  }
}
