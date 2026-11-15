import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di.dart';
import '../../../core/navigation/app_route.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/session_cubit.dart';
import '../../doctor_portal/presentation/doctor_apply_page.dart';
import '../../hospital/presentation/hospital_home_page.dart';
import '../../notifications/presentation/notifications_page.dart';
import '../../pharmacy/presentation/pharmacy_home_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _changePhoto(BuildContext context) async {
    final session = context.read<SessionCubit>();
    final auth = context.read<Deps>().auth;
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (file == null) return;
    try {
      session.updateUser(await auth.changePhoto(await file.readAsBytes(), file.name));
      if (context.mounted) showSnack(context, 'Photo updated');
    } on ApiException catch (e) {
      if (context.mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SessionCubit>().state;
    final user = state.user;
    if (user == null) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    final workspaces = user.workspaces;

    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 24, 20, 28),
          decoration: const BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))),
          child: Column(children: [
            Stack(children: [
              Avatar(name: user.name, url: user.imageUrl, radius: 46),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _changePhoto(context),
                    child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.camera_alt, size: 18)),
                  ),
                ),
              ),
            ]).animate().scaleXY(begin: .8, end: 1, curve: Curves.easeOutBack),
            const SizedBox(height: 12),
            Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            Text(user.email, style: const TextStyle(color: Colors.white70)),
            if (user.area != null)
              Text('${user.area!.name}, ${user.governorate?.name ?? ''}', style: const TextStyle(color: Colors.white70)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (workspaces.length > 1) ...[
              const SectionTitle('Workspace'),
              Wrap(spacing: 8, children: [
                for (final w in workspaces)
                  ChoiceChip(
                    label: Text(w.label),
                    selected: state.workspace == w,
                    onSelected: (_) => context.read<SessionCubit>().switchWorkspace(w),
                  ),
              ]).entrance(0),
            ],
            const SectionTitle('Account'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                _Row(icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: () => context.push(const NotificationsPage())),
                if (!user.hasRole('Doctor')) _Row(icon: Icons.medical_information_outlined, label: 'Join as a doctor', onTap: () => context.push(const DoctorApplyPage())),
                if (!user.hasRole('Pharmacy')) _Row(icon: Icons.local_pharmacy_outlined, label: 'Register a pharmacy', onTap: () => context.push(const PharmacyHomePage(standalone: true))),
                if (!user.hasRole('Hospital')) _Row(icon: Icons.local_hospital_outlined, label: 'Register a hospital', onTap: () => context.push(const HospitalHomePage(standalone: true))),
              ]),
            ).entrance(1),
            const SizedBox(height: 16),
            AppCard(
              padding: EdgeInsets.zero,
              child: _Row(
                icon: Icons.logout_rounded,
                label: 'Log out',
                color: AppColors.danger,
                onTap: () => context.read<SessionCubit>().logout(),
              ),
            ).entrance(2),
            const SizedBox(height: 24),
            Center(child: Opacity(opacity: .6, child: Column(children: [const AppWordmark(size: 24), const SizedBox(height: 4), Text('Version 2.0', style: t.bodySmall)]))),
          ]),
        ),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        trailing: color == null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      );
}
