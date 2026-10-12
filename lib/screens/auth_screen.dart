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

  void _switchTo(bool creating) {
    if (_busy || creating == _creating) return;
    setState(() {
      _creating = creating;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    final action = _creating ? t.authCreateAccount : t.authSignIn;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
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
                      const SizedBox(height: 8),
                      // Hero: the wordmark on a printed card.
                      Container(
                        decoration: printBox(context, radius: 24),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // Halftone corner, kept clear of the text.
                            Positioned(
                              right: -4,
                              top: -4,
                              width: 96,
                              height: 84,
                              child: CustomPaint(
                                painter: _DotsPainter(colors.outlineVariant),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'OCTAVA',
                                    style: displayStyle(
                                      size: 72,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    t.authHeadline,
                                    style: displayStyle(
                                      size: 28,
                                      color: OctavaColors.pink,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    t.authTagline,
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _AuthTabs(creating: _creating, onChanged: _switchTo),
                      const SizedBox(height: 20),
                      Container(
                        decoration: printBox(context, radius: 24),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: t.authEmail,
                                prefixIcon: const Icon(Icons.mail_outline),
                              ),
                              validator: (v) =>
                                  v != null && _emailPattern.hasMatch(v.trim())
                                  ? null
                                  : t.authEmailError,
                            ),
                            const SizedBox(height: 16),
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
                                labelText: t.authPassword,
                                prefixIcon: const Icon(Icons.lock_outline),
                                helperText: _creating
                                    ? t.authPasswordHelper
                                    : null,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return t.authPasswordEmpty;
                                }
                                if (_creating && v.length < 8) {
                                  return t.authPasswordShort;
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
                                decoration: printBox(
                                  context,
                                  color: colors.tertiaryContainer,
                                  radius: 12,
                                  shadow: 0,
                                ),
                                child: Text(_notice!),
                              ),
                            ],
                            const SizedBox(height: 24),
                            PrintButton(
                              onPressed: _busy ? null : _submit,
                              child: _busy
                                  ? const SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      spacing: 8,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            action,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // The age rule, as a stamped notice.
                      Container(
                        decoration: printBox(
                          context,
                          color: colors.tertiaryContainer,
                          radius: 20,
                          shadow: 0,
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          spacing: 10,
                          children: [
                            Transform.rotate(
                              angle: -0.03,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                color: OctavaColors.yellow,
                                child: Text(
                                  t.authAgeTitle,
                                  style: displayStyle(
                                    size: 24,
                                    color: OctavaColors.ink,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              t.authAgeBody,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                height: 1.5,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
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

final _emailPattern = RegExp(r'^\S+@\S+\.\S+$');

/// "Create account | Sign in" as two tabs; the chosen one is a pink pill.
class _AuthTabs extends StatelessWidget {
  const _AuthTabs({required this.creating, required this.onChanged});

  final bool creating;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    Widget tab(String label, bool value) {
      final on = creating == value;
      return Expanded(
        child: Semantics(
          selected: on,
          button: true,
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 48,
              alignment: Alignment.center,
              decoration: on
                  ? printBox(
                      context,
                      color: OctavaColors.pink,
                      radius: 999,
                      shadow: 2,
                      borderColor: OctavaColors.ink,
                    )
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: on ? OctavaColors.ink : colors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: printBox(context, radius: 999, shadow: 0),
      child: Row(
        spacing: 6,
        children: [tab(t.authCreateAccount, true), tab(t.authSignIn, false)],
      ),
    );
  }
}

/// A patch of halftone dots in pink, aqua and the line colour.
class _DotsPainter extends CustomPainter {
  _DotsPainter(this.line);

  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 12.0;
    final inks = [OctavaColors.pink, OctavaColors.aqua, line];
    var i = 0;
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        final paint = Paint()
          ..color = inks[i++ % inks.length].withValues(alpha: 0.45);
        canvas.drawCircle(Offset(x, y), 2.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.line != line;
}
