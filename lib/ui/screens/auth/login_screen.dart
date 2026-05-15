import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/session_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final session = context.read<SessionState>();
    try {
      if (_isRegisterMode) {
        await session.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await session.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegisterMode ? 'Kayıt Ol' : 'Giriş Yap'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFDBEAFE),
                          Color(0xFFF8FAFC),
                          Color(0xFFFFF7ED),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.directions_bus_rounded, size: 30),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _isRegisterMode
                              ? 'Yeni hesap oluştur'
                              : 'Hesabınla giriş yap',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRegisterMode
                              ? 'Kayıt olan kullanıcılar Firebase Authentication içinde görünecek.'
                              : 'Kayıt olduğun e-posta ve şifre ile tekrar giriş yapabilirsin.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_isRegisterMode) ...[
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Ad Soyad',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (!_isRegisterMode) return null;
                                  if (value == null || value.trim().length < 3) {
                                    return 'Ad soyad en az 3 karakter olmalı.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'E-posta',
                                prefixIcon: Icon(Icons.alternate_email),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty) {
                                  return 'E-posta zorunlu.';
                                }
                                if (!email.contains('@') || !email.contains('.')) {
                                  return 'Geçerli bir e-posta girin.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _hidePassword,
                              textInputAction:
                                  _isRegisterMode ? TextInputAction.next : TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: 'Şifre',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                                  icon: Icon(
                                    _hidePassword ? Icons.visibility_off : Icons.visibility,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Şifre zorunlu.';
                                }
                                if (_isRegisterMode && value.length < 6) {
                                  return 'Şifre en az 6 karakter olmalı.';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) {
                                if (!_isRegisterMode && !session.isLoading) {
                                  _submit();
                                }
                              },
                            ),
                            if (_isRegisterMode) ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _hideConfirmPassword,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Şifre Tekrar',
                                  prefixIcon: const Icon(Icons.verified_user_outlined),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _hideConfirmPassword = !_hideConfirmPassword,
                                    ),
                                    icon: Icon(
                                      _hideConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (!_isRegisterMode) return null;
                                  if (value == null || value.isEmpty) {
                                    return 'Şifre tekrar zorunlu.';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Şifreler birbiriyle aynı olmalı.';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) {
                                  if (!session.isLoading) {
                                    _submit();
                                  }
                                },
                              ),
                            ],
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              Text(
                                _error!,
                                style: TextStyle(color: Theme.of(context).colorScheme.error),
                              ),
                            ],
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: session.isLoading ? null : _submit,
                              icon: session.isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Icon(_isRegisterMode ? Icons.person_add_alt_1 : Icons.login),
                              label: Text(_isRegisterMode ? 'Kayıt Ol' : 'Giriş Yap'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: session.isLoading ? null : _toggleMode,
                              child: Text(
                                _isRegisterMode
                                    ? 'Zaten hesabın var mı? Giriş yap'
                                    : 'Hesabın yok mu? Kayıt ol',
                              ),
                            ),
                          ],
                        ),
                      ),
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
