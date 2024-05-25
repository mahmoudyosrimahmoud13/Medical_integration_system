import 'package:flutter/material.dart';

class GenericDropDownButton extends StatelessWidget {
  const GenericDropDownButton(
      {super.key,
      required this.items,
      this.onChanged,
      required this.color,
      required this.style});
  final List<DropdownMenuItem<dynamic>> items;
  final void Function(dynamic)? onChanged;
  final Color color;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(12)),
        child: DropdownButton(
          dropdownColor: Colors.amber,
          focusColor: Colors.amber,
          hint: Text('fksnfknds'),
          borderRadius: BorderRadius.circular(12),
          underline: SizedBox.shrink(),
          items: items,
          onChanged: onChanged,
          style: style,
        ));
  }
}
