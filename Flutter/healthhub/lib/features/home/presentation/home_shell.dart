import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../admin/presentation/admin_page.dart';
import '../../appointments/presentation/appointments_page.dart';
import '../../auth/domain/auth.dart';
import '../../auth/presentation/session_cubit.dart';
import '../../doctor_portal/presentation/doctor_home_page.dart';
import '../../doctor_portal/presentation/doctor_patients_page.dart';
import '../../doctor_portal/presentation/doctor_schedule_page.dart';
import '../../doctors/presentation/find_doctors_page.dart';
import '../../hospital/presentation/hospital_home_page.dart';
import '../../pharmacy/presentation/pharmacy_home_page.dart';
import '../../pharmacy/presentation/pharmacy_stock_page.dart';
import '../../records/presentation/records_page.dart';
import 'patient_home_page.dart';
import 'profile_page.dart';

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon, this.page);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}

/// Bottom navigation. The tabs depend on the active workspace (patient, doctor, pharmacy, hospital, admin).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  List<_Tab> _tabsFor(Workspace w) => switch (w) {
        Workspace.patient => const [
            _Tab('Home', Icons.home_outlined, Icons.home_rounded, PatientHomePage()),
            _Tab('Doctors', Icons.search, Icons.search, FindDoctorsPage()),
            _Tab('Visits', Icons.calendar_today_outlined, Icons.calendar_today_rounded, AppointmentsPage()),
            _Tab('Record', Icons.folder_outlined, Icons.folder_rounded, RecordsPage()),
            _Tab('Profile', Icons.person_outline, Icons.person_rounded, ProfilePage()),
          ],
        Workspace.doctor => const [
            _Tab('Today', Icons.dashboard_outlined, Icons.dashboard_rounded, DoctorHomePage()),
            _Tab('Patients', Icons.people_outline, Icons.people_rounded, DoctorPatientsPage()),
            _Tab('Schedule', Icons.schedule_outlined, Icons.schedule_rounded, DoctorSchedulePage()),
            _Tab('Profile', Icons.person_outline, Icons.person_rounded, ProfilePage()),
          ],
        Workspace.pharmacy => const [
            _Tab('Counter', Icons.local_pharmacy_outlined, Icons.local_pharmacy_rounded, PharmacyHomePage()),
            _Tab('Stock', Icons.inventory_2_outlined, Icons.inventory_2_rounded, PharmacyStockPage()),
            _Tab('Profile', Icons.person_outline, Icons.person_rounded, ProfilePage()),
          ],
        Workspace.hospital => const [
            _Tab('Hospital', Icons.local_hospital_outlined, Icons.local_hospital_rounded, HospitalHomePage()),
            _Tab('Profile', Icons.person_outline, Icons.person_rounded, ProfilePage()),
          ],
        Workspace.admin => const [
            _Tab('Requests', Icons.fact_check_outlined, Icons.fact_check_rounded, AdminPage()),
            _Tab('Profile', Icons.person_outline, Icons.person_rounded, ProfilePage()),
          ],
      };

  @override
  Widget build(BuildContext context) {
    final workspace = context.select((SessionCubit c) => c.state.workspace);
    final tabs = _tabsFor(workspace);
    final index = _index.clamp(0, tabs.length - 1);
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(position: Tween(begin: const Offset(0, .02), end: Offset.zero).animate(a), child: child),
        ),
        child: KeyedSubtree(key: ValueKey('$workspace-$index'), child: tabs[index].page),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in tabs) NavigationDestination(icon: Icon(t.icon), selectedIcon: Icon(t.selectedIcon), label: t.label),
        ],
      ),
    );
  }
}
