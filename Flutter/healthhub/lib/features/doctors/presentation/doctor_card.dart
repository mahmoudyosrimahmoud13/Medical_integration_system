import 'package:flutter/material.dart';

import '../../../core/navigation/app_route.dart';
import '../../../core/widgets/common.dart';
import '../domain/doctors.dart';
import 'doctor_details_page.dart';

class RatingStars extends StatelessWidget {
  const RatingStars(this.value, {super.key, this.size = 16, this.count});

  final double value;
  final double size;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 1; i <= 5; i++)
        Icon(
          value >= i ? Icons.star_rounded : (value >= i - .5 ? Icons.star_half_rounded : Icons.star_outline_rounded),
          size: size,
          color: const Color(0xFFFFB020),
        ),
      if (count != null) ...[
        const SizedBox(width: 4),
        Text('($count)', style: Theme.of(context).textTheme.bodySmall),
      ],
    ]);
  }
}

class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key, required this.doctor, this.trailing});

  final DoctorSummary doctor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: () => context.push(DoctorDetailsPage(doctorId: doctor.id, preview: doctor)),
      child: Row(children: [
        Avatar(name: doctor.name, url: doctor.imageUrl, radius: 32, heroTag: 'doctor-${doctor.id}'),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dr. ${doctor.name}', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(doctor.specialty, style: t.bodyMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(children: [
              RatingStars(doctor.ratingStars, size: 15, count: doctor.reviewCount),
              const Spacer(),
              if (doctor.price > 0)
                Text('${doctor.price.toStringAsFixed(0)} EGP', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.location_on_outlined, size: 14, color: scheme.outline),
              const SizedBox(width: 2),
              Expanded(
                child: Text('${doctor.area}, ${doctor.governorate}', style: t.bodySmall, overflow: TextOverflow.ellipsis),
              ),
            ]),
          ]),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}
