import 'package:flutter/material.dart';

import 'data/app_models.dart';
import 'sign_in_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    String roleLabel(UserRole r) => switch (r) {
      UserRole.admin => 'Admin',
      UserRole.receptionist => 'Receptionist',
      UserRole.doctor => 'Doctor',
      UserRole.patient => 'Patient',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome,',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              user.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text('${user.email} • ${roleLabel(user.role)}'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SignInPage()),
                  (_) => false,
                );
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

