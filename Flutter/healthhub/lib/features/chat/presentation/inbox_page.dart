import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di.dart';
import '../../../core/navigation/app_route.dart';
import '../../../core/state/load_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../chat.dart';
import 'conversation_page.dart';
import 'new_message_page.dart';
import '../../../core/i18n/i18n.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoadCubit<List<Conversation>>(context.read<Deps>().chat.conversations),
      child: Builder(builder: (context) {
        final cubit = context.watch<LoadCubit<List<Conversation>>>();
        return Scaffold(
          body: Column(children: [
            GradientHeader(subtitle: tr('Messages'), title: tr('Inbox')),
            Expanded(
              child: AsyncBody<List<Conversation>>(
                state: cubit.state,
                onRetry: cubit.load,
                isEmpty: (d) => d.isEmpty,
                empty: EmptyView(
                  image: 'assets/images/notifications.svg',
                  title: tr('No messages yet'),
                  message: tr('Write to your doctor, a pharmacy or a hospital.'),
                  action: FilledButton.icon(onPressed: () => _compose(context, cubit), icon: const Icon(Icons.edit_outlined), label: Text(tr('New message'))),
                ),
                builder: (items) => RefreshIndicator(
                  onRefresh: cubit.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ConversationTile(c: items[i], onBack: cubit.load).entrance(i),
                  ),
                ),
              ),
            ),
          ]),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _compose(context, cubit),
            tooltip: tr('New message'),
            child: const Icon(Icons.edit_outlined),
          ),
        );
      }),
    );
  }

  Future<void> _compose(BuildContext context, LoadCubit<List<Conversation>> cubit) async {
    await context.push(const NewMessagePage());
    cubit.load();
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.c, required this.onBack});

  final Conversation c;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final last = c.lastMessage;
    final when = DateUtils.isSameDay(c.lastMessageAt, DateTime.now()) ? DateFormat.jm(AppSettings.dateLocale).format(c.lastMessageAt) : DateFormat.MMMd(AppSettings.dateLocale).format(c.lastMessageAt);
    return AppCard(
      color: c.unread > 0 ? AppColors.primary.withValues(alpha: .06) : null,
      onTap: () async {
        await context.push(ConversationPage(conversation: c));
        onBack();
      },
      child: Row(children: [
        Avatar(name: c.otherName, url: c.otherImageUrl, radius: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(c.otherRole == 'Doctor' ? 'Dr. ${c.otherName}' : c.otherName, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
              Text(when, style: t.bodySmall),
            ]),
            Text(c.otherRole, style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
            if (last != null)
              Text('${last.mine ? tr('You: ') : ''}${last.text}', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: t.bodyMedium?.copyWith(fontWeight: c.unread > 0 ? FontWeight.w700 : FontWeight.w400)),
          ]),
        ),
        if (c.unread > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
            child: Text('${c.unread}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          ).popIn(),
        ],
      ]),
    );
  }
}
