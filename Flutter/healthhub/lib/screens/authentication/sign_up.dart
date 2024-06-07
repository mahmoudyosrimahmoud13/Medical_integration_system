// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:healthhub/helpers/helper_methods.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:healthhub/cubit/adress/adress_cubit.dart';
import 'package:healthhub/cubit/register/register_cubit.dart';
import 'package:healthhub/models/register_user_model.dart';
import 'package:healthhub/widgets/generic_texfield.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  //model
  late RegisterUserModel model;
  //keys
  final _formKey = GlobalKey<FormState>();
  // nulls
  File? _image;
  DateTime? _birthDay;

  // helpers
  String governrateDownValue = 'Choose governrate';
  String areaDownValue = 'Choose area';
  bool _visibility = false;
  bool? _gender = true;

  // values
  bool _privacy = true;

  // errors
  bool _birthdateError = false;

  // Controllers
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nationalIDController = TextEditingController();

  //Regex
  bool _isPassword(String value) {
    RegExp regExp =
        RegExp(r"^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{8,}$");
    return regExp.hasMatch(value);
  }

  bool _isEmail(String value) {
    RegExp regExp = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return regExp.hasMatch(value);
  }

  bool _isPhoneNumber(String value) {
    RegExp regExp = RegExp(r"^01[0125][0-9]{8}$");
    return regExp.hasMatch(value);
  }

  bool _isName(String value) {
    RegExp regExp = RegExp(
        r"(^[A-Za-z]{3,16})([ ]{0,1})([A-Za-z]{3,16})?([ ]{0,1})?([A-Za-z]{3,16})?([ ]{0,1})?([A-Za-z]{3,16})");
    return regExp.hasMatch(value);
  }

  void _pickDate() {
    setState(() async {
      _birthDay = await showDatePicker(
        context: context,
        firstDate: DateTime(1950),
        lastDate: DateTime.now(),
      );
    });
  }

  void _pickImage() async {
    final ImagePicker imagePicker = ImagePicker();
    final image = await imagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = File(image!.path);
    });
  }

  void _register(RegisterCubit cubit, RegisterState state) {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _birthdateError = true;
      });
    } else {
      model = RegisterUserModel(
          image: _image,
          nationalID: _nationalIDController.text,
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          phone: _phoneController.text,
          birday: _birthDay!.toString(),
          area: areaDownValue,
          gender: _gender!);

      cubit.Register(model: model);

      if (state is RegisterSuccess) {
        if (state.message == 'Cheack Mail to Confirem Mail') {
          showMessage(message: state.message);
          Navigator.pop(context);
        } else {
          showMessage(message: state.message, type: MessageType.faild);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocBuilder<AdressCubit, AdressState>(
      builder: (context, state) {
        if (state is AdressLoading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        } else if (state is AdressSucsses) {
          final governrates = state.governrates;
          final areas = state.areas;
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
                              onTap: _pickImage,
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
                            validator: (value) {
                              if (!_isName(value!)) {
                                return 'Enter correct name';
                              }
                            },
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          const Text('Email'),
                          GenericTextField(
                            textInputType: TextInputType.emailAddress,
                            textEditingController: _emailController,
                            hint: 'ex: ex@example.com',
                            validator: (value) {
                              if (!_isEmail(value!)) {
                                return "Enter correct Email";
                              }
                            },
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          const Text('Phone'),
                          GenericTextField(
                            length: 11,
                            textInputType: TextInputType.number,
                            textEditingController: _phoneController,
                            hint: 'ex: 01XXXXXXXXX',
                            validator: (value) {
                              if (!_isPhoneNumber(value!)) {
                                return 'Enter correct phone number';
                              }
                            },
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          const Text('National ID'),
                          GenericTextField(
                            length: 14,
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
                          SizedBox(
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
                              icon: const Icon(Icons.calendar_month),
                            ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          const Text('Governrate'),
                          DropdownButtonFormField<String>(
                            value: 'Choose Governrate',
                            icon: const Icon(Icons.location_city),
                            items: governrates,
                            onChanged: (value) {
                              setState(
                                () {
                                  governrateDownValue = value!;
                                  areaDownValue = 'Choose area';
                                },
                              );
                              BlocProvider.of<AdressCubit>(context)
                                  .getAreas(key: governrateDownValue);
                            },
                            validator: (value) {
                              if (value == 'Choose Governrate') {
                                return "Please choose the governrate";
                              }
                            },
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          const Text('Area'),
                          DropdownButtonFormField<String>(
                            value: areaDownValue,
                            icon: const Icon(Icons.home),
                            items: areas,
                            onChanged: (value) {
                              setState(
                                () {
                                  areaDownValue = value!;
                                  value = areaDownValue;
                                },
                              );
                            },
                            validator: (value) {
                              if (value == 'Choose area') {
                                return "Please choose the area";
                              }
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
                            validator: (value) {
                              if (!_isPassword(value!)) {
                                return 'the password is too weak';
                              }
                            },
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          const Text('Gender'),
                          Row(
                            children: [
                              const Text('Male'),
                              Radio(
                                value: true,
                                groupValue: _gender,
                                onChanged: (value) {
                                  setState(() {
                                    _gender = value;
                                  });
                                },
                              ),
                              const Text('Female'),
                              Radio(
                                value: false,
                                groupValue: _gender,
                                onChanged: (value) {
                                  setState(() {
                                    _gender = value;
                                  });
                                },
                              ),
                            ],
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
                          _privacy
                              ? const SizedBox.shrink()
                              : Text(
                                  'You need to accept the privacy policy.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error),
                                ),
                          BlocBuilder<RegisterCubit, RegisterState>(
                            builder: (context, state) {
                              return ElevatedButton(
                                onPressed: () {
                                  _register(
                                      BlocProvider.of<RegisterCubit>(context),
                                      state);
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                child: state is RegisterLoading
                                    ? const SizedBox(
                                        height: 15,
                                        width: 15,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Sign up',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium!
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary),
                                      ),
                              );
                            },
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
