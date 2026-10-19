import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../data/avatar_repository.dart';
import '../data/band_repository.dart';
import '../data/clip_repository.dart';
import '../data/location_repository.dart';
import '../data/profile_options.dart';
import '../data/repositories.dart';
import '../models/profile_draft.dart';
import '../models/profile_link.dart';
import '../theme.dart';
import '../widgets/avatar_section.dart';
import '../widgets/band_roles_sheet.dart';
import '../widgets/clips_section.dart';
import '../widgets/location_section.dart';
import '../widgets/genre_picker.dart';
import '../widgets/record_sheet.dart';
import 'card_preview_screen.dart';

import 'package:intl/intl.dart';

import '../widgets/language_picker.dart';
import '../widgets/theme_picker.dart';

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
    this.avatars,
    this.location,
    this.bandNeeds,
    this.onSignOut,
    this.only,
  });

  /// When editing, show just this section (its id: 'about', 'play', 'want'
  /// or 'links') on its own page, titled with its name, with Save changes.
  /// The profile page lists the sections and opens each one like this.
  final String? only;

  /// "Your band needs" section, shown when editing.
  final BandNeedsRepository? bandNeeds;

  /// Shows "Sign out" in the app bar when editing.
  final VoidCallback? onSignOut;

  /// Avatar section, shown when editing.
  final AvatarRepository? avatars;

  /// Location section, shown when editing.
  final LocationRepository? location;

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

  /// Sections opened in edit mode, by id. All start closed; while setting
  /// up a profile every section is open and can't be closed.
  final Set<String> _openSections = {};

  /// Moves [id] to the front of [_instruments], making it the main one.
  void _makeMain(String id) {
    // Dart maps keep insertion order, so re-insert with [id] first.
    final skill = _instruments.remove(id)!;
    final rest = Map.of(_instruments);
    _instruments
      ..clear()
      ..[id] = skill
      ..addAll(rest);
  }

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

  // Clips, for the "hidden from the feed" warning. Null until loaded.
  int? _clipCount;
  int _clipsVersion = 0;

  // Counted here too: the clips section is far down the (lazy) list and
  // only reports once it's scrolled into view.
  Future<void> _countClips() async {
    try {
      final n = (await widget.clips!.myClips()).length;
      if (mounted) {
        setState(() {
          _clipCount = n;
        });
      }
    } catch (_) {
      // No warning is better than a wrong one; the section shows the error.
    }
  }

  Future<void> _recordFromWarning() async {
    await showRecordSheet(context, clips: widget.clips!);
    if (mounted) {
      setState(() {
        _clipsVersion++;
      });
      await _countClips();
    }
  }

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    if (p == null) return;
    if (widget.clips != null) _countClips();
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
        _linkError = context.t.linkInvalid;
      } else if (_links.length >= 6) {
        _linkError = context.t.linkMax;
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
      helpText: context.t.birthDatePickerTitle,
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
        title: Text(context.t.confirmBirthDateTitle),
        content: Text(context.t.confirmBirthDateBody(formatDate(_birthDate!))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.t.confirmBirthDateNo),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.t.confirmBirthDateYes),
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
      // Open the sections with problems, so they can be seen. (Only these
      // three can have one when editing; the birth date is sign-up only.)
      if (_name.text.trim().isEmpty) _openSections.add('about');
      if (_instruments.isEmpty) _openSections.add('play');
      if (_linkError != null) _openSections.add('links');
      _instrumentError = _instruments.isEmpty
          ? context.t.pickInstrumentError
          : null;
      // The problems may be scrolled out of view, so say so next to the button.
      _error = valid
          ? null
          : (_linkError != null
                ? context.t.linkCheckError
                : context.t.answersMissing);
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
      appBar: widget.only != null
          ? AppBar(title: Text(sectionTitle(context, widget.only!)))
          : _editing
          ? AppBar(
              backgroundColor: colors.surface,
              actions: [
                if (widget.onSignOut != null)
                  TextButton.icon(
                    onPressed: () {
                      // Back to the first screen, which becomes sign-in.
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      widget.onSignOut!();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(context.t.signOut),
                  ),
              ],
            )
          : null,
      // A single section keeps Save changes pinned to the bottom (above the
      // keyboard, since the body shrinks for it).
      body: widget.only == null
          ? _form(context)
          : Column(
              children: [
                Expanded(child: _form(context)),
                Material(
                  shape: Border(top: BorderSide(color: colors.outlineVariant)),

                  color: colors.surface,
                  child: SafeArea(
                    top: false,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                          child: _saveArea(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// The error (if any) and the main button.
  Widget _saveArea(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              _error!,
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        PrintButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : Text(
                  _editing ? context.t.saveChanges : context.t.createProfile,
                ),
        ),
      ],
    );
  }

  Widget _form(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: _sectionCards(
                only: widget.only,
                open: _editing ? _openSections : null,
                onToggle: (id) => setState(() {
                  if (!_openSections.remove(id)) _openSections.add(id);
                }),
                [
                  Text(
                    _editing
                        ? context.t.profileTitle
                        : context.t.profileSetUpTitle,
                    style: displayStyle(size: 44, color: colors.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.t.profileSubtitle,
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
                              avatars: widget.avatars,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.visibility_outlined),
                        label: Text(context.t.seeYourCard),
                      ),
                    ),
                  ],
                  if (_editing && widget.clips != null && _clipCount == 0) ...[
                    const SizedBox(height: 16),
                    NoClipsWarning(onRecord: _recordFromWarning),
                  ],
                  if (_editing && widget.avatars != null) ...[
                    _Section('avatar', context.t.sectionAvatar),
                    AvatarSection(avatars: widget.avatars!),
                  ],
                  _Section('about', context.t.sectionAbout),
                  TextFormField(
                    controller: _name,
                    maxLength: 40,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: context.t.fieldName,
                      counterText: '',
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? context.t.fieldNameError
                        : null,
                  ),
                  if (_needsBirthDate) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _birthDateText,
                      readOnly: true,
                      onTap: _pickBirthDate,
                      decoration: InputDecoration(
                        labelText: context.t.fieldBirthDate,
                        helperText: context.t.fieldBirthDateHelper,
                        suffixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      validator: (_) => _birthDate == null
                          ? context.t.fieldBirthDateError
                          : null,
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _area,
                    maxLength: 60,
                    decoration: InputDecoration(
                      labelText: context.t.fieldArea,
                      hintText: context.t.fieldAreaHint,
                      counterText: '',
                    ),
                  ),
                  if (_editing && widget.bandNeeds != null) ...[
                    _Section('band', context.t.sectionBand),
                    BandNeedsSection(
                      repository: widget.bandNeeds!,
                      // The first instrument is the main one.
                      myRole: _instruments.keys.firstOrNull,
                    ),
                  ],
                  if (_editing && widget.location != null) ...[
                    _Section('location', context.t.sectionLocation),
                    LocationSection(location: widget.location!),
                  ],
                  _Section('play', context.t.sectionPlay),
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
                                  ? context.t.instrumentMain(
                                      instrumentLabels[id]!,
                                    )
                                  : instrumentLabels[id]!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // The star picks the main instrument (the first
                          // one): it's on the card and fills band roles.
                          IconButton(
                            tooltip: i == 0
                                ? context.t.instrumentIsMain
                                : context.t.instrumentMakeMain,
                            isSelected: i == 0,
                            onPressed: i == 0
                                ? null
                                : () => setState(() => _makeMain(id)),
                            icon: const Icon(Icons.star_outline_rounded),
                            selectedIcon: const Icon(
                              Icons.star_rounded,
                              color: OctavaColors.pink,
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
                  Text(
                    context.t.fieldGenres,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  GenrePicker(
                    selected: _genres,
                    max: 10,
                    onChanged: (picked) => setState(() {
                      _genres
                        ..clear()
                        ..addAll(picked);
                    }),
                  ),
                  _Section('want', context.t.sectionWant),
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
                    context.t.rehearseQuestion,
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
                    context.t.gearQuestion,
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
                    decoration: InputDecoration(
                      labelText: context.t.fieldLookingFor,
                      hintText: context.t.fieldLookingForHint,
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (_editing) ...[
                    _Section('links', context.t.sectionLinks),
                    TextField(
                      controller: _linkInput,
                      keyboardType: TextInputType.url,
                      onSubmitted: (_) => _addLink(),
                      decoration: InputDecoration(
                        labelText: context.t.linksLabel,
                        hintText: context.t.linksHint,
                        errorText: _linkError,
                        suffixIcon: IconButton(
                          tooltip: context.t.addLink,
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
                          tooltip: context.t.removeLink,
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
                    _Section('clips', context.t.sectionClips),
                    ClipsSection(
                      // A new key reloads the list after recording from the warning.
                      key: ValueKey(_clipsVersion),
                      clips: widget.clips!,
                      player: widget.player!,
                      onCountChanged: (n) => setState(() {
                        _clipCount = n;
                      }),
                    ),
                  ],
                  if (_editing) ...[
                    _Section('language', context.t.sectionLanguage),
                    const LanguageSection(),
                    _Section('theme', context.t.sectionTheme),
                    const ThemeSection(),
                  ],
                  const _EndOfSections(),
                  if (widget.only == null) ...[
                    const SizedBox(height: 12),
                    _saveArea(context),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A full date in the app's language, e.g. "March 12, 2001".
String formatDate(DateTime d) =>
    DateFormat.yMMMMd(L10n.current.localeName).format(d);

/// Just the fields of section [only] (no heading or card), then whatever
/// follows the sections (the error and Save changes).
List<Widget> _onlySection(List<Widget> children, String only) {
  final start = children.indexWhere((w) => w is _Section && w.id == only);
  final end = children.indexWhere((w) => w is _EndOfSections);
  if (start < 0 || end < 0) return children;
  var stop = children.indexWhere((w) => w is _Section, start + 1);
  if (stop < 0 || stop > end) stop = end;
  return [...children.sublist(start + 1, stop), ...children.sublist(end + 1)];
}

/// A profile section's name, by its id.
String sectionTitle(BuildContext context, String id) {
  final t = context.t;
  return switch (id) {
    'avatar' => t.sectionAvatar,
    'about' => t.sectionAbout,
    'band' => t.sectionBand,
    'location' => t.sectionLocation,
    'play' => t.sectionPlay,
    'want' => t.sectionWant,
    'links' => t.sectionLinks,
    'clips' => t.sectionClips,
    'language' => t.sectionLanguage,
    'theme' => t.sectionTheme,
    _ => id,
  };
}

/// A section heading. [_sectionCards] puts it, and everything after it up
/// to the next heading, on one printed card. [id] stays the same in every
/// language, so a section stays open when the language changes.
class _Section extends StatelessWidget {
  const _Section(this.id, this.title);
  final String id;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 10,
    children: [
      Container(width: 6, height: 24, color: OctavaColors.pink),
      Expanded(
        child: Text(
          title,
          style: displayStyle(
            size: 30,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    ],
  );
}

/// Marks where the last section's card ends (the save button comes after).
class _EndOfSections extends StatelessWidget {
  const _EndOfSections();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Groups the form into cards: each [_Section] and the widgets after it,
/// until the next one or [_EndOfSections]. Widgets before the first
/// heading (the title and warnings) stay as they are. With [open] (edit
/// mode) each card folds: only the ids in [open] show their contents.
List<Widget> _sectionCards(
  List<Widget> children, {
  Set<String>? open,
  required ValueChanged<String> onToggle,
  String? only,
}) {
  if (only != null) return _onlySection(children, only);
  final out = <Widget>[];
  _Section? heading;
  List<Widget>? body;
  void finish() {
    if (heading case final h?) {
      out.add(
        _SectionCard(
          key: ValueKey(h.id),
          heading: h,
          open: open?.contains(h.id),
          onToggle: () => onToggle(h.id),
          children: body!,
        ),
      );
    }
    heading = null;
    body = null;
  }

  for (final w in children) {
    if (w is _Section) {
      finish();
      heading = w;
      body = [];
    } else if (w is _EndOfSections) {
      finish();
    } else if (body case final b?) {
      b.add(w);
    } else {
      out.add(w);
    }
  }
  finish();
  return out;
}

/// One printed card. [open] null: always open, with no arrow (sign-up).
/// Otherwise tapping the heading folds or unfolds it. Folded contents stay
/// built (only squeezed to zero height), so their fields still validate.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.heading,
    required this.open,
    required this.onToggle,
    required this.children,
  });

  final _Section heading;
  final bool? open;
  final VoidCallback onToggle;
  final List<Widget> children;

  static const _duration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final foldable = open != null;
    final shown = open ?? true;
    final body = Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        decoration: printBox(context, radius: 24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!foldable)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: heading,
              )
            else
              Semantics(
                button: true,
                expanded: shown,
                child: InkWell(
                  onTap: onToggle,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                    child: Row(
                      children: [
                        Expanded(child: heading),
                        AnimatedRotation(
                          turns: shown ? 0.5 : 0,
                          duration: _duration,
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            Icons.expand_more_rounded,
                            size: 28,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!foldable)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                child: body,
              )
            else
              // Folded: zero height and hidden from taps and screen readers,
              // but still built.
              ClipRect(
                child: AnimatedAlign(
                  duration: _duration,
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  heightFactor: shown ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !shown,
                    child: ExcludeSemantics(
                      excluding: !shown,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                        child: body,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shown while the person has no audio clips: they don't appear in decks.
class NoClipsWarning extends StatelessWidget {
  const NoClipsWarning({super.key, required this.onRecord});

  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    // Yellow in both modes, so the text stays dark ink.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: printBox(
        context,
        color: OctavaColors.yellow,
        radius: 20,
        borderColor: OctavaColors.ink,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Row(
            spacing: 8,
            children: [
              const Icon(
                Icons.visibility_off_outlined,
                color: OctavaColors.ink,
              ),
              Expanded(
                child: Text(
                  context.t.noClipsTitle,
                  style: displayStyle(size: 26, color: OctavaColors.ink),
                ),
              ),
            ],
          ),
          Text(
            context.t.noClipsBody,
            style: const TextStyle(color: OctavaColors.ink, height: 1.5),
          ),
          FilledButton.icon(
            onPressed: onRecord,
            icon: const Icon(Icons.mic_rounded),
            label: Text(context.t.noClipsAction),
          ),
        ],
      ),
    );
  }
}
