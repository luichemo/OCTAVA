import 'package:flutter/material.dart';

import '../data/clip_repository.dart';
import '../data/profile_options.dart';
import '../data/repositories.dart';
import '../models/profile_draft.dart';
import '../models/profile_link.dart';
import '../theme.dart';
import '../widgets/clips_section.dart';
import 'card_preview_screen.dart';

/// The profile form. First-time setup asks for the date of birth (once, can't
/// be changed); given [initial], it edits an existing profile instead and adds
/// links and audio clips.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.repository,
    required this.needsBirthDate,
    required this.onDone,
    this.initial,
    this.clips,
    this.player,
  });

  /// The current profile when editing; null during sign-up.
  final ProfileDraft? initial;

  /// Audio clips section, shown when editing.
  final ClipRepository? clips;
  final ClipPlayer? player;

  final ProfileRepository repository;

  /// False when the birth date was saved on an earlier attempt.
  final bool needsBirthDate;
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _area = TextEditingController();
  final _lookingFor = TextEditingController();
  final _birthDateText = TextEditingController();

  DateTime? _birthDate;
  late bool _needsBirthDate = widget.needsBirthDate;
  final Map<String, String> _instruments =
      {}; // id → skill, in the order picked
  final List<String> _genres = [];
  final Set<String> _goals = {};
  String? _frequency;
  final Set<String> _gear = {};

  final List<ProfileLink> _links = [];
  final _linkInput = TextEditingController();
  String? _linkError;

  String? _instrumentError;
  String? _error;
  bool _saving = false;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    if (p == null) return;
    _name.text = p.displayName;
    _area.text = p.area;
    _lookingFor.text = p.lookingFor;
    _instruments.addAll(p.instruments);
    _genres.addAll(p.genres);
    _goals.addAll(p.goals);
    _frequency = p.frequency;
    _gear.addAll(p.gear);
    _links.addAll(p.links);
  }

  void _addLink() {
    final link = ProfileLink.fromInput(_linkInput.text);
    setState(() {
      if (link == null) {
        _linkError = 'Paste a full web address, like youtube.com/watch?v=…';
      } else if (_links.length >= 6) {
        _linkError = 'You can add up to 6 links.';
      } else {
        if (!_links.contains(link)) _links.add(link);
        _linkInput.clear();
        _linkError = null;
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _lookingFor.dispose();
    _birthDateText.dispose();
    _linkInput.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final latest = DateTime(now.year - 16, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: latest,
      initialEntryMode: DatePickerEntryMode.input,
      helpText: 'Your date of birth',
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateText.text = formatDate(picked);
      });
    }
  }

  Future<bool> _confirmBirthDate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Is your date of birth right?'),
        content: Text(
          '${formatDate(_birthDate!)}. You can\'t change it later, '
          'because it decides who you can meet on OCTAVA.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Change it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, it's right"),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _submit() async {
    // A link typed but not added with Enter or + would otherwise be lost.
    if (_linkInput.text.trim().isNotEmpty) {
      _addLink();
    } else {
      _linkError = null;
    }
    final formOk = _formKey.currentState!.validate();
    final valid =
        formOk && _instruments.isNotEmpty && _linkInput.text.trim().isEmpty;
    setState(() {
      _instrumentError = _instruments.isEmpty
          ? 'Pick at least one instrument'
          : null;
      // The problems may be scrolled out of view, so say so next to the button.
      _error = valid
          ? null
          : (_linkError != null
                ? 'Check the link: it isn\'t a web address we can use.'
                : 'Some answers are missing. Check the fields marked in red above.');
    });
    if (!valid) return;
    if (_needsBirthDate && !await _confirmBirthDate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_needsBirthDate) {
        await widget.repository.saveBirthDate(_birthDate!);
        // Saved for good; if the profile step fails, a retry skips this.
        setState(() => _needsBirthDate = false);
      }
      final draft = ProfileDraft(
        displayName: _name.text,
        area: _area.text,
        lookingFor: _lookingFor.text,
        instruments: Map.of(_instruments),
        genres: List.of(_genres),
        goals: Set.of(_goals),
        frequency: _frequency,
        gear: Set.of(_gear),
        links: List.of(_links),
      );
      if (_editing) {
        await widget.repository.updateProfile(draft);
      } else {
        await widget.repository.createProfile(draft);
      }
      widget.onDone();
    } on UserFacingException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: _editing ? AppBar(backgroundColor: colors.surface) : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  Text(
                    _editing ? 'Your profile' : 'Set up your profile',
                    style: displayStyle(size: 44, color: colors.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is what other musicians see when they swipe.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  if (_editing) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CardPreviewScreen(
                              repository: widget.repository,
                              player: widget.player,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('See your card'),
                      ),
                    ),
                  ],
                  _Section('About you'),
                  TextFormField(
                    controller: _name,
                    maxLength: 40,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      counterText: '',
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Enter the name people will see'
                        : null,
                  ),
                  if (_needsBirthDate) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _birthDateText,
                      readOnly: true,
                      onTap: _pickBirthDate,
                      decoration: const InputDecoration(
                        labelText: 'Date of birth',
                        helperText: 'OCTAVA is for ages 16 and over. Others only see your age.',
                        suffixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      validator: (_) => _birthDate == null
                          ? 'Enter your date of birth'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _area,
                    maxLength: 60,
                    decoration: const InputDecoration(
                      labelText: 'Area (optional)',
                      hintText: 'e.g. Vake, Tbilisi',
                      counterText: '',
                    ),
                  ),
                  _Section('What you play'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final MapEntry(key: id, value: label)
                          in instrumentLabels.entries)
                        FilterChip(
                          label: Text(label),
                          selected: _instruments.containsKey(id),
                          onSelected: (on) => setState(() {
                            on
                                ? _instruments[id] = 'intermediate'
                                : _instruments.remove(id);
                            if (on) _instrumentError = null;
                          }),
                        ),
                    ],
                  ),
                  if (_instrumentError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _instrumentError!,
                        style: TextStyle(color: colors.error, fontSize: 13),
                      ),
                    ),
                  for (final (i, id) in _instruments.keys.indexed)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              i == 0
                                  ? '${instrumentLabels[id]} (main)'
                                  : instrumentLabels[id]!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DropdownButton<String>(
                            value: _instruments[id],
                            onChanged: (skill) =>
                                setState(() => _instruments[id] = skill!),
                            items: [
                              for (final MapEntry(key: value, value: label)
                                  in skillLabels.entries)
                                DropdownMenuItem(
                                  value: value,
                                  child: Text(label),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  _TagInput(
                    label: 'Genres',
                    hint: 'Type a genre and press Enter',
                    values: _genres,
                    onChanged: () => setState(() {}),
                  ),
                  _Section('What you want'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final MapEntry(key: id, value: label)
                          in goalLabels.entries)
                        FilterChip(
                          label: Text(label),
                          selected: _goals.contains(id),
                          onSelected: (on) => setState(
                            () => on ? _goals.add(id) : _goals.remove(id),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'How often can you rehearse?',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final MapEntry(key: id, value: label)
                          in frequencyLabels.entries)
                        ChoiceChip(
                          label: Text(label),
                          selected: _frequency == id,
                          onSelected: (on) =>
                              setState(() => _frequency = on ? id : null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'What do you have?',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final MapEntry(key: id, value: label)
                          in gearLabels.entries)
                        FilterChip(
                          label: Text(label),
                          selected: _gear.contains(id),
                          onSelected: (on) => setState(
                            () => on ? _gear.add(id) : _gear.remove(id),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lookingFor,
                    maxLength: 300,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'What are you looking for? (optional)',
                      hintText:
                          'e.g. A band that rehearses weekly and plays shows',
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (_editing) ...[
                    _Section('Links'),
                    TextField(
                      controller: _linkInput,
                      keyboardType: TextInputType.url,
                      onSubmitted: (_) => _addLink(),
                      decoration: InputDecoration(
                        labelText: 'YouTube, TikTok, SoundCloud, Spotify…',
                        hintText: 'Paste a link and press Enter',
                        errorText: _linkError,
                        suffixIcon: IconButton(
                          tooltip: 'Add link',
                          onPressed: _addLink,
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ),
                    ),
                    for (final link in _links)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.link_rounded),
                        title: Text(link.label),
                        subtitle: Text(
                          link.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          tooltip: 'Remove link',
                          onPressed: () => setState(() {
                            _links.remove(link);
                          }),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                  ],
                  if (_editing &&
                      widget.clips != null &&
                      widget.player != null) ...[
                    _Section('Audio clips'),
                    ClipsSection(clips: widget.clips!, player: widget.player!),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: colors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : Text(_editing ? 'Save changes' : 'Create profile'),
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

/// "12 March 2001".
String formatDate(DateTime d) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Text(
      title,
      style: displayStyle(
        size: 28,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}

/// A text field that turns entries into removable chips (max 10).
class _TagInput extends StatefulWidget {
  const _TagInput({
    required this.label,
    required this.hint,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final List<String> values;
  final VoidCallback onChanged;

  @override
  State<_TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<_TagInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final value = _controller.text.trim();
    _controller.clear();
    if (value.isEmpty || widget.values.length >= 10) return;
    if (widget.values.any((v) => v.toLowerCase() == value.toLowerCase())) {
      return;
    }
    widget.values.add(value);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final full = widget.values.length >= 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          enabled: !full,
          onSubmitted: (_) => _add(),
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: full ? 'You can add up to 10' : widget.hint,
            suffixIcon: IconButton(
              tooltip: 'Add',
              onPressed: full ? null : _add,
              icon: const Icon(Icons.add_rounded),
            ),
          ),
        ),
        if (widget.values.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in widget.values)
                InputChip(
                  label: Text(v),
                  onDeleted: () {
                    widget.values.remove(v);
                    widget.onChanged();
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}
