import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_slots.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../doctors/domain/doctors.dart';
import '../domain/appointments.dart';

/// Opens the booking flow. Returns the new appointment, or null if the user closed it.
/// Pass [reschedule] to move an existing appointment instead of booking a new one.
Future<Appointment?> showBookingSheet(BuildContext context, Doctor doctor, {Appointment? reschedule}) {
  return showModalBottomSheet<Appointment>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: .82,
      child: BookingSheet(doctor: doctor, reschedule: reschedule),
    ),
  );
}

class BookingSheet extends StatefulWidget {
  const BookingSheet({super.key, required this.doctor, this.reschedule});

  final Doctor doctor;
  final Appointment? reschedule;

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  late final List<DateTime> _days = workingDays(widget.doctor.schedule.map((s) => s.day));
  DateTime? _day;
  List<Slot> _slots = const [];
  Slot? _slot;
  bool _loadingSlots = false;
  bool _booking = false;
  Appointment? _done;

  @override
  void initState() {
    super.initState();
    if (_days.isNotEmpty) _selectDay(_days.first);
  }

  ScheduleDay? _windowFor(DateTime day) {
    final name = weekdayName(day);
    for (final s in widget.doctor.schedule) {
      if (s.day == name) return s;
    }
    return null;
  }

  Future<void> _selectDay(DateTime day) async {
    setState(() {
      _day = day;
      _slot = null;
      _loadingSlots = true;
    });
    final window = _windowFor(day);
    var booked = <String>[];
    try {
      final taken = await context.read<Deps>().appointments.bookedSlots(widget.doctor.id, day);
      booked = taken.map((b) => b.from).toList();
      // Moving my own appointment: its current hour should look free.
      final mine = widget.reschedule;
      if (mine != null && DateUtils.isSameDay(mine.day, day)) booked.remove(mine.from);
    } catch (_) {
      // show the slots anyway; the server still refuses taken ones
    }
    if (!mounted || _day != day) return;
    setState(() {
      _slots = window == null ? const [] : buildSlots(from: window.from, to: window.to, day: day, booked: booked);
      _loadingSlots = false;
    });
  }

  Future<void> _book() async {
    if (_day == null || _slot == null) return;
    setState(() => _booking = true);
    final repo = context.read<Deps>().appointments;
    try {
      final appt = widget.reschedule == null
          ? await repo.book(doctorId: widget.doctor.id, day: _day!, from: _slot!.label)
          : await repo.reschedule(widget.reschedule!.id, day: _day!, from: _slot!.label);
      if (!mounted) return;
      setState(() => _done = appt);
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      if (mounted) Navigator.of(context).pop(appt);
    } on ApiException catch (e) {
      if (!mounted) return;
      showSnack(context, e.message, error: true);
      _selectDay(_day!); // refresh, the slot may have just been taken
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done != null) return _Success(appointment: _done!, doctor: widget.doctor);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.reschedule == null ? 'Book with Dr. ${widget.doctor.name}' : 'Move your appointment',
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Each visit is one hour.', style: t.bodySmall),
        const SizedBox(height: 16),
        Text('Day', style: t.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final d = _days[i];
              final selected = _day != null && DateUtils.isSameDay(d, _day);
              return Pressable(
                onTap: () => _selectDay(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  width: 66,
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.heroGradient : null,
                    color: selected ? null : scheme.surfaceContainerHighest.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(DateFormat.E().format(d), style: TextStyle(color: selected ? Colors.white70 : scheme.outline, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${d.day}', style: TextStyle(color: selected ? Colors.white : scheme.onSurface, fontSize: 22, fontWeight: FontWeight.w800)),
                    Text(DateFormat.MMM().format(d), style: TextStyle(color: selected ? Colors.white70 : scheme.outline, fontSize: 11)),
                  ]),
                ),
              ).entrance(i, dy: 0, baseDelayMs: 30);
            },
          ),
        ),
        const SizedBox(height: 20),
        Text('Time', style: t.labelLarge),
        const SizedBox(height: 8),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _loadingSlots
                ? const Center(key: ValueKey('l'), child: CircularProgressIndicator())
                : _slots.isEmpty
                    ? const Center(key: ValueKey('e'), child: Text('No free hours on this day. Try another day.'))
                    : GridView.builder(
                        key: ValueKey(_day),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 120, mainAxisExtent: 48, crossAxisSpacing: 10, mainAxisSpacing: 10),
                        itemCount: _slots.length,
                        itemBuilder: (_, i) {
                          final slot = _slots[i];
                          final selected = _slot == slot;
                          return Pressable(
                            onTap: slot.available ? () => setState(() => _slot = slot) : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: !slot.available
                                    ? scheme.surfaceContainerHighest.withValues(alpha: .4)
                                    : selected
                                        ? scheme.primary
                                        : scheme.primaryContainer.withValues(alpha: .5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                slot.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: !slot.available ? scheme.outline : (selected ? Colors.white : scheme.onPrimaryContainer),
                                  decoration: slot.available ? null : TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ).entrance(i, dy: .2, baseDelayMs: 25);
                        },
                      ),
          ),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: _slot == null ? 'Pick a time' : (widget.reschedule == null ? 'Book ${_slot!.label}' : 'Move to ${_slot!.label}'),
          icon: Icons.check,
          busy: _booking,
          onPressed: _slot == null ? null : _book,
        ),
      ]),
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({required this.appointment, required this.doctor});

  final Appointment appointment;
  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 110,
          height: 110,
          decoration: const BoxDecoration(gradient: AppColors.mintGradient, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 64),
        ).popIn(),
        const SizedBox(height: 20),
        Text("You're booked!", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))
            .animate()
            .fadeIn(delay: 250.ms),
        const SizedBox(height: 8),
        Text(
          '${appointment.dayName}, ${DateFormat.yMMMd().format(appointment.day)}\n${appointment.from} with Dr. ${doctor.name}',
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms),
      ]),
    );
  }
}
