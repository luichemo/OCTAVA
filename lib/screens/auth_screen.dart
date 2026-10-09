import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../data/repositories.dart';
import '../theme.dart';
import '../widgets/language_picker.dart';

/// Create an account or sign in with email and password. When this succeeds,
/// Supabase's auth state changes and AuthGate moves on by itself.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.auth});

  final AuthRepository auth;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creating = false; // Opens on context.t.authSignIn; returning users are the common case.
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      if (_creating) {
        final needsConfirmation = await widget.auth.signUp(
          _email.text,
          _password.text,
        );
        if (needsConfirmation && mounted) {
          setState(() {
            _creating = false;
            _notice = context.t.authCheckEmail;
          });
        }
      } else {
        await widget.auth.signIn(_email.text, _password.text);
      }
    } on UserFacingException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final action = _creating
        ? context.t.authCreateAccount
        : context.t.authSignIn;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerRight,
                        child: LanguageToggle(),
                      ),
                      Text(
                        'OCTAVA',
                        style: displayStyle(size: 72, color: colors.onSurface),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.t.authTagline,
                        style: TextStyle(
                          fontSize: 17,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: context.t.authEmail,
                        ),
                        validator: (v) =>
                            v != null &&
                                RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim())
                            ? null
                            : context.t.authEmailError,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        autofillHints: [
                          _creating
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: context.t.authPassword,
                          helperText: _creating
                              ? context.t.authPasswordHelper
                              : null,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return context.t.authPasswordEmpty;
                          }
                          if (_creating && v.length < 8) {
                            return context.t.authPasswordShort;
                          }
                          return null;
                        },
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
                      if (_notice != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.tertiaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_notice!),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(action),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                _creating = !_creating;
                                _error = null;
                              }),
                        child: Text(
                          _creating
                              ? context.t.authHaveAccount
                              : context.t.authNewAccount,
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
