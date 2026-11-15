import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../core/navigation/app_route.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../records/domain/records.dart';
import '../../records/presentation/record_view.dart';
import 'write_session_page.dart';

/// Look up a patient by email, read the record, and write a new visit.
class DoctorPatientsPage extends StatefulWidget {
  const DoctorPatientsPage({super.key});

  @override
  State<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends State<DoctorPatientsPage> {
  final _email = TextEditingController();
  MedicalRecord? _record;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _lookup([String? email]) async {
    final value = (email ?? _email.text).trim();
    if (Validators.email(value) != null) {
      showSnack(context, 'Enter the patient\'s email', error: true);
      return;
    }
    if (email != null) _email.text = email;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await context.read<Deps>().records.patientRecord(value);
      if (mounted) setState(() => _record = r);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _record = null;
          _error = e.isNotFound ? 'No patient with this email.' : e.message;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;
    return Scaffold(
      body: Column(children: [
        GradientHeader(
          subtitle: 'Patients',
          title: 'Medical records',
          bottom: TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _lookup(),
            decoration: InputDecoration(
              hintText: "Patient's email",
              prefixIcon: const Icon(Icons.person_search_outlined),
              suffixIcon: IconButton(onPressed: _lookup, icon: const Icon(Icons.arrow_forward)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _loading
                ? const SkeletonList(key: ValueKey('l'))
                : _error != null
                    ? ErrorView(key: const ValueKey('e'), message: _error!)
                    : record == null
                        ? const EmptyView(key: ValueKey('empty'), title: 'Find a patient', message: 'Enter the email the patient registered with to open their record.')
                        : RecordView(
                            key: ValueKey(record.patient.id),
                            record: record,
                            header: AppCard(
                              child: Row(children: [
                                Avatar(name: record.patient.name, url: record.patient.imageUrl, radius: 26),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(record.patient.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                    Text([record.patient.gender, if (record.patient.age != null) '${record.patient.age} years', if (record.patient.phone != null) record.patient.phone!].join(' · ')),
                                  ]),
                                ),
                              ]),
                            ).entrance(0),
                          ),
          ),
        ),
      ]),
      floatingActionButton: record == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final written = await context.push<bool>(WriteSessionPage(record: record));
                if (written == true) _lookup(record.patient.email);
              },
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('New visit'),
            ).popIn(),
    );
  }
}
