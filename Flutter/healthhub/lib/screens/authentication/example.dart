import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:healthhub/cubit/adress/adress_cubit.dart';
import 'package:healthhub/models/Register_user_model.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    File file;
    final Map<dynamic, dynamic> response;

    return BlocBuilder<AdressCubit, AdressState>(
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
              child: Center(
            child: Column(
              children: [
                ElevatedButton(
                    onPressed: () async {
                      final image = ImagePicker();
                      final lol =
                          await image.pickImage(source: ImageSource.gallery);
                      print(lol!.path);
                      file = File(lol!.path);
                      final url1 =
                          Uri.http('healthhub.runasp.net', '/auth/Register');
                      FormData dat = FormData.fromMap({
                        'img': await MultipartFile.fromFile(lol.path,
                            filename: 'fgf',
                            contentType: MediaType('image', 'png')),
                        'input': jsonEncode({
                          'name': 'mahmoud yosri',
                          'email': '1.3theoneaboveall@gmail.com',
                          'password': 'FakeMan11@',
                          'phone': '0111887',
                          'birday': DateTime.now().toString(),
                          'area': 'Mina El-Basal',
                          'gender': true
                        })
                      });
                      final dio = Dio(BaseOptions(
                          baseUrl: 'http://healthhub.runasp.net',
                          headers: {'accept': 'multipart/form-data'}));

                      try {
                        final response =
                            await dio.post('/Auth/Register', data: dat);
                        print('fsssssssssssssssssssssssssssssssssssssss');
                        print(response);
                      } catch (e) {
                        print(e);
                      }
                    },
                    child: Text('image')),
                ElevatedButton(onPressed: () {}, child: Text(''))
              ],
            ),
          )),
        );
      },
    );
  }
}
