import 'package:flutter/material.dart';
import 'package:healthhub/helpers/helper_methods.dart';
import 'package:healthhub/screens/prescription_details.dart';

class PrescriptionCard extends StatelessWidget {
  const PrescriptionCard({
    super.key,
    this.onDismissed,
    required this.dKey,
    required this.doctorName,
    required this.date,
    required this.doctorImg,
    required this.doctorPhone,
    required this.doctorEmail,
    required this.index,
    required this.diseaseName,
  });

  final void Function(DismissDirection)? onDismissed;
  final Key dKey;
  final int index;
  final String doctorImg;
  final String doctorPhone;
  final String doctorEmail;
  final String doctorName;
  final String diseaseName;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            foregroundImage: NetworkImage(
                'http://healthhubserver.runasp.net/Image/User/$doctorImg'),
          ),
          title: Text("dr.$doctorName"),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: $date'),
              Text('Disease: $diseaseName'),
              Text('Phone: $doctorPhone'),
              Text('email: $doctorEmail'),
            ],
          ),
          onTap: () {
            navigateTo(toPage: PrescriptionDetails());
          },
        ),
      ),
    );
  }
}
