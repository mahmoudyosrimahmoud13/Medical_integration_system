import 'package:animate_do/animate_do.dart';
import 'package:final_project/cubits/cubit/register_cubit_cubit.dart';
import 'package:final_project/pages/SignUp/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // تعريف متغير بولياني لتمثيل الجنس

  String selectedCity = 'Government';

  Map<String, List<String>> cityAreaMap = {
    'Government': ['Area'],
    'Cairo': ['Nasr City', 'Maadi', 'Zamalek', 'Heliopolis', 'Dokki'],
    'Alexandria': ['Gleem', 'Sidi Gaber', 'Montaza', 'Roushdy', 'Stanley'],
    'Giza': [
      'Warraq',
      'Smart Village',
      'Haram',
      'Saft Allaban',
      '6th of October'
    ],
    'Luxor': ['Luxor City', 'Karnak', 'West Bank', 'East Bank', 'New Karnak'],
    'Aswan': [
      'Aswan City',
      'Elephantine Island',
      'Nubian Village',
      'Kom Ombo',
      'Philae'
    ],
    'Suez': ['Suez City', 'Ismailia', 'Port Said', 'El Arish', 'Rafah'],
    'Red Sea': [
      'Hurghada',
      'Sharm El Sheikh',
      'Marsa Alam',
      'El Gouna',
      'Dahab'
    ],
    'South Sinai': ['Dahab', 'Nuweiba', 'Saint Catherine', 'Ras Sudr', 'Taba'],
    'North Sinai': ['Arish', 'Rafah', 'Sheikh Zuweid', 'Bir al-Abed', 'Nakhl'],
    'Sharqia': ['Zagazig', 'Faqous', 'Husseiniya', 'Abu Hammad', 'Bilbeis'],
    'Dakahlia': [
      'Mansoura',
      'Talkha',
      'Mit Ghamr',
      'Mitt Abu al-Kum',
      'Dekernes'
    ],
    'Gharbia': ['Tanta', 'Kafr El Zayat', 'Mahalla', 'Basyoun', 'Samanoud'],
    'Faiyum': ['Faiyum City', 'Tamiya', 'Ibsheway', 'Senouras', 'Sinnuris'],
    'Beni Suef': ['Beni Suef City', 'Nasser', 'Beba', 'El-Wasta', 'Bibin'],
    'Minya': ['Minya City', 'Beni Mazar', 'Maghagha', 'Deir Mawas', 'Mallawi'],
    'Assiut': ['Assiut City', 'Manfalut', 'Badari', 'Abu Tig', 'Dairut'],
    'Sohag': ['Sohag City', 'Akhmim', 'Girga', 'Tahta', 'Maragha'],
    'Qena': ['Qena City', 'Nag Hammadi', 'Luxor', 'Dishna', 'Naqada'],
    'New Valley': ['Kharga', 'Dakhla', 'Farafra', 'Mut', 'Baris'],
    'Matrouh': ['Marsa Matrouh', 'Siwa', 'Sallum', 'El Hamam', 'Alamein'],
  };

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegisterCubit(),
      child: Builder(
        builder: (context) {
          RegisterCubit cubit = BlocProvider.of<RegisterCubit>(context);
          return Scaffold(
            resizeToAvoidBottomInset: true,
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
            body: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  height: MediaQuery.of(context).size.height,
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      FadeInUp(
                        duration: const Duration(milliseconds: 1000),
                        child: Container(
                            height: 64,
                            width: 195,
                            decoration: const BoxDecoration(
                                image: DecorationImage(
                                    image: AssetImage("assets/pngimg/11.png"),
                                    fit: BoxFit.fill))),
                      ),
                      Column(
                        children: <Widget>[
                          FadeInUp(
                              duration: const Duration(milliseconds: 1000),
                              child: const Text(
                                "Sign up",
                                style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Kanit'),
                              )),
                          const SizedBox(
                            height: 10,
                          ),
                          FadeInUp(
                              duration: const Duration(milliseconds: 1200),
                              child: Text(
                                "Create an account, It's free",
                                style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                    fontFamily: 'Kanit'),
                              )),
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          FadeInUp(
                            duration: const Duration(milliseconds: 1400),
                            child: Form(
                              key: cubit.formkey,
                              autovalidateMode: cubit.autovalidateMode,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: RegisterCubit.get(context)
                                        .fullNameController,
                                    decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.person_2),
                                        labelText: "Full Name",
                                        labelStyle:
                                            TextStyle(fontFamily: "Kanit")),
                                  ),
                                  TextFormField(
                                    controller: RegisterCubit.get(context)
                                        .emailController,
                                    decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.mail),
                                        labelText: "Email",
                                        labelStyle:
                                            TextStyle(fontFamily: "Kanit")),
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
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
                                    onSaved: (value) {
                                      // Save the email to your model or state
                                    },
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                  ),
                                  TextFormField(
                                    controller: cubit.passwordController,
                                    decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.lock),
                                        labelText: "Password",
                                        labelStyle:
                                            TextStyle(fontFamily: "Kanit")),
                                    obscureText: true,
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
                                      if (!passwordRegex.hasMatch(value)) {
                                        return 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character';
                                      }
                                      return null;
                                    },
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                  ),
                                  TextFormField(
                                    controller: RegisterCubit.get(context)
                                        .confirmPasswordController,
                                    decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.lock),
                                        labelText: "Confirm Password",
                                        labelStyle:
                                            TextStyle(fontFamily: "Kanit")),
                                    obscureText: true,
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return 'Please enter your password again';
                                      }
                                      // Check if passwords match
                                      if (value !=
                                          cubit.passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                  ),
                                  TextFormField(
                                    controller: RegisterCubit.get(context)
                                        .phoneNumberController,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone Number',
                                      prefixIcon: Icon(Icons.phone),
                                      hintText: 'Enter your phone number',
                                    ),
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return 'Please enter your phone number';
                                      }
                                      // You can add more validation logic here if needed
                                      return null;
                                    },
                                    onSaved: (value) {
                                      // Save the phone number to your model or state
                                    },
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          FadeInUp(
                            duration: const Duration(milliseconds: 1400),
                            child: TextField(
                              controller:
                                  RegisterCubit.get(context).dateController,
                              readOnly: true, // Make the text field read-only
                              decoration: InputDecoration(
                                labelText: 'Birth Date',
                                prefixIcon: const Icon(Icons
                                    .calendar_today), // Add a calendar icon as a prefix
                                border: OutlineInputBorder(
                                  // Add border with rounded corners
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  // Add focused border
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(
                                    color: Theme.of(context)
                                        .primaryColor, // Use the primary color for the border
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              onTap: () => _selectDate(context),
                            ),
                          ),
                          FadeInUp(
                              duration: const Duration(milliseconds: 1400),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  DropdownButton<bool>(
                                    value: RegisterCubit.get(context).isMale,
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontFamily: "Kanit"),
                                    onChanged: (newValue) {
                                      setState(() {
                                        RegisterCubit.get(context).isMale =
                                            newValue!;
                                      });
                                    },
                                    items: const [
                                      DropdownMenuItem<bool>(
                                        value: true,
                                        child: Text("Male"),
                                      ),
                                      DropdownMenuItem<bool>(
                                        value: false,
                                        child: Text("Female"),
                                      ),
                                    ],
                                  ),
                                  DropdownButton<String>(
                                    value: selectedCity,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedCity = newValue!;
                                        // When city changes, update the selected sub-city
                                        RegisterCubit.get(context)
                                                .selectedArea =
                                            cityAreaMap[selectedCity]![0];
                                      });
                                    },
                                    items: cityAreaMap.keys
                                        .map<DropdownMenuItem<String>>(
                                            (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 20),
                                  DropdownButton<String>(
                                    value:
                                        RegisterCubit.get(context).selectedArea,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        RegisterCubit.get(context)
                                            .selectedArea = newValue!;
                                      });
                                    },
                                    items: cityAreaMap[selectedCity]!
                                        .map<DropdownMenuItem<String>>(
                                            (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              )),
                        ],
                      ),
                      FadeInUp(
                        duration: const Duration(milliseconds: 1500),
                        child: BlocBuilder<RegisterCubit, RegisterStates>(
                          builder: (context, state) {
                            if (state is RegisterCubitLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return MaterialButton(
                              minWidth: double.infinity,
                              height: 60,
                              onPressed: () {
                                RegisterCubit.get(context).postform();
                              },
                              color: Colors.black,
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
                            );
                          },
                        ),
                      ),
                      FadeInUp(
                          duration: const Duration(milliseconds: 1600),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Text("Already have an account?"),
                              GestureDetector(
                                child: const Text(
                                  " Login",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      fontFamily: 'Kanit'),
                                ),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginPage()));
                                },
                              ),
                            ],
                          )),
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

  @override
  void dispose() {
    RegisterCubit.get(context).confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        // Update the birthday text field value with the selected date
        RegisterCubit.get(context)
            .updateBirthdayField(DateFormat('dd/MM/yyyy').format(pickedDate));
      });
    }
  }
}
