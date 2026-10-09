import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../data/profile_options.dart';
import '../models/deck_filters.dart';
import '../theme.dart';
import '../widgets/tag_input.dart';

/// Choose who shows up in the deck. Pops with the new [DeckFilters], or null
/// when left with the back button.
class FiltersScreen extends StatefulWidget {
  const FiltersScreen({
    super.key,
    required this.initial,
    required this.hasLocation,
  });

  final DeckFilters initial;

  /// Distance only works once you've shared a location.
  final bool hasLocation;

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late int? _maxKm = widget.initial.maxKm;
  late final Set<String> _instruments = {...widget.initial.instruments};
  late String? _minSkill = widget.initial.minSkill;
  late final List<String> _genres = [...widget.initial.genres];
  late final Set<String> _goals = {...widget.initial.goals};
  late final Set<String> _frequencies = {...widget.initial.frequencies};

  void _reset() {
    setState(() {
      _maxKm = const DeckFilters().maxKm;
      _instruments.clear();
      _minSkill = null;
      _genres.clear();
      _goals.clear();
      _frequencies.clear();
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      DeckFilters(
        maxKm: _maxKm,
        instruments: {..._instruments},
        minSkill: _minSkill,
        genres: [..._genres],
        goals: {..._goals},
        frequencies: {..._frequencies},
      ),
    );
  }

  Widget _chips<T>(
    Map<T, String> options,
    bool Function(T) isOn,
    void Function(T, bool) onChanged,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final MapEntry(key: value, value: label) in options.entries)
        FilterChip(
          label: Text(label),
          selected: isOn(value),
          onSelected: (on) => setState(() => onChanged(value, on)),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hint = TextStyle(color: colors.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          context.t.filtersTitle,
          style: displayStyle(size: 32, color: colors.onSurface),
        ),
        actions: [TextButton(onPressed: _reset, child: Text(context.t.reset))],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _Heading(context.t.filterDistance),
                if (!widget.hasLocation)
                  Text(context.t.filterDistanceNoLocation, style: hint)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final km in DeckFilters.distanceChoices)
                        ChoiceChip(
                          label: Text(context.t.kmShort(km)),
                          selected: _maxKm == km,
                          onSelected: (_) => setState(() {
                            _maxKm = km;
                          }),
                        ),
                      ChoiceChip(
                        label: Text(context.t.anywhere),
                        selected: _maxKm == null,
                        onSelected: (_) => setState(() {
                          _maxKm = null;
                        }),
                      ),
                    ],
                  ),
                _Heading(context.t.filterInstruments),
                Text(context.t.filterInstrumentsHint, style: hint),
                const SizedBox(height: 8),
                _chips<String>(instrumentLabels, _instruments.contains, (
                  id,
                  on,
                ) {
                  on ? _instruments.add(id) : _instruments.remove(id);
                }),
                _Heading(context.t.filterSkill),
                if (_instruments.isEmpty)
                  Text(context.t.filterSkillNeedsInstruments, style: hint)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(context.t.any),
                        selected: _minSkill == null,
                        onSelected: (_) => setState(() {
                          _minSkill = null;
                        }),
                      ),
                      for (final MapEntry(key: id, value: label)
                          in skillLabels.entries)
                        ChoiceChip(
                          label: Text(
                            id == 'pro'
                                ? label
                                : context.t.skillOrBetter(label),
                          ),
                          selected: _minSkill == id,
                          onSelected: (_) => setState(() {
                            _minSkill = id;
                          }),
                        ),
                    ],
                  ),
                _Heading(context.t.fieldGenres),
                Text(context.t.filterGenresHint, style: hint),
                const SizedBox(height: 8),
                TagInput(
                  label: context.t.fieldGenres,
                  hint: context.t.fieldGenresHint,
                  values: _genres,
                  onChanged: () => setState(() {}),
                ),
                _Heading(context.t.filterGoals),
                _chips<String>(goalLabels, _goals.contains, (id, on) {
                  on ? _goals.add(id) : _goals.remove(id);
                }),
                _Heading(context.t.filterRehearses),
                _chips<String>(frequencyLabels, _frequencies.contains, (
                  id,
                  on,
                ) {
                  on ? _frequencies.add(id) : _frequencies.remove(id);
                }),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _apply,
                  child: Text(context.t.showMusicians),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(
      text,
      style: displayStyle(
        size: 26,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}
