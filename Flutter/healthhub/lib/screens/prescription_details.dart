import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:healthhub/widgets/drug_card.dart';
import 'package:intl/intl.dart';

class PrescriptionDetails extends StatefulWidget {
  const PrescriptionDetails({super.key});

  @override
  State<PrescriptionDetails> createState() => _PrescriptionDetailsState();
}

class _PrescriptionDetailsState extends State<PrescriptionDetails> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final colors = Theme.of(context).colorScheme;
    final textTehme = Theme.of(context).textTheme;
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Dr.Sara',
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
                          'Phone: 01xxxxxxxx',
                          style: textTehme.bodyLarge,
                        ),
                        Text(
                          'Email: ex@example.com',
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
                          'Disease: ????',
                          style: textTehme.bodyLarge,
                        ),
                        Text(
                          'Date: ' + DateFormat.yMEd().format(DateTime.now()),
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
                        DrugCard(
                            drugName: 'drugName',
                            repeate: 'repeate',
                            instructions: 'instructions',
                            startDate: DateTime.now(),
                            endDate: DateTime.now()),
                        DrugCard(
                            drugName: 'drugName',
                            repeate: 'repeate',
                            instructions: 'instructions',
                            startDate: DateTime.now(),
                            endDate: DateTime.now()),
                        DrugCard(
                            drugName: 'drugName',
                            repeate: 'repeate',
                            instructions: 'instructions',
                            startDate: DateTime.now(),
                            endDate: DateTime.now()),
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
  }
}
