import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class Notifications extends StatelessWidget {
  const Notifications({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: Container(
        child: Column(
          children: [
            SvgPicture(SvgAssetLoader('assets/Push notifications-amico.svg')),
            Text(
              'You don\'t have notifications.',
              style: Theme.of(context).textTheme.titleLarge,
            )
          ],
        ),
      ),
    );
  }
}
