import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  const InfoCard(this.image,{
    super.key, required this.name, required this.role,  
  });
  final String name, role, image;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {},
      leading: CircleAvatar(
          backgroundColor: Colors.white24,
          child: CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage(image),
          )),
      title: Text(
        name,
        style: TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        role,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
