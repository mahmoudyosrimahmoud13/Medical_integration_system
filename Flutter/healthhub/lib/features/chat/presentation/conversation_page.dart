import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../chat.dart';

/// One thread. Polls for new messages every few seconds while open.
class ConversationPage extends StatefulWidget {
  const ConversationPage({super.key, required this.conversation});

  final Conversation conversation;

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <ChatMessage>[];
  Timer? _poll;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  ChatRepository get _repo => context.read<Deps>().chat;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _load(incremental: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool incremental = false}) async {
    try {
      final after = incremental && _messages.isNotEmpty ? _messages.last.sentAt : null;
      final fresh = await _repo.messages(widget.conversation.id, after: after);
      if (!mounted) return;
      setState(() {
        if (!incremental) _messages.clear();
        final known = _messages.map((m) => m.id).toSet();
        _messages.addAll(fresh.where((m) => !known.contains(m.id)));
        _loading = false;
        _error = null;
      });
      if (fresh.isNotEmpty) _scrollToEnd();
    } on ApiException catch (e) {
      if (mounted && !incremental) setState(() => _error = e.message);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final m = await _repo.send(widget.conversation.id, text);
      if (!mounted) return;
      _text.clear();
      setState(() => _messages.add(m));
      _scrollToEnd();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conversation;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          Avatar(name: c.otherName, url: c.otherImageUrl, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.otherRole == 'Doctor' ? 'Dr. ${c.otherName}' : c.otherName, style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis),
              Text(c.subject.isNotEmpty ? c.subject : c.otherRole, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final m = _messages[i];
                        final showDay = i == 0 || !DateUtils.isSameDay(_messages[i - 1].sentAt, m.sentAt);
                        return Column(children: [
                          if (showDay)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(DateFormat.yMMMEd().format(m.sentAt), style: Theme.of(context).textTheme.labelSmall),
                            ),
                          _Bubble(m: m).animate().fadeIn(duration: 200.ms).slideY(begin: .1, end: 0),
                        ]);
                      },
                    ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            decoration: BoxDecoration(color: scheme.surface, border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: .5)))),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(hintText: 'Write a message', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: _sending ? null : _send,
                icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.m});

  final ChatMessage m;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(m.mine ? 18 : 4),
      bottomRight: Radius.circular(m.mine ? 4 : 18),
    );
    return Align(
      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .76),
        decoration: BoxDecoration(gradient: m.mine ? AppColors.heroGradient : null, color: m.mine ? null : scheme.surfaceContainerHighest.withValues(alpha: .6), borderRadius: radius),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(m.text, style: TextStyle(color: m.mine ? Colors.white : scheme.onSurface, height: 1.35)),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(DateFormat.jm().format(m.sentAt), style: TextStyle(fontSize: 11, color: m.mine ? Colors.white70 : scheme.outline)),
            if (m.mine) ...[
              const SizedBox(width: 4),
              Icon(m.readAt != null ? Icons.done_all : Icons.done, size: 14, color: m.readAt != null ? AppColors.amber : Colors.white70),
            ],
          ]),
        ]),
      ),
    );
  }
}
