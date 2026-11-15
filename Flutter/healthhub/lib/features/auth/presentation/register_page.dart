import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../catalog/presentation/pickers.dart';
import '../domain/auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _nid = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  DateTime? _birth;
  String _gender = 'male';
  String? _areaId;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _nid, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now.subtract(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _birth = picked);
  }

  Future<void> _submit() async {
    final valid = _form.currentState!.validate();
    if (!valid || _birth == null) {
      if (_birth == null) showSnack(context, 'Pick your birth date', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<Deps>().auth.register(RegisterData(
            name: _name.text,
            email: _email.text,
            password: _password.text,
            phone: _phone.text,
            birthDate: _birth!,
            nationalId: _nid.text,
            gender: _gender,
            areaId: _areaId!,
          ));
      if (!mounted) return;
      showSnack(context, 'Account created. You can log in now.');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[
      TextFormField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)), validator: Validators.name),
      TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)), validator: Validators.email),
      TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile number', prefixIcon: Icon(Icons.phone_outlined)), validator: Validators.phone),
      TextFormField(controller: _nid, keyboardType: TextInputType.number, maxLength: 14, decoration: const InputDecoration(labelText: 'National ID', prefixIcon: Icon(Icons.badge_outlined), counterText: ''), validator: Validators.nationalId),
      InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _pickBirth,
        child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Birth date', prefixIcon: Icon(Icons.cake_outlined)),
          child: Text(_birth == null ? 'Tap to pick' : DateFormat.yMMMd().format(_birth!)),
        ),
      ),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'male', label: Text('Male'), icon: Icon(Icons.male)),
          ButtonSegment(value: 'female', label: Text('Female'), icon: Icon(Icons.female)),
        ],
        selected: {_gender},
        onSelectionChanged: (s) => setState(() => _gender = s.first),
      ),
      AreaPicker(onChanged: (_, area) => _areaId = area),
      TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline), helperText: 'Upper and lower case, a number and a symbol', helperMaxLines: 2), validator: Validators.password),
      TextFormField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_reset)), validator: Validators.match(() => _password.text)),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Create your account')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            for (var i = 0; i < fields.length; i++) Padding(padding: const EdgeInsets.only(bottom: 14), child: fields[i].entrance(i)),
            const SizedBox(height: 8),
            PrimaryButton(label: 'Create account', icon: Icons.check, busy: _busy, onPressed: _submit).entrance(fields.length),
          ],
        ),
      ),
    );
  }
}
