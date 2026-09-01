import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../offer_models.dart';
import '../offers_provider.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OffersProvider>().loadAll();
  }

  Future<void> _confirmDelete(Offer o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete offer?'),
        content: Text('"${o.title}" will no longer show on the website.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await context.read<OffersProvider>().deleteOffer(o.id);
      } catch (e) {
        if (mounted) showSnack(context, e.toString(), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OffersProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Offers')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/offers/new'),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadAll(force: true),
        child: provider.loading && provider.offers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : provider.offers.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'No offers yet.\nTap + to post one — it shows in a banner strip at\nthe top of the website.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.offers.length,
                    itemBuilder: (context, i) {
                      final o = provider.offers[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.surfaceAlt,
                            child: Text('${o.order}'),
                          ),
                          title: Text(o.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            o.description.isEmpty ? (o.isActive ? 'Active' : 'Hidden') : o.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!o.isActive)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(Icons.visibility_off_outlined, size: 18, color: AppColors.textMuted),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                onPressed: () => _confirmDelete(o),
                              ),
                            ],
                          ),
                          onTap: () => context.push('/offers/${o.id}/edit'),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
