import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:healthhub/cubit/adress/adress_cubit.dart';
import 'package:healthhub/widgets/generic_texfield.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  //keys
  final _formKey = GlobalKey<FormState>();
  // nulls
  File? _image;
  DateTime? _birthDay;
  // helpers
  String governrateDownValue = 'Choose governrate';
  String areaDownValue = 'Choose area';
  bool _visibility = false;

  // values
  bool _privacy = false;

  // Controllers
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nationalIDController = TextEditingController();

  void _pickDate() {
    setState(() async {
      _birthDay = await showDatePicker(
        context: context,
        firstDate: DateTime(1950),
        lastDate: DateTime.now(),
      );
    });
    print(_birthDay.toString());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocBuilder<AdressCubit, AdressState>(
      builder: (context, state) {
        if (state is AdressLoading) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (state is AdressSucsses) {
          final _governrates = state.governrates;
          final _areas = state.areas;
          return Scaffold(
              body: Container(
            height: size.height,
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).colorScheme.primary,
                  height: size.height * 0.155,
                  child: const Center(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 22,
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SvgPicture(
                            SvgAssetLoader('assets/logo/logo.svg'),
                            height: 83,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                    child: SingleChildScrollView(
                  child: Container(
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withAlpha(20),
                    padding: const EdgeInsets.all(12),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REGISTRATION',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                          ),
                          Text('Create an account',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onBackground)),
                          const SizedBox(
                            height: 12,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () async {
                                final ImagePicker imagePicker = ImagePicker();
                                final image = await imagePicker.pickImage(
                                    source: ImageSource.gallery);

                                setState(() {
                                  _image = File(image!.path);
                                });
                              },
                              child: CircleAvatar(
                                radius: 75,
                                backgroundImage:
                                    _image == null ? null : FileImage(_image!),
                                child: _image != null
                                    ? null
                                    : const Text('Pick a profile image'),
                              ),
                            ),
                          ),
                          const Text('Full name'),
                          GenericTextField(
                            textEditingController: _nameController,
                            hint: 'ex: sukuna ryomen',
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          const Text('Email'),
                          GenericTextField(
                              textInputType: TextInputType.emailAddress,
                              textEditingController: _emailController,
                              hint: 'ex: ex@example.com'),
                          const SizedBox(
                            height: 15,
                          ),
                          const Text('Phone'),
                          GenericTextField(
                              textInputType: TextInputType.number,
                              textEditingController: _phoneController,
                              hint: 'ex: 01XXXXXXXXX'),
                          const SizedBox(
                            height: 15,
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          const Text('National ID'),
                          GenericTextField(
                            textInputType: TextInputType.number,
                            textEditingController: _nationalIDController,
                            hint: '14 digit ex: 29501023201952',
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          const Text('Birthday'),
                          const SizedBox(
                            height: 5,
                          ),
                          Container(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _pickDate,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .background
                                      .withAlpha(100),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              label: Text(
                                _birthDay == null
                                    ? 'Pick a date'
                                    : DateFormat.yMd().format(_birthDay!),
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground),
                              ),
                              icon: Icon(Icons.calendar_month),
                            ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          const Text('Governrate'),
                          DropdownButtonFormField(
                            value: 'Choose Governrate',
                            icon: const Icon(Icons.location_city),
                            items: _governrates,
                            onChanged: (value) {
                              setState(() {
                                governrateDownValue = value!;
                                areaDownValue = 'Choose area';
                              });
                              BlocProvider.of<AdressCubit>(context)
                                  .getAreas(key: governrateDownValue);
                            },
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          const Text('Area'),
                          DropdownButtonFormField<String>(
                            value: areaDownValue,
                            icon: const Icon(Icons.home),
                            items: _areas,
                            onChanged: (value) {
                              setState(() {
                                areaDownValue = value!;
                                value = areaDownValue;
                              });
                            },
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          const Text('Password'),
                          GenericTextField(
                            textInputType: TextInputType.visiblePassword,
                            obscureText: _visibility,
                            textEditingController: _passwordController,
                            hint: ' Must have non alphanumeric character. ',
                            iconButton: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _visibility = _visibility ? false : true;
                                  });
                                },
                                icon: Icon(_visibility
                                    ? Icons.visibility
                                    : Icons.visibility_off)),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: _privacy,
                                onChanged: (value) {
                                  setState(() {
                                    _privacy = value!;
                                  });
                                },
                              ),
                              TextButton(
                                  onPressed: () {},
                                  child: Row(
                                    children: [
                                      Text(
                                        'I agree on ',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onBackground),
                                      ),
                                      Text(
                                        'privacy plicy.',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                      ),
                                    ],
                                  ))
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            child: Text(
                              'Sign up',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                            ),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .background
                                    .withAlpha(100),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                          )
                        ],
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ));
        } else {
          return const Scaffold();
        }
      },
    );
  }
}
