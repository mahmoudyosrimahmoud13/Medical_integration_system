import 'package:flutter/material.dart';

class SortWidget extends StatelessWidget {
  const SortWidget({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: colors.onPrimary),
        borderRadius: BorderRadius.all(Radius.circular(50)),
      ),
      child: Text(
        text,
        style: TextStyle(color: colors.onPrimary),
      ),
    );
  }
}
