import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/navigation/app_route.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import 'session_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // On success the app gate swaps this page for the home screen.
      await context.read<SessionCubit>().login(_login.text, _password.text);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Stack(children: [
        Container(height: 300, decoration: const BoxDecoration(gradient: AppColors.heroGradient)),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(children: [
                  const SizedBox(height: 12),
                  const PulsingLogo(size: 76).animate().fadeIn().scaleXY(begin: .6, end: 1, curve: Curves.easeOutBack),
                  const SizedBox(height: 12),
                  const Text('Welcome back', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800))
                      .animate()
                      .fadeIn(delay: 120.ms)
                      .slideY(begin: .3, end: 0),
                  const Text('Log in to continue to HealthHub', style: TextStyle(color: Colors.white70))
                      .animate()
                      .fadeIn(delay: 200.ms),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _form,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          TextFormField(
                            key: const Key('login-email'),
                            controller: _login,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(labelText: 'Email or username', prefixIcon: Icon(Icons.alternate_email)),
                            validator: (v) => Validators.required(v, 'Email or username'),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            key: const Key('login-password'),
                            controller: _password,
                            obscureText: _hide,
                            onFieldSubmitted: (_) => _submit(),
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined, key: ValueKey(_hide)),
                                ),
                                onPressed: () => setState(() => _hide = !_hide),
                              ),
                            ),
                            validator: Validators.loginPassword,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push(const ForgotPasswordPage()),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            child: _error == null
                                ? const SizedBox.shrink()
                                : Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger.withValues(alpha: .1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(children: [
                                      const Icon(Icons.error_outline, color: AppColors.danger),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger))),
                                    ]),
                                  ).animate().shakeX(hz: 4, amount: 4, duration: 400.ms),
                          ),
                          PrimaryButton(key: const Key('login-submit'), label: 'Log in', busy: _busy, onPressed: _submit),
                        ]),
                      ),
                    ),
                  ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: .08, end: 0),
                  const SizedBox(height: 16),
                  // Wrap, not Row: on narrow phones or with large text the link moves to its own line.
                  Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text('New to HealthHub?', style: t.bodyMedium),
                    TextButton(onPressed: () => context.push(const RegisterPage()), child: const Text('Create an account')),
                  ]).animate().fadeIn(delay: 400.ms),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
