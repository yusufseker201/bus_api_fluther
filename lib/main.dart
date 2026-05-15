import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'state/app_state.dart';
import 'state/session_state.dart';
import 'ui/screens/home/home_screen.dart';
import 'ui/theme/app_theme.dart';

bool _firebaseReady = false;
String? _firebaseInitError;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebaseIfSupported();

  ErrorWidget.builder = (details) {
    return Material(
      color: const Color(0xFFF7F8FB),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Uygulama baslatilirken hata olustu.\n\n${details.exception}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ),
    );
  };

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter startup error: ${details.exceptionAsString()}');
    debugPrintStack(stackTrace: details.stack);
  };

  runApp(const BusDensityMobileApp());
}

Future<void> _initializeFirebaseIfSupported() async {
  if (!_supportsFirebaseOnCurrentPlatform()) {
    return;
  }

  try {
    if (Firebase.apps.isEmpty) {
      final initialize = Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      if (kIsWeb) {
        await initialize.timeout(const Duration(seconds: 20));
      } else {
        await initialize.timeout(const Duration(seconds: 8));
      }
    } else {
      Firebase.app();
    }
    _firebaseReady = true;
    _firebaseInitError = null;
  } catch (e, stackTrace) {
    _firebaseReady = false;
    _firebaseInitError = e.toString();
    debugPrint('Firebase initialize error: $e');
    debugPrintStack(stackTrace: stackTrace);
  }
}

bool _supportsFirebaseOnCurrentPlatform() {
  if (kIsWeb) return true;

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => true,
    TargetPlatform.iOS => true,
    TargetPlatform.macOS => true,
    TargetPlatform.windows => true,
    TargetPlatform.linux => false,
    TargetPlatform.fuchsia => false,
  };
}

class BusDensityMobileApp extends StatelessWidget {
  const BusDensityMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(
          create: (_) => _firebaseReady
              ? AuthService()
              : (kIsWeb
                    ? AuthService.webFallback()
                    : AuthService.disabled(
                        reason:
                            'Firebase kimlik doğrulama baslatilamadi. ${_firebaseInitError ?? 'Firebase ayarlarini kontrol edin.'}',
                      )),
        ),
        ChangeNotifierProvider(
          create: (context) => SessionState(context.read<AuthService>())..load(),
        ),
        ProxyProvider<SessionState, ApiService>(
          update: (_, session, previous) => ApiService(tokenProvider: () => session.token),
        ),
        ChangeNotifierProxyProvider<ApiService, AppState>(
          create: (context) => AppState(context.read<ApiService>())..refreshAll(),
          update: (_, api, state) => (state ?? AppState(api))..updateApi(api),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kahramanmaraş Otobüs Yoğunluğu',
        theme: AppTheme.light(),
        home: const AppRoot(),
      ),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();
    if (session.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (session.error != null && session.error!.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Başlangıç Uyarısı')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.error_outline, size: 56),
              const SizedBox(height: 16),
              Text(
                'Oturum yüklenirken bir sorun oluştu',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                session.error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.read<SessionState>().load(),
                child: const Text('Tekrar dene'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                ),
                child: const Text('Uygulamayı yine de aç'),
              ),
            ],
          ),
        ),
      );
    }
    return const HomeScreen();
  }
}
