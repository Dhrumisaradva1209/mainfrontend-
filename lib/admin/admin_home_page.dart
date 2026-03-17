import 'package:flutter/material.dart';

import '../data/app_models.dart';
import '../data/app_repository.dart';
import '../sign_in_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key, required this.admin});

  final AppUser admin;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _tab = 0;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  UserRole _newUserRole = UserRole.receptionist;
  bool _submitting = false;
  bool _obscure = true;

  AppRepository get _repo => AppRepository.instance;

  @override
  void initState() {
    super.initState();
    _repo.ensureSeeded();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final clinic = _repo.getClinicOrThrow(widget.admin.clinicId);
    final body = switch (_tab) {
      0 => _OverviewTab(admin: widget.admin, clinic: clinic),
      1 => _UsersTab(admin: widget.admin),
      _ => _CreateUserTab(
          admin: widget.admin,
          nameCtrl: _nameCtrl,
          emailCtrl: _emailCtrl,
          passwordCtrl: _passwordCtrl,
          role: _newUserRole,
          obscurePassword: _obscure,
          submitting: _submitting,
          onToggleObscure: () => setState(() => _obscure = !_obscure),
          onRoleChanged: (r) => setState(() => _newUserRole = r),
          onCreate: _createUser,
        ),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin • ${clinic.name}'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignInPage()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Clinic'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.person_add_alt_1_outlined), label: 'Create'),
        ],
      ),
    );
  }

  Future<void> _createUser() async {
    if (_submitting) return;

    final role = _newUserRole;
    if (role == UserRole.admin) {
      _snack('Admins cannot be created here');
      return;
    }

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (name.isEmpty) {
      _snack('Name is required');
      return;
    }

    setState(() => _submitting = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      _repo.createUserForClinic(
        clinicId: widget.admin.clinicId,
        name: name,
        email: email,
        password: password,
        role: role,
      );

      _nameCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.clear();

      if (!mounted) return;
      _snack('User created');
      setState(() => _tab = 1);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.admin, required this.clinic});

  final AppUser admin;
  final Clinic clinic;

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    final counts = repo.countUsersByRole(admin.clinicId);
    final total = repo.listUsersForClinic(admin.clinicId).length;

    Widget stat(String label, String value, IconData icon) {
      final cs = Theme.of(context).colorScheme;
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    int c(UserRole r) => counts[r] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Clinic info', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          title: Text(clinic.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(clinic.address),
          trailing: const Icon(Icons.local_hospital_outlined),
        ),
        const SizedBox(height: 18),
        Text('Counts', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        stat('Total users', '$total', Icons.groups_outlined),
        const SizedBox(height: 10),
        stat('Receptionists', '${c(UserRole.receptionist)}', Icons.support_agent_outlined),
        const SizedBox(height: 10),
        stat('Doctors', '${c(UserRole.doctor)}', Icons.medical_services_outlined),
        const SizedBox(height: 10),
        stat('Patients', '${c(UserRole.patient)}', Icons.person_outline),
      ],
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab({required this.admin});

  final AppUser admin;

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    final users = repo.listUsersForClinic(admin.clinicId);

    String roleLabel(UserRole r) => switch (r) {
      UserRole.admin => 'Admin',
      UserRole.receptionist => 'Receptionist',
      UserRole.doctor => 'Doctor',
      UserRole.patient => 'Patient',
    };

    IconData roleIcon(UserRole r) => switch (r) {
      UserRole.admin => Icons.verified_user_outlined,
      UserRole.receptionist => Icons.support_agent_outlined,
      UserRole.doctor => Icons.medical_services_outlined,
      UserRole.patient => Icons.person_outline,
    };

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, i) {
        final u = users[i];
        return ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          leading: CircleAvatar(child: Icon(roleIcon(u.role))),
          title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('${u.email}\n${roleLabel(u.role)}'),
          isThreeLine: true,
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: users.length,
    );
  }
}

class _CreateUserTab extends StatelessWidget {
  const _CreateUserTab({
    required this.admin,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.role,
    required this.obscurePassword,
    required this.submitting,
    required this.onToggleObscure,
    required this.onRoleChanged,
    required this.onCreate,
  });

  final AppUser admin;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final UserRole role;
  final bool obscurePassword;
  final bool submitting;
  final VoidCallback onToggleObscure;
  final ValueChanged<UserRole> onRoleChanged;
  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    DropdownMenuItem<UserRole> item(UserRole r, String label, IconData icon) {
      return DropdownMenuItem(
        value: r,
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 10),
            Text(label),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Create user', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                TextField(
                  controller: nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: obscurePassword ? 'Show password' : 'Hide password',
                      onPressed: submitting ? null : onToggleObscure,
                      icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  value: role,
                  items: [
                    item(UserRole.receptionist, 'Receptionist', Icons.support_agent_outlined),
                    item(UserRole.doctor, 'Doctor', Icons.medical_services_outlined),
                    item(UserRole.patient, 'Patient', Icons.person_outline),
                  ],
                  onChanged: submitting ? null : (v) => v == null ? null : onRoleChanged(v),
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: submitting ? null : onCreate,
                    child: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create user'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Users are created under your clinic automatically.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

