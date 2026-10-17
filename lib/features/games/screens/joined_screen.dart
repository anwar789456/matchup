import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../common/widgets/coming_soon.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../data/games_repository.dart';
import '../widgets/game_widgets.dart';

/// GAM-05 · Tu es inscrit: the dark header with the check mark and the kickoff, the summary card,
/// « Ta place » on the pitch, the invite card, then « Voir mes matchs ».
class JoinedScreen extends ConsumerWidget {
  const JoinedScreen({super.key, required this.gameId});

  final String gameId;

  // GAM-05: a 136 mark (88 accent disc with two rings), the main overlaps the header by 24.
  static const double _mark = 136;
  static const double _disc = 88;
  static const double _overlap = 24;
  static const double _check = 40;

  static Uri _calendar(MuGame g) {
    String stamp(DateTime d) =>
        '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}'
        'T${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}00';
    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': '${g.sport.label} · ${g.title}',
      'dates': '${stamp(g.start)}/${stamp(g.start.add(const Duration(hours: 1)))}',
      'ctz': 'Africa/Tunis',
      'location': '${g.venue}, ${g.place}',
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final details = ref.watch(gameDetailsProvider(gameId));
    void home() => context.go(Routes.home);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) home();
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: switch (details) {
          AsyncData(:final value) => _body(context, value, home),
          AsyncError() => Center(
            child: MuButton.primary(label: 'Retour à l’accueil', onPressed: home),
          ),
          _ => const Center(child: MuSpinner(semanticLabel: 'Chargement')),
        },
        bottomNavigationBar: details.value == null
            ? null
            : StickyActionBar(
                children: [
                  MuButton.primary(
                    label: 'Voir mes matchs',
                    trailing: PhosphorIcons.arrowRight(),
                    size: MuButtonSize.xl,
                    fullWidth: true,
                    onPressed: () => context.go(Routes.matches),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _body(BuildContext context, GameDetails d, VoidCallback home) {
    final c = context.mu;
    final g = d.game;
    final link = 'https://matchup.tn/g/${g.id}';
    final others = g.players.where((p) => p.name != Story.myName).length - 1;
    final organiserFirst = (g.organiser ?? 'L’organisateur').split(' ').first;
    final end = g.start.add(const Duration(hours: 1));
    final weekday = switch (g.start.weekday) {
      DateTime.monday => 'lundi',
      DateTime.tuesday => 'mardi',
      DateTime.wednesday => 'mercredi',
      DateTime.thursday => 'jeudi',
      DateTime.friday => 'vendredi',
      DateTime.saturday => 'samedi',
      _ => 'dimanche',
    };

    final header = Theme(
      data: MuTheme.dark(),
      child: Builder(
        builder: (context) {
          final dc = context.mu;
          return Container(
            color: dc.bg,
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s6 + _overlap),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: MuIconButton(
                      icon: PhosphorIcons.x(),
                      label: 'Fermer et revenir à l’accueil',
                      size: MuIconButtonSize.l,
                      onPressed: home,
                    ),
                  ),
                  SizedBox(
                    width: _mark,
                    height: _mark,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: _mark,
                          height: _mark,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: dc.accent.withValues(alpha: 0.25), width: 2),
                          ),
                        ),
                        Container(
                          width: _mark - MuSpace.s4,
                          height: _mark - MuSpace.s4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: dc.accent.withValues(alpha: 0.5), width: 2),
                          ),
                        ),
                        Container(
                          width: _disc,
                          height: _disc,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: dc.accent),
                          child: Icon(
                            PhosphorIcons.check(PhosphorIconsStyle.bold),
                            size: _check,
                            color: dc.onAccent,
                            semanticLabel: 'Inscription confirmée',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: MuSpace.s5),
                  Semantics(
                    header: true,
                    child: Text(
                      'Tu es dans la partie !',
                      textAlign: TextAlign.center,
                      style: MuType.h1.copyWith(color: dc.text),
                    ),
                  ),
                  const SizedBox(height: MuSpace.s2),
                  Text(
                    '$organiserFirst et $others joueurs t’attendent $weekday à ${g.venue}. '
                    'Ta part est payée.',
                    textAlign: TextAlign.center,
                    style: MuType.bodyL.copyWith(color: dc.textSecondary),
                  ),
                  const SizedBox(height: MuSpace.s4),
                  KickoffPill(start: g.start),
                ],
              ),
            ),
          );
        },
      ),
    );

    Widget row(IconData icon, Widget title, Widget caption) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: MuSize.iconS, color: c.textSecondary),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, caption]),
          ),
        ],
      ),
    );
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    final label = MuType.label.copyWith(color: c.text);

    final summary = MuCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(
            PhosphorIcons.calendarCheck(),
            Text('${formatDay(g.start)} · ${formatTime(g.start)}–${formatTime(end)}', style: label),
            Text('Arrive 10 min avant', style: caption),
          ),
          const SizedBox(height: MuSpace.s2),
          row(
            PhosphorIcons.mapPin(),
            Text(g.title, style: label),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: Story.streetOf(d.venue)),
                  if (g.distanceKm != null) ...[
                    const TextSpan(text: ' · '),
                    TextSpan(
                      text: '${formatLevel(g.distanceKm!)} km',
                      style: MuType.labelS.copyWith(color: c.text),
                    ),
                  ],
                ],
              ),
              style: caption,
            ),
          ),
          const SizedBox(height: MuSpace.s2),
          row(
            PhosphorIcons.receipt(),
            Row(
              children: [
                Text('Ta part · ${formatDT(g.pricePerPlayer)}', style: label),
                const SizedBox(width: MuSpace.s2),
                const MuStatusBadge(status: MuStatus.paid, label: 'Payé', size: MuBadgeSize.s),
              ],
            ),
            Text('Annulation gratuite jusqu’à ${formatDateTime(d.freeUntil)}', style: caption),
          ),
          const SizedBox(height: MuSpace.s4),
          Row(
            children: [
              Expanded(
                child: MuButton.secondary(
                  label: 'Calendrier',
                  leading: PhosphorIcons.calendarPlus(),
                  fullWidth: true,
                  onPressed: () => launchUrl(_calendar(g), mode: LaunchMode.externalApplication),
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: MuButton.secondary(
                  label: 'Discussion',
                  leading: PhosphorIcons.chatCircle(),
                  fullWidth: true,
                  onPressed: () => showComingSoon(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final invite = MuCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: MuSize.controlM,
                height: MuSize.controlM,
                decoration: BoxDecoration(color: c.accent, borderRadius: MuRadius.smAll),
                child: Icon(PhosphorIcons.userPlus(), size: MuSize.iconS, color: c.onAccent),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.spotsLeft == 1 ? 'Plus qu’une place' : 'Encore ${g.spotsLeft} places',
                      style: MuType.labelL.copyWith(color: c.text),
                    ),
                    Text(
                      'Invite un ami pour compléter la partie. Il paiera sa part de '
                      '${formatDT(g.pricePerPlayer)}.',
                      style: caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Row(
            children: [
              Expanded(
                child: MuButton.secondary(
                  label: 'WhatsApp',
                  leading: PhosphorIcons.whatsappLogo(),
                  fullWidth: true,
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      text:
                          'Rejoins-moi : ${g.sport.label} · ${g.title} · '
                          '${formatDateTime(g.start)} · $link',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: MuButton.secondary(
                  label: 'Copier le lien',
                  leading: PhosphorIcons.link(),
                  fullWidth: true,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: link));
                    if (context.mounted) MuToast.show(context, title: 'Lien copié');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        header,
        Transform.translate(
          offset: const Offset(0, -_overlap),
          child: Container(
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(MuRadius.lg)),
            ),
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s5, MuSpace.s4, MuSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                summary,
                const SizedBox(height: MuSpace.s6),
                MuLineup(sport: g.sport, teams: d.teams, title: 'Ta place', disabled: true),
                const SizedBox(height: MuSpace.s4),
                if (g.spotsLeft > 0) invite,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
