import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../catalog/presentation/pickers.dart';
import '../../records/domain/records.dart';

/// Diagnosis + prescriptions for one visit, with an AI interaction check before saving.
class WriteSessionPage extends StatefulWidget {
  const WriteSessionPage({super.key, required this.record});

  final MedicalRecord record;

  @override
  State<WriteSessionPage> createState() => _WriteSessionPageState();
}

class _WriteSessionPageState extends State<WriteSessionPage> {
  final _form = GlobalKey<FormState>();
  final _disease = TextEditingController();
  final _notes = TextEditingController();
  bool _chronic = false;
  bool _cured = false;
  final _lines = <NewPrescription>[];
  InteractionReport? _report;
  bool _checking = false;
  bool _saving = false;

  @override
  void dispose() {
    _disease.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _addLine(String drugId, String drugName) async {
    final line = await showModalBottomSheet<NewPrescription>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _LineSheet(drugId: drugId, drugName: drugName),
    );
    if (line != null) {
      setState(() {
        _lines.add(line);
        _report = null;
      });
    }
  }

  Future<void> _check() async {
    if (_lines.isEmpty) return;
    setState(() => _checking = true);
    try {
      final r = await context.read<Deps>().records.checkInteractions(widget.record.patient.email, _lines.map((l) => l.drugId).toList());
      if (mounted) setState(() => _report = r);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_report?.impact == true) {
      final go = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Interaction found'),
          content: const Text('The check flagged a possible interaction. Save this prescription anyway?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Review')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save anyway')),
          ],
        ),
      );
      if (go != true) return;
    }
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      await context.read<Deps>().records.writeSession(NewSession(
            patientEmail: widget.record.patient.email,
            diseaseName: _disease.text,
            sessionNotes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            persistent: _chronic,
            cured: _cured,
            prescriptions: _lines,
          ));
      if (!mounted) return;
      showSnack(context, 'Visit saved. The patient was notified.');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final report = _report;
    return Scaffold(
      appBar: AppBar(title: Text('New visit: ${widget.record.patient.firstName}')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 120), children: [
          if (widget.record.currentPrescriptions.isNotEmpty)
            AppCard(
              color: AppColors.warning.withValues(alpha: .1),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Currently taking', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(widget.record.currentPrescriptions.map((p) => p.drugName).join(', ')),
              ]),
            ).entrance(0),
          const SectionTitle('Diagnosis'),
          TextFormField(controller: _disease, decoration: const InputDecoration(labelText: 'Condition', prefixIcon: Icon(Icons.coronavirus_outlined)), validator: (v) => v == null || v.trim().length < 2 ? 'Enter the condition' : null).entrance(1),
          const SizedBox(height: 12),
          TextFormField(controller: _notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Visit notes', alignLabelWithHint: true)).entrance(2),
          Row(children: [
            Expanded(child: SwitchListTile(title: const Text('Chronic'), value: _chronic, onChanged: (v) => setState(() => _chronic = v), contentPadding: EdgeInsets.zero)),
            Expanded(child: SwitchListTile(title: const Text('Cured'), value: _cured, onChanged: (v) => setState(() => _cured = v), contentPadding: EdgeInsets.zero)),
          ]).entrance(3),
          const SectionTitle('Prescription'),
          DrugSearchField(label: 'Add a drug', onPicked: (d) => _addLine(d.id, d.name)).entrance(4),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            alignment: Alignment.topCenter,
            child: Column(children: [
              for (var i = 0; i < _lines.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Dismissible(
                    key: ValueKey('${_lines[i].drugId}-$i'),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => setState(() {
                      _lines.removeAt(i);
                      _report = null;
                    }),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    child: AppCard(
                      child: Row(children: [
                        const Icon(Icons.medication_rounded, color: AppColors.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_lines[i].drugName, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text([
                              if (_lines[i].repeat != null) _lines[i].repeat!,
                              '${_lines[i].repeatCount}x',
                              if (_lines[i].endDate != null) 'until ${DateFormat.MMMd().format(_lines[i].endDate!)}',
                            ].join(' · '), style: t.bodySmall),
                          ]),
                        ),
                        Icon(Icons.swipe_left_outlined, size: 18, color: Theme.of(context).colorScheme.outline),
                      ]),
                    ),
                  ).popIn(),
                ),
            ]),
          ),
          if (_lines.isNotEmpty) ...[
            OutlinedButton.icon(
              onPressed: _checking ? null : _check,
              icon: _checking ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.science_outlined),
              label: const Text('Check interactions'),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: report == null ? const SizedBox.shrink() : _ReportCard(report: report, key: ValueKey(report)),
            ),
          ],
        ]),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: PrimaryButton(label: 'Save visit', icon: Icons.check, busy: _saving, onPressed: _save),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({super.key, required this.report});

  final InteractionReport report;

  @override
  Widget build(BuildContext context) {
    final (color, icon, title) = !report.available
        ? (AppColors.warning, Icons.help_outline, 'Interaction model not available')
        : report.impact
            ? (AppColors.danger, Icons.warning_amber_rounded, 'Possible interaction')
            : (AppColors.accent, Icons.check_circle_outline, 'No interactions found');
    return AppCard(
      color: color.withValues(alpha: .1),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color).animate().scaleXY(begin: .5, end: 1, curve: Curves.elasticOut, duration: 600.ms),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        for (final p in report.pairs.where((p) => p.interacts != false))
          Padding(padding: const EdgeInsets.only(top: 4), child: Text('${p.drugA} + ${p.drugB}: ${p.description}')),
        if (report.available && !report.impact) const Text('Checked against each other and the patient\'s current medicines.'),
      ]),
    );
  }
}

