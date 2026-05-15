import 'dart:convert';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';

class AuthService {
  static const _requestTimeout = Duration(seconds: 12);

  AuthService({
    FirebaseAuth? firebaseAuth,
    http.Client? client,
    bool useRestAuth = false,
  })  : _client = client ?? http.Client(),
        _firebaseAuth = useRestAuth ? null : (firebaseAuth ?? FirebaseAuth.instance),
        _useRestAuth = useRestAuth,
        _disabledReason = null;

  AuthService.webFallback({http.Client? client})
    : _client = client ?? http.Client(),
      _firebaseAuth = null,
      _useRestAuth = true,
      _disabledReason = null;

  AuthService.disabled({
    http.Client? client,
    String? reason,
  })
    : _client = client ?? http.Client(),
      _firebaseAuth = null,
      _useRestAuth = false,
      _disabledReason = reason;

  static const _tokenKey = 'api_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _emailKey = 'auth_email';
  static const _nameKey = 'auth_name';

  final http.Client _client;
  final FirebaseAuth? _firebaseAuth;
  final bool _useRestAuth;
  final String? _disabledReason;

  User? get currentUser => _firebaseAuth?.currentUser;

  Future<AuthSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    if (_useRestAuth) {
      final email = prefs.getString(_emailKey);
      if (email == null || email.isEmpty) {
        return null;
      }
      return AuthSession(
        token: prefs.getString(_tokenKey),
        refreshToken: prefs.getString(_refreshTokenKey),
        email: email,
        displayName: prefs.getString(_nameKey),
      );
    }

