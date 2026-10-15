import 'package:flutter/material.dart';

import '../data/bands_repository.dart';
import '../data/profile_options.dart';
import '../data/repositories.dart';
import '../l10n/l10n.dart';
import '../models/band_group.dart';
import '../theme.dart';
import '../widgets/genre_picker.dart';

/// Edits a band's public profile: name, description, genres and the roles
/// it's looking for. Pops true when saved.
class BandProfileScreen extends StatefulWidget {
  const BandProfileScreen({
    super.key,
    required this.repository,
    required this.band,
  });

  final BandsRepository repository;
  final MyBand band;

  @override
  State<BandProfileScreen> createState() => _BandProfileScreenState();
}

class _BandProfileScreenState extends State<BandProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.band.name);
  late final _description = TextEditingController(
    text: widget.band.description ?? '',
  );
  late List<String> _genres = List.of(widget.band.genres);
  late final List<String> _roles = List.of(widget.band.openRoles);
  bool _saving = false;

  /// The most roles a band can look for at once (the database's limit).
  static const _maxRoles = 8;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _saving = true;
    });
    try {
      await widget.repository.updateProfile(
        widget.band.id,
        name: _name.text,
        description: _description.text.trim(),
        genres: _genres,
        openRoles: _roles,
      );
      navigator.pop(true);
    } on UserFacingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(t.bandEditTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  t.bandEditHint,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  maxLength: 60,
                  decoration: InputDecoration(labelText: t.bandNameLabel),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? t.bandNameError : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _description,
                  maxLength: 500,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: t.bandDescriptionLabel,
                    hintText: t.bandDescriptionHint,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                _Label(t.fieldGenres),
                GenrePicker(
                  selected: _genres,
                  max: 10,
                  onChanged: (next) => setState(() {
                    _genres = next;
                  }),
                ),
                const SizedBox(height: 20),
                _Label(t.bandOpenRolesLabel),
                Text(
                  t.bandOpenRolesHint,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final MapEntry(key: id, value: label)
                        in instrumentLabels.entries)
                      FilterChip(
                        label: Text(label),
                        selected: _roles.contains(id),
                        onSelected:
                            !_roles.contains(id) && _roles.length >= _maxRoles
                            ? null
                            : (on) => setState(() {
                                on ? _roles.add(id) : _roles.remove(id);
                              }),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                PrintButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : Text(t.saveChanges),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: displayStyle(
        size: 22,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}
