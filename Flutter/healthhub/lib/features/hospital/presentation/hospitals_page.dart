import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../core/navigation/app_route.dart';
import '../../../core/state/load_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../doctors/presentation/doctor_card.dart';
import '../domain/hospital.dart';

/// Patient side: browse hospitals and their departments.
class HospitalsPage extends StatelessWidget {
  const HospitalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoadCubit<List<Hospital>>(() => context.read<Deps>().hospital.find()),
      child: Builder(builder: (context) {
        final cubit = context.watch<LoadCubit<List<Hospital>>>();
        return Scaffold(
          appBar: AppBar(title: const Text('Hospitals')),
          body: AsyncBody<List<Hospital>>(
            state: cubit.state,
            onRetry: cubit.load,
            isEmpty: (d) => d.isEmpty,
            empty: const EmptyView(title: 'No hospitals yet', message: 'Hospitals appear here once they join HealthHub.'),
            builder: (items) => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => HospitalCard(hospital: items[i]).entrance(i),
            ),
          ),
        );
      }),
    );
  }
}

class HospitalCard extends StatelessWidget {
  const HospitalCard({super.key, required this.hospital});

  final Hospital hospital;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      onTap: () => context.push(HospitalDetailsPage(hospital: hospital)),
      child: Row(children: [
        Hero(
          tag: 'hospital-${hospital.id}',
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(hospital.name, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text('${hospital.area}, ${hospital.governorate}', style: t.bodySmall),
            const SizedBox(height: 4),
            Text('${hospital.doctors.length} doctor${hospital.doctors.length == 1 ? '' : 's'} · ${hospital.departments.length} department${hospital.departments.length == 1 ? '' : 's'}',
                style: t.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
          ]),
        ),
        const Icon(Icons.chevron_right),
      ]),
    );
  }
}

class HospitalDetailsPage extends StatelessWidget {
  const HospitalDetailsPage({super.key, required this.hospital});

  final Hospital hospital;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final departments = hospital.departments;
    var i = 0;
    return Scaffold(
      appBar: AppBar(title: Text(hospital.name)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        AppCard(
          child: Row(children: [
            Hero(
              tag: 'hospital-${hospital.id}',
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 36),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(hospital.name, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                if (hospital.description.isNotEmpty) Text(hospital.description),
                InfoRow(icon: Icons.place_outlined, text: [hospital.address, hospital.area, hospital.governorate].where((s) => s.isNotEmpty).join(', ')),
                if (hospital.phone != null) InfoRow(icon: Icons.phone_outlined, text: hospital.phone!),
              ]),
            ),
          ]),
        ).entrance(i++),
        if (departments.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 24), child: Text('No doctors listed yet.'))
        else
          for (final entry in departments.entries) ...[
            SectionTitle(entry.key),
            for (final d in entry.value) Padding(padding: const EdgeInsets.only(bottom: 10), child: DoctorCard(doctor: d).entrance(i++)),
          ],
      ]),
    );
  }
}
