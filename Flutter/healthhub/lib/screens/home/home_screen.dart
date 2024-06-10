import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:healthhub/cubit/get_user_data/get_user_data_cubit.dart';
import 'package:healthhub/helpers/cache_helper.dart';
import 'package:healthhub/helpers/helper_methods.dart';
import 'package:healthhub/screens/home/appointments_screen.dart';
import 'package:healthhub/screens/home/prescription.dart';
import 'package:healthhub/screens/home/search_screen.dart';
import 'package:healthhub/screens/home/settings_screen.dart';
import 'package:healthhub/screens/loading_screen.dart';
import 'package:healthhub/widgets/nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 3;

  @override
  Widget build(BuildContext context) {
    Widget screen = SearchScreen(
      name: CacheHelper.getData(key: 'name'),
      url: CacheHelper.getData(key: 'image'),
    );

    if (_currentIndex == 0) {
      setState(() {
        screen = SettingsScreen();
      });
    }
    if (_currentIndex == 1) {
      setState(() {
        screen = AppointmentScreen(
          name: CacheHelper.getData(key: 'name'),
          url: CacheHelper.getData(key: 'image'),
        );
      });
    }
    if (_currentIndex == 2) {
      setState(() {
        screen = SearchScreen(
          name: CacheHelper.getData(key: 'name'),
          url: CacheHelper.getData(key: 'image'),
        );
      });
    }
    if (_currentIndex == 3) {
      setState(() {
        screen = PrescriptionScreen(
          name: CacheHelper.getData(key: 'name'),
          url: CacheHelper.getData(key: 'image'),
        );
      });
    }
    return BlocBuilder<GetUserDataCubit, GetUserDataState>(
      builder: (context, state) {
        if (state is GetUserDataSuccess) {
          return Scaffold(
              body: screen,
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.miniCenterDocked,
              floatingActionButton: FloatingActionButton(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: CircleBorder(),
                elevation: 5,
                clipBehavior: Clip.hardEdge,
                onPressed: () {
                  navigateTo(toPage: SettingsScreen());
                },
                child: Icon(
                  Icons.alarm_add,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              bottomNavigationBar: NavBar(
                currentIndex: _currentIndex,
                ontap: (value) {
                  setState(() {
                    _currentIndex = value;
                  });
                },
              ));
        } else {
          return const LoadingScreen();
        }
      },
    );
  }
}
