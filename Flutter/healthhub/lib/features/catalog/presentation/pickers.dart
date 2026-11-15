import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../domain/catalog.dart';

/// Governorate + area dropdowns. Picking a governorate loads its areas.
class AreaPicker extends StatefulWidget {
  const AreaPicker({super.key, required this.onChanged, this.required = true, this.initialGovernorateId, this.dense = false});

  /// Called with (governorateId, areaId). Either can be null.
  final void Function(String? governorateId, String? areaId) onChanged;
  final bool required;
  final String? initialGovernorateId;
  final bool dense;

  @override
  State<AreaPicker> createState() => _AreaPickerState();
}

class _AreaPickerState extends State<AreaPicker> {
  List<Governorate> _governorates = const [];
  List<Area> _areas = const [];
  String? _gov;
  String? _area;
  bool _loadingAreas = false;

  @override
  void initState() {
    super.initState();
    _gov = widget.initialGovernorateId;
    _load();
  }

  Future<void> _load() async {
    final catalog = context.read<Deps>().catalog;
    try {
      final govs = await catalog.governorates();
      if (!mounted) return;
      setState(() => _governorates = govs);
      if (_gov != null) await _loadAreas(_gov!);
    } catch (_) {
      // the dropdown stays empty; the form validator will ask the user to pick
    }
  }

  Future<void> _loadAreas(String govId) async {
    setState(() => _loadingAreas = true);
    try {
      final areas = await context.read<Deps>().catalog.areas(govId);
      if (mounted) setState(() => _areas = areas);
    } catch (_) {
      if (mounted) setState(() => _areas = const []);
    } finally {
      if (mounted) setState(() => _loadingAreas = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: widget.dense ? 10 : 14);
    return Column(children: [
      DropdownButtonFormField<String>(
        initialValue: _gov,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Governorate', prefixIcon: Icon(Icons.map_outlined)),
        items: [
          if (!widget.required) const DropdownMenuItem(value: null, child: Text('Any governorate')),
          for (final g in _governorates) DropdownMenuItem(value: g.id, child: Text(g.name)),
        ],
        validator: (v) => widget.required && v == null ? 'Pick your governorate' : null,
        onChanged: (v) {
          setState(() {
            _gov = v;
            _area = null;
            _areas = const [];
          });
          widget.onChanged(v, null);
          if (v != null) _loadAreas(v);
        },
      ),
      gap,
      DropdownButtonFormField<String>(
        key: ValueKey(_gov),
        initialValue: _area,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Area',
          prefixIcon: const Icon(Icons.location_on_outlined),
          suffixIcon: _loadingAreas ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))) : null,
        ),
        items: [
          if (!widget.required) const DropdownMenuItem(value: null, child: Text('Any area')),
          for (final a in _areas) DropdownMenuItem(value: a.id, child: Text(a.name)),
        ],
        validator: (v) => widget.required && v == null ? 'Pick your area' : null,
        onChanged: _gov == null
            ? null
            : (v) {
                setState(() => _area = v);
                widget.onChanged(_gov, v);
              },
      ),
    ]);
  }
}

/// Dropdown of medical specialties.
class SpecialtyPicker extends StatefulWidget {
  const SpecialtyPicker({super.key, required this.onChanged, this.value, this.required = false});

  final ValueChanged<String?> onChanged;
  final String? value;
  final bool required;

  @override
  State<SpecialtyPicker> createState() => _SpecialtyPickerState();
}

class _SpecialtyPickerState extends State<SpecialtyPicker> {
  List<Specialty> _items = const [];

  @override
  void initState() {
    super.initState();
    context.read<Deps>().catalog.specialties().then((v) {
      if (mounted) setState(() => _items = v);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('${widget.value}-${_items.length}'),
      initialValue: _items.any((s) => s.id == widget.value) ? widget.value : null,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Specialty', prefixIcon: Icon(Icons.medical_services_outlined)),
      items: [
        if (!widget.required) const DropdownMenuItem(value: null, child: Text('All specialties')),
        for (final s in _items) DropdownMenuItem(value: s.id, child: Text(s.name)),
      ],
      validator: (v) => widget.required && v == null ? 'Pick a specialty' : null,
      onChanged: widget.onChanged,
    );
  }
}

/// Search-as-you-type field for drugs. Calls [onPicked] with the chosen drug.
class DrugSearchField extends StatefulWidget {
  const DrugSearchField({super.key, required this.onPicked, this.label = 'Search a drug'});

  final ValueChanged<Drug> onPicked;
  final String label;

  @override
  State<DrugSearchField> createState() => _DrugSearchFieldState();
}

class _DrugSearchFieldState extends State<DrugSearchField> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<List<Drug>> _search(String q) {
    final completer = Completer<List<Drug>>();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        completer.complete(await context.read<Deps>().catalog.searchDrugs(q));
      } catch (_) {
        completer.complete(const []);
      }
    });
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Drug>(
      displayStringForOption: (d) => d.name,
      optionsBuilder: (value) => value.text.trim().length < 2 ? const <Drug>[] : _search(value.text),
      onSelected: (d) {
        widget.onPicked(d);
        FocusScope.of(context).unfocus();
      },
      fieldViewBuilder: (context, controller, focus, onSubmit) => TextField(
        controller: controller,
        focusNode: focus,
        decoration: InputDecoration(labelText: widget.label, prefixIcon: const Icon(Icons.medication_outlined)),
      ),
    );
  }
}


/// Search-as-you-type for branded products ("Panadol", "Concor"). Returns the product; use `drugId` for stock lookups.
class ProductSearchField extends StatefulWidget {
  const ProductSearchField({super.key, required this.onPicked, this.label = 'Search by brand or ingredient'});

  final ValueChanged<Product> onPicked;
  final String label;

  @override
  State<ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends State<ProductSearchField> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<List<Product>> _search(String q) {
    final completer = Completer<List<Product>>();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        completer.complete(await context.read<Deps>().catalog.searchProducts(q));
      } catch (_) {
        completer.complete(const []);
      }
    });
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Product>(
      displayStringForOption: (p) => p.title,
      optionsBuilder: (value) => value.text.trim().length < 2 ? const <Product>[] : _search(value.text),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320, maxWidth: 520),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final p in options)
                  ListTile(
                    dense: true,
                    title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${p.activeIngredient} · ${p.manufacturer}'),
                    trailing: Text(p.price > 0 ? '${p.price.toStringAsFixed(0)} EGP' : ''),
                    onTap: () => onSelected(p),
                  ),
              ],
            ),
          ),
        ),
      ),
      onSelected: (p) {
        widget.onPicked(p);
        FocusScope.of(context).unfocus();
      },
      fieldViewBuilder: (context, controller, focus, onSubmit) => TextField(
        controller: controller,
        focusNode: focus,
        decoration: InputDecoration(labelText: widget.label, prefixIcon: const Icon(Icons.medication_outlined)),
      ),
    );
  }
}
