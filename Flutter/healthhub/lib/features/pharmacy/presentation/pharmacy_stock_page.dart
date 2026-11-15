import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/state/load_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../catalog/presentation/pickers.dart';
import '../domain/pharmacy.dart';

class PharmacyStockPage extends StatelessWidget {
  const PharmacyStockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoadCubit<List<StockItem>>(context.read<Deps>().pharmacy.stock),
      child: const _StockView(),
    );
  }
}

class _StockView extends StatelessWidget {
  const _StockView();

  Future<void> _edit(BuildContext context, {String? drugId, String? drugName, StockItem? existing}) async {
    final cubit = context.read<LoadCubit<List<StockItem>>>();
    final repo = context.read<Deps>().pharmacy;
    final result = await showModalBottomSheet<(String, String, int, double)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => RepositoryProvider.value(value: context.read<Deps>(), child: _StockSheet(drugId: drugId ?? existing?.drugId, drugName: drugName ?? existing?.drugName, existing: existing)),
    );
    if (result == null) return;
    try {
      await repo.setStock(result.$1, result.$3, result.$4);
      cubit.load();
      if (context.mounted) showSnack(context, '${result.$2} updated');
    } on ApiException catch (e) {
      if (context.mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<LoadCubit<List<StockItem>>>();
    final repo = context.read<Deps>().pharmacy;
    return Scaffold(
      appBar: AppBar(title: const Text('Stock')),
      body: AsyncBody<List<StockItem>>(
        state: cubit.state,
        onRetry: cubit.load,
        isEmpty: (d) => d.isEmpty,
        empty: const EmptyView(title: 'No stock yet', message: 'Add the medicines you carry so patients can find you.'),
        builder: (items) => RefreshIndicator(
          onRefresh: cubit.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final it = items[i];
              return Dismissible(
                key: ValueKey(it.drugId),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  try {
                    await repo.removeStock(it.drugId);
                    return true;
                  } on ApiException catch (e) {
                    if (context.mounted) showSnack(context, e.message, error: true);
                    return false;
                  }
                },
                onDismissed: (_) => cubit.load(),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: AppCard(
                  onTap: () => _edit(context, existing: it),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(it.drugName, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${it.price.toStringAsFixed(2)} EGP', style: Theme.of(context).textTheme.bodySmall),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (it.outOfStock ? AppColors.danger : it.lowStock ? AppColors.warning : AppColors.accent).withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${it.quantity}', style: TextStyle(fontWeight: FontWeight.w800, color: it.outOfStock ? AppColors.danger : it.lowStock ? AppColors.warning : AppColors.accent)),
                    ),
                  ]),
                ),
              ).entrance(i);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add),
        label: const Text('Add medicine'),
      ),
    );
  }
}

class _StockSheet extends StatefulWidget {
  const _StockSheet({this.drugId, this.drugName, this.existing});

  final String? drugId;
  final String? drugName;
  final StockItem? existing;

  @override
  State<_StockSheet> createState() => _StockSheetState();
}

class _StockSheetState extends State<_StockSheet> {
  String? _id;
  String? _name;
  late final _qty = TextEditingController(text: '${widget.existing?.quantity ?? 10}');
  late final _price = TextEditingController(text: widget.existing == null ? '' : widget.existing!.price.toStringAsFixed(2));

  @override
  void initState() {
    super.initState();
    _id = widget.drugId;
    _name = widget.drugName;
  }

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(_price.text);
    final qty = int.tryParse(_qty.text);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.existing == null ? 'Add medicine' : 'Update stock', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        if (_name == null)
          DrugSearchField(onPicked: (d) => setState(() {
                _id = d.id;
                _name = d.name;
              }))
        else
          InputChip(label: Text(_name!), avatar: const Icon(Icons.medication, size: 18), onDeleted: widget.existing == null ? () => setState(() => _id = _name = null) : null),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: TextField(controller: _qty, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Quantity'))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: _price, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Price', suffixText: 'EGP'))),
        ]),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _id == null || price == null || qty == null || qty < 0 || price < 0 ? null : () => Navigator.pop(context, (_id!, _name!, qty, price)),
          child: const Text('Save'),
        ),
      ]),
    );
  }
}
