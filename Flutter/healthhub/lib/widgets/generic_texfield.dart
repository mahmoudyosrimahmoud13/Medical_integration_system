import 'package:flutter/material.dart';

// ignore: must_be_immutable
class GenericTextField extends StatelessWidget {
  GenericTextField(
      {super.key,
      required this.textEditingController,
      required this.hint,
      this.obscureText,
      this.iconButton,
      this.validator,
      this.textInputType,
      this.radius,
      this.alpha}) {
    obscureText ??= false;
    radius ??= 5;
    alpha ??= 100;
  }

  final TextEditingController textEditingController;
  final String hint;
  final IconButton? iconButton;
  final String? Function(String? value)? validator;
  final TextInputType? textInputType;
  bool? obscureText;
  double? radius;
  int? alpha;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: textEditingController,
          decoration: InputDecoration(
              focusedBorder: OutlineInputBorder(
                  borderSide:
                      const BorderSide(width: 0, color: Colors.transparent),
                  borderRadius: BorderRadius.all(Radius.circular(radius!))),
              enabledBorder: OutlineInputBorder(
                  borderSide:
                      const BorderSide(width: 0, color: Colors.transparent),
                  borderRadius: BorderRadius.all(Radius.circular(radius!))),
              border: OutlineInputBorder(
                  borderSide:
                      const BorderSide(width: 0, color: Colors.transparent),
                  borderRadius: BorderRadius.all(Radius.circular(radius!))),
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.background.withAlpha(alpha!),
              hintText: hint,
              suffixIcon: iconButton,
              suffixIconColor: Theme.of(context).colorScheme.onBackground),
          obscureText: obscureText!,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
          ),
          keyboardType: textInputType,
          validator: validator,
        ),
      ],
    );
  }
}
