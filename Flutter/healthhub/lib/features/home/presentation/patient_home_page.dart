import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di.dart';
import '../../../core/navigation/app_route.dart';
import '../../../core/state/load_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/clay.dart';
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
import '../../../core/i18n/i18n.dart';

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
    final greeting = hour < 12 ? tr('Good morning') : (hour < 18 ? tr('Good afternoon') : tr('Good evening'));

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
                    Text(tr('Search doctors, specialties...'), style: TextStyle(color: Theme.of(context).colorScheme.outline)),
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
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.25,
                // a little room so the soft clay shadows are not cut off at the edges
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  _Action(icon: Icons.medical_services_rounded, label: tr('Book a doctor'), tint: Clay.lilac, color: AppColors.primary, onTap: () => context.push(const FindDoctorsPage(showBack: true))).entrance(1),
                  _Action(icon: Icons.local_pharmacy_rounded, label: tr('Find a medicine'), tint: Clay.mint, color: const Color(0xFF12A383), onTap: () => context.push(const FindPharmacyPage())).entrance(2),
                  _Action(icon: Icons.local_hospital_rounded, label: tr('Hospitals'), tint: Clay.butter, color: const Color(0xFFC98A00), onTap: () => context.push(const HospitalsPage())).entrance(3),
                  _Action(icon: Icons.qr_code_2_rounded, label: tr('Share prescriptions'), tint: Clay.blush, color: AppColors.danger, onTap: () => showShareCodeSheet(context)).entrance(4),
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
    final when = days == 0 ? tr('Today') : (days == 1 ? tr('Tomorrow') : DateFormat.MMMEd(AppSettings.dateLocale).format(appointment.day));
    return ClayCard(
      onTap: () => context.push(const AppointmentsPage()),
      tint: Clay.mint,
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Avatar(name: d?.name ?? '', url: d?.imageUrl, radius: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('Next visit · {date} at {time}', {'date': when, 'time': clock(appointment.from)}), style: const TextStyle(fontWeight: FontWeight.w800)),
            if (d != null) Text('${tr('Dr. {name}', {'name': d.name})}${tr(', ')}${tr(d.specialty)}'),
            if (d != null) Text('${place(d.area)}${tr(', ')}${place(d.governorate)}', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        const Icon(Icons.chevron_right),
      ]),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap, required this.tint, required this.color});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color tint; // the pastel clay colour of the card
  final Color color; // the icon colour

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      onTap: onTap,
      tint: tint,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        ClayBubble(icon: icon, color: color, size: 50),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ]),
    );
  }
}
