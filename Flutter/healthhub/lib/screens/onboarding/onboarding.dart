import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:healthhub/helpers/helper_methods.dart';
import 'package:healthhub/screens/authentication/login.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController pageController;

  @override
  void initState() {
    pageController = PageController(initialPage: 0);
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
                itemCount: onboard.length,
                controller: pageController,
                itemBuilder: (context, index) => onboard[index]),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SmoothPageIndicator(
                    controller: pageController,
                    count: onboard.length,
                    effect: ExpandingDotsEffect(
                        spacing: 6,
                        radius: 66,
                        activeDotColor: Theme.of(context).colorScheme.primary,
                        dotHeight: 7,
                        dotWidth: 7,
                        expansionFactor: 4)),
                SizedBox(
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(elevation: 0),
                      onPressed: () {
                        print(pageController.page);
                        if (pageController.page == 3) {
                          navigateTo(toPage: LoginScreen(), replace: true);
                        }

                        pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.ease);
                      },
                      child: Icon(Icons.navigate_next_rounded)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

final List<OnboardingItem> onboard = [
  const OnboardingItem(
    imagePath: 'assets/logo/colored_logo.svg',
    title: 'Health hub',
    subTitle: 'Your all in one health app.',
  ),
  const OnboardingItem(
    imagePath: 'assets/onboarding/Profile pic-rafiki.svg',
    title: 'Profile Setup',
    subTitle:
        'Personalize your health profile with medical history and preferences.',
  ),
  const OnboardingItem(
      imagePath: 'assets/onboarding/Health professional team-amico.svg',
      title: 'Find Care Providers',
      subTitle:
          'Discover nearby doctors, pharmacists, and hospitals with ease.'),
  const OnboardingItem(
      imagePath: 'assets/onboarding/blood research-cuate.svg',
      title: 'Medical Records Management',
      subTitle:
          'Keep all medical records securely stored and easily accessible.')
];

class OnboardingItem extends StatelessWidget {
  const OnboardingItem({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subTitle,
  });
  final String imagePath;
  final String title;
  final String subTitle;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(),
          SvgPicture(
            SvgAssetLoader(imagePath),
            height: 300,
          ),
          const Spacer(),
          Text(
            title,
            style: Theme.of(context).textTheme.displayMedium!.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            subTitle,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
            textAlign: TextAlign.center,
          ),
          const Spacer()
        ],
      ),
    );
  }
}
