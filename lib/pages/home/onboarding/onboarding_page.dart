import 'package:final_project/logics/cache_helper.dart';
import 'package:final_project/pages/SignUp/home_page.dart';
import 'package:final_project/pages/home/onboarding/onboard_item.dart';
import 'package:final_project/pages/home/styles/app_styles.dart';
import 'package:final_project/pages/home/styles/size_configs.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({Key? key}) : super(key: key);

  @override
  State<OnBoardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnBoardingPage> {
  final controller = OnboardItem();
  final pageController = PageController();
  bool isLastPage = false;

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double sizeH = SizeConfig.blockSizeH!;
    double sizeV = SizeConfig.blockSizeV!;
    return Scaffold(
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 650),
          child: FloatingActionButton(
            onPressed: () =>
                pageController.jumpToPage(controller.onboarddata.length - 1),
            backgroundColor: Colors.white,
            elevation: 0,
            child: Text(
              'Skip',
              style: TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFamily: 'Kanit'),
            ),
          ),
        ),
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Expanded(
                child: PageView.builder(
              itemCount: controller.onboarddata.length,
              onPageChanged: (index) => setState(() =>
                  isLastPage = controller.onboarddata.length - 1 == index),
              controller: pageController,
              itemBuilder: (context, index) => Column(
                children: [
                  SizedBox(
                    height: sizeV * 15,
                  ),
                  Container(
                    height: sizeV * 30,
                    width: sizeH * 80,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage(controller.onboarddata[index].img),
                          fit: BoxFit.fill),
                    ),
                  ),
                  SizedBox(
                    height: sizeV * 5,
                  ),
                  Text(
                    controller.onboarddata[index].title,
                    textAlign: TextAlign.center,
                    style: kTitle,
                  ),
                  SizedBox(
                    height: sizeV * 2,
                  ),
                  Text(controller.onboarddata[index].subTitle,
                      textAlign: TextAlign.center, style: kBodyText),
                  SizedBox(
                    height: sizeV * 21,
                  ),
                ],
              ),
            ))
          ],
        ),
        bottomSheet: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: isLastPage
              ? startButton()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      SmoothPageIndicator(
                          controller: pageController,
                          count: controller.onboarddata.length,
                          onDotClicked: (index) => pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeIn),
                          effect: WormEffect(
                            dotHeight: 5,
                            dotWidth: 12,
                            activeDotColor: kPrimaryColor,
                          )),
                      FloatingActionButton(
                        onPressed: () {
                          pageController.nextPage(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeIn);
                        },
                        backgroundColor: kPrimaryColor,
                        child: const Icon(
                          Icons.navigate_next_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ]),
        ));
  }

  Widget startButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 285),
      child: FloatingActionButton(
        onPressed: () async {
          CacheHelper.setOnboarding(onBoarding: true);

          //After we press get started button this onboarding value become true
          // same key
          if (!mounted) return;
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const Home()));
        },
        backgroundColor: kPrimaryColor,
        child: const Icon(
          Icons.done_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}
