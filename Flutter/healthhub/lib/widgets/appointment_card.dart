import 'package:flutter/material.dart';

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({super.key, this.onDismissed, required this.dKey});

  final void Function(DismissDirection)? onDismissed;
  final Key dKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      child: Dismissible(
        key: dKey,
        onDismissed: onDismissed,
        direction: DismissDirection.endToStart,
        background: Card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.onError,
                ),
              )
            ],
          ),
          color: Theme.of(context).colorScheme.error,
        ),
        child: Card(
          child: ListTile(
            leading: const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(
                  'assets/placeholders/pngtree-male-doctor-avatar-icon-illustration-png-image_8537702.png'),
            ),
            title: const Text("dr.Doctor"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('From : ????'),
                const Text('To : ????'),
              ],
            ),
            onTap: () {},
          ),
        ),
      ),
    );
  }
}
