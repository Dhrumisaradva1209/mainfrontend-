import 'dart:collection';

import 'app_models.dart';

/// Simple in-memory repository used just for demo / local state.
class AppRepository {
  AppRepository._internal();

  static final AppRepository instance = AppRepository._internal();

  final Map<String, Clinic> _clinicsById = {};
  final Map<String, AppUser> _usersById = {};

  bool _seeded = false;

  /// Ensure we have one demo clinic and some demo users.
  void ensureSeeded() {
    if (_seeded) return;
    _seeded = true;

    const clinic = Clinic(
      id: 'clinic_1',
      name: 'Sunrise Health Clinic',
      address: '123 Main Street, Ahmedabad',
    );
    _clinicsById[clinic.id] = clinic;

    AppUser mkUser(String id, String name, String email, String password, UserRole role) {
      return AppUser(
        id: id,
        clinicId: clinic.id,
        name: name,
        email: email.toLowerCase(),
        password: password,
        role: role,
      );
    }

    final users = <AppUser>[
      mkUser('u_admin', 'Admin User', 'admin@clinic.com', 'admin123', UserRole.admin),
      mkUser('u_doctor', 'Dr. Patel', 'doctor@clinic.com', 'doctor123', UserRole.doctor),
      mkUser('u_reception', 'Reception Staff', 'reception@clinic.com', 'reception123', UserRole.receptionist),
      mkUser('u_patient', 'Patient Demo', 'patient@clinic.com', 'patient123', UserRole.patient),
    ];

    for (final u in users) {
      _usersById[u.id] = u;
    }
  }

  Clinic getClinicOrThrow(String id) {
    final clinic = _clinicsById[id];
    if (clinic == null) {
      throw Exception('Clinic not found');
    }
    return clinic;
  }

  List<AppUser> listUsersForClinic(String clinicId) {
    return _usersById.values.where((u) => u.clinicId == clinicId).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Map<UserRole, int> countUsersByRole(String clinicId) {
    final result = <UserRole, int>{};
    for (final u in listUsersForClinic(clinicId)) {
      result[u.role] = (result[u.role] ?? 0) + 1;
    }
    return UnmodifiableMapView(result);
  }

  /// Create a new user in the given clinic.
  ///
  /// Throws [Exception] if the email already exists for that clinic.
  void createUserForClinic({
    required String clinicId,
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw Exception('Email is required');
    }
    if (password.isEmpty) {
      throw Exception('Password is required');
    }

    // Make sure clinic exists.
    getClinicOrThrow(clinicId);

    final alreadyExists = _usersById.values.any(
      (u) => u.clinicId == clinicId && u.email == normalizedEmail,
    );
    if (alreadyExists) {
      throw Exception('A user with this email already exists');
    }

    final id = 'u_${_usersById.length + 1}';
    final user = AppUser(
      id: id,
      clinicId: clinicId,
      name: name,
      email: normalizedEmail,
      password: password,
      role: role,
    );
    _usersById[user.id] = user;
  }

  /// Find user by email for sign-in.
  AppUser? findUserByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    return _usersById.values.firstWhere(
      (u) => u.email == normalized,
      // orElse: () => null,
    );
  }
}

