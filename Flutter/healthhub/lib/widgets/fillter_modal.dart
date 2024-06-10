import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:healthhub/cubit/Area/area_cubit.dart';
import 'package:healthhub/cubit/governrate/governrates_cubit.dart';
import 'package:healthhub/cubit/search/search_cubit.dart';
import 'package:healthhub/cubit/specialities/specialities_cubit.dart';
import 'package:healthhub/helpers/helper_methods.dart';

// ignore: must_be_immutable
class FillterModal extends StatelessWidget {
  FillterModal({super.key, required this.onfillter});

  final void Function(Map<String, dynamic> keys) onfillter;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int areaDownValue = 10000;
  int specialityDownValue = 10000;
  int governrateDownValue = 10000;
  List areaData = [];
  List specialityData = [];
  List governrateData = [];

  void _apply() {
    if (_formKey.currentState!.validate()) {
      print('ccccccccccccccccccccccccccccccccc');
      print(areaDownValue);
      onfillter({
        'area': areaDownValue == 10000 ? {} : areaData[areaDownValue],
        'governrate': governrateDownValue == 10000
            ? {}
            : governrateData[governrateDownValue],
        'speciality': specialityDownValue == 10000
            ? {}
            : specialityData[specialityDownValue]
      });
      if (specialityDownValue != 10000) {
        print('//////////////////////////' +
            specialityData[specialityDownValue]['id']);

        BlocProvider.of<SearchCubit>(navigatorKey.currentState!.context)
            .getDoctorsInGovernorate(
                area: areaDownValue == 10000
                    ? null
                    : areaData[areaDownValue]['id'],
                governrate: governrateDownValue == 10000
                    ? null
                    : governrateData[governrateDownValue]['id'],
                specialtie: specialityData[specialityDownValue]['id']);
      }

      Navigator.pop(navigatorKey.currentState!.context);
    }
  }

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<AreaCubit>(context).getArea();
    BlocProvider.of<SpecialitiesCubit>(context).getSpecialities();
    BlocProvider.of<GovernratesCubit>(context).getGovernrates();
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(25),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Area',
              style: textTheme.titleLarge,
            ),
            BlocBuilder<AreaCubit, AreaState>(
              builder: (context, state) {
                if (state is AreaSuccess) {
                  areaData = state.data;

                  return DropdownButtonFormField(
                    value: areaDownValue,
                    icon: const Icon(Icons.home),
                    items: state.areas,
                    onChanged: (value) {
                      areaDownValue = value!;
                    },
                  );
                } else {
                  return const SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              'Speciality',
              style: textTheme.titleLarge,
            ),
            BlocBuilder<SpecialitiesCubit, SpecialitiesState>(
              builder: (context, state) {
                if (state is SpecialitiesSuccess) {
                  specialityData = state.data;

                  return DropdownButtonFormField(
                    value: specialityDownValue,
                    icon: const Icon(Icons.local_hospital),
                    items: state.specialities,
                    onChanged: (value) {
                      specialityDownValue = value!;
                    },
                    validator: (value) {
                      if (specialityDownValue == 10000) {
                        return 'Please choose specialty';
                      }
                    },
                  );
                } else {
                  return const SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              'Governrate',
              style: textTheme.titleLarge,
            ),
            BlocBuilder<GovernratesCubit, GovernratesState>(
              builder: (context, state) {
                if (state is GovernratesSuccess) {
                  governrateData = state.data;

                  return DropdownButtonFormField(
                    value: governrateDownValue,
                    icon: const Icon(Icons.location_city),
                    items: state.governrates,
                    onChanged: (value) {
                      governrateDownValue = value!;
                    },
                  );
                } else {
                  return const SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
            Expanded(
              child: Container(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary),
                    onPressed: _apply,
                    child: Text(
                      'Apply',
                      style: TextStyle(color: colors.onPrimary),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
