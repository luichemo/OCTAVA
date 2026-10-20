import 'package:flutter/material.dart';

import '../data/repositories.dart';
import '../l10n/l10n.dart';
import '../theme.dart';

/// Choose a new password, after opening a reset link. With [tokenHash] (the
/// link's one-time code, `?reset=` on the web) it first signs in with it;
/// without, Supabase has already signed in (same-browser recovery).
/// [onDone] moves on: to the app if signed in, otherwise to sign-in.
class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({
    super.key,
    required this.auth,
    required this.onDone,
    this.tokenHash,
  });

  final AuthRepository auth;
  final VoidCallback onDone;
  final String? tokenHash;

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  late final Future<void>? _opening = widget.tokenHash == null
      ? null
      : widget.auth.openResetLink(widget.tokenHash!);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final done = context.t.resetDone;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.setNewPassword(_password.text);
      messenger.showSnackBar(SnackBar(content: Text(done)));
      widget.onDone();
    } on UserFacingException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _opening == null
                  ? _form(context)
                  : FutureBuilder<void>(
                      future: _opening,
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snap.hasError) return _badLink(context);
                        return _form(context);
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badLink(BuildContext context) {
    final t = context.t;
    return Container(
      decoration: printBox(context, radius: 24),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          const Icon(Icons.link_off, size: 40),
          Text(t.errResetLink, textAlign: TextAlign.center),
          PrintButton(onPressed: widget.onDone, child: Text(t.resetBack)),
        ],
      ),
    );
  }

  Widget _form(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Container(
          decoration: printBox(context, radius: 24),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.resetTitle,
                style: displayStyle(size: 30, color: colors.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                t.resetBody,
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: t.resetNew,
                  prefixIcon: const Icon(Icons.lock_outline),
                  helperText: t.authPasswordHelper,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return t.authPasswordEmpty;
                  if (v.length < 8) return t.authPasswordShort;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _repeat,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  labelText: t.resetRepeat,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                validator: (v) => v == _password.text ? null : t.resetMismatch,
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: TextStyle(
                    color: colors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrintButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : Text(t.resetSave),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : widget.onDone,
                child: Text(t.resetNotNow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
