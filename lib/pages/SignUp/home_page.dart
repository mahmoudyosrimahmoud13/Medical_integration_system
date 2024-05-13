import 'package:animate_do/animate_do.dart';
import 'package:final_project/pages/SignUp/login_page.dart';
import 'package:final_project/pages/SignUp/sign_page.dart';
import 'package:final_project/pages/home/styles/app_styles.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.white,
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Column(
                children: <Widget>[
                  FadeInUp(
                      duration: const Duration(milliseconds: 1400),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 230),
                        child: Container(
                          width: 170,
                          height: MediaQuery.of(context).size.height / 10,
                          decoration: const BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage('assets/pngimg/11.png'))),
                        ),
                      )),
                  FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: Text(
                        "Welcome",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                            color: kPrimaryColor,
                            fontFamily: 'Kanit'),
                      )),
                  const SizedBox(
                    height: 20,
                  ),
                  FadeInUp(
                      duration: const Duration(milliseconds: 1200),
                      child: const Text(
                        "Automatic identity verification which enables you to verify your identity",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color(0xff555555),
                            fontSize: 15,
                            fontFamily: 'Kanit'),
                      )),
                ],
              ),
              FadeInUp(
                  duration: const Duration(milliseconds: 1400),
                  child: Container(
                    height: MediaQuery.of(context).size.height / 3,
                    decoration: const BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage('assets/images/19.jpg'))),
                  )),
              Column(
                children: <Widget>[
                  FadeInUp(
                      duration: const Duration(milliseconds: 1500),
                      child: MaterialButton(
                        minWidth: double.infinity,
                        height: 60,
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()));
                        },
                        shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.black),
                            borderRadius: BorderRadius.circular(50)),
                        child: const Text(
                          "Login",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              fontFamily: 'Kanit'),
                        ),
                      )),
                  const SizedBox(
                    height: 20,
                  ),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1600),
                    child: MaterialButton(
                      minWidth: double.infinity,
                      height: 60,
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignupPage()));
                      },
                      color: kPrimaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                      child: const Text(
                        "Sign up",
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Colors.white,
                            fontFamily: 'Kanit'),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
