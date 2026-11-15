import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../domain/records.dart';

/// The medical record body, shared by the patient's own record and a doctor's patient lookup.
class RecordView extends StatelessWidget {
  const RecordView({super.key, required this.record, this.header, this.footer});

  final MedicalRecord record;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    var i = 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (header != null) header!,
        Row(children: [
          Expanded(child: StatTile(label: 'Active drugs', value: record.currentPrescriptions.length, icon: Icons.medication_outlined)),
          const SizedBox(width: 10),
          Expanded(child: StatTile(label: 'Visits', value: record.sessions.length, icon: Icons.event_note_outlined, color: AppColors.accent)),
          const SizedBox(width: 10),
          Expanded(child: StatTile(label: 'Chronic', value: record.chronic.length, icon: Icons.favorite_outline, color: AppColors.danger)),
        ]).entrance(i++),
        const SectionTitle('Current medicines'),
        if (record.currentPrescriptions.isEmpty)
          const AppCard(child: Text('No active prescriptions.'))
        else
          for (final p in record.currentPrescriptions) Padding(padding: const EdgeInsets.only(bottom: 10), child: PrescriptionTile(p).entrance(i++)),
        if (record.diseases.isNotEmpty) ...[
          const SectionTitle('Conditions'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final d in record.diseases)
              Chip(
                avatar: Icon(
                  d.cured ? Icons.check_circle : (d.persistent ? Icons.all_inclusive : Icons.circle_outlined),
                  size: 18,
                  color: d.cured ? AppColors.accent : (d.persistent ? AppColors.danger : AppColors.warning),
                ),
                label: Text(d.name),
              ),
          ]).entrance(i++),
        ],
        const SectionTitle('Visit history'),
        if (record.sessions.isEmpty)
          const AppCard(child: Text('No visits recorded yet.'))
        else
          for (final s in record.sessions) Padding(padding: const EdgeInsets.only(bottom: 10), child: SessionTile(s).entrance(i++)),
        if (record.ctScans.isNotEmpty) ...[
          const SectionTitle('Scans'),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: record.ctScans.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, k) {
                final c = record.ctScans[k];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(children: [
                    Image.network(c.url, width: 120, height: 120, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 120, color: Colors.black12, child: const Icon(Icons.description_outlined, size: 40))),
                    if (c.uploadedAt != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          color: Colors.black45,
                          padding: const EdgeInsets.all(4),
                          child: Text(DateFormat.yMMMd().format(c.uploadedAt!), style: const TextStyle(color: Colors.white, fontSize: 11), textAlign: TextAlign.center),
                        ),
                      ),
                  ]),
                ).entrance(k, dy: 0);
              },
            ),
          ),
        ],
        if (footer != null) footer!,
      ],
    );
  }
}

class PrescriptionTile extends StatelessWidget {
  const PrescriptionTile(this.p, {super.key});

  final Prescription p;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final dates = [
      if (p.startDate != null) 'from ${DateFormat.MMMd().format(p.startDate!)}',
      if (p.endDate != null) 'until ${DateFormat.yMMMd().format(p.endDate!)}',
    ].join(' ');
    return AppCard(
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(gradient: AppColors.mintGradient, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.medication_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.drugName, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            Text([if (p.repeat != null) p.repeat!, '${p.repeatCount}x'].join(' · '), style: t.bodyMedium),
            if (dates.isNotEmpty) Text(dates, style: t.bodySmall),
            if (p.note != null && p.note!.isNotEmpty) Text(p.note!, style: t.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
          ]),
        ),
      ]),
    );
  }
}

class SessionTile extends StatelessWidget {
  const SessionTile(this.s, {super.key});

  final MedicalSession s;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        leading: Avatar(name: s.doctor.name, url: s.doctor.imageUrl, radius: 20),
        title: Text(s.diseaseName, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text('Dr. ${s.doctor.name} · ${DateFormat.yMMMd().format(s.date)}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.notes != null && s.notes!.isNotEmpty) ...[Text(s.notes!), const SizedBox(height: 10)],
          for (final p in s.prescriptions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                const Icon(Icons.circle, size: 6),
                const SizedBox(width: 8),
                Expanded(child: Text('${p.drugName}${p.repeat == null ? '' : ' · ${p.repeat}'}')),
              ]),
            ),
          if (s.doctor.phone != null) ...[const SizedBox(height: 8), InfoRow(icon: Icons.phone_outlined, text: s.doctor.phone!)],
        ],
      ),
    );
  }
}
