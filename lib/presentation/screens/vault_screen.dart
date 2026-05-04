import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/vault_item.dart';
import '../providers/app_providers.dart';
import 'auth_screen.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  late Future<List<VaultItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final repo = ref.read(vaultRepositoryProvider);
    _itemsFuture = repo == null ? Future.value([]) : repo.listItems();
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).signOut();
    ref.read(sessionProvider.notifier).clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  Future<void> _addItem() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const _AddItemScreen()),
    );
    if (added == true) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<VaultItem>>(
        future: _itemsFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Lỗi: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Chưa có mật khẩu nào.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _VaultTile(item: items[i]),
          );
        },
      ),
    );
  }
}

class _VaultTile extends StatelessWidget {
  const _VaultTile({required this.item});
  final VaultItem item;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: item.password));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã copy. Tự xoá sau 30 giây.')),
    );
    Timer(const Duration(seconds: 30), () async {
      final cur = await Clipboard.getData('text/plain');
      if (cur?.text == item.password) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.serviceName),
      subtitle: Text(item.username),
      trailing: IconButton(
        icon: const Icon(Icons.copy),
        onPressed: () => _copy(context),
      ),
    );
  }
}

class _AddItemScreen extends ConsumerStatefulWidget {
  const _AddItemScreen();

  @override
  ConsumerState<_AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<_AddItemScreen> {
  final _service = TextEditingController();
  final _url = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _service.dispose();
    _url.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _generate() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final rng = Random.secure();
    _password.text =
        List.generate(20, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(vaultRepositoryProvider);
      if (repo == null) return;
      await repo.addItem(
        serviceName: _service.text.trim(),
        url: _url.text.trim(),
        secret: VaultItemSecret(
          username: _username.text.trim(),
          password: _password.text,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm mật khẩu')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _service,
              decoration: const InputDecoration(labelText: 'Tên dịch vụ'),
            ),
            TextField(
              controller: _url,
              decoration: const InputDecoration(labelText: 'URL'),
            ),
            TextField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Username / Email'),
            ),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
              ),
              IconButton(
                  onPressed: _generate, icon: const Icon(Icons.casino)),
            ]),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: const Text('Lưu (mã hoá rồi đẩy lên Firestore)'),
            ),
          ],
        ),
      ),
    );
  }
}
