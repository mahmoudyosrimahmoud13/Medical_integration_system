import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/state/load_cubit.dart';
import '../../../core/utils/time_slots.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../doctors/domain/doctors.dart';

/// Weekly working hours and visit price.
class DoctorSchedulePage extends StatelessWidget {
  const DoctorSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoadCubit<List<ScheduleDay>>(context.read<Deps>().doctorPortal.schedule),
      child: const _ScheduleView(),
    );
  }
}

class _ScheduleView extends StatefulWidget {
  const _ScheduleView();

  @override
  State<_ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<_ScheduleView> {
  final Map<String, (int from, int to)> _days = {}; // minutes after midnight
  bool _loadedOnce = false;
  bool _saving = false;
  bool _dirty = false;

  void _seed(List<ScheduleDay> days) {
    if (_loadedOnce) return;
    _loadedOnce = true;
    for (final d in days) {
      final f = parseClock(d.from), t = parseClock(d.to);
      if (f != null && t != null) _days[d.day] = (f, t);
    }
  }

  Future<void> _edit(String day) async {
    final current = _days[day] ?? (9 * 60, 17 * 60);
    final from = await showTimePicker(context: context, initialTime: TimeOfDay(hour: current.$1 ~/ 60, minute: current.$1 % 60), helpText: '$day: start');
    if (from == null || !mounted) return;
    final to = await showTimePicker(context: context, initialTime: TimeOfDay(hour: current.$2 ~/ 60, minute: current.$2 % 60), helpText: '$day: end');
    if (to == null) return;
    final f = from.hour * 60 + from.minute, t = to.hour * 60 + to.minute;
    if (t <= f) {
      if (mounted) showSnack(context, 'End time must be after start time', error: true);
      return;
    }
    setState(() {
      _days[day] = (f, t);
      _dirty = true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<Deps>().doctorPortal.saveSchedule([
        for (final e in _days.entries) ScheduleDay(day: e.key, from: formatClock(e.value.$1), to: formatClock(e.value.$2)),
      ]);
      if (!mounted) return;
      setState(() => _dirty = false);
      showSnack(context, 'Schedule saved. Patients see the new hours now.');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _price() async {
    final c = TextEditingController();
    final v = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Visit price'),
        content: TextField(controller: c, keyboardType: TextInputType.number, autofocus: true, decoration: const InputDecoration(suffixText: 'EGP')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(c.text)), child: const Text('Save')),
        ],
      ),
    );
    if (v == null || !mounted) return;
    try {
      await context.read<Deps>().doctorPortal.setPrice(v);
      if (mounted) showSnack(context, 'Price updated');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<LoadCubit<List<ScheduleDay>>>();
    if (cubit.state.data != null) _seed(cubit.state.data!);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Working hours'),
        actions: [IconButton(onPressed: _price, icon: const Icon(Icons.payments_outlined), tooltip: 'Visit price')],
      ),
      body: AsyncBody<List<ScheduleDay>>(
        state: cubit.state,
        onRetry: cubit.load,
        builder: (_) => ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 120), children: [
          Text('Tap a day to turn it on, then tap the hours to change them. Visits are one hour each.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          for (var i = 0; i < weekdays.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Builder(builder: (context) {
                final day = weekdays[i];
                final on = _days.containsKey(day);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: on ? scheme.primaryContainer.withValues(alpha: .45) : scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: on ? scheme.primary.withValues(alpha: .4) : scheme.outlineVariant.withValues(alpha: .5)),
                  ),
                  child: Row(children: [
                    Switch(
                      value: on,
                      onChanged: (v) => setState(() {
                        if (v) {
                          _days[day] = (9 * 60, 17 * 60);
                        } else {
                          _days.remove(day);
                        }
                        _dirty = true;
                      }),
                    ),
                    Expanded(child: Text(day, style: TextStyle(fontWeight: FontWeight.w700, color: on ? null : scheme.outline))),
                    if (on)
                      TextButton.icon(
                        onPressed: () => _edit(day),
                        icon: const Icon(Icons.schedule, size: 18),
                        label: Text('${formatClock(_days[day]!.$1)} - ${formatClock(_days[day]!.$2)}'),
                      ),
                    const SizedBox(width: 8),
                  ]),
                ).entrance(i);
              }),
            ),
        ]),
      ),
      bottomNavigationBar: AnimatedSlide(
        offset: _dirty ? Offset.zero : const Offset(0, 1.2),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: SafeArea(minimum: const EdgeInsets.all(16), child: PrimaryButton(label: 'Save schedule', icon: Icons.check, busy: _saving, onPressed: _save)),
      ),
    );
  }
}
