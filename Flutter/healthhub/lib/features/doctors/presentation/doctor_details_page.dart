import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/state/load_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../appointments/presentation/booking_sheet.dart';
import '../../chat/presentation/new_message_page.dart';
import '../domain/doctors.dart';
import 'doctor_card.dart';

class DoctorDetailsPage extends StatelessWidget {
  const DoctorDetailsPage({super.key, required this.doctorId, this.preview});

  final String doctorId;
  final DoctorSummary? preview; // shown instantly while the full profile loads

  @override
  Widget build(BuildContext context) {
    final repo = context.read<Deps>().doctors;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LoadCubit<Doctor>(() => repo.details(doctorId))),
        BlocProvider(create: (_) => LoadCubit<List<Review>>(() => repo.reviews(doctorId))),
      ],
      child: _DetailsView(doctorId: doctorId, preview: preview),
    );
  }
}

class _DetailsView extends StatelessWidget {
  const _DetailsView({required this.doctorId, this.preview});

  final String doctorId;
  final DoctorSummary? preview;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LoadCubit<Doctor>>().state;
    final DoctorSummary? d = state.data ?? preview;
    final full = state.data;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 270,
          pinned: true,
          stretch: true,
          foregroundColor: Colors.white,
          actions: [
            if (full != null && full.userId.isNotEmpty)
              IconButton(
                tooltip: 'Message',
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () => NewMessagePage.open(context, userId: full.userId, subject: 'Question for Dr. ${full.name}'),
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: Container(
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              child: SafeArea(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 24),
                  Avatar(name: d?.name ?? '', url: d?.imageUrl, radius: 52, heroTag: 'doctor-$doctorId'),
                  const SizedBox(height: 12),
                  Text('Dr. ${d?.name ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))
                      .animate()
                      .fadeIn(delay: 150.ms),
                  Text(d?.specialty ?? '', style: const TextStyle(color: Colors.white70)).animate().fadeIn(delay: 250.ms),
                  const SizedBox(height: 8),
                  if (d != null) RatingStars(d.ratingStars, size: 18, count: d.reviewCount).animate().fadeIn(delay: 350.ms),
                ]),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          sliver: SliverList.list(children: [
            if (d != null)
              Row(children: [
                Expanded(child: _Pill(icon: Icons.payments_outlined, label: 'Visit', value: d.price > 0 ? '${d.price.toStringAsFixed(0)} EGP' : 'Ask clinic')),
                const SizedBox(width: 10),
                Expanded(child: _Pill(icon: Icons.reviews_outlined, label: 'Reviews', value: '${d.reviewCount}')),
                const SizedBox(width: 10),
                Expanded(child: _Pill(icon: Icons.location_city_outlined, label: 'Area', value: d.area)),
              ]).entrance(0),
            if (full == null && state.status == LoadStatus.failure)
              Padding(padding: const EdgeInsets.only(top: 24), child: ErrorView(message: state.error ?? '', onRetry: context.read<LoadCubit<Doctor>>().load)),
            if (full == null && state.isLoading) const Padding(padding: EdgeInsets.only(top: 24), child: SkeletonList(count: 2)),
            if (full != null) ...[
              if (full.summary.isNotEmpty) ...[
                const SectionTitle('About'),
                AppCard(child: Text(full.summary, style: t.bodyMedium?.copyWith(height: 1.5))).entrance(1),
              ],
              const SectionTitle('Clinic'),
              AppCard(
                child: Column(children: [
                  InfoRow(icon: Icons.place_outlined, text: [full.address, full.area, full.governorate].where((s) => s.isNotEmpty).join(', ')),
                  if (full.phone != null) InfoRow(icon: Icons.phone_outlined, text: full.phone!),
                  if (full.college.isNotEmpty)
                    InfoRow(
                      icon: Icons.school_outlined,
                      text: full.graduationYear == null ? full.college : '${full.college}, class of ${full.graduationYear!.year}',
                    ),
                ]),
              ).entrance(2),
              const SectionTitle('Working hours'),
              if (full.schedule.isEmpty)
                const AppCard(child: Text('This doctor has not published working hours yet.'))
              else
                AppCard(
                  child: Column(children: [
                    for (final s in full.schedule)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          Text(s.day, style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text('${s.from} - ${s.to}'),
                        ]),
                      ),
                  ]),
                ).entrance(3),
              SectionTitle('Reviews', action: TextButton(onPressed: () => _rate(context), child: const Text('Rate'))),
              const _Reviews(),
            ],
          ]),
        ),
      ]),
      bottomNavigationBar: full == null || full.schedule.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: 'Book an appointment',
                icon: Icons.calendar_month_outlined,
                onPressed: () => showBookingSheet(context, full),
              ).animate().slideY(begin: 1, end: 0, duration: 450.ms, curve: Curves.easeOutCubic),
            ),
    );
  }

  Future<void> _rate(BuildContext context) async {
    final repo = context.read<Deps>().doctors;
    final reviews = context.read<LoadCubit<List<Review>>>();
    final doctor = context.read<LoadCubit<Doctor>>();
    final result = await showDialog<(double, String)>(context: context, builder: (_) => const _RateDialog());
    if (result == null || !context.mounted) return;
    try {
      await repo.addReview(doctorId, result.$1, result.$2);
      reviews.load();
      doctor.load();
      if (context.mounted) showSnack(context, 'Thanks for your review!');
    } on ApiException catch (e) {
      if (context.mounted) showSnack(context, e.message, error: true);
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 6),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ]),
      );
}

class _Reviews extends StatelessWidget {
  const _Reviews();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LoadCubit<List<Review>>>().state;
    final items = s.data ?? const <Review>[];
    if (s.isLoading && items.isEmpty) return const SkeletonList(count: 2, itemHeight: 70);
    if (items.isEmpty) return const AppCard(child: Text('No reviews yet. Be the first after your visit.'));
    return Column(children: [
      for (var i = 0; i < items.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Avatar(name: items[i].patientName, radius: 16),
                const SizedBox(width: 10),
                Expanded(child: Text(items[i].patientName, style: const TextStyle(fontWeight: FontWeight.w700))),
                RatingStars(items[i].rate, size: 14),
              ]),
              if (items[i].message.isNotEmpty) ...[const SizedBox(height: 8), Text(items[i].message)],
              if (items[i].sentAt != null) ...[
                const SizedBox(height: 4),
                Text(DateFormat.yMMMd().format(items[i].sentAt!), style: Theme.of(context).textTheme.bodySmall),
              ],
            ]),
          ),
        ).entrance(i),
    ]);
  }
}

class _RateDialog extends StatefulWidget {
  const _RateDialog();

  @override
  State<_RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends State<_RateDialog> {
  int _rate = 5;
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate your visit'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 1; i <= 5; i++)
            IconButton(
              onPressed: () => setState(() => _rate = i),
              icon: AnimatedScale(
                scale: i <= _rate ? 1.15 : 1,
                duration: const Duration(milliseconds: 200),
                child: Icon(i <= _rate ? Icons.star_rounded : Icons.star_outline_rounded, color: const Color(0xFFFFB020), size: 34),
              ),
            ),
        ]),
        TextField(controller: _text, maxLines: 3, decoration: const InputDecoration(hintText: 'Tell others about your visit (optional)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, (_rate.toDouble(), _text.text.trim())), child: const Text('Send')),
      ],
    );
  }
}
