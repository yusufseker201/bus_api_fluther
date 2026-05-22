import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/app_state.dart';
import '../../../state/session_state.dart';
import '../auth/login_screen.dart';
import 'tabs/lines_tab.dart';
import 'tabs/map_tab.dart';
import 'tabs/stops_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 1;
  late final Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = context.read<AppState>().loadInitialData();
    // Start polling once on entry. It will be cancelled in dispose.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().startPolling();
    });
  }

  @override
  void dispose() {
    context.read<AppState>().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final session = context.watch<SessionState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kahramanmaraş Yoğunluk'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _AuthActionButton(
              isLoggedIn: session.isLoggedIn,
              onPressed: () {
                if (session.isLoggedIn) {
                  session.logout();
                  return;
                }

                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !app.hasLoadedOnce) {
              return const Center(child: CircularProgressIndicator());
            }

            if (app.error != null && !app.hasLoadedOnce) {
              return _HomeInfoState(
                title: 'Veriler yuklenemedi',
                message: app.error!,
                actionLabel: 'Tekrar dene',
                onAction: () => context.read<AppState>().refreshAll(),
              );
            }

            return IndexedStack(
              index: _index,
              children: const [
                MapTab(),
                LinesTab(),
                StopsTab(),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (idx) => setState(() => _index = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Harita'),
          NavigationDestination(icon: Icon(Icons.directions_bus_outlined), selectedIcon: Icon(Icons.directions_bus), label: 'Hatlar'),
          NavigationDestination(icon: Icon(Icons.pin_drop_outlined), selectedIcon: Icon(Icons.pin_drop), label: 'Duraklar'),
        ],
      ),
    );
  }
}

class _AuthActionButton extends StatelessWidget {
  const _AuthActionButton({
    required this.isLoggedIn,
    required this.onPressed,
  });

  final bool isLoggedIn;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 420;
    final backgroundColor = isLoggedIn
        ? const Color(0xFFE2E8F0)
        : const Color(0xFFDBEAFE);
    final foregroundColor = isLoggedIn
        ? const Color(0xFF1E293B)
        : const Color(0xFF1D4ED8);
    final icon = isLoggedIn ? Icons.logout_rounded : Icons.login_rounded;
    final label = isLoggedIn ? 'Çıkış Yap' : 'Giriş Yap';

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: compact ? 148 : 176,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: foregroundColor),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeInfoState extends StatelessWidget {
  const _HomeInfoState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
