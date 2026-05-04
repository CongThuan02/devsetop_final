import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'vault_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isRegister = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(authRepositoryProvider);
      final session = _isRegister
          ? await auth.register(
              email: _email.text.trim(),
              masterPassword: _password.text,
            )
          : await auth.signIn(
              email: _email.text.trim(),
              masterPassword: _password.text,
            );
      ref.read(sessionProvider.notifier).set(session);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const VaultScreen()),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegister ? 'Đăng ký' : 'Đăng nhập'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Master password (≥12 ký tự)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_isRegister ? 'Tạo tài khoản' : 'Mở khoá'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() => _isRegister = !_isRegister),
              child: Text(_isRegister
                  ? 'Đã có tài khoản? Đăng nhập'
                  : 'Chưa có tài khoản? Đăng ký'),
            ),
            if (_isRegister)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  '⚠ Master password KHÔNG thể khôi phục. '
                  'Nếu quên, toàn bộ dữ liệu mất vĩnh viễn.',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
