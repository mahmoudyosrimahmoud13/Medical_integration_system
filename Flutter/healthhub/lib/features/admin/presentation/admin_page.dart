import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/state/load_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../admin_repository.dart';
import '../../../core/i18n/i18n.dart';

/// Admin: review doctor, pharmacy and hospital requests.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        GradientHeader(
          subtitle: tr('Admin'),
          title: tr('Requests to review'),
          bottom: Container(
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(14))),
              labelColor: AppColors.navy,
              unselectedLabelColor: Colors.white,
              dividerColor: Colors.transparent,
              tabs: [Tab(text: tr('Doctors')), Tab(text: tr('Pharmacies')), Tab(text: tr('Hospitals'))],
            ),
          ),
        ),
        const Expanded(
          child: TabBarView(children: [_RequestList(kind: 'doctor'), _RequestList(kind: 'pharmacy'), _RequestList(kind: 'hospital')]),
        ),
      ]),
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(kind),
      create: (_) => LoadCubit<List<PendingRequest>>(() => context.read<Deps>().admin.pending(kind)),
      child: Builder(builder: (context) {
        final cubit = context.watch<LoadCubit<List<PendingRequest>>>();
        Future<void> review(PendingRequest r, bool accept) async {
          try {
            await context.read<Deps>().admin.review(r.kind, r.id, accept: accept);
            cubit.load();
            if (context.mounted) showSnack(context, tr(accept ? '{name} accepted' : '{name} rejected', {'name': r.title}));
          } on ApiException catch (e) {
            if (context.mounted) showSnack(context, e.message, error: true);
          }
        }

        return AsyncBody<List<PendingRequest>>(
          state: cubit.state,
          onRetry: cubit.load,
          isEmpty: (d) => d.isEmpty,
          empty: EmptyView(title: tr('Nothing to review'), message: tr('New requests show up here.')),
          builder: (items) => RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final r = items[i];
                return AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text(r.subtitle, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    for (final d in r.details) Padding(padding: const EdgeInsets.only(top: 4), child: Text(d)),
                    if (r.files.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(spacing: 6, children: [for (var k = 0; k < r.files.length; k++) Chip(avatar: const Icon(Icons.attach_file, size: 16), label: Text(tr('Certificate {n}', {'n': k + 1})))]),
                      ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: OutlinedButton(onPressed: () => review(r, false), child: Text(tr('Reject')))),
                      const SizedBox(width: 10),
                      Expanded(child: FilledButton(onPressed: () => review(r, true), child: Text(tr('Accept')))),
                    ]),
                  ]),
                ).entrance(i);
              },
            ),
          ),
        );
      }),
    );
  }
}
