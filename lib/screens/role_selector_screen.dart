import 'package:flutter/material.dart';
import '../app.dart';

class RoleSelectorScreen extends StatefulWidget {
  const RoleSelectorScreen({super.key});

  @override
  State<RoleSelectorScreen> createState() => _RoleSelectorScreenState();
}

class _RoleSelectorScreenState extends State<RoleSelectorScreen> {
  String? selectedRole;

  final List<String> roles = ['Admin', 'Proposer', 'Reviewer', 'HOD'];

  void _navigateToDashboard() {
    if (selectedRole == null) return;

    switch (selectedRole) {
      case 'Admin':
        Navigator.pushNamed(context, AppRoutes.adminDashboard);
        break;
      case 'Proposer':
        Navigator.pushNamed(context, AppRoutes.proposerDashboard);
        break;
      case 'Reviewer':
        Navigator.pushNamed(context, AppRoutes.reviewerDashboard);
        break;
      case 'HOD':
        Navigator.pushNamed(context, AppRoutes.hodDashboard);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select User Role')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Choose Role',
                border: OutlineInputBorder(),
              ),
              value: selectedRole,
              items: roles
                  .map(
                    (role) => DropdownMenuItem(value: role, child: Text(role)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedRole = value;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _navigateToDashboard,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
