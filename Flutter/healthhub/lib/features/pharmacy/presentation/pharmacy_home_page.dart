import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/state/load_cubit.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../doctor_portal/domain/doctor_portal.dart';
import '../../doctor_portal/presentation/doctor_apply_page.dart';
import '../../records/presentation/record_view.dart';
import '../domain/pharmacy.dart';
import 'facility_apply_form.dart';
import '../../../core/i18n/i18n.dart';

/// Pharmacy counter: enter a patient's share code to see what to dispense.
/// When opened from the profile by someone without a pharmacy, it shows the application form.
class PharmacyHomePage extends StatelessWidget {
  const PharmacyHomePage({super.key, this.standalone = false});

  final bool standalone;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoadCubit<(ApplicationStatus, Pharmacy?)>(context.read<Deps>().pharmacy.mine),
      child: Builder(builder: (context) {
        final cubit = context.watch<LoadCubit<(ApplicationStatus, Pharmacy?)>>();
        return Scaffold(
          appBar: standalone ? AppBar(title: Text(tr('Register a pharmacy'))) : null,
          body: AsyncBody<(ApplicationStatus, Pharmacy?)>(
            state: cubit.state,
            onRetry: cubit.load,
            builder: (data) {
              final (status, pharmacy) = data;
              if (status.isNone || status.isRejected) {
                return FacilityApplyForm(
                  kind: 'pharmacy',
                  onSubmit: (a) async {
                    try {
                      await context.read<Deps>().pharmacy.apply(a);
                      cubit.load();
                    } on ApiException catch (e) {
                      if (context.mounted) showSnack(context, e.message, error: true);
                    }
                  },
                );
              }
              if (!status.isAccepted) return StatusCard(status: status, kind: 'pharmacy');
              if (standalone) return StatusCard(status: status, kind: 'pharmacy');
              return _Counter(pharmacy: pharmacy!);
            },
          ),
        );
      }),
    );
  }
}

class _Counter extends StatefulWidget {
  const _Counter({required this.pharmacy});

  final Pharmacy pharmacy;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  final _code = TextEditingController();
  SharedPrescriptions? _result;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    if (_code.text.trim().length < 4) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await context.read<Deps>().pharmacy.prescriptionsByCode(_code.text);
      if (mounted) setState(() => _result = r);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _result = null;
          _error = e.message;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Column(children: [
      GradientHeader(
        subtitle: widget.pharmacy.name,
        title: tr('Counter'),
        bottom: TextField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _lookup(),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 4),
          decoration: InputDecoration(
            hintText: tr('PATIENT CODE'),
            hintStyle: const TextStyle(letterSpacing: 2, fontSize: 16, fontWeight: FontWeight.w500),
            prefixIcon: const Icon(Icons.qr_code_2_rounded),
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
              ? const SkeletonList(key: ValueKey('l'), count: 3)
              : _error != null
                  ? ErrorView(key: const ValueKey('e'), message: _error!)
                  : result == null
                      ? EmptyView(
                          key: ValueKey('empty'),
                          title: tr('Ask the patient for their code'),
                          message: tr('Patients make a 6-character code in the HealthHub app. It shows their current prescriptions for 30 minutes.'),
                        )
                      : ListView(
                          key: ValueKey(result),
                          padding: const EdgeInsets.all(16),
                          children: [
                            Text(tr('Prescriptions for {name}', {'name': result.patientName}), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)).animate().fadeIn(),
                            const SizedBox(height: 12),
                            if (result.prescriptions.isEmpty) AppCard(child: Text(tr('This patient has no active prescriptions.'))),
                            for (var i = 0; i < result.prescriptions.length; i++)
                              Padding(padding: const EdgeInsets.only(bottom: 10), child: PrescriptionTile(result.prescriptions[i]).entrance(i)),
                          ],
                        ),
        ),
      ),
    ]);
  }
}
