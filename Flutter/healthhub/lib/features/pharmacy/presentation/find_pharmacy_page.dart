import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../catalog/domain/catalog.dart';
import '../../catalog/presentation/pickers.dart';
import '../../chat/presentation/new_message_page.dart';
import '../domain/pharmacy.dart';

/// Patient side: pick a drug, see which pharmacies have it in stock and at what price.
class FindPharmacyPage extends StatefulWidget {
  const FindPharmacyPage({super.key});

  @override
  State<FindPharmacyPage> createState() => _FindPharmacyPageState();
}

class _FindPharmacyPageState extends State<FindPharmacyPage> {
  Product? _product;
  String? _gov;
  String? _area;
  List<Pharmacy>? _results;
  String? _error;
  bool _loading = false;

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await context.read<Deps>().pharmacy.find(drugId: _product?.drugId, governorateId: _gov, areaId: _area);
      if (mounted) setState(() => _results = r);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      appBar: AppBar(title: const Text('Find a pharmacy')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
        ProductSearchField(
          label: 'Which medicine do you need? (e.g. Panadol)',
          onPicked: (p) {
            setState(() => _product = p);
            _search();
          },
        ),
        if (_product != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(children: [
              InputChip(
                label: Text(_product!.title),
                avatar: const Icon(Icons.medication, size: 18),
                onDeleted: () {
                  setState(() => _product = null);
                  _search();
                },
              ).popIn(),
              const SizedBox(width: 8),
              Expanded(child: Text('Showing pharmacies with ${_product!.activeIngredient}', style: Theme.of(context).textTheme.bodySmall)),
            ]),
          ),
        const SizedBox(height: 12),
        AreaPicker(
          required: false,
          dense: true,
          onChanged: (g, a) {
            _gov = g;
            _area = a;
            _search();
          },
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _loading && results == null
              ? const SkeletonList(key: ValueKey('l'), count: 3)
              : _error != null
                  ? ErrorView(key: const ValueKey('e'), message: _error!, onRetry: _search)
                  : (results ?? const []).isEmpty
                      ? EmptyView(
                          key: const ValueKey('none'),
                          image: 'assets/images/no_results.svg',
                          title: _product == null ? 'No pharmacies here yet' : 'No pharmacy has ${_product!.activeIngredient} in stock nearby',
                          message: 'Try another area.',
                        )
                      : Column(key: ValueKey('r${results!.length}${_product?.id}'), children: [
                          for (var i = 0; i < results.length; i++)
                            Padding(padding: const EdgeInsets.only(top: 12), child: PharmacyCard(pharmacy: results[i]).entrance(i)),
                        ]),
        ),
      ]),
    );
  }
}

class PharmacyCard extends StatelessWidget {
  const PharmacyCard({super.key, required this.pharmacy});

  final Pharmacy pharmacy;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final item = pharmacy.item;
    return AppCard(
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(gradient: AppColors.mintGradient, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pharmacy.name, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text([pharmacy.address, pharmacy.area].where((s) => s.isNotEmpty).join(', '), style: t.bodySmall),
            if (pharmacy.phone != null) Text(pharmacy.phone!, style: t.bodySmall),
          ]),
        ),
        if (item != null)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${item.price.toStringAsFixed(0)} EGP', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            Text(item.lowStock ? 'Only ${item.quantity} left' : 'In stock',
                style: t.bodySmall?.copyWith(color: item.lowStock ? AppColors.warning : AppColors.accent, fontWeight: FontWeight.w700)),
          ]),
        if (pharmacy.ownerId.isNotEmpty)
          IconButton(
            tooltip: 'Message the pharmacy',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => NewMessagePage.open(context, userId: pharmacy.ownerId, subject: item == null ? '' : 'About ${item.drugName}'),
          ),
      ]),
    );
  }
}
