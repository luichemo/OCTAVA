import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repositories.dart';
import '../l10n/l10n.dart';
import '../theme.dart';
import 'auth_screen.dart';

/// "Forgot password?" from sign-in: type your email, get a reset link.
/// Once sent it says to check your email, with Send again after a minute
/// (Supabase sends one email per address about every 60 s).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.auth, this.email = ''});

  final AuthRepository auth;

  /// Filled in from the sign-in form.
  final String email;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

/// How long Send again stays off after a link goes out.
const resendWait = Duration(seconds: 60);

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  bool _busy = false;
  String? _error;

  /// The address the link went to; null until it's sent.
  String? _sentTo;
  int _wait = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sentTo == null && !_formKey.currentState!.validate()) return;
    final email = _sentTo ?? _email.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.sendPasswordReset(email);
      if (!mounted) return;
      setState(() {
        _sentTo = email;
      });
      _startWait();
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

  void _startWait() {
    _timer?.cancel();
    setState(() {
      _wait = resendWait.inSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _wait--;
      });
      if (_wait <= 0) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _sentTo == null ? _form(context) : _sent(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorText(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Text(
      _error!,
      style: TextStyle(
        color: Theme.of(context).colorScheme.error,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _spinner() => const SizedBox.square(
    dimension: 22,
    child: CircularProgressIndicator(strokeWidth: 3),
  );

  Widget _form(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: Container(
        key: const ValueKey('form'),
        decoration: printBox(context, radius: 24),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.forgotTitle,
              style: displayStyle(size: 30, color: colors.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              t.forgotBody,
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _email,
              autofocus: widget.email.isEmpty,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _send(),
              decoration: InputDecoration(
                labelText: t.authEmail,
                prefixIcon: const Icon(Icons.mail_outline),
              ),
              validator: (v) => v != null && emailPattern.hasMatch(v.trim())
                  ? null
                  : t.authEmailError,
            ),
            if (_error != null) _errorText(context),
            const SizedBox(height: 24),
            PrintButton(
              onPressed: _busy ? null : _send,
              child: _busy ? _spinner() : Text(t.forgotSend),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sent(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('sent'),
      decoration: printBox(context, radius: 24),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.mark_email_read_outlined, size: 44),
          const SizedBox(height: 12),
          Text(
            t.forgotSentTitle,
            textAlign: TextAlign.center,
            style: displayStyle(size: 30, color: colors.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            t.authResetSent(_sentTo!),
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurface, height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            t.forgotHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
          ),
          if (_error != null) _errorText(context),
          const SizedBox(height: 24),
          PrintButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.resetBack),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy || _wait > 0 ? null : _send,
            child: _busy
                ? _spinner()
                : Text(_wait > 0 ? t.forgotResendIn(_wait) : t.forgotResend),
          ),
        ],
      ),
    );
  }
}
