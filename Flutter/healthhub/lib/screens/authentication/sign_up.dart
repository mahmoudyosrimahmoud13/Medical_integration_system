import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:healthhub/widgets/generic_texfield.dart';
import 'package:image_picker/image_picker.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  File? _image;

  final _formKey = GlobalKey<FormState>();
  DateTime? _birthDay;

  void _pickDate() async {
    _birthDay = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    print(_birthDay.toString());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
        body: SafeArea(
      child: Container(
        height: size.height,
        child: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.primary,
              height: size.height * 0.1,
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SvgPicture(SvgAssetLoader('assets/logo/logo.svg')),
                ),
              ),
            ),
            Expanded(
                child: SingleChildScrollView(
              child: Container(
                color: Theme.of(context).colorScheme.onBackground.withAlpha(20),
                padding: const EdgeInsets.all(12),
                child: Form(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REGISTRATION',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary),
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
                        textEditingController: TextEditingController(),
                        hint: 'ex: sukuna ryomen',
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      const Text('Email'),
                      GenericTextField(
                          textInputType: TextInputType.emailAddress,
                          textEditingController: TextEditingController(),
                          hint: 'ex: ex@example.com'),
                      const SizedBox(
                        height: 15,
                      ),
                      const Text('Phone'),
                      GenericTextField(
                          textInputType: TextInputType.number,
                          textEditingController: TextEditingController(),
                          hint: 'ex: 01XXXXXXXXX'),
                      const SizedBox(
                        height: 15,
                      ),
                      const Text('Birthday'),
                      const SizedBox(
                        height: 5,
                      ),
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _pickDate,
                          child: Text(
                            'Pick a date',
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onBackground),
                          ),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .background
                                  .withAlpha(100),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      const Text('Governrate'),
                      DropdownButton(
                        items: [],
                        onChanged: (value) {},
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      const Text('Area'),
                      DropdownButton(
                        items: [],
                        onChanged: (value) {},
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      const Text('Password'),
                      GenericTextField(
                        obscureText: true,
                        textEditingController: TextEditingController(),
                        hint: 'Contains ',
                        iconButton: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.visibility)),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: false,
                            onChanged: (value) {},
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
                      ElevatedButton(onPressed: () {}, child: Text('Sign up'))
                    ],
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    ));
  }
}
