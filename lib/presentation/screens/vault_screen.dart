import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/validation/validators.dart';
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
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
  }

  Future<void> _addItem() async {
    final ok = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const _ItemFormScreen()));
    if (ok == true) setState(_reload);
  }

  Future<void> _editItem(VaultItem item) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _ItemFormScreen(existing: item)),
    );
    if (ok == true) setState(_reload);
  }

  Future<void> _deleteItem(VaultItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Xoá mật khẩu?'),
            content: Text(
              'Bạn có chắc muốn xoá "${item.serviceName}"? '
              'Hành động này không thể hoàn tác.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Huỷ'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Xoá'),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    try {
      await ref.read(vaultRepositoryProvider)!.deleteItem(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xoá.')));
      setState(_reload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.tertiary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Kho mật khẩu'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('Thêm mật khẩu'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: FutureBuilder<List<VaultItem>>(
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
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                       spacing: 12,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 64,
                          color: scheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có mật khẩu nào',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Nhấn "Thêm mật khẩu" để bắt đầu',
                          style: TextStyle(
                            fontSize: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder:
                    (_, i) => Card(
                      margin: EdgeInsets.zero,
                      child: _VaultTile(
                        item: items[i],
                        onEdit: () => _editItem(items[i]),
                        onDelete: () => _deleteItem(items[i]),
                      ),
                    ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VaultTile extends StatefulWidget {
  const _VaultTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });
  final VaultItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_VaultTile> createState() => _VaultTileState();
}

class _VaultTileState extends State<_VaultTile> {
  bool _revealed = false;

  Future<void> _copy(
    String label,
    String value, {
    bool autoClear = false,
  }) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          autoClear
              ? 'Đã sao chép $label. Tự xoá sau 30 giây.'
              : 'Đã sao chép $label.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    if (!autoClear) return;
    Timer(const Duration(seconds: 30), () async {
      final cur = await Clipboard.getData('text/plain');
      if (cur?.text == value) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final scheme = Theme.of(context).colorScheme;
    final initial = item.serviceName.isEmpty
        ? '?'
        : item.serviceName.characters.first.toUpperCase();
    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          initial,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(
        item.serviceName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        item.username,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        if (item.url.isNotEmpty)
          _Field(
            label: 'URL',
            value: item.url,
            onCopy: () => _copy('URL', item.url),
          ),
        _Field(
          label: 'Tên đăng nhập',
          value: item.username,
          onCopy: () => _copy('tên đăng nhập', item.username),
        ),
        _Field(
          label: 'Mật khẩu',
          value: _revealed ? item.password : '•' * item.password.length,
          onCopy: () => _copy('mật khẩu', item.password, autoClear: true),
          trailing: IconButton(
            icon: Icon(_revealed ? Icons.visibility_off : Icons.visibility),
            tooltip: _revealed ? 'Ẩn' : 'Hiện',
            onPressed: () => setState(() => _revealed = !_revealed),
          ),
        ),
        if (item.note.isNotEmpty)
          _Field(
            label: 'Ghi chú',
            value: item.note,
            onCopy: () => _copy('ghi chú', item.note),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Sửa'),
              onPressed: widget.onEdit,
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Xoá', style: TextStyle(color: Colors.red)),
              onPressed: widget.onDelete,
            ),
          ],
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.onCopy,
    this.trailing,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
               spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                Text(
                  value,
                  style: const TextStyle(fontFamily: 'monospace'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Sao chép $label',
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}

class _ItemFormScreen extends ConsumerStatefulWidget {
  const _ItemFormScreen({this.existing});
  final VaultItem? existing;

  @override
  ConsumerState<_ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<_ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _service;
  late final TextEditingController _url;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _note;
  bool _busy = false;
  bool _obscure = true;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _service = TextEditingController(text: e?.serviceName ?? '');
    _url = TextEditingController(text: e?.url ?? '');
    _username = TextEditingController(text: e?.username ?? '');
    _password = TextEditingController(text: e?.password ?? '');
    _note = TextEditingController(text: e?.note ?? '');
  }

  @override
  void dispose() {
    _service.dispose();
    _url.dispose();
    _username.dispose();
    _password.dispose();
    _note.dispose();
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(vaultRepositoryProvider);
      if (repo == null) return;
      final secret = VaultItemSecret(
        username: _username.text.trim(),
        password: _password.text,
        note: _note.text,
      );
      if (_isEdit) {
        await repo.updateItem(
          id: widget.existing!.id,
          serviceName: _service.text.trim(),
          url: _url.text.trim(),
          secret: secret,
        );
      } else {
        await repo.addItem(
          serviceName: _service.text.trim(),
          url: _url.text.trim(),
          secret: secret,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Sửa mật khẩu' : 'Thêm mật khẩu')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
             spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _service,
                decoration: const InputDecoration(
                  labelText: 'Tên dịch vụ *',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: Validators.serviceName,
              ),
              TextFormField(
                controller: _url,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ web (tuỳ chọn)',
                  prefixIcon: Icon(Icons.link),
                  hintText: 'https://...',
                ),
                validator: Validators.optionalUrl,
              ),
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(
                  labelText: 'Tên đăng nhập / Thư điện tử *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator:
                    (v) => Validators.required(v, label: 'Tên đăng nhập'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu *',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: Validators.vaultPassword,
                    ),
                  ),
                  IconButton(
                    tooltip: _obscure ? 'Hiện' : 'Ẩn',
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  IconButton(
                    tooltip: 'Tạo ngẫu nhiên',
                    onPressed: _generate,
                    icon: const Icon(Icons.casino),
                  ),
                ],
              ),
              TextFormField(
                controller: _note,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tuỳ chọn)',
                  prefixIcon: Icon(Icons.notes),
                ),
                validator:
                    (v) => Validators.maxLength(v, 500, label: 'Ghi chú'),
              ),
              const SizedBox(height: 8),
              const Text(
                '* là trường bắt buộc',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _save,
                child:
                    _busy
                        ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(
                          _isEdit
                              ? 'Cập nhật (mã hoá rồi tải lên máy chủ)'
                              : 'Lưu (mã hoá rồi tải lên máy chủ)',
                        ),
              ),
            ],
          ),
        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
