import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/validation/validators.dart';
import '../providers/app_providers.dart';
import 'vault_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isRegister = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  String _humanizeError(Object e) {
    final msg = e.toString();
    if (msg.contains('invalid-credential') ||
        msg.contains('INVALID_LOGIN_CREDENTIALS') ||
        msg.contains('user-not-found') ||
        msg.contains('wrong-password')) {
      return 'Tài khoản hoặc mật khẩu không chính xác. '
          'Nếu đây là lần đầu, hãy chuyển sang "Đăng ký".';
    }
    if (msg.contains('email-already-in-use')) {
      return 'Email này đã được đăng ký. Hãy chọn "Đăng nhập".';
    }
    if (msg.contains('weak-password')) {
      return 'Mật khẩu quá yếu (cần ≥6 ký tự, khuyến nghị ≥12).';
    }
    if (msg.contains('invalid-email')) {
      return 'Thư điện tử không hợp lệ.';
    }
    if (msg.contains('network')) {
      return 'Lỗi mạng. Hãy kiểm tra kết nối internet.';
    }
    if (msg.contains('too-many-requests')) {
      return 'Quá nhiều lần thử. Hãy đợi vài phút rồi thử lại.';
    }
    return msg;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      final session =
          _isRegister
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
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const VaultScreen()));
    } catch (e) {
      setState(() => _error = _humanizeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isRegister ? 'Đăng kýs' : 'Đăng nhậps')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Tài khoản',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: _isRegister ? 'Mật khẩu (≥6 ký tự)' : 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator:
                    _isRegister
                        ? Validators.masterPassword
                        : Validators.signInPassword,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child:
                    _busy
                        ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(_isRegister ? 'Tạo tài khoản' : 'Đăng nhập'),
              ),
              TextButton(
                onPressed:
                    _busy
                        ? null
                        : () => setState(() {
                          _isRegister = !_isRegister;
                          _error = null;
                          _formKey.currentState?.reset();
                        }),
                child: Text(
                  _isRegister
                      ? 'Đã có tài khoản? Đăng nhập'
                      : 'Chưa có tài khoản? Đăng ký',
                ),
              ),
              if (_isRegister)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    '⚠ Mật khẩu KHÔNG thể khôi phục. '
                    'Nếu quên, toàn bộ dữ liệu sẽ mất vĩnh viễn.',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
