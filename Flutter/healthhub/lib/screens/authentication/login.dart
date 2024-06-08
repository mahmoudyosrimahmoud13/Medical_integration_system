import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:healthhub/cubit/authentication/authentication_cubit.dart';
import 'package:healthhub/helpers/helper_methods.dart';
import 'package:healthhub/screens/authentication/sign_up.dart';
import 'package:healthhub/screens/home/search_screen.dart';
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
  bool _showPassword = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    bool _isPassword(String value) {
      RegExp regExp =
          RegExp(r"^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{8,}$");
      return regExp.hasMatch(value);
    }

    bool _isEmail(String value) {
      RegExp regExp = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
      return regExp.hasMatch(value);
    }

    void _login(AuthenticationCubit cubit, AuthenticationState state) {
      if (_key.currentState!.validate()) {
        final Map<String, String> data = {
          "userName": _emailController.text,
          "password": _passowrdController.text
        };
        cubit.login(data: data);
        if (state is AuthenticationSuccess) {
          if (state.message == null) {
            showMessage(message: 'Login successful');
            navigateTo(toPage: SearchScreen(), replace: true);
          } else {
            showMessage(message: state.message!);
          }
        } else if (state is AuthenticationError) {
          showMessage(message: state.error, type: MessageType.faild);
        }
      }
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(100),
                ),
              ),
              height: size.height * 0.85,
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
                        validator: (value) {
                          if (!_isEmail(value!)) {
                            return 'Enter a correct email.';
                          }
                        },
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
                        validator: (value) {
                          if (!_isPassword(value!)) {
                            return 'Choose a strong password';
                          }
                        },
                      ),
                      TextButton(
                          onPressed: () {},
                          child: Text(
                            'Forget your password?',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .background),
                          )),
                      Container(
                        height: 75,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        width: double.infinity,
                        child: BlocBuilder<AuthenticationCubit,
                            AuthenticationState>(
                          builder: (context, state) {
                            return ElevatedButton(
                              onPressed: () {
                                final cubit =
                                    BlocProvider.of<AuthenticationCubit>(
                                        context);
                                _login(cubit, state);
                              },
                              style: ElevatedButton.styleFrom(
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                          bottomRight: Radius.circular(100),
                                          bottomLeft: Radius.circular(10),
                                          topLeft: Radius.circular(10),
                                          topRight: Radius.circular(10)))),
                              child: state is AuthenticationLoading
                                  ? SizedBox(
                                      height: 25,
                                      width: 25,
                                      child: CircularProgressIndicator(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    )
                                  : Text(
                                      'Login',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                    ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            const Text('Don\'t have an account?'),
            const SizedBox(
              height: 15,
            ),
            Container(
              height: 50,
              width: size.width * 0.9,
              child: ElevatedButton(
                onPressed: () {
                  navigateTo(toPage: SignUpScreen());
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)))),
                child: Text(
                  'Sign up!',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
