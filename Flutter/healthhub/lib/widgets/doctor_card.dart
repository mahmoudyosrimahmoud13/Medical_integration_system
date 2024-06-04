import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      child: Card(
        child: ListTile(
          leading: const CircleAvatar(
            backgroundImage: AssetImage(
                'assets/placeholders/pngtree-male-doctor-avatar-icon-illustration-png-image_8537702.png'),
          ),
          title: const Text("dr.Doctor"),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Specialization : ????'),
              RatingBar.builder(
                itemBuilder: (context, index) => const Icon(
                  Icons.star,
                  color: Colors.orangeAccent,
                  size: 1,
                ),
                onRatingUpdate: (value) {},
                initialRating: 5,
                minRating: 0,
                maxRating: 5,
                allowHalfRating: true,
                glowRadius: 5,
              )
            ],
          ),
          onTap: () {},
        ),
      ),
    );
  }
}
