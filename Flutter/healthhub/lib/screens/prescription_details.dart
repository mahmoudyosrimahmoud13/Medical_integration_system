import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:healthhub/cubit/get_prescriptions/get_prescriptions_cubit.dart';
import 'package:healthhub/screens/loading_screen.dart';
import 'package:healthhub/widgets/drug_card.dart';
import 'package:intl/intl.dart';

class PrescriptionDetails extends StatefulWidget {
  const PrescriptionDetails({super.key, required this.index});
  final int index;

  @override
  State<PrescriptionDetails> createState() => _PrescriptionDetailsState();
}

class _PrescriptionDetailsState extends State<PrescriptionDetails> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final colors = Theme.of(context).colorScheme;
    final textTehme = Theme.of(context).textTheme;
    return BlocBuilder<GetPrescriptionsCubit, GetPrescriptionsState>(
      builder: (context, state) {
        if (state is GetPrescriptionsSuccess) {
          final data = state.data[widget.index];

          final List medications = data['repentances'];
          final drugs = medications
              .map(
                (e) => DrugCard(
                    drugName: e['drugName'],
                    repeat: e['repeat'].toString(),
                    repeatCount: e['repeatCount'].toString(),
                    note: e['note'].toString(),
                    startdate: e['nostartdatete'].toString(),
                    enddate: e['enddate'].toString()),
              )
              .toList();
          print(widget.index);
          print(data);
          return Scaffold(
            backgroundColor: colors.primary,
            body: Container(
              child: Column(
                children: [
                  Container(
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
                    child: Container(
                      decoration: BoxDecoration(
                          color: colors.onPrimary,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(25),
                              topRight: Radius.circular(25))),
                      child: SingleChildScrollView(
                        child: Container(
                          padding: EdgeInsets.all(20),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Dr.${data['dcotorName']}',
                                    style: textTehme.displaySmall,
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: colors.primary),
                                    onPressed: () {},
                                    child: Icon(
                                      Icons.qr_code_rounded,
                                      color: colors.onPrimary,
                                    ),
                                  )
                                ],
                              ),
                              Text(
                                'Phone: ${data['doctorPhone']}',
                                style: textTehme.bodyLarge,
                              ),
                              Text(
                                'Email: ${data['doctorEmail']}',
                                style: textTehme.bodyLarge,
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Divider(),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                'Prescription details',
                                style: textTehme.titleLarge,
                              ),
                              Text(
                                'Disease: ${data['diseaseName']}',
                                style: textTehme.bodyLarge,
                              ),
                              Text(
                                'Date: ${data['date']}',
                                style: textTehme.bodyLarge,
                              ),
                              SizedBox(
                                height: 25,
                              ),
                              Text(
                                'Medications',
                                style: textTehme.titleLarge,
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Column(
                                children: [...drugs],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        } else {
          return const LoadingScreen();
        }
      },
    );
  }
}
