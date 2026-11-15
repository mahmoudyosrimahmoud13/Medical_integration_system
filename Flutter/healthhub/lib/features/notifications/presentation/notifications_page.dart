import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di.dart';
import '../../../core/state/load_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../notifications.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  IconData _icon(String type) {
    if (type.contains('Cancel')) return Icons.event_busy_rounded;
    if (type.contains('Prescription')) return Icons.medication_rounded;
    if (type.contains('Rate')) return Icons.star_rounded;
    if (type.contains('Result')) return Icons.verified_rounded;
    return Icons.notifications_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoadCubit<List<AppNotification>>(context.read<Deps>().notifications.all),
      child: Builder(builder: (context) {
        final cubit = context.watch<LoadCubit<List<AppNotification>>>();
        return Scaffold(
          appBar: AppBar(title: const Text('Notifications')),
          body: AsyncBody<List<AppNotification>>(
            state: cubit.state,
            onRetry: cubit.load,
            isEmpty: (d) => d.isEmpty,
            empty: const EmptyView(image: 'assets/images/notifications.svg', title: "You're all caught up", message: 'New activity shows up here.'),
            builder: (items) => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final n = items[i];
                return AppCard(
                  color: n.isRead ? null : AppColors.primary.withValues(alpha: .06),
                  onTap: n.isRead
                      ? null
                      : () async {
                          await context.read<Deps>().notifications.markRead(n.id);
                          cubit.load();
                        },
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(_icon(n.type), color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n.message, style: TextStyle(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700)),
                        if (n.createdAt != null)
                          Text(DateFormat.yMMMd().add_jm().format(n.createdAt!), style: Theme.of(context).textTheme.bodySmall),
                      ]),
                    ),
                    if (!n.isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
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
