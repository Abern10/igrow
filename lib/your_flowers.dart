import 'package:flutter/material.dart';
import 'widgets/gradient_container.dart';

class YourFlowers extends StatelessWidget {
  const YourFlowers({super.key});

  @override
  Widget build(BuildContext context) {
    return const GradientContainer(
      child: Center(
        child: Text(
          'Your Favorite Flowers',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 4.0,
                color: Colors.black45,
                offset: Offset(1.0, 1.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}