    final auth = _firebaseAuth;
    final user = auth?.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      final session = AuthSession(
        token: token,
        email: user.email ?? '',
        displayName: user.displayName,
      );
      await saveSession(
        token: session.token,
        email: session.email,
        name: session.displayName,
      );
      return session;
    }

    final storedEmail = prefs.getString(_emailKey);
    if (storedEmail == null || storedEmail.isEmpty) {
      return null;
    }

    return AuthSession(
      token: prefs.getString(_tokenKey),
      refreshToken: prefs.getString(_refreshTokenKey),
      email: storedEmail,
      displayName: prefs.getString(_nameKey),
    );
  }

  Future<void> saveSession({
    String? token,
    String? refreshToken,
    required String email,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null && token.isNotEmpty) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    } else {
      await prefs.remove(_refreshTokenKey);
    }
    await prefs.setString(_emailKey, email);
    if (name != null && name.trim().isNotEmpty) {
      await prefs.setString(_nameKey, name.trim());
    } else {
      await prefs.remove(_nameKey);
    }
  }

  Future<void> clearSession() async {
    if (!_useRestAuth) {
      await _firebaseAuth?.signOut();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_useRestAuth) {
      return _registerWithRest(name: name, email: email, password: password);
    }

    final auth = _firebaseAuth;
    if (auth == null) {
      throw AuthException(
        _disabledReason ??
            'Firebase kimlik doğrulama başlatılamadı. Firebase ayarlarını kontrol edin.',
      );
    }

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ).timeout(_requestTimeout);
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Kayıt sonrası kullanıcı oluşturulamadı.');
      }

      await user.updateDisplayName(name.trim());
      await user.reload();

      final refreshedUser = auth.currentUser ?? user;
      final idToken = await refreshedUser.getIdToken();
      final session = AuthSession(
        token: idToken,
        email: refreshedUser.email ?? email.trim(),
        displayName: refreshedUser.displayName ?? name.trim(),
      );
      await saveSession(
        token: session.token,
        email: session.email,
        name: session.displayName,
      );
      return session;
    } on TimeoutException {
      throw const AuthException(
        'Kimlik doğrulama servisi zamanında cevap vermedi. Baglantinizi kontrol edip tekrar deneyin.',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_firebaseMessageFromCode(e.code, e.message));
    } catch (e) {
      throw AuthException(_unknownAuthMessage(e));
    }
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (_useRestAuth) {
      return _loginWithRest(email: email, password: password);
    }

    final auth = _firebaseAuth;
    if (auth == null) {
      throw AuthException(
        _disabledReason ??
            'Firebase kimlik doğrulama başlatılamadı. Firebase ayarlarını kontrol edin.',
      );
    }

    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ).timeout(_requestTimeout);
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Giriş sonrası kullanıcı bilgisi alınamadı.');
      }

      final idToken = await user.getIdToken();
      final session = AuthSession(
        token: idToken,
        email: user.email ?? email.trim(),
        displayName: user.displayName,
      );
      await saveSession(
        token: session.token,
        email: session.email,
        name: session.displayName,
      );
      return session;
    } on TimeoutException {
      throw const AuthException(
        'Kimlik doğrulama servisi zamanında cevap vermedi. Baglantinizi kontrol edip tekrar deneyin.',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_firebaseMessageFromCode(e.code, e.message));
    } catch (e) {
      throw AuthException(_unknownAuthMessage(e));
    }
  }

  Future<AuthSession> _registerWithRest({
    required String name,
    required String email,
    required String password,
  }) async {
    final apiKey = DefaultFirebaseOptions.web.apiKey;
    final signupUri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
    );

    final signUpRes = await _safeRestPost(
      signupUri,
      body: {
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      },
    );

    final signUpBody = _decodeBody(signUpRes.body);
    if (signUpRes.statusCode < 200 || signUpRes.statusCode >= 300) {
      throw AuthException(_firebaseRestMessage(signUpBody));
    }

    final idToken = signUpBody['idToken']?.toString();
    final refreshToken = signUpBody['refreshToken']?.toString();
    if (idToken == null || idToken.isEmpty) {
      throw const AuthException('Kayıt başarılı oldu ama oturum anahtarı alınamadı.');
    }

    final updateUri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:update?key=$apiKey',
    );
    final updateRes = await _safeRestPost(
      updateUri,
      body: {
        'idToken': idToken,
        'displayName': name.trim(),
        'returnSecureToken': true,
      },
    );

    final updateBody = _decodeBody(updateRes.body);
    if (updateRes.statusCode < 200 || updateRes.statusCode >= 300) {
      throw AuthException(_firebaseRestMessage(updateBody));
    }

    final session = AuthSession(
      token: updateBody['idToken']?.toString() ?? idToken,
      refreshToken: updateBody['refreshToken']?.toString() ?? refreshToken,
      email: updateBody['email']?.toString() ?? email.trim(),
      displayName: updateBody['displayName']?.toString() ?? name.trim(),
    );

    await saveSession(
      token: session.token,
      refreshToken: session.refreshToken,
      email: session.email,
      name: session.displayName,
    );
    return session;
  }

  Future<AuthSession> _loginWithRest({
    required String email,
    required String password,
  }) async {
    final apiKey = DefaultFirebaseOptions.web.apiKey;
    final signInUri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
    );

    final signInRes = await _safeRestPost(
      signInUri,
      body: {
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      },
    );

    final signInBody = _decodeBody(signInRes.body);
    if (signInRes.statusCode < 200 || signInRes.statusCode >= 300) {
      throw AuthException(_firebaseRestMessage(signInBody));
    }

    final session = AuthSession(
      token: signInBody['idToken']?.toString(),
      refreshToken: signInBody['refreshToken']?.toString(),
      email: signInBody['email']?.toString() ?? email.trim(),
      displayName: signInBody['displayName']?.toString(),
    );

    await saveSession(
      token: session.token,
      refreshToken: session.refreshToken,
      email: session.email,
      name: session.displayName,
    );
    return session;
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  Future<http.Response> _safeRestPost(
    Uri uri, {
    required Map<String, dynamic> body,
  }) async {
    try {
      return await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const AuthException(
        'Kimlik doğrulama servisi zamaninda cevap vermedi. Baglantinizi kontrol edip tekrar deneyin.',
      );
    } on http.ClientException catch (e) {
      throw AuthException(_restConnectionMessage(e.message));
    } catch (e) {
      throw AuthException(_unknownAuthMessage(e));
    }
  }

  String _firebaseRestMessage(Map<String, dynamic> body) {
    final error = body['error'];
    if (error is Map<String, dynamic>) {
      final code = error['message']?.toString();
      return _firebaseMessageFromCode(code, null);
    }
    return 'Kimlik doğrulama sırasında bir hata oluştu.';
  }

  String _firebaseMessageFromCode(String? code, String? fallbackMessage) {
    switch (code) {
      case 'EMAIL_EXISTS':
      case 'email-already-in-use':
        return 'Bu e-posta ile zaten kayıt olunmuş.';
      case 'INVALID_EMAIL':
      case 'invalid-email':
        return 'Geçerli bir e-posta adresi girin.';
      case 'WEAK_PASSWORD':
      case 'weak-password':
        return 'Şifre en az 6 karakter olmalı.';
      case 'INVALID_LOGIN_CREDENTIALS':
      case 'EMAIL_NOT_FOUND':
      case 'INVALID_PASSWORD':
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'TOO_MANY_ATTEMPTS_TRY_LATER':
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Biraz sonra tekrar deneyin.';
      case 'network-request-failed':
        return 'Ağ bağlantısı kurulamadı. İnternetinizi kontrol edin.';
      case 'OPERATION_NOT_ALLOWED':
        return 'Firebase üzerinde Email/Password girişi aktif değil.';
      case 'web-context-cancelled':
      case 'popup-closed-by-user':
        return 'Kimlik doğrulama işlemi yarıda kesildi.';
      case 'app-not-authorized':
      case 'INVALID_APP_CREDENTIAL':
      case 'INVALID_APP_ID':
      case 'invalid-app-credential':
        return 'Firebase uygulama ayarlari gecerli degil. Proje konfigurasyonunu kontrol edin.';
      case 'unauthorized-domain':
        return 'Bu domain Firebase Authentication icin yetkili degil. Firebase Console > Authentication > Settings > Authorized domains kismina localhost ekleyin.';
      case 'API_KEY_SERVICE_BLOCKED':
      case 'API_KEY_HTTP_REFERRER_BLOCKED':
      case 'PROJECT_NOT_FOUND':
      case 'CONFIGURATION_NOT_FOUND':
        return 'Firebase web ayarlarinda bir yapilandirma sorunu var. API anahtari, authDomain ve yetkili domain ayarlarini kontrol edin.';
      default:
        return fallbackMessage ?? 'Kimlik doğrulama sırasında bir hata oluştu.';
    }
  }

  String _unknownAuthMessage(Object error) {
    final raw = error.toString();

    if (raw.contains('Failed to fetch')) {
      return _restConnectionMessage(raw);
    }

    return 'Kimlik doğrulama sırasında beklenmeyen bir hata oluştu: $raw';
  }

  String _restConnectionMessage(String raw) {
    final hints = <String>[
      'Kimlik doğrulama servisine baglanilamadi.',
    ];

    if (kIsWeb) {
      hints.add(
        'Firebase Console > Authentication > Settings > Authorized domains kismina localhost ekli oldugundan emin olun.',
      );
      hints.add(
        'Tarayicida reklam engelleyici, privacy eklentisi veya kurumsal ag filtresi Google/Firebase isteklerini engelliyor olabilir.',
      );
    }

    if (raw.isNotEmpty) {
      hints.add('Teknik detay: $raw');
    }

    return hints.join(' ');
  }
}

class AuthSession {
  const AuthSession({
    required this.email,
    this.token,
    this.refreshToken,
    this.displayName,
  });

  final String email;
  final String? token;
  final String? refreshToken;
  final String? displayName;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