class _LineSheet extends StatefulWidget {
  const _LineSheet({required this.drugId, required this.drugName});

  final String drugId;
  final String drugName;

  @override
  State<_LineSheet> createState() => _LineSheetState();
}

class _LineSheetState extends State<_LineSheet> {
  final _note = TextEditingController();
  String _repeat = 'daily';
  int _count = 1;
  int _days = 7;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.drugName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _repeat,
          decoration: const InputDecoration(labelText: 'How often'),
          items: const [
            DropdownMenuItem(value: 'daily', child: Text('Once a day')),
            DropdownMenuItem(value: 'every 12 hours', child: Text('Every 12 hours')),
            DropdownMenuItem(value: 'every 8 hours', child: Text('Every 8 hours')),
            DropdownMenuItem(value: 'weekly', child: Text('Once a week')),
            DropdownMenuItem(value: 'when needed', child: Text('When needed')),
          ],
          onChanged: (v) => setState(() => _repeat = v!),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Stepper(label: 'Per dose', value: _count, onChanged: (v) => setState(() => _count = v))),
          const SizedBox(width: 12),
          Expanded(child: _Stepper(label: 'Days', value: _days, step: 1, max: 365, onChanged: (v) => setState(() => _days = v))),
        ]),
        const SizedBox(height: 12),
        TextField(controller: _note, decoration: const InputDecoration(labelText: 'Note, e.g. after food')),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            NewPrescription(
              drugId: widget.drugId,
              drugName: widget.drugName,
              repeat: _repeat,
              repeatCount: _count,
              note: _note.text.trim().isEmpty ? null : _note.text.trim(),
              startDate: DateTime.now(),
              endDate: DateTime.now().add(Duration(days: _days)),
            ),
          ),
          child: const Text('Add to prescription'),
        ),
      ]),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.onChanged, this.step = 1, this.max = 20});

  final String label;
  final int value;
  final int step;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => InputDecorator(
        decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsets.symmetric(horizontal: 8)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(onPressed: value > 1 ? () => onChanged(value - step) : null, icon: const Icon(Icons.remove)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Text('$value', key: ValueKey(value), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          IconButton(onPressed: value < max ? () => onChanged(value + step) : null, icon: const Icon(Icons.add)),
        ]),
      );
}
