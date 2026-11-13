import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/tournoi_providers.dart';
import '../data/tournoi_repository.dart';
import '../logic/bracket_logic.dart';
import '../organizer/org_widgets.dart';
import '../organizer/planning_screen.dart';

/// TRN-10 · Match en direct, then TRN-11 · Résumé once it is over: the score (refreshed by the
/// sync as the organiser enters it), where and when, and a recap to share.
class MatchScreen extends ConsumerWidget {
  const MatchScreen({super.key, required this.id, required this.matchId});

  final String id;

  /// [TournoiRepository.matchId].
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TournoiLoader(
        id: id,
        builder: (context, t) {
          final c = context.mu;
          final matches = ref.watch(matchsProvider(id)).value ?? const <MatchPlan>[];
          final names = teamNames(ref.watch(equipesProvider(id)).value ?? const []);
          final m = matches.where((x) => TournoiRepository.matchId(id, x) == matchId).firstOrNull;
          if (m == null) {
            return OrgPage(
              title: l10n.trnMatch,
              back: Routes.tournoi(id),
              children: [MuEmptyState(title: l10n.trnIntrouvable, compact: true)],
            );
          }
          final sizes = roundSizes(matches);
          final a = names[m.equipe1] ?? l10n.trnADeterminer;
          final b = names[m.equipe2] ?? l10n.trnADeterminer;
          final done = m.statut == MatchStatus.termine;
          final live = m.statut == MatchStatus.enDirect;
          final winner = m.vainqueur == null ? null : names[m.vainqueur];
          final recap = done && winner != null
              ? l10n.trnRecapTexte(
                  winner,
                  m.vainqueur == m.equipe1 ? b : a,
                  '${m.score1 ?? 0}-${m.score2 ?? 0}',
                  matchLabel(m, sizes),
                  t.draft.nom,
                )
              : null;

          Widget team(String name, int? score, bool won) => Expanded(
                child: Column(children: [
                  MuAvatar(name: name, size: MuAvatarSize.l),
                  const SizedBox(height: MuSpace.s2),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: (won ? MuType.labelL : MuType.body).copyWith(color: c.text),
                  ),
                  const SizedBox(height: MuSpace.s2),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(score == null ? '–' : '$score', style: MuType.h1.copyWith(color: c.text)),
                  ),
                ]),
              );

          return OrgPage(
            title: done ? l10n.trnResume : (live ? l10n.trnMatchEnDirect : l10n.trnMatch),
            subtitle: '${t.draft.nom} · ${matchLabel(m, sizes)}',
            back: Routes.tournoi(id),
            bottom: recap == null
                ? null
                : MuButton.primary(
                    label: l10n.trnPartagerResume,
                    leading: PhosphorIcons.shareNetwork(),
                    size: MuButtonSize.l,
                    fullWidth: true,
                    onPressed: () => SharePlus.instance.share(ShareParams(text: recap)),
                  ),
            children: [
              Row(children: [
                if (live) MuStatusBadge(status: MuStatus.live, label: l10n.trnEnDirect),
                if (done) MuStatusBadge(status: MuStatus.confirmed, label: l10n.trnTermine),
                if (!live && !done) MuStatusBadge(status: MuStatus.pending, label: l10n.trnAJouer),
              ]),
              const SizedBox(height: MuSpace.s4),
              Container(
                padding: const EdgeInsetsDirectional.all(MuSpace.s5),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(MuRadius.lg),
                  border: Border.all(color: live ? c.primary : c.border),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  team(a, m.score1, done && m.vainqueur == m.equipe1),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: MuSpace.s8),
                    child: Text(l10n.trnContre, style: MuType.caption.copyWith(color: c.textSecondary)),
                  ),
                  team(b, m.score2, done && m.vainqueur == m.equipe2),
                ]),
              ),
              const SizedBox(height: MuSpace.s4),
              MuSettingsGroup(children: [
                MuSettingsRow(
                  icon: PhosphorIcons.clock(),
                  title: l10n.trnQuand,
                  value: m.debut == null ? '—' : formatDateTime(m.debut!),
                  chevron: false,
                ),
                MuSettingsRow(
                  icon: PhosphorIcons.mapPin(),
                  title: l10n.trnOu,
                  value: [t.draft.etablissement, ?m.terrain].join(' · '),
                  chevron: false,
                ),
              ]),
              if (live) ...[
                const SizedBox(height: MuSpace.s3),
                Text(l10n.trnScoreMisAJour, style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
              if (recap != null) ...[
                const SizedBox(height: MuSpace.s5),
                Text(l10n.trnResume, style: MuType.h3.copyWith(color: c.text)),
                const SizedBox(height: MuSpace.s2),
                Text(recap, style: MuType.body.copyWith(color: c.text)),
              ],
            ],
          );
        },
      );
}

/// ORG-14 seen by players: the organiser's announcements, newest first.
class AnnoncesSection extends ConsumerWidget {
  const AnnoncesSection({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final list = ref.watch(annoncesProvider(id)).value ?? const <(String, DateTime)>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: MuSpace.s5),
        Text(l10n.trnAnnoncesOrga, style: MuType.h3.copyWith(color: c.text)),
        const SizedBox(height: MuSpace.s2),
        for (final (message, at) in list)
          Container(
            margin: const EdgeInsetsDirectional.only(bottom: MuSpace.s2),
            padding: const EdgeInsetsDirectional.all(MuSpace.s3),
            decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(MuRadius.md)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(PhosphorIcons.megaphone(), size: 20, color: c.textSecondary),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(message, style: MuType.body.copyWith(color: c.text)),
                  Text(formatDateTime(at), style: MuType.caption.copyWith(color: c.textSecondary)),
                ]),
              ),
            ]),
          ),
      ],
    );
  }
}
