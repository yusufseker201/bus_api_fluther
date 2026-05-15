import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class SessionState extends ChangeNotifier {
  SessionState(this._authService);

  final AuthService _authService;

  String? _token;
  String? _email;
  String? _displayName;
  String? _error;
  bool _isLoading = false;

  String? get token => _token;
  String? get email => _email;
  String? get displayName => _displayName;
  String? get error => _error;
  bool get isLoggedIn => _authService.currentUser != null || (_token != null && _token!.isNotEmpty);
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final session = await _authService.loadSession();
      _token = session?.token;
      _email = session?.email;
      _displayName = session?.displayName;
    } catch (e) {
      _token = null;
      _email = null;
      _displayName = null;
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final session = await _authService.login(email: email, password: password);
      _token = session.token;
      _email = session.email;
      _displayName = session.displayName;
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final session = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      _token = session.token;
      _email = session.email;
      _displayName = session.displayName;
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.clearSession();
    _token = null;
    _email = null;
    _displayName = null;
    notifyListeners();
  }
}
