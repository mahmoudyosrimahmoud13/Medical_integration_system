import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di.dart';
import '../../../core/navigation/app_route.dart';
import '../../../core/state/load_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../appointments/domain/appointments.dart';
import '../../appointments/presentation/appointments_page.dart';
import '../../auth/presentation/session_cubit.dart';
import '../../catalog/domain/catalog.dart';
import '../../doctors/presentation/find_doctors_page.dart';
import '../../hospital/presentation/hospitals_page.dart';
import '../../notifications/presentation/notifications_page.dart';
import '../../pharmacy/presentation/find_pharmacy_page.dart';
import '../../records/presentation/records_page.dart';

class PatientHomePage extends StatelessWidget {
  const PatientHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = context.read<Deps>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LoadCubit<List<Appointment>>(deps.appointments.mine)),
        BlocProvider(create: (_) => LoadCubit<List<Specialty>>(deps.catalog.specialties)),
      ],
      child: const _PatientHomeView(),
    );
  }
}

class _PatientHomeView extends StatelessWidget {
  const _PatientHomeView();

  @override
  Widget build(BuildContext context) {
    final user = context.select((SessionCubit c) => c.state.user);
    final appts = context.watch<LoadCubit<List<Appointment>>>();
    final specs = context.watch<LoadCubit<List<Specialty>>>().state.data ?? const <Specialty>[];
    final next = (appts.state.data ?? const <Appointment>[]).firstOrNull;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 18 ? 'Good afternoon' : 'Good evening');

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: appts.load,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              subtitle: greeting,
              title: user?.firstName ?? 'there',
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  onPressed: () => context.push(const NotificationsPage()),
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                ),
                Avatar(name: user?.name ?? '', url: user?.imageUrl, radius: 22),
              ]),
              bottom: Pressable(
                onTap: () => context.push(const FindDoctorsPage(showBack: true)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Icon(Icons.search, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(width: 10),
                    Text('Search doctors, specialties...', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                  ]),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList.list(children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: next == null
                    ? const SizedBox.shrink()
                    : _NextVisit(key: ValueKey(next.id), appointment: next).entrance(0),
              ),
              const SectionTitle('What do you need?'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  _Action(icon: Icons.medical_services_rounded, label: 'Book a doctor', gradient: AppColors.heroGradient, onTap: () => context.push(const FindDoctorsPage(showBack: true))).entrance(1),
                  _Action(icon: Icons.local_pharmacy_rounded, label: 'Find a medicine', gradient: AppColors.mintGradient, onTap: () => context.push(const FindPharmacyPage())).entrance(2),
                  _Action(icon: Icons.local_hospital_rounded, label: 'Hospitals', color: AppColors.warning, onTap: () => context.push(const HospitalsPage())).entrance(3),
                  _Action(icon: Icons.qr_code_2_rounded, label: 'Share prescriptions', color: AppColors.danger, onTap: () => showShareCodeSheet(context)).entrance(4),
                ],
              ),
              if (specs.isNotEmpty) ...[
                const SectionTitle('Browse by specialty'),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: specs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ActionChip(
                      label: Text(specs[i].name),
                      onPressed: () => context.push(FindDoctorsPage(initialSpecialtyId: specs[i].id, showBack: true)),
                    ).entrance(i, dy: 0, baseDelayMs: 25),
                  ),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _NextVisit extends StatelessWidget {
  const _NextVisit({super.key, required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final d = appointment.doctor;
    final days = appointment.day.difference(DateUtils.dateOnly(DateTime.now())).inDays;
    final when = days == 0 ? 'Today' : (days == 1 ? 'Tomorrow' : DateFormat.MMMEd().format(appointment.day));
    return AppCard(
      onTap: () => context.push(const AppointmentsPage()),
      color: AppColors.accent.withValues(alpha: .12),
      child: Row(children: [
        Avatar(name: d?.name ?? '', url: d?.imageUrl, radius: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Next visit · $when at ${appointment.from}', style: const TextStyle(fontWeight: FontWeight.w800)),
            if (d != null) Text('Dr. ${d.name}, ${d.specialty}'),
            if (d != null) Text('${d.area}, ${d.governorate}', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        const Icon(Icons.chevron_right),
      ]),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap, this.gradient, this.color});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Gradient? gradient;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final onColor = gradient != null ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? color!.withValues(alpha: .14) : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, color: gradient != null ? Colors.white : color, size: 30),
          Text(label, style: TextStyle(color: onColor, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      ),
    );
  }
}
