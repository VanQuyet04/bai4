import 'package:flutter/material.dart';

void showCustomSnackBar(BuildContext context, String title, Color bgColor) {
  final snackBar = SnackBar(
    content: Text(title),
    backgroundColor: bgColor,
    duration: const Duration(seconds: 2),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
