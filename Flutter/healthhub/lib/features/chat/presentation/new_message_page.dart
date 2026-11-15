import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../core/navigation/app_route.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/state/load_cubit.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../chat.dart';
import 'conversation_page.dart';

/// Pick someone you're allowed to write to (grouped by relationship), then open the thread.
class NewMessagePage extends StatelessWidget {
  const NewMessagePage({super.key});

  /// Starts (or reopens) a conversation with [userId] and opens it. Used from doctor and pharmacy pages too.
  static Future<void> open(BuildContext context, {required String userId, String subject = ''}) async {
    try {
      final conv = await context.read<Deps>().chat.start(userId, subject: subject);
      if (context.mounted) await context.push(ConversationPage(conversation: conv));
    } on ApiException catch (e) {
      if (context.mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoadCubit<List<Contact>>(context.read<Deps>().chat.contacts),
      child: Builder(builder: (context) {
        final cubit = context.watch<LoadCubit<List<Contact>>>();
        return Scaffold(
          appBar: AppBar(title: const Text('New message')),
          body: AsyncBody<List<Contact>>(
            state: cubit.state,
            onRetry: cubit.load,
            isEmpty: (d) => d.isEmpty,
            empty: const EmptyView(title: 'No one to write to yet', message: 'Book a doctor or open a pharmacy page to start a conversation.'),
            builder: (items) {
              final groups = <String, List<Contact>>{};
              for (final c in items) {
                groups.putIfAbsent(c.role, () => []).add(c);
              }
              var i = 0;
              return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
                for (final e in groups.entries) ...[
                  SectionTitle('${e.key}s'),
                  for (final c in e.value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        onTap: () async {
                          await open(context, userId: c.userId);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: Row(children: [
                          Avatar(name: c.name, url: c.imageUrl, radius: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(c.role == 'Doctor' ? 'Dr. ${c.name}' : c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(c.context, style: Theme.of(context).textTheme.bodySmall),
                            ]),
                          ),
                          const Icon(Icons.chevron_right),
                        ]),
                      ).entrance(i++),
                    ),
                ],
              ]);
            },
          ),
        );
      }),
    );
  }
}
