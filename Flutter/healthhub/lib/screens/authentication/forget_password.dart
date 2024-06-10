import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:healthhub/cubit/authentication/authentication_cubit.dart';

import 'package:healthhub/widgets/generic_texfield.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isEmail(String value) {
    RegExp regExp = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return regExp.hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.onBackground.withAlpha(20),
        title: Text(
          'Forget password',
          style: textTheme.titleLarge,
        ),
      ),
      body: Container(
        height: double.maxFinite,
        color: Theme.of(context).colorScheme.onBackground.withAlpha(20),
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: SvgPicture(
                        SvgAssetLoader('assets/Forgotpassword.svg'),
                      )),
                  const Text('Your email'),
                  GenericTextField(
                    textInputType: TextInputType.emailAddress,
                    textEditingController: _emailController,
                    hint: 'Enter yout email.',
                    validator: (value) {
                      if (!_isEmail(value!)) {
                        return "Enter correct Email";
                      }
                    },
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  BlocBuilder<AuthenticationCubit, AuthenticationState>(
                    builder: (context, state) {
                      return SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              BlocProvider.of<AuthenticationCubit>(context)
                                  .forgotPassword(email: _emailController.text);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              elevation: 0,
                              shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)))),
                          child: BlocBuilder<AuthenticationCubit,
                              AuthenticationState>(
                            builder: (context, state) {
                              if (state is! AuthenticationLoading) {
                                return Text(
                                  'Reset',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary),
                                );
                              } else {
                                return SizedBox(
                                    height: 25,
                                    width: 25,
                                    child: CircularProgressIndicator(
                                      color: colors.onPrimary,
                                    ));
                              }
                            },
                          ),
                        ),
                      );
                    },
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
