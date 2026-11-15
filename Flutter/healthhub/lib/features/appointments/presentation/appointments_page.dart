import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/state/load_cubit.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../domain/appointments.dart';
import 'booking_sheet.dart';
import '../../../core/i18n/i18n.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoadCubit<List<Appointment>>(() => context.read<Deps>().appointments.mine()),
      child: const _AppointmentsView(),
    );
  }
}

class _AppointmentsView extends StatelessWidget {
  const _AppointmentsView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<LoadCubit<List<Appointment>>>();
    return Scaffold(
      body: Column(children: [
        GradientHeader(subtitle: tr('Your visits'), title: tr('Appointments')),
        Expanded(
          child: AsyncBody<List<Appointment>>(
            state: cubit.state,
            onRetry: cubit.load,
            isEmpty: (d) => d.isEmpty,
            empty: EmptyView(
              image: 'assets/images/booking.svg',
              title: tr('No upcoming appointments'),
              message: tr('Find a doctor and book a time that suits you.'),
            ),
            builder: (items) => RefreshIndicator(
              onRefresh: cubit.load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => AppointmentCard(appointment: items[i], onChanged: cubit.load).entrance(i),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// A date block plus doctor details, with move and cancel actions.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({super.key, required this.appointment, this.onChanged, this.showPatient = false, this.onCancel});

  final Appointment appointment;
  final VoidCallback? onChanged;
  final bool showPatient;
  final Future<void> Function()? onCancel;

  Future<void> _cancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('Cancel appointment?')),
        content: Text(tr('{day} {date} at {time}', {'day': tr(appointment.dayName), 'date': DateFormat.yMMMd(AppSettings.dateLocale).format(appointment.day), 'time': clock(appointment.from)})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('Keep it'))),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: Text(tr('Cancel it'))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      if (onCancel != null) {
        await onCancel!();
      } else {
        await context.read<Deps>().appointments.cancel(appointment.id);
      }
      if (context.mounted) showSnack(context, tr('Appointment cancelled'));
      onChanged?.call();
    } on ApiException catch (e) {
      if (context.mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _move(BuildContext context) async {
    final doctorId = appointment.doctor?.id;
    if (doctorId == null) return;
    try {
      final doctor = await context.read<Deps>().doctors.details(doctorId);
      if (!context.mounted) return;
      final moved = await showBookingSheet(context, doctor, reschedule: appointment);
      if (moved != null) onChanged?.call();
    } on ApiException catch (e) {
      if (context.mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final d = appointment.doctor;
    final p = appointment.patient;
    return AppCard(
      child: Column(children: [
        Row(children: [
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Text(DateFormat.MMM(AppSettings.dateLocale).format(appointment.day).toUpperCase(), style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 12, fontWeight: FontWeight.w700)),
              Text('${appointment.day.day}', style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 24, fontWeight: FontWeight.w800)),
              Text(DateFormat.E(AppSettings.dateLocale).format(appointment.day), style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 12)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (showPatient && p != null) ...[
                Text(p.name, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text([tr(p.gender), if (p.age != null) tr('{n} years', {'n': p.age}), if (p.phone != null) p.phone!].join(' · '), style: t.bodySmall),
              ] else if (d != null) ...[
                Text('Dr. ${d.name}', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text(tr(d.specialty), style: t.bodyMedium?.copyWith(color: scheme.primary)),
                Text('${place(d.area)}${tr(', ')}${place(d.governorate)}', style: t.bodySmall),
              ],
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.schedule, size: 16, color: scheme.outline),
                const SizedBox(width: 4),
                Text('${clock(appointment.from)} - ${clock(appointment.to)}', style: t.labelLarge),
              ]),
            ]),
          ),
          if (showPatient && d != null) Avatar(name: d.name, url: d.imageUrl, radius: 18),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          if (!showPatient)
            Expanded(child: OutlinedButton.icon(onPressed: () => _move(context), icon: const Icon(Icons.edit_calendar_outlined, size: 18), label: Text(tr('Move')))),
          if (!showPatient) const SizedBox(width: 10),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () => _cancel(context),
              icon: const Icon(Icons.close, size: 18),
              label: Text(tr('Cancel')),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            ),
          ),
        ]),
      ]),
    );
  }
}
