import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:healthhub/widgets/generic_texfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _key = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passowrdController = TextEditingController();
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    bool _isPassword(String value) {
      RegExp regExp = RegExp(
          r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[_#$^+=!*()@%&]).{8,}$");
      return regExp.hasMatch(value);
    }

    bool _isEmail(String value) {
      RegExp regExp = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
      return regExp.hasMatch(value);
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(180),
          ),
        ),
        height: size.height * 0.9,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 30,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SvgPicture(
                            SvgAssetLoader('assets/logo/logo.svg'),
                          ),
                          Text(
                            'Helth\nHub.',
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .background),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Text('Email',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.background)),
                  GenericTextField(
                    hint: 'Email',
                    textEditingController: _emailController,
                    textInputType: TextInputType.emailAddress,
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Text(
                    'Password',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.background),
                  ),
                  GenericTextField(
                    hint: 'Password',
                    textInputType: TextInputType.visiblePassword,
                    textEditingController: _passowrdController,
                    obscureText: _showPassword,
                    iconButton: IconButton(
                        onPressed: () {
                          setState(() {
                            _showPassword
                                ? _showPassword = false
                                : _showPassword = true;
                          });
                        },
                        icon: Icon(_showPassword
                            ? Icons.visibility_off
                            : Icons.visibility)),
                  ),
                  TextButton(
                      onPressed: () {},
                      child: Text(
                        'Forget your password?',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).colorScheme.background),
                      )),
                  Container(
                    height: 75,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(180),
                                  bottomLeft: Radius.circular(10),
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10)))),
                      child: Text(
                        'Login',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
