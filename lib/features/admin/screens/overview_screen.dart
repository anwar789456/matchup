import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_widgets.dart';
import '../../../l10n/l10n.dart';

enum _Period { week, month, year }

/// ADM-01 · Vue d’ensemble: the period, 4 KPIs, « À traiter », bookings by sport, the latest
/// reports with their AI score, and the Premium subscribers at risk.
class AdminOverviewScreen extends ConsumerStatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  ConsumerState<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends ConsumerState<AdminOverviewScreen> {
  _Period _period = _Period.week;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final now = ref.read(clockProvider)();
    final o = ref.watch(adminOverviewProvider).value;
    final reports = ref.watch(adminModerationProvider).value ?? const <ModerationItem>[];
    final verifs = (ref.watch(adminVerificationsProvider).value ?? const <AdminVerification>[])
        .where((v) => v.status != AdminVerificationStatus.approved)
        .toList();
    final payouts = (ref.watch(adminPayoutsProvider).value ?? const <AdminPayout>[])
        .where((p) => !p.validated)
        .length;
    final refunds = (ref.watch(adminRefundsProvider).value ?? const <AdminRefund>[])
        .where((r) => !r.done)
        .length;
    final churn = (ref.watch(adminChurnProvider).value ?? const <ChurnRisk>[])
        .where((r) => !r.ignored)
        .toList();
    final high = reports.where((r) => r.score >= 0.8).length;
    final oldest = reports.isEmpty
        ? null
        : reports.map((r) => r.reported).reduce((a, b) => a.isBefore(b) ? a : b);
    final coaches = verifs.where((v) => v.kind == AdminVerificationKind.coach).length;
    final venues = verifs.where((v) => v.kind == AdminVerificationKind.venue).map((v) => v.name);
    final todo = reports.length + verifs.length + payouts + refunds;
    final recent = [...reports]..sort((a, b) => b.score.compareTo(a.score));
    final shown = [
      ...recent.where((r) => r.kind != ModerationKind.review).take(2),
      ...recent.where((r) => r.kind == ModerationKind.review).take(1),
    ];
    return Scaffold(
      backgroundColor: c.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          AdminHeader(
            title: l10n.vueDEnsemble,
            subtitle: l10n.bonjour2(Story.adminName.split(' ').first, formatDateTime(now)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s1, MuSpace.s4, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MuSegmentedControl<_Period>(
                  semanticLabel: l10n.periode,
                  expand: true,
                  value: _period,
                  onChanged: (p) => setState(() => _period = p),
                  segments: [
                    MuSegment(value: _Period.week, label: l10n.jours),
                    MuSegment(value: _Period.month, label: l10n.jours2),
                    MuSegment(value: _Period.year, label: l10n.mois),
                  ],
                ),
                const SizedBox(height: MuSpace.s3),
                AdminKpiGrid(
                  children: [
                    MuKpiCard(
                      label: l10n.utilisateurs,
                      value: formatInt(o?.users ?? 12480),
                      delta: o?.usersDelta ?? 312,
                      deltaText: signedInt(o?.usersDelta ?? 312),
                      period: l10n.vsSemDerniere,
                    ),
                    MuKpiCard(
                      label: l10n.reservations,
                      value: formatInt(o?.bookings ?? 1945),
                      delta: o?.bookingsDelta ?? 8,
                      deltaText: signedPercent(o?.bookingsDelta ?? 8),
                      period: l10n.vsSemDerniere,
                    ),
                    MuKpiCard(
                      label: l10n.revenus,
                      value: formatAmount(o?.revenue ?? 48600),
                      unit: dtUnit,
                      delta: o?.revenueDelta ?? 6,
                      deltaText: signedPercent(o?.revenueDelta ?? 6),
                      period: l10n.vsSemDerniere,
                    ),
                    MuKpiCard(
                      label: l10n.terrainsActifs2,
                      value: formatInt(o?.venues ?? 64),
                      delta: o?.venuesDelta ?? 2,
                      deltaText: signedInt(o?.venuesDelta ?? 2),
                      period: l10n.vsSemDerniere,
                    ),
                  ],
                ),
                const SizedBox(height: adminSectionGap),
                AdminSectionHead(
                  title: l10n.aTraiter,
                  end: AdminMuted(l10n.elements(formatInt(todo))),
                ),
                const SizedBox(height: MuSpace.s2),
                AdminList(
                  inset: AdminList.tileInset,
                  children: [
                    AdminRow(
                      leading: AdminIconTile(PhosphorIcons.flag(), tone: AdminTileTone.error),
                      end: MuCounter(
                        value: reports.length,
                        semanticLabel: '${reports.length} signalements',
                      ),
                      onTap: () => context.go(Routes.adminModeration),
                      child: AdminTexts(
                        title: l10n.signalementsOuverts,
                        lines: [
                          [
                            l10n.scoreIaEleve(high),
                            if (oldest != null) 'depuis ${formatDay(oldest)}',
                          ].join(' · '),
                        ],
                      ),
                    ),
                    AdminRow(
                      leading: AdminIconTile(
                        PhosphorIcons.sealCheck(),
                        tone: AdminTileTone.warning,
                      ),
                      end: MuCounter(
                        value: verifs.length,
                        tone: MuCounterTone.neutral,
                        semanticLabel: l10n.verifications(verifs.length),
                      ),
                      onTap: () => context.go(Routes.adminVerifications),
                      child: AdminTexts(
                        title: l10n.verificationsEnAttente,
                        lines: [
                          [if (coaches > 0) '$coaches coachs', ...venues].join(' · '),
                        ],
                      ),
                    ),
                    AdminRow(
                      leading: AdminIconTile(PhosphorIcons.bank()),
                      onTap: () => context.push(Routes.adminPayouts),
                      child: AdminTexts(
                        title: l10n.versementsEtRemboursements,
                        lines: [l10n.versementsRemboursements(payouts, refunds)],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: adminSectionGap),
                if (o == null)
                  const MuSkeleton(height: 260)
                else
                  MuBarChart(
                    title: l10n.reservationsParSport,
                    subtitle: l10n.matchupDerniersJoursReservations(formatInt(o.bookings)),
                    categories: [for (final d in o.days) '${d.day} ${formatMonth(d)}'],
                    tooltipCategories: [for (final d in o.days) formatDay(d)],
                    series: [
                      for (final e in o.bySport.entries) MuBarSeries.sport(e.key, data: e.value),
                    ],
                    format: (v) => formatInt(v.round()),
                    height: 260,
                    totalLabel: l10n.reservationsAuTotal,
                  ),
                const SizedBox(height: adminSectionGap),
                AdminSectionHead(
                  title: l10n.signalementsRecents,
                  end: MuButton.tertiary(
                    label: l10n.voirLes(reports.length),
                    size: MuButtonSize.s,
                    onPressed: () => context.go(Routes.adminModeration),
                  ),
                ),
                const SizedBox(height: MuSpace.s2),
                AdminList(
                  children: [
                    for (final r in shown)
                      AdminRow(
                        top: true,
                        chevron: false,
                        end: AdminScore.toxicity(r.score),
                        onTap: () => r.reviewable
                            ? context.push(Routes.adminReview(r.id))
                            : context.go(Routes.adminModeration),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _overviewType(r),
                              style: MuType.labelS.copyWith(color: c.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _overviewQuote(r),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MuType.body.copyWith(color: c.text),
                            ),
                            const SizedBox(height: 2),
                            AdminWhy(
                              r.kind == ModerationKind.review
                                  ? l10n.aucuneToxiciteAvisConteste
                                  : r.why,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: MuSpace.s2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
                  child: AdminMuted(
                    l10n.leScoreIaAideA,
                  ),
                ),
                const SizedBox(height: adminSectionGap),
                AdminSectionHead(title: l10n.abonnements),
                const SizedBox(height: MuSpace.s2),
                AdminList(
                  inset: AdminList.tileInset,
                  children: [
                    AdminRow(
                      leading: AdminIconTile(
                        PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                        tone: AdminTileTone.ai,
                      ),
                      onTap: () => context.push(Routes.adminChurn),
                      child: AdminTexts(
                        title: l10n.abonnesPremiumARisque(churn.length),
                        titleEnd: MuAiLabel(size: MuAiLabelSize.s),
                        lines: [churn.map((r) => r.name).join(', ')],
                      ),
                    ),
                    AdminRow(
                      leading: AdminIconTile(PhosphorIcons.crownSimple()),
                      onTap: () => context.go(Routes.adminFinance),
                      child: AdminTexts(
                        title: l10n.abonnesPremium2(o?.premium ?? 180),
                        lines: [
                          l10n.cetteSemaineEssaisEnCours(formatDT(o?.premiumWeek ?? 3420), o?.trials ?? 24),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s16 + MuSpace.s10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ADM-01 shortens the queue's labels (« Post · Équipement · promo_crampons »).
  static String _overviewType(ModerationItem r) => switch (r.kind) {
    ModerationKind.comment => l10n.commentaire('${r.author}'),
    ModerationKind.review => r.type,
    _ => '${r.type} · ${r.author}',
  };

  static String _overviewQuote(ModerationItem r) => switch (r.id) {
    'promo' => l10n.vendsCramponsPasCher,
    'yassine' => l10n.franchementTEsNul,
    'hoop' => l10n.panierCasseDepuisDesSemaines,
    _ => r.quote,
  };
}
