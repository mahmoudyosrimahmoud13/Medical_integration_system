import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../core/state/load_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../appointments/domain/appointments.dart';
import '../../appointments/presentation/appointments_page.dart';
import '../../auth/presentation/session_cubit.dart';
import '../domain/doctor_portal.dart';

/// Doctor's day: stats and the upcoming booked patients.
class DoctorHomePage extends StatelessWidget {
  const DoctorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<Deps>().doctorPortal;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LoadCubit<DoctorStats>(repo.stats)),
        BlocProvider(create: (_) => LoadCubit<List<Appointment>>(repo.appointments)),
      ],
      child: const _DoctorHomeView(),
    );
  }
}

class _DoctorHomeView extends StatelessWidget {
  const _DoctorHomeView();

  @override
  Widget build(BuildContext context) {
    final user = context.select((SessionCubit c) => c.state.user);
    final stats = context.watch<LoadCubit<DoctorStats>>().state.data ?? const DoctorStats();
    final appts = context.watch<LoadCubit<List<Appointment>>>();
    final repo = context.read<Deps>().doctorPortal;

    Future<void> refresh() async {
      await Future.wait([context.read<LoadCubit<DoctorStats>>().load(), appts.load()]);
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: refresh,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              subtitle: 'Doctor workspace',
              title: 'Dr. ${user?.firstName ?? ''}',
              trailing: Avatar(name: user?.name ?? '', url: user?.imageUrl, radius: 22),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList.list(children: [
              Row(children: [
                Expanded(child: StatTile(label: 'Upcoming', value: stats.upcoming, icon: Icons.event_available_outlined)),
                const SizedBox(width: 10),
                Expanded(child: StatTile(label: 'Patients', value: stats.total, icon: Icons.people_outline, color: AppColors.accent)),
                const SizedBox(width: 10),
                Expanded(child: StatTile(label: 'Women', value: stats.total == 0 ? 0 : (stats.female * 100 / stats.total).round(), icon: Icons.female, color: AppColors.danger)),
              ]).entrance(0),
              const SectionTitle('Booked patients'),
              AsyncBody<List<Appointment>>(
                state: appts.state,
                onRetry: appts.load,
                loading: const SkeletonList(count: 3),
                isEmpty: (d) => d.isEmpty,
                empty: const EmptyView(image: 'assets/images/booking.svg', title: 'No bookings yet', message: 'Patients can book once your schedule is published.'),
                builder: (items) => Column(children: [
                  for (var i = 0; i < items.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppointmentCard(
                        appointment: items[i],
                        showPatient: true,
                        onCancel: () => repo.cancelAppointment(items[i].id),
                        onChanged: refresh,
                      ).entrance(i + 1),
                    ),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
