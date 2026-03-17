import 'package:flutter/foundation.dart';

@immutable
class Clinic {
  const Clinic({
    required this.id,
    required this.name,
    required this.address,
  });

  final String id;
  final String name;
  final String address;
}

enum UserRole {
  admin,
  receptionist,
  doctor,
  patient,
}

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.clinicId,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  final String id;
  final String clinicId;
  final String name;
  final String email;
  final String password;
  final UserRole role;
}

