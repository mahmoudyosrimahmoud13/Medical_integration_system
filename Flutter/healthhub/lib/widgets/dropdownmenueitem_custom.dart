import 'package:flutter/material.dart';

class CustomDropdownmenueitem extends StatelessWidget {
  const CustomDropdownmenueitem({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(text),
        const Divider(),
      ],
    );
  }
}
