import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:healthhub/cubit/get_doctor/get_doctor_cubit.dart';
import 'package:healthhub/helpers/helper_methods.dart';
import 'package:healthhub/screens/docor_details.dart';

class DoctorCard extends StatelessWidget {
  const DoctorCard(
      {super.key,
      required this.image,
      required this.name,
      required this.phone,
      required this.rate,
      required this.area,
      required this.adress,
      required this.id});
  final String image;
  final String name;
  final String phone;
  final String area;
  final String adress;
  final String id;

  final double rate;

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<GetDoctorCubit>(context).getDoctor(id: id);
    return Container(
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage(image, scale: 1000),
          ),
          title: Text("dr.$name"),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phone : $phone'),
              Text('Area : $area'),
              Text('Adress : $adress'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RatingBar.builder(
                    itemBuilder: (context, index) => const Icon(
                      Icons.star,
                      color: Colors.orangeAccent,
                      size: 1,
                    ),
                    onRatingUpdate: (value) {},
                    initialRating: rate,
                    minRating: 0,
                    maxRating: 5,
                    glowRadius: 5,
                    ignoreGestures: true,
                    itemSize: 20,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Text('(5/$rate)')
                ],
              )
            ],
          ),
          onTap: () {
            navigateTo(
                toPage: DoctorDetailsScreen(
              id: id,
            ));
          },
        ),
      ),
    );
  }
}
