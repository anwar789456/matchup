import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/draft_file.dart';
import '../../common/data/pro_providers.dart';
import '../../common/widgets/pro_wizard_scaffold.dart';
import '../controllers/coach_controller.dart';
import '../data/coach_draft.dart';
import '../widgets/coach_wizard.dart';
import '../../../l10n/l10n.dart';

/// COA-01 — the coach profile: photo, city, bio, specialties (6 max), sports and levels.
class CoachProfileScreen extends ConsumerStatefulWidget {
  const CoachProfileScreen({super.key});

  @override
  ConsumerState<CoachProfileScreen> createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends ConsumerState<CoachProfileScreen> {
  late final _bio = TextEditingController(text: ref.read(coachProvider).requireValue.bio);

  String? _bioError;
  String? _specialtiesError;
  String? _sportsError;
  String? _levelsError;

  CoachController get _coach => ref.read(coachProvider.notifier);

  @override
  void dispose() {
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ref.read(fileSourceProvider).pickImages();
    if (picked.isEmpty || !mounted) return;
    final f = picked.first;
    final id = 'photo-${DateTime.now().microsecondsSinceEpoch}';
    await ref.read(uploadServiceProvider).upload(f.name, f.sizeBytes).drain<void>();
    if (f.bytes != null) ref.read(uploadedBytesProvider)[id] = f.bytes!;
    await _coach.edit(
      (d) => d.copyWith(
        photo: DraftFile(id: id, name: f.name, sizeBytes: f.sizeBytes),
      ),
    );
  }

  List<T> _toggle<T>(List<T> list, T value) =>
      list.contains(value) ? (list.where((e) => e != value).toList()) : [...list, value];

  bool _validate() {
    final d = ref.read(coachProvider).requireValue;
    setState(() {
      _bioError = d.bio.trim().isEmpty ? l10n.presenteToiEnQuelquesPhrases : null;
      _specialtiesError = d.specialties.isEmpty ? l10n.choisisAuMoinsUneSpecialite : null;
      _sportsError = d.sports.isEmpty ? l10n.choisisAuMoinsUnSport : null;
      _levelsError = d.levels.isEmpty ? l10n.choisisAuMoinsUnNiveau : null;
    });
    return [_bioError, _specialtiesError, _sportsError, _levelsError].every((e) => e == null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final d = ref.watch(coachProvider).requireValue;
    final photo = d.photo == null ? null : ref.read(uploadedBytesProvider)[d.photo!.id];
    final full = d.specialties.length >= CoachCatalog.maxSpecialties;

    Widget groupLabel(String text, {String? aside}) => Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(text, style: MuType.label.copyWith(color: c.text)),
          ),
        ),
        if (aside != null) Text(aside, style: MuType.caption.copyWith(color: c.textSecondary)),
      ],
    );

    final sports = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        groupLabel(l10n.sports),
        const SizedBox(height: MuSpace.s3),
        Wrap(
          spacing: MuSpace.s2,
          runSpacing: MuSpace.s2,
          children: [
            for (final (sport, label) in CoachCatalog.sports)
              MuChip(
                label: label,
                sport: sport,
                selected: d.sports.contains(sport),
                onSelected: (_) {
                  setState(() => _sportsError = null);
                  _coach.edit((d) => d.copyWith(sports: _toggle(d.sports, sport)));
                },
              ),
          ],
        ),
        if (_sportsError != null) ...[
          const SizedBox(height: MuSpace.s2),
          MuFieldMessage.error(_sportsError!),
        ],
      ],
    );

    Widget level(String l) => MuCheckbox(
          label: l,
          value: d.levels.contains(l),
          onChanged: (_) {
            setState(() => _levelsError = null);
            _coach.edit((d) => d.copyWith(levels: _toggle(d.levels, l)));
          },
        );
    // Two by two, as in the design.
    final levels = MuCheckboxGroup(
      label: l10n.niveauxQueTuEntraines,
      error: _levelsError,
      children: [
        for (var i = 0; i < CoachCatalog.levels.length; i += 2)
          Row(
            children: [
              Expanded(child: level(CoachCatalog.levels[i])),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: i + 1 < CoachCatalog.levels.length
                    ? level(CoachCatalog.levels[i + 1])
                    : const SizedBox(),
              ),
            ],
          ),
      ],
    );

    return CoachWizard(
      step: 0,
      title: l10n.presenteToiAuxJoueurs,
      lead: l10n.lesElevesChoisissentDAbord,
      validate: _validate,
      body: ProFormCard(
        divided: false,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProFieldGrid(
                children: [
                  MuFileUpload.avatar(
                    label: l10n.photoDeProfil,
                    name: d.name,
                    helper: l10n.jpgPngVisageBienVisible,
                    image: photo == null ? null : MemoryImage(photo),
                    onAdd: _pickPhoto,
                    onRemove: (_) => _coach.edit((d) => d.copyWith(clearPhoto: true)),
                  ),
                  MuSelect<String>(
                    label: l10n.villeOuTuCoaches,
                    size: MuFieldSize.m,
                    value: d.city,
                    helper: l10n.lesElevesCherchentUnCoach,
                    options: [
                      for (final city in CoachCatalog.cities)
                        MuSelectOption(value: city, label: city),
                    ],
                    onChanged: (v) => _coach.edit((d) => d.copyWith(city: v)),
                  ),
                ],
              ),
              const SizedBox(height: MuSpace.s5),
              MuTextField(
                label: l10n.bio,
                controller: _bio,
                size: MuFieldSize.m,
                multiline: true,
                minLines: 3,
                maxLength: CoachCatalog.bioMax,
                error: _bioError,
                onChanged: (v) {
                  if (_bioError != null) setState(() => _bioError = null);
                  _coach.edit((d) => d.copyWith(bio: v));
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: MuSpace.s5),
                child: Container(height: 1, color: c.border),
              ),
              groupLabel(
                l10n.specialites,
                aside:
                    l10n.specialiteSurMax(d.specialties.length, d.specialties.length > 1 ? 's' : '', CoachCatalog.maxSpecialties),
              ),
              const SizedBox(height: MuSpace.s3),
              Wrap(
                spacing: MuSpace.s2,
                runSpacing: MuSpace.s2,
                children: [
                  for (final s in CoachCatalog.specialties)
                    MuChip(
                      label: s,
                      selected: d.specialties.contains(s),
                      onSelected: full && !d.specialties.contains(s)
                          ? null
                          : (_) {
                              setState(() => _specialtiesError = null);
                              _coach.edit(
                                (d) => d.copyWith(specialties: _toggle(d.specialties, s)),
                              );
                            },
                    ),
                ],
              ),
              if (_specialtiesError != null) ...[
                const SizedBox(height: MuSpace.s2),
                MuFieldMessage.error(_specialtiesError!),
              ],
              const SizedBox(height: MuSpace.s5),
              ProFieldGrid(children: [sports, levels]),
            ],
          ),
        ],
      ),
    );
  }
}
