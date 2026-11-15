import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/state/load_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../domain/records.dart';
import 'record_view.dart';
import '../../../core/i18n/i18n.dart';

/// The patient's own medical record, with a share code for pharmacies and scan upload.
class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoadCubit<MedicalRecord>(() => context.read<Deps>().records.myRecord()),
      child: const _RecordsView(),
    );
  }
}

class _RecordsView extends StatelessWidget {
  const _RecordsView();

  Future<void> _upload(BuildContext context) async {
    final cubit = context.read<LoadCubit<MedicalRecord>>();
    final repo = context.read<Deps>().records;
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    try {
      await repo.uploadCt(await file.readAsBytes(), file.name);
      cubit.load();
      if (context.mounted) showSnack(context, tr('Scan added to your record'));
    } on ApiException catch (e) {
      if (context.mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<LoadCubit<MedicalRecord>>();
    return Scaffold(
      body: Column(children: [
        GradientHeader(
          subtitle: tr('Medical record'),
          title: tr('Your health, in one place'),
          bottom: Row(children: [
            Expanded(
              child: _HeaderAction(icon: Icons.qr_code_2_rounded, label: tr('Share with pharmacy'), onTap: () => showShareCodeSheet(context)),
            ),
            const SizedBox(width: 10),
            Expanded(child: _HeaderAction(icon: Icons.add_photo_alternate_outlined, label: tr('Add a scan'), onTap: () => _upload(context))),
          ]),
        ),
        Expanded(
          child: AsyncBody<MedicalRecord>(
            state: cubit.state,
            onRetry: cubit.load,
            builder: (r) => RefreshIndicator(onRefresh: cubit.load, child: RecordView(record: r)),
          ),
        ),
      ]),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          ]),
        ),
      );
}

Future<void> showShareCodeSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => RepositoryProvider.value(value: context.read<Deps>(), child: const _ShareCodeSheet()),
    );

class _ShareCodeSheet extends StatefulWidget {
  const _ShareCodeSheet();

  @override
  State<_ShareCodeSheet> createState() => _ShareCodeSheetState();
}

class _ShareCodeSheetState extends State<_ShareCodeSheet> {
  ShareCode? _code;
  String? _error;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _create();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _error = null);
    try {
      final code = await context.read<Deps>().records.shareCode();
      if (!mounted) return;
      setState(() => _code = code);
      _tick?.cancel();
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final code = _code;
    final left = code == null ? Duration.zero : code.expiresAt.difference(DateTime.now());
    final expired = code != null && left.isNegative;
    final fraction = code == null ? 0.0 : (left.inSeconds / (30 * 60)).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(tr('Show this code at the pharmacy'), style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(tr('The pharmacist can see your current prescriptions for 30 minutes.'), style: t.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        if (_error != null) ErrorView(message: _error!, onRetry: _create),
        if (_error == null && code == null) const CircularProgressIndicator(),
        if (code != null)
          Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 200,
              height: 200,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: const Duration(milliseconds: 800),
                builder: (_, v, __) => CircularProgressIndicator(
                  value: v,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  color: expired ? AppColors.danger : AppColors.accent,
                ),
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(code.code, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 4)).popIn(),
              const SizedBox(height: 6),
              Text(
                expired ? tr('Expired') : '${left.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, '0')} left',
                style: t.labelLarge?.copyWith(color: expired ? AppColors.danger : null),
              ).animate(key: ValueKey(expired)).fadeIn(),
            ]),
          ]),
        const SizedBox(height: 24),
        if (expired) PrimaryButton(label: tr('Get a new code'), onPressed: _create),
      ]),
    );
  }
}
