import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/config.dart';
import '../../core/i18n/i18n.dart';
import '../../core/server/server_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animations.dart';
import '../../core/widgets/common.dart';

/// Asks for the server address. Shown before anything else the first time the app opens,
/// and from the login screen or the profile page when the address changes
/// (a free Cloudflare link changes every time the server restarts).
///
/// On the first run, saving the address swaps this screen for the app.
/// Opened later, it closes and returns true when a new address was saved.
class ServerPage extends StatefulWidget {
  const ServerPage({super.key, this.firstRun = false});

  final bool firstRun;

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  final _form = GlobalKey<FormState>();
  late final _address = TextEditingController(text: ServerSettings.url.value ?? AppConfig.builtInAddress ?? '');
  bool _busy = false;
  String? _error;
  bool _offerAnyway = false;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _offerAnyway = false;
    });
    final address = ServerSettings.normalize(_address.text);
    final ok = await ServerSettings.check(address);
    if (!mounted) return;
    if (ok) {
      await _save(address);
    } else {
      setState(() {
        _busy = false;
        _error = tr("No HealthHub server answered at {address}. Check that the server is running on the computer and that the address is the latest one.", {'address': address});
        _offerAnyway = true;
      });
    }
  }

  Future<void> _save(String address) async {
    await ServerSettings.save(address);
    if (!mounted) return;
    if (widget.firstRun) return; // the app swaps this screen for the login screen
    showSnack(context, tr('Connected to {server}', {'server': ServerSettings.shortName(address)}));
    Navigator.of(context).pop(true);
  }

  String? _validate(String? v) {
    if (v == null || v.trim().isEmpty) return tr('Enter the server address');
    if (!ServerSettings.looksValid(v)) return tr('This does not look like a web address');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(tr('Server address'), style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(tr('The app gets doctors, bookings and records from your HealthHub server. Paste the address it shows.'),
                style: t.bodyMedium),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('server-address'),
              controller: _address,
              keyboardType: TextInputType.url,
              textDirection: TextDirection.ltr, // addresses read left to right, also in Arabic
              autocorrect: false,
              enableSuggestions: false,
              onFieldSubmitted: (_) => _connect(),
              decoration: InputDecoration(
                labelText: tr('Server address'),
                hintText: 'https://your-link.trycloudflare.com',
                prefixIcon: const Icon(Icons.dns_outlined),
              ),
              validator: _validate,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: _error == null
                  ? const SizedBox(height: 16)
                  : Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.wifi_off_rounded, color: AppColors.danger),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger))),
                      ]),
                    ).animate().shakeX(hz: 4, amount: 4, duration: 400.ms),
            ),
            PrimaryButton(key: const Key('server-connect'), label: tr('Connect'), busy: _busy, onPressed: _connect),
            if (_offerAnyway)
              TextButton(
                onPressed: () => _save(ServerSettings.normalize(_address.text)),
                child: Text(tr('Save this address anyway')),
              ),
          ]),
        ),
      ),
    );

    final help = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tr('Where do I find the address?'), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      _Step(n: 1, text: tr('On the computer, open the HealthHub folder and run ./run.sh (run.bat on Windows).')),
      _Step(n: 2, text: tr('For a link that works anywhere, choose the Cloudflare option. It looks like https://something.trycloudflare.com')),
      _Step(n: 3, text: tr('On the same Wi-Fi you can also use the Wi-Fi address it shows, like http://192.168.1.10:8020')),
      _Step(n: 4, text: tr('The free Cloudflare link changes when the server restarts. Come back here to paste the new one.')),
    ]);

    if (!widget.firstRun) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('Server'))),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          if (ServerSettings.url.value != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(tr('Now using {server}', {'server': ServerSettings.shortName(ServerSettings.url.value)}), style: t.bodyMedium),
            ),
          card,
          const SizedBox(height: 20),
          help,
        ]),
      );
    }

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
                  Text(tr('Connect to your server'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                  Text(tr('One step before you start'), style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 28),
                  card.animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: .08, end: 0),
                  const SizedBox(height: 20),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: help),
                ]),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: AlignmentDirectional.topEnd,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton.icon(
                onPressed: () => AppSettings.setLang(AppSettings.isArabic ? 'en' : 'ar'),
                icon: const Icon(Icons.language, color: Colors.white),
                label: Text(AppSettings.isArabic ? 'English' : 'العربية', style: const TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.text});

  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: scheme.primaryContainer,
          child: Text('$n', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ]),
    );
  }
}
