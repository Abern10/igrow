import 'package:flutter/material.dart';

class GradientContainer extends StatelessWidget {
  final Widget child;
  const GradientContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8BC34A), Color(0xFF558B2F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}