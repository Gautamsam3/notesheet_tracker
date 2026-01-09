// lib/widgets/greeting_section.dart

import 'package:flutter/material.dart';

class GreetingSection extends StatelessWidget {
  final String userName;

  const GreetingSection({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        'Hello, $userName 👋',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.blue[900],
        ),
      ),
    );
  }
}
