import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/clock.dart';
import '../../../core/directions.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../common/widgets/coming_soon.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../../games/widgets/game_widgets.dart';
import '../controllers/matches_providers.dart';
import '../data/bookings_repository.dart';
import '../../../l10n/l10n.dart';

/// MAT-05 · Détail de la réservation: the court under the lights, the facts and the QR code, the
/// place, the players and their payments, the chat, the cancellation policy; the sticky « Inviter
/// des joueurs ». « Annuler la réservation » opens MAT-06.
class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _cancelling = false;

  // MAT-05: photo 248, map 152, payment rows ≥ 52, the « + » ring 32.
  static const double _photo = 248;
  static const double _map = 152;
  static const double _mapZoom = 1.6;
  static const double _row = 52;
  static const double _plus = 32;
  static const double _bottomRoom = MuSpace.s16 + MuSpace.s8;

  String get _link => 'https://matchup.tn/r/${widget.bookingId}';

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _link));
    if (mounted) MuToast.show(context, title: l10n.lienCopie);
  }

  void _showTicket(BookingDetails d) {
    final b = d.booking;
    MuTakeover.show<void>(
      context,
      builder: (ctx) => MuTakeover(
        title: l10n.tonBillet,
        onClose: () => Navigator.of(ctx).pop(),
        body: ListView(
          padding: const EdgeInsets.all(MuSpace.s4),
          children: [
            MuTicket(
              reference: b.id!,
              sport: b.sport,
              venue: '${b.venue} · ${b.place}',
              court: b.court ?? '',
              date: formatDay(b.start),
              time: formatTime(b.start),
              players: '${d.playersIn}/${d.spotsTotal}',
              paid: formatDT(b.share),
              data: _link,
            ),
            const SizedBox(height: MuSpace.s3),
            Text(
              l10n.presenteCeCodeAL2(elideDe(b.venue)),
              textAlign: TextAlign.center,
              style: MuType.caption.copyWith(color: ctx.mu.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// MAT-06 · Annuler la réservation ?
  Future<void> _cancel(BookingDetails d) async {
    final b = d.booking;
    final nav = Navigator.of(context, rootNavigator: true);
    final n = d.playersIn;
    final confirmed = await MuDialog.show<bool>(
      context,
      tone: MuDialogTone.destructive,
      icon: PhosphorIcons.calendarX(),
      title: l10n.annulerLaReservation,
      description:
          l10n.lesJoueursEtSerontPrevenus(b.title, formatDateTime(b.start), b.venue),
      consequence:
          l10n.lesJoueursSerontRemboursesChacun(n, formatDT(b.share)),
      consequenceIcon: PhosphorIcons.wallet(),
      content: Builder(
        builder: (context) {
          final c = context.mu;
          Widget line(String label, Widget value) => Padding(
            padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
            child: Row(
              children: [
                Expanded(
                  child: Text(label, style: MuType.body.copyWith(color: c.text)),
                ),
                value,
              ],
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              line(
                l10n.taPartRemboursee,
                Text(formatDT(b.share), style: MuType.numS.copyWith(color: c.text)),
              ),
              line(
                l10n.totalRembourseJoueurs(n),
                Text(formatDT(b.share * n), style: MuType.numS.copyWith(color: c.text)),
              ),
              line(
                l10n.annulationGratuiteAvant(formatDay(d.freeUntil)),
                const MuStatusBadge(status: MuStatus.refunded, label: '100 %', size: MuBadgeSize.s),
              ),
            ],
          );
        },
      ),
      actions: [
        MuButton.secondary(
          label: l10n.garderLaReservation,
          size: MuButtonSize.l,
          fullWidth: true,
          onPressed: () => nav.pop(false),
        ),
        MuButton.destructive(
          label: l10n.annulerLaReservation2,
          size: MuButtonSize.l,
          fullWidth: true,
          onPressed: () => nav.pop(true),
        ),
      ],
    );
    if (confirmed != true || !mounted) return;
    setState(() => _cancelling = true);
    // The page closes on « Mes matchs »: the toast lives in the app's overlay.
    final overlay = Overlay.of(context, rootOverlay: true);
    final c = await ref.read(matchesActionsProvider).cancel(widget.bookingId);
    if (!mounted) return;
    context.go(Routes.matches);
    if (!overlay.mounted) return;
    MuToast.show(
      overlay.context,
      overlay: overlay,
      tone: MuToastTone.success,
      title: l10n.reservationAnnulee,
      description:
          l10n.remboursesSurLesSoldesMatchup(formatDT(c.totalRefund ?? c.refund)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final details = ref.watch(bookingDetailsProvider(widget.bookingId));
    return Scaffold(
      backgroundColor: c.bg,
      body: switch (details) {
        AsyncData(:final value) => _body(context, value),
        AsyncError() => Center(
          child: Padding(
            padding: const EdgeInsets.all(MuSpace.s4),
            child: MuEmptyState(
              title: l10n.reservationIntrouvable,
              description: l10n.elleAPeutEtreEte,
              actions: [
                MuButton.primary(
                  label: l10n.voirMesMatchs,
                  onPressed: () => context.go(Routes.matches),
                ),
              ],
            ),
          ),
        ),
        _ => Column(
          children: [
            SizedBox(
              height: _photo,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const MuSkeleton(height: _photo, radius: BorderRadius.zero),
                  Align(
                    alignment: Alignment.topCenter,
                    child: MuTopAppBar.media(onBack: () => context.pop()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: MuSkeletonGroup(
                label: l10n.chargementDeLaReservation,
                child: const Padding(
                  padding: EdgeInsets.all(MuSpace.s4),
                  child: MuSkeleton.text(lines: 6),
                ),
              ),
            ),
          ],
        ),
      },
      bottomNavigationBar: details.value == null || !details.value!.organizer
          ? null
          : StickyActionBar(
              children: [
                MuButton.primary(
                  label: l10n.inviterDesJoueursPlaces(details.value!.openSpots),
                  leading: PhosphorIcons.userPlus(),
                  size: MuButtonSize.xl,
                  fullWidth: true,
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      text:
                          l10n.rejoinsMaPartie(details.value!.booking.sport.label, details.value!.booking.title, formatDateTime(details.value!.booking.start), _link),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _body(BuildContext context, BookingDetails d) {
    final c = context.mu;
    final b = d.booking;
    final now = ref.read(clockProvider)();
    final days = b.start.difference(now).inDays;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    final weekday = switch (b.start.weekday) {
      DateTime.monday => l10n.lundi,
      DateTime.tuesday => l10n.mardi,
      DateTime.wednesday => l10n.mercredi,
      DateTime.thursday => l10n.jeudi,
      DateTime.friday => l10n.vendredi,
      DateTime.saturday => l10n.samedi,
      _ => l10n.dimanche,
    };

    final hero = SizedBox(
      height: _photo,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MuCourtArt(
            sport: b.sport,
            variant: MuCourtArtVariant.photo,
            semanticLabel: l10n.sousLesProjecteurs(b.venue, '${b.court}'),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: MuTopAppBar.media(
              onBack: () => context.pop(),
              backLabel: l10n.retourAMesMatchs,
              actions: [
                MuBarAction(
                  icon: PhosphorIcons.shareNetwork(),
                  label: l10n.partager,
                  onPressed: () => SharePlus.instance.share(ShareParams(text: _link)),
                ),
                MuBarAction(
                  icon: PhosphorIcons.dotsThree(),
                  label: l10n.plusDActions,
                  onPressed: () => showComingSoon(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            MuStatusBadge(
              status: MuStatus.confirmed,
              label: l10n.confirmee,
              size: MuBadgeSize.s,
            ),
            const SizedBox(width: MuSpace.s2),
            MuChip(
              label: b.sport == MuSport.football ? l10n.footballVs : b.sport.label,
              kind: MuChipKind.sport,
              sport: b.sport,
              size: MuChipSize.s,
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: l10n.ref2),
                    TextSpan(text: b.id, style: MuType.numXs.copyWith(color: c.text)),
                  ],
                ),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: caption,
              ),
            ),
          ],
        ),
        const SizedBox(height: MuSpace.s3),
        Semantics(
          header: true,
          child: Text(b.title, style: MuType.h2.copyWith(color: c.text)),
        ),
        const SizedBox(height: MuSpace.s1),
        Text(
          '${d.isPublic ? l10n.partiePublique : l10n.partiePrivee} · ${d.gameType}'
          '${d.levelMin != null ? l10n.niveau3(formatLevel(d.levelMin!), formatLevel(d.levelMax!)) : ''}'
          '${d.organizer ? l10n.tuOrganises : ''}',
          style: MuType.body.copyWith(color: c.textSecondary),
        ),
      ],
    );

    final facts = Semantics(
      label: l10n.quandEtCombien,
      child: FactsCard(
        flex: const [100, 125, 90],
        valueStyle: MuType.numM,
        cells: [
          FactCell(
            weekday,
            '${b.start.day} ${formatMonth(b.start)}',
            caption: days <= 0 ? l10n.aujourdHui : l10n.dansJour(days, days > 1 ? 's' : ''),
          ),
          FactCell(l10n.horaire, b.timeRange, caption: '${b.duration}${d.lit ? l10n.eclaire2 : ''}'),
          FactCell(
            l10n.taPart,
            formatAmount(b.share),
            valueUnit: dtUnit,
            captionWidget: Row(
              children: [
                Icon(
                  PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                  size: MuSize.iconXs - 2,
                  color: c.successText,
                ),
                const SizedBox(width: MuSpace.s1 / 2),
                Text(l10n.paye, style: MuType.caption.copyWith(color: c.successText)),
              ],
            ),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(MuSpace.s3, 0, MuSpace.s3, MuSpace.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MuButton.secondary(
                label: l10n.afficherLeQrCode,
                leading: PhosphorIcons.qrCode(),
                fullWidth: true,
                onPressed: () => _showTicket(d),
              ),
              const SizedBox(height: MuSpace.s2),
              Text(
                l10n.tonBilletPourLAccueil(elideDe(b.venue)),
                textAlign: TextAlign.center,
                style: caption,
              ),
            ],
          ),
        ),
      ),
    );

    final place = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(l10n.lieu),
        const SizedBox(height: MuSpace.s3),
        MuCardSurface(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(MuRadius.md)),
                child: SizedBox(
                  height: _map,
                  child: MuMapView(
                    center: d.venue.position!,
                    zoom: _mapZoom,
                    label: '${d.venue.name}, ${d.venue.place}',
                    venues: [
                      MuMapVenue(
                        id: d.venue.id,
                        name: d.venue.name,
                        sport: b.sport,
                        position: d.venue.position!,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(MuSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(d.venue.name, style: MuType.labelL.copyWith(color: c.text)),
                                  if (d.venue.verified) ...[
                                    const SizedBox(width: MuSpace.s2),
                                    MuStatusBadge(
                                      status: MuStatus.verified,
                                      label: l10n.verifie,
                                      size: MuBadgeSize.s,
                                      iconOnly: true,
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                '${Story.streetOf(d.venue).split(',').first}'
                                '${d.venue.distanceKm != null ? l10n.km3(formatLevel(d.venue.distanceKm!)) : ''}',
                                style: caption,
                              ),
                            ],
                          ),
                        ),
                        MuButton.secondary(
                          label: l10n.itineraire,
                          leading: PhosphorIcons.navigationArrow(),
                          size: MuButtonSize.s,
                          onPressed: () => openDirections(d.venue.position!),
                        ),
                      ],
                    ),
                    const SizedBox(height: MuSpace.s2),
                    Text(d.venueNote, style: caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final filled = [for (final t in d.teams) t.players.whereType<MuLineupPlayer>().length];
    final players = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(
          l10n.joueurs,
          trailing: MuButton.tertiary(
            label: l10n.copierLeLien,
            leading: PhosphorIcons.link(),
            size: MuButtonSize.s,
            onPressed: _copyLink,
          ),
        ),
        const SizedBox(height: MuSpace.s3),
        MuCardSurface(
          padding: const EdgeInsets.all(MuSpace.s3),
          child: Row(
            children: [
              Expanded(
                flex: 11,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: MuLineup(
                    sport: b.sport,
                    teams: d.teams,
                    variant: MuLineupVariant.compact,
                    header: false,
                    disabled: true,
                  ),
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              Container(width: 1, height: MuSize.controlL, color: c.border),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                flex: 9,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.niveauMoyen, style: MuType.overline.copyWith(color: c.textSecondary)),
                    MuLevelIndicator(level: d.averageLevel, size: MuLevelSize.s),
                    Text(
                      '${d.teams[0].name} ${filled[0]}/${d.teams[0].players.length} · '
                      '${d.teams[1].name} ${filled[1]}/${d.teams[1].players.length}',
                      style: caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MuSpace.s3),
        MuCardSurface(
          padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, MuSpace.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                button: true,
                label: l10n.suivreLesPaiements,
                child: InkWell(
                  onTap: () => context.push(Routes.bookingPayments(b.id!)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.paiements, style: MuType.h3.copyWith(color: c.text)),
                            Text(
                              l10n.leTerrainParJoueur(formatDT(d.courtPrice), formatDT(b.share)),
                              style: caption,
                            ),
                          ],
                        ),
                      ),
                      Text(formatDT(d.received), style: MuType.numS.copyWith(color: c.text)),
                      Text(l10n.recus, style: caption),
                      const SizedBox(width: MuSpace.s1),
                      Icon(PhosphorIcons.caretRight(), size: MuSize.iconXs, color: c.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: MuSpace.s2),
              for (final p in d.payments)
                Container(
                  constraints: const BoxConstraints(minHeight: _row),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.border)),
                  ),
                  child: Row(
                    children: [
                      MuAvatar(name: p.person.name, size: MuAvatarSize.s),
                      const SizedBox(width: MuSpace.s3),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.you ? l10n.toi2(p.person.name) : p.person.name,
                              style: MuType.label.copyWith(color: c.text),
                            ),
                            if (p.organizer && p.paidAt != null)
                              Text(
                                l10n.organisateurPayeLe(formatDay(p.paidAt!)),
                                style: caption,
                              ),
                          ],
                        ),
                      ),
                      if (p.paid)
                        MuStatusBadge(
                          status: MuStatus.paid,
                          label: l10n.paye,
                          size: MuBadgeSize.s,
                        )
                      else
                        MuStatusBadge(
                          status: MuStatus.pending,
                          label: l10n.enAttente,
                          size: MuBadgeSize.s,
                        ),
                    ],
                  ),
                ),
              if (d.openSpots > 0)
                Container(
                  constraints: const BoxConstraints(minHeight: _row),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.border)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: _plus,
                        height: _plus,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: c.borderStrong),
                        ),
                        child: Icon(
                          PhosphorIcons.plus(),
                          size: MuSize.iconXs,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(width: MuSpace.s3),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.placesPubliques(d.openSpots),
                              style: MuType.label.copyWith(color: c.text),
                            ),
                            Text(
                              l10n.payesParChaqueJoueurQui(formatDT(b.share)),
                              style: caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    final chat = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(
          l10n.discussion,
          trailing: d.unreadMessages > 0
              ? Text(l10n.nouveauxMessages(d.unreadMessages), style: caption)
              : null,
        ),
        const SizedBox(height: MuSpace.s3),
        MuCardSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (d.messages.isEmpty)
                Text(l10n.pasEncoreDeMessage, style: caption)
              else
                for (final (i, m) in d.messages.indexed) ...[
                  if (i > 0) const SizedBox(height: MuSpace.s3),
                  ChatMessage(author: m.author, time: m.time, text: m.text),
                ],
              const SizedBox(height: MuSpace.s3),
              MuButton.secondary(
                label: l10n.ouvrirLaDiscussion,
                leading: PhosphorIcons.chatCircle(),
                fullWidth: true,
                onPressed: () => showComingSoon(context),
              ),
            ],
          ),
        ),
      ],
    );

    Widget tier(IconData icon, Color color, String title, String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: MuSize.iconXs, color: color),
        const SizedBox(width: MuSpace.s2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: MuType.label.copyWith(color: c.text)),
              Text(text, style: caption),
            ],
          ),
        ),
      ],
    );
    final cancellation = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(l10n.annulation),
        const SizedBox(height: MuSpace.s3),
        MuCardSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: l10n.annulationGratuiteJusquAH,
                child: Row(
                  children: [
                    Expanded(
                      flex: 13,
                      child: Container(
                        height: MuSpace.s1,
                        decoration: BoxDecoration(color: c.success, borderRadius: MuRadius.fullAll),
                      ),
                    ),
                    const SizedBox(width: MuSpace.s1),
                    Expanded(
                      flex: 10,
                      child: Container(
                        height: MuSpace.s1,
                        decoration: BoxDecoration(color: c.warning, borderRadius: MuRadius.fullAll),
                      ),
                    ),
                    const SizedBox(width: MuSpace.s1),
                    Expanded(
                      flex: 10,
                      child: Container(
                        height: MuSpace.s1,
                        decoration: BoxDecoration(color: c.error, borderRadius: MuRadius.fullAll),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MuSpace.s4),
              tier(
                PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                c.success,
                l10n.gratuiteJusquAu(formatDateTime(d.freeUntil)),
                l10n.rembourseTuEsIci,
              ),
              const SizedBox(height: MuSpace.s3),
              tier(
                PhosphorIcons.clock(PhosphorIconsStyle.fill),
                c.warning,
                l10n.entreHEtHAvant,
                l10n.rembourse,
              ),
              const SizedBox(height: MuSpace.s3),
              tier(
                PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
                c.error,
                l10n.moinsDeHAvant,
                l10n.nonRemboursable,
              ),
              const SizedBox(height: MuSpace.s4),
              Text(
                l10n.siTuAnnulesLesJoueurs(d.playersIn),
                style: caption,
              ),
            ],
          ),
        ),
        if (d.organizer) ...[
          const SizedBox(height: MuSpace.s4),
          MuButton.destructiveOutline(
            label: l10n.annulerLaReservation2,
            leading: PhosphorIcons.calendarX(),
            size: MuButtonSize.l,
            fullWidth: true,
            loading: _cancelling,
            onPressed: _cancelling ? null : () => _cancel(d),
          ),
        ],
      ],
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        hero,
        Padding(
          padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, _bottomRoom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: MuSpace.s4),
              facts,
              const SizedBox(height: MuSpace.s6),
              place,
              const SizedBox(height: MuSpace.s6),
              players,
              const SizedBox(height: MuSpace.s6),
              chat,
              const SizedBox(height: MuSpace.s6),
              cancellation,
            ],
          ),
        ),
      ],
    );
  }
}
