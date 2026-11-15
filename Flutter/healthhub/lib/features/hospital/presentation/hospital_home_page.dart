import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/state/load_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../appointments/domain/appointments.dart';
import '../../appointments/presentation/appointments_page.dart';
import '../../doctor_portal/domain/doctor_portal.dart';
import '../../doctor_portal/presentation/doctor_apply_page.dart';
import '../../doctors/presentation/doctor_card.dart';
import '../../pharmacy/presentation/facility_apply_form.dart';
import '../domain/hospital.dart';

/// Hospital manager: departments and doctors, plus the appointments booked with them.
class HospitalHomePage extends StatelessWidget {
  const HospitalHomePage({super.key, this.standalone = false});

  final bool standalone;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoadCubit<(ApplicationStatus, Hospital?)>(context.read<Deps>().hospital.mine),
      child: Builder(builder: (context) {
        final cubit = context.watch<LoadCubit<(ApplicationStatus, Hospital?)>>();
        return Scaffold(
          appBar: standalone ? AppBar(title: const Text('Register a hospital')) : null,
          body: AsyncBody<(ApplicationStatus, Hospital?)>(
            state: cubit.state,
            onRetry: cubit.load,
            builder: (data) {
              final (status, hospital) = data;
              if (status.isNone || status.isRejected) {
                return FacilityApplyForm(
                  kind: 'hospital',
                  withDescription: true,
                  onSubmit: (a) async {
                    try {
                      await context.read<Deps>().hospital.apply(a);
                      cubit.load();
                    } on ApiException catch (e) {
                      if (context.mounted) showSnack(context, e.message, error: true);
                    }
                  },
                );
              }
              if (!status.isAccepted || standalone) return StatusCard(status: status, kind: 'hospital');
              return _Manage(hospital: hospital!, onChanged: cubit.load);
            },
          ),
        );
      }),
    );
  }
}

class _Manage extends StatelessWidget {
  const _Manage({required this.hospital, required this.onChanged});

  final Hospital hospital;
  final VoidCallback onChanged;

  Future<void> _addDoctor(BuildContext context) async {
    final email = TextEditingController();
    final dept = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add a doctor'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: "Doctor's HealthHub email")),
          const SizedBox(height: 12),
          TextField(controller: dept, decoration: const InputDecoration(labelText: 'Department')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (Validators.email(email.text) != null) {
      showSnack(context, 'Enter a valid email', error: true);
      return;
    }
    try {
      await context.read<Deps>().hospital.addDoctor(email.text, dept.text);
      onChanged();
      if (context.mounted) showSnack(context, 'Doctor added');
    } on ApiException catch (e) {
      if (context.mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(children: [
        GradientHeader(
          subtitle: 'Hospital workspace',
          title: hospital.name,
          bottom: Container(
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
            child: const TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(14))),
              labelColor: AppColors.navy,
              unselectedLabelColor: Colors.white,
              dividerColor: Colors.transparent,
              tabs: [Tab(text: 'Doctors'), Tab(text: 'Appointments')],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(children: [
            _Doctors(hospital: hospital, onAdd: () => _addDoctor(context), onChanged: onChanged),
            const _HospitalAppointments(),
          ]),
        ),
      ]),
    );
  }
}

class _Doctors extends StatelessWidget {
  const _Doctors({required this.hospital, required this.onAdd, required this.onChanged});

  final Hospital hospital;
  final VoidCallback onAdd;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final departments = hospital.departments;
    var i = 0;
    return Scaffold(
      body: departments.isEmpty
          ? EmptyView(title: 'No doctors yet', message: 'Add doctors by their HealthHub email and group them into departments.', action: FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add a doctor')))
          : ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
              for (final e in departments.entries) ...[
                SectionTitle(e.key),
                for (final d in e.value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DoctorCard(
                      doctor: d,
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                        onPressed: () async {
                          try {
                            await context.read<Deps>().hospital.removeDoctor(d.id);
                            onChanged();
                          } on ApiException catch (err) {
                            if (context.mounted) showSnack(context, err.message, error: true);
                          }
                        },
                      ),
                    ).entrance(i++),
                  ),
              ],
            ]),
      floatingActionButton: departments.isEmpty ? null : FloatingActionButton.extended(onPressed: onAdd, icon: const Icon(Icons.person_add_alt_1), label: const Text('Add doctor')),
    );
  }
}

class _HospitalAppointments extends StatelessWidget {
  const _HospitalAppointments();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoadCubit<List<Appointment>>(context.read<Deps>().hospital.appointments),
      child: Builder(builder: (context) {
        final cubit = context.watch<LoadCubit<List<Appointment>>>();
        return AsyncBody<List<Appointment>>(
          state: cubit.state,
          onRetry: cubit.load,
          isEmpty: (d) => d.isEmpty,
          empty: const EmptyView(image: 'assets/images/booking.svg', title: 'No upcoming appointments', message: 'Bookings with your doctors show up here.'),
          builder: (items) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => IgnorePointer(child: AppointmentCard(appointment: items[i], showPatient: true)).entrance(i),
          ),
        );
      }),
    );
  }
}
