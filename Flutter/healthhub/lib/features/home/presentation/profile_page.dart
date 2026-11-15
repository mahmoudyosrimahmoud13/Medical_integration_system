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
import '../../../core/i18n/i18n.dart';
import '../../../core/server/server_settings.dart';
import '../../server/server_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _changePhoto(BuildContext context) async {
    final session = context.read<SessionCubit>();
    final auth = context.read<Deps>().auth;
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (file == null) return;
    try {
      session.updateUser(await auth.changePhoto(await file.readAsBytes(), file.name));
      if (context.mounted) showSnack(context, tr('Photo updated'));
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
              Text('${place(user.area!.name, user.area!.nameAr)}${tr(', ')}${place(user.governorate?.name, user.governorate?.nameAr)}', style: const TextStyle(color: Colors.white70)),
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
                    label: Text(tr(w.label)),
                    selected: state.workspace == w,
                    onSelected: (_) => context.read<SessionCubit>().switchWorkspace(w),
                  ),
              ]).entrance(0),
            ],
            const SectionTitle('Appearance'),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('Theme'), style: t.labelLarge),
                const SizedBox(height: 8),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: AppSettings.themeMode,
                  builder: (context, mode, _) => SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode_outlined), label: Text(tr('Light'))),
                      ButtonSegment(value: ThemeMode.system, icon: const Icon(Icons.brightness_auto_outlined), label: Text(tr('Auto'))),
                      ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode_outlined), label: Text(tr('Dark'))),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) => AppSettings.setThemeMode(s.first),
                  ),
                ),
                const SizedBox(height: 16),
                Text(tr('Language'), style: t.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'en', label: Text('English')),
                    ButtonSegment(value: 'ar', label: Text('العربية')),
                  ],
                  selected: {AppSettings.lang.value},
                  onSelectionChanged: (s) => AppSettings.setLang(s.first),
                ),
              ]),
            ).entrance(1),
            const SectionTitle('Server'),
            AppCard(
              padding: EdgeInsets.zero,
              child: ValueListenableBuilder<String?>(
                valueListenable: ServerSettings.url,
                builder: (context, url, _) => ListTile(
                  key: const Key('profile-server'),
                  leading: const Icon(Icons.dns_outlined),
                  title: Text(tr('Server address'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(url ?? tr('Not set'), textDirection: TextDirection.ltr),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(const ServerPage()),
                ),
              ),
            ).entrance(1),
            const SectionTitle('Account'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                _Row(icon: Icons.notifications_none_rounded, label: tr('Notifications'), onTap: () => context.push(const NotificationsPage())),
                if (!user.hasRole('Doctor')) _Row(icon: Icons.medical_information_outlined, label: tr('Join as a doctor'), onTap: () => context.push(const DoctorApplyPage())),
                if (!user.hasRole('Pharmacy')) _Row(icon: Icons.local_pharmacy_outlined, label: tr('Register a pharmacy'), onTap: () => context.push(const PharmacyHomePage(standalone: true))),
                if (!user.hasRole('Hospital')) _Row(icon: Icons.local_hospital_outlined, label: tr('Register a hospital'), onTap: () => context.push(const HospitalHomePage(standalone: true))),
              ]),
            ).entrance(1),
            const SizedBox(height: 16),
            AppCard(
              padding: EdgeInsets.zero,
              child: _Row(
                icon: Icons.logout_rounded,
                label: tr('Log out'),
                color: AppColors.danger,
                onTap: () => context.read<SessionCubit>().logout(),
              ),
            ).entrance(2),
            const SizedBox(height: 24),
            Center(child: Opacity(opacity: .6, child: Column(children: [const AppWordmark(size: 24), const SizedBox(height: 4), Text(tr('Version 2.0'), style: t.bodySmall)]))),
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
