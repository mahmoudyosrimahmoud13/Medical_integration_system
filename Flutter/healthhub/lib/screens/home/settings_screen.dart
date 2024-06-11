import 'package:flutter/material.dart';
import 'package:healthhub/helpers/helper_methods.dart';
import 'package:healthhub/screens/authentication/login.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Container(
        child: Center(
          child: ElevatedButton.icon(
            onPressed: () {
              navigateTo(toPage: const LoginScreen());
            },
            label: const Text('Logout'),
            icon: const Icon(Icons.logout),
          ),
        ),
      ),
    );
  }
}
