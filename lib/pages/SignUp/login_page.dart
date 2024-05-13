import 'package:animate_do/animate_do.dart';
import 'package:final_project/cubits/login_cubit/login_cubit_cubit.dart';
import 'package:final_project/pages/SignUp/sign_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(),
      child: Builder(
        builder: (context) {
          LoginCubit cubit = BlocProvider.of<LoginCubit>(context);
          return ColoredBox(
            color: Colors.white,
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: Colors.white,
              appBar: AppBar(
                elevation: 0,
                backgroundColor: Colors.white,
                leading: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    size: 20,
                    color: Colors.black,
                  ),
                ),
              ),
              body: SizedBox(
                height: MediaQuery.of(context).size.height,
                width: double.infinity,
                child: Form(
                  key: cubit.formkey,
                  autovalidateMode: cubit.autovalidateMode,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Column(
                              children: <Widget>[
                                FadeInUp(
                                  duration: const Duration(milliseconds: 1000),
                                  child: Container(
                                      height: 64,
                                      width: 195,
                                      decoration: const BoxDecoration(
                                          image: DecorationImage(
                                              image: AssetImage(
                                                  "assets/pngimg/11.png"),
                                              fit: BoxFit.fill))),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                FadeInUp(
                                    duration:
                                        const Duration(milliseconds: 1000),
                                    child: const Text(
                                      "Login",
                                      style: TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Kanit'),
                                    )),
                                const SizedBox(
                                  height: 20,
                                ),
                                FadeInUp(
                                    duration:
                                        const Duration(milliseconds: 1200),
                                    child: Text(
                                      "Login to your account",
                                      style: TextStyle(
                                        fontFamily: 'Kanit',
                                        fontSize: 15,
                                        color: Colors.grey[700],
                                      ),
                                    )),
                              ],
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              child: Column(
                                children: <Widget>[
                                  FadeInUp(
                                      duration:
                                          const Duration(milliseconds: 1200),
                                      child: TextFormField(
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return 'Please enter an email';
                                            }
                                            // Regular expression for email validation
                                            final emailRegex = RegExp(
                                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                            if (!emailRegex.hasMatch(value)) {
                                              return 'Please enter a valid email';
                                            }
                                            return null;
                                          },
                                          controller: cubit.emailController,
                                          decoration: const InputDecoration(
                                              prefixIcon: Icon(Icons.email),
                                              labelText: "Email",
                                              labelStyle: TextStyle(
                                                  fontFamily: "Kanit")))),
                                  FadeInUp(
                                      duration:
                                          const Duration(milliseconds: 1300),
                                      child: TextFormField(
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return 'Please enter a password';
                                            }
                                            // Password length check
                                            if (value.length < 8) {
                                              return 'Password must be at least 8 characters long';
                                            }
                                            // Password complexity check
                                            final passwordRegex = RegExp(
                                                r'^(?=.*?[a-z])(?=.*?[A-Z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$');
                                            if (!passwordRegex
                                                .hasMatch(value)) {
                                              return 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character';
                                            }
                                            return null;
                                          },
                                          controller: cubit.passwordController,
                                          decoration: const InputDecoration(
                                              prefixIcon: Icon(Icons.lock),
                                              labelText: "Password",
                                              labelStyle: TextStyle(
                                                  fontFamily: "Kanit")),
                                          obscureText: true)),
                                ],
                              ),
                            ),
                            FadeInUp(
                              duration: const Duration(milliseconds: 1400),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 40),
                                child: BlocBuilder<LoginCubit, LoginCubitState>(
                                  builder: (context, state) {
                                    if (state is LoginCubitLoading) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    return MaterialButton(
                                      minWidth: double.infinity,
                                      height: 60,
                                      onPressed: () {
                                        // Your logic here
                                        cubit.login();
                                      },
                                      color: Colors.black,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(50)),
                                      child: const Text(
                                        "Login",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontFamily: 'Kanit'),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            FadeInUp(
                                duration: const Duration(milliseconds: 1500),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Text("Don't have an account?"),
                                    GestureDetector(
                                      child: const Text(
                                        "Sign up",
                                        style: TextStyle(
                                            fontFamily: 'Kanit',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18),
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const SignupPage()));
                                      },
                                    ),
                                  ],
                                ))
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
