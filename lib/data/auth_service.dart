import 'app_models.dart';
import 'app_repository.dart';

class AuthService {
  AuthService(this._repo) {
    // Make sure demo data exists.
    _repo.ensureSeeded();
  }

  final AppRepository _repo;

  /// Sign in with email and password.
  ///
  /// Throws [Exception] with a user-friendly message if credentials are invalid.
  AppUser signInOrThrow({required String email, required String password}) {
    final user = _repo.findUserByEmail(email);
    if (user == null) {
      throw Exception('No account found for this email');
    }
    if (user.password != password) {
      throw Exception('Invalid password');
    }
    return user;
  }
}

