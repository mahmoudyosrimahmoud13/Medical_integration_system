import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../catalog/presentation/pickers.dart';
import '../domain/doctors.dart';
import 'doctor_card.dart';
import 'doctor_search_cubit.dart';
import '../../../core/i18n/i18n.dart';

class FindDoctorsPage extends StatelessWidget {
  const FindDoctorsPage({super.key, this.initialSpecialtyId, this.showBack = false});

  final String? initialSpecialtyId;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DoctorSearchCubit(context.read<Deps>().doctors, initial: DoctorFilter(specialtyId: initialSpecialtyId))..search(),
      child: _FindDoctorsView(showBack: showBack),
    );
  }
}

class _FindDoctorsView extends StatefulWidget {
  const _FindDoctorsView({required this.showBack});

  final bool showBack;

  @override
  State<_FindDoctorsView> createState() => _FindDoctorsViewState();
}

class _FindDoctorsViewState extends State<_FindDoctorsView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        context.read<DoctorSearchCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _openFilters() {
    final cubit = context.read<DoctorSearchCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(value: cubit, child: const _FilterSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DoctorSearchCubit>();
    return Scaffold(
      body: Column(children: [
        GradientHeader(
          subtitle: tr('Find a doctor'),
          title: tr('Who do you need today?'),
          trailing: widget.showBack
              ? IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white))
              : null,
          bottom: Row(children: [
            Expanded(
              child: TextField(
                onChanged: cubit.setName,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: tr('Search by doctor name'),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _openFilters,
                child: const Padding(padding: EdgeInsets.all(15), child: Icon(Icons.tune_rounded)),
              ),
            ),
          ]),
        ),
        Expanded(
          child: BlocBuilder<DoctorSearchCubit, DoctorSearchState>(
            builder: (context, s) {
              final Widget child;
              if (s.loading && s.items.isEmpty) {
                child = const SkeletonList(key: ValueKey('loading'));
              } else if (s.error != null && s.items.isEmpty) {
                child = ErrorView(key: const ValueKey('error'), message: s.error!, onRetry: cubit.search);
              } else if (s.items.isEmpty) {
                child = EmptyView(
                  key: ValueKey('empty'),
                  image: 'assets/images/no_results.svg',
                  title: tr('No doctors found'),
                  message: tr('Try another specialty or a wider area.'),
                );
              } else {
                child = RefreshIndicator(
                  key: const ValueKey('list'),
                  onRefresh: cubit.search,
                  child: ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: s.items.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return Text(s.total == 1 ? tr('1 doctor found') : tr('{n} doctors found', {'n': s.total}),
                            style: Theme.of(context).textTheme.labelLarge);
                      }
                      final card = DoctorCard(doctor: s.items[i - 1]).entrance(i);
                      if (i == s.items.length && s.loadingMore) {
                        return Column(children: [card, const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())]);
                      }
                      return card;
                    },
                  ),
                );
              }
              return AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: child);
            },
          ),
        ),
      ]),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DoctorSearchCubit>();
    final f = cubit.state.filter;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(tr('Filters'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        SpecialtyPicker(value: f.specialtyId, onChanged: cubit.setSpecialty),
        const SizedBox(height: 14),
        AreaPicker(required: false, initialGovernorateId: f.governorateId, onChanged: cubit.setLocation, dense: true),
        const SizedBox(height: 16),
        Text(tr('Sort by'), style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        BlocBuilder<DoctorSearchCubit, DoctorSearchState>(
          buildWhen: (a, b) => a.filter.sort != b.filter.sort,
          builder: (context, s) => SegmentedButton<DoctorSort>(
            segments: [
              ButtonSegment(value: DoctorSort.none, label: Text(tr('Name'))),
              ButtonSegment(value: DoctorSort.rate, label: Text(tr('Top rated')), icon: Icon(Icons.star_outline)),
              ButtonSegment(value: DoctorSort.join, label: Text(tr('Experience'))),
            ],
            selected: {s.filter.sort},
            onSelectionChanged: (v) => cubit.setSort(v.first),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: () => Navigator.pop(context), child: Text(tr('Show doctors'))),
      ]),
    );
  }
}
