import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/state/load_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/session_cubit.dart';
import '../../catalog/presentation/pickers.dart';
import '../domain/doctor_portal.dart';

/// Shows the current application status, or the form to apply as a doctor.
class DoctorApplyPage extends StatelessWidget {
  const DoctorApplyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoadCubit<ApplicationStatus>(context.read<Deps>().doctorPortal.status),
      child: Builder(builder: (context) {
        final cubit = context.watch<LoadCubit<ApplicationStatus>>();
        return Scaffold(
          appBar: AppBar(title: const Text('Join as a doctor')),
          body: AsyncBody<ApplicationStatus>(
            state: cubit.state,
            onRetry: cubit.load,
            builder: (s) => s.isNone || s.isRejected ? _ApplyForm(rejected: s.isRejected, onDone: cubit.load) : StatusCard(status: s, kind: 'doctor'),
          ),
        );
      }),
    );
  }
}

/// "Under review" / "Accepted" card used by doctor, pharmacy and hospital applications.
class StatusCard extends StatelessWidget {
  const StatusCard({super.key, required this.status, required this.kind});

  final ApplicationStatus status;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final accepted = status.isAccepted;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: accepted ? AppColors.mintGradient : null,
              color: accepted ? null : AppColors.warning.withValues(alpha: .15),
              shape: BoxShape.circle,
            ),
            child: Icon(accepted ? Icons.verified_rounded : Icons.hourglass_top_rounded, size: 48, color: accepted ? Colors.white : AppColors.warning),
          ).popIn(),
          const SizedBox(height: 20),
          Text(accepted ? 'You are approved' : 'Under review', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))
              .animate()
              .fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            accepted
                ? 'Your $kind workspace is ready. Switch to it from your profile.'
                : 'Our team checks every $kind request. You will get a notification when it is reviewed.',
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
          if (accepted) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                final session = context.read<SessionCubit>();
                if (status.accessToken != null) await context.read<Deps>().auth.useToken(status.accessToken!);
                await session.refresh();
                if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: const Text('Open my workspace'),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ]),
      ),
    );
  }
}

class _ApplyForm extends StatefulWidget {
  const _ApplyForm({required this.rejected, required this.onDone});

  final bool rejected;
  final VoidCallback onDone;

  @override
  State<_ApplyForm> createState() => _ApplyFormState();
}

class _ApplyFormState extends State<_ApplyForm> {
  final _form = GlobalKey<FormState>();
  final _college = TextEditingController();
  final _summary = TextEditingController();
  final _address = TextEditingController();
  String? _specialty;
  String? _area;
  DateTime? _graduation;
  final _files = <({List<int> bytes, String name})>[];
  bool _busy = false;

  @override
  void dispose() {
    _college.dispose();
    _summary.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true, type: FileType.custom, allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg']);
    if (result == null) return;
    setState(() {
      for (final f in result.files) {
        if (f.bytes != null) _files.add((bytes: f.bytes!, name: f.name));
      }
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_files.isEmpty) {
      showSnack(context, 'Add at least one certificate', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<Deps>().doctorPortal.apply(DoctorApplication(
            specialtyId: _specialty!,
            areaId: _area!,
            college: _college.text,
            graduationYear: _graduation,
            summary: _summary.text,
            address: _address.text,
            certificates: _files,
          ));
      if (mounted) showSnack(context, 'Request sent');
      widget.onDone();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[
      if (widget.rejected)
        AppCard(
          color: AppColors.danger.withValues(alpha: .08),
          child: const Text('Your previous request was not approved. You can send a new one with updated details.'),
        ),
      SpecialtyPicker(required: true, onChanged: (v) => _specialty = v),
      AreaPicker(onChanged: (_, a) => _area = a),
      TextFormField(controller: _college, decoration: const InputDecoration(labelText: 'Medical school', prefixIcon: Icon(Icons.school_outlined)), validator: (v) => v == null || v.trim().length < 3 ? 'Enter your medical school' : null),
      InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final d = await showDatePicker(context: context, initialDate: DateTime(DateTime.now().year - 5), firstDate: DateTime(1960), lastDate: DateTime.now());
          if (d != null) setState(() => _graduation = d);
        },
        child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Graduation year', prefixIcon: Icon(Icons.event_outlined)),
          child: Text(_graduation == null ? 'Tap to pick' : '${_graduation!.year}'),
        ),
      ),
      TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Clinic address', prefixIcon: Icon(Icons.place_outlined))),
      TextFormField(controller: _summary, maxLines: 4, decoration: const InputDecoration(labelText: 'About you (shown to patients)', alignLabelWithHint: true)),
      AppCard(
        onTap: _pickFiles,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.upload_file_outlined),
            const SizedBox(width: 10),
            Expanded(child: Text(_files.isEmpty ? 'Add certificates (PDF or photo)' : '${_files.length} file${_files.length == 1 ? '' : 's'} attached', style: const TextStyle(fontWeight: FontWeight.w600))),
            const Icon(Icons.add),
          ]),
          if (_files.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final f in _files) InputChip(label: Text(f.name, overflow: TextOverflow.ellipsis), onDeleted: () => setState(() => _files.remove(f))),
            ]),
          ],
        ]),
      ),
    ];
    return Form(
      key: _form,
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
        for (var i = 0; i < fields.length; i++) Padding(padding: const EdgeInsets.only(bottom: 14), child: fields[i].entrance(i)),
        PrimaryButton(label: 'Send request', icon: Icons.send_rounded, busy: _busy, onPressed: _submit).entrance(fields.length),
      ]),
    );
  }
}
