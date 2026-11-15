import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/di.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common.dart';
import '../../../core/i18n/i18n.dart';

/// Two steps: send a reset code to the email, then enter the code and a new password.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = context.read<Deps>().auth;
    try {
      if (!_codeSent) {
        await auth.forgotPassword(_email.text);
        if (!mounted) return;
        setState(() => _codeSent = true);
        showSnack(context, tr('If this email is registered, a code is on its way.'));
      } else {
        await auth.resetPassword(_code.text, _password.text);
        if (!mounted) return;
        showSnack(context, tr('Password changed. Log in with your new password.'));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Reset password'))),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          SvgPicture.asset('assets/images/forgot_password.svg', height: 200).animate().fadeIn().scaleXY(begin: .9, end: 1),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SizeTransition(sizeFactor: a, child: c)),
            child: !_codeSent
                ? Column(key: const ValueKey('email'), children: [
                    const Text("Enter your email and we'll send you a reset code."),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: tr('Email'), prefixIcon: Icon(Icons.email_outlined)),
                      validator: Validators.email,
                    ),
                  ])
                : Column(key: const ValueKey('code'), children: [
                    Text(tr('We sent a code to {email}. Paste it below and choose a new password.', {'email': _email.text})),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _code,
                      decoration: InputDecoration(labelText: tr('Reset code'), prefixIcon: Icon(Icons.key_outlined)),
                      validator: (v) => Validators.required(v, 'The code'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: InputDecoration(labelText: tr('New password'), prefixIcon: Icon(Icons.lock_outline)),
                      validator: Validators.password,
                    ),
                  ]),
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: _codeSent ? tr('Change password') : tr('Send code'), busy: _busy, onPressed: _submit),
        ]),
      ),
    );
  }
}
