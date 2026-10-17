import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../controllers/matches_providers.dart';
import '../data/bookings_repository.dart';
import '../../../l10n/l10n.dart';

/// MAT-08 · Évaluer les joueurs: the full sheet with, per mate, « Son niveau ce jour-là » and the
/// fair-play stars; « Envoyer » saves the (anonymous) ratings and goes on to the score (MAT-09).
Future<void> showRateSheet(BuildContext context, WidgetRef ref, PastMatch match) async {
  final form = GlobalKey<_RateFormState>();
  final sent = await MuBottomSheet.show<bool>(
    context,
    title: l10n.evalueLesJoueurs,
    height: MuSheetHeight.full,
    snapPoints: const [MuSheetHeight.full],
    footer: _RateFooter(form: form),
    child: _RateForm(key: form, match: match),
  );
  if (sent == true && context.mounted) {
    MuToast.show(context, tone: MuToastTone.success, title: l10n.merciEvaluationsEnvoyees);
    if (match.sport == MuSport.padel) context.push(Routes.matchScore(match.id));
  }
}

/// « Plus tard » and « Envoyer », outside the scrolling part.
class _RateFooter extends StatefulWidget {
  const _RateFooter({required this.form});

  final GlobalKey<_RateFormState> form;

  @override
  State<_RateFooter> createState() => _RateFooterState();
}

class _RateFooterState extends State<_RateFooter> {
  bool _sending = false;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: MuButton.secondary(
          label: l10n.plusTard,
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
        ),
      ),
      const SizedBox(width: MuSpace.s3),
      Expanded(
        child: MuButton.primary(
          label: l10n.envoyer,
          size: MuButtonSize.xl,
          fullWidth: true,
          loading: _sending,
          onPressed: _sending
              ? null
              : () {
                  setState(() => _sending = true);
                  widget.form.currentState?.send();
                },
        ),
      ),
    ],
  );
}

class _RateForm extends ConsumerStatefulWidget {
  const _RateForm({super.key, required this.match});

  final PastMatch match;

  @override
  ConsumerState<_RateForm> createState() => _RateFormState();
}

class _RateFormState extends ConsumerState<_RateForm> {
  // MAT-08's defaults: the partner as announced and exemplary, the first opponent above and
  // friendly, the last one untouched.
  late final List<LevelVerdict?> _levels = [
    for (final (i, m) in widget.match.mates.indexed)
      m.partner ? LevelVerdict.asAnnounced : (i == 1 ? LevelVerdict.above : null),
  ];
  late final List<int> _stars = [
    for (final (i, m) in widget.match.mates.indexed) m.partner ? 5 : (i == 1 ? 4 : 0),
  ];
  static final _words = [l10n.mauvaisEsprit, l10n.limite, l10n.correct, l10n.sympa, l10n.exemplaire];

  Future<void> send() async {
    final ratings = [
      for (final (i, m) in widget.match.mates.indexed)
        MateRating(person: m.person, level: _levels[i], fairPlay: _stars[i]),
    ];
    await ref.read(matchesActionsProvider).rate(widget.match.id, ratings);
    if (mounted) Navigator.of(context, rootNavigator: true).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final m = widget.match;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    return Padding(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.notesAnonymes(m.sport.label, m.venue, formatDay(m.date)),
            style: caption,
          ),
          const SizedBox(height: MuSpace.s2),
          for (final (i, mate) in m.mates.indexed) _mate(context, i, mate),
          const SizedBox(height: MuSpace.s3),
          Row(
            children: [
              Expanded(child: Text(l10n.quelquUnNEstPas, style: caption)),
              MuButton.tertiary(
                label: l10n.signalerUneAbsence,
                leading: PhosphorIcons.flag(),
                size: MuButtonSize.s,
                onPressed: () => showComingSoon(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mate(BuildContext context, int i, MatchMate mate) {
    final c = context.mu;
    // mat-mate: gap 10, padding 10 0, a top rule.
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MuAvatar(name: mate.person.name, level: mate.announcedLevel),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mate.person.name, style: MuType.labelL.copyWith(color: c.text)),
                    Text(
                      l10n.annoncee(mate.role, formatLevel(mate.announcedLevel)),
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(l10n.sonNiveauCeJourLa, style: MuType.labelS.copyWith(color: c.text)),
          const SizedBox(height: MuSpace.s2),
          Semantics(
            label: l10n.niveauDe(mate.person.name),
            child: Wrap(
              spacing: MuSpace.s2,
              children: [
                for (final (v, label) in [
                  (LevelVerdict.below, l10n.enDessous),
                  (LevelVerdict.asAnnounced, l10n.conforme),
                  (LevelVerdict.above, l10n.auDessus),
                ])
                  MuChip(
                    label: label,
                    kind: MuChipKind.choice,
                    size: MuChipSize.s,
                    selected: _levels[i] == v,
                    onSelected: (_) => setState(() => _levels[i] = v),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          MuStarRating.input(
            value: _stars[i].toDouble(),
            label: l10n.fairPlay,
            words: _words,
            size: 20,
            onChanged: (v) => setState(() => _stars[i] = v),
          ),
        ],
      ),
    );
  }
}
