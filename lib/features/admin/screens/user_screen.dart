import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_widgets.dart';
import '../../../l10n/l10n.dart';

/// ADM-03 · Fiche utilisateur: profile and numbers, contact, the no-show alert, the open report,
/// recent activity, payments and sanctions, then « Avertir » / « Suspendre » (ADM-04).
class AdminUserScreen extends ConsumerWidget {
  const AdminUserScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final d = ref.watch(adminUserDetailProvider(userId)).value;
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          AdminBar(
            title: l10n.ficheUtilisateur,
            caption: d == null ? l10n.admin : l10n.adminId(d.code),
            backLabel: l10n.retourAuxUtilisateurs,
            fallback: Routes.adminUsers,
            actions: [
              MuIconButton(
                icon: PhosphorIcons.dotsThreeVertical(),
                label: l10n.plusDActions,
                size: MuIconButtonSize.l,
                onPressed: () => showComingSoon(context),
              ),
            ],
          ),
          Expanded(
            child: d == null
                ? const Center(child: MuSpinner())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      MuSpace.s4,
                      MuSpace.s2,
                      MuSpace.s4,
                      MuSpace.s8,
                    ),
                    children: _body(context, c, d),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: d == null
          ? null
          : StickyActionBar(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: MuButton.secondary(
                        label: l10n.avertir,
                        leading: PhosphorIcons.warning(),
                        size: MuButtonSize.xl,
                        fullWidth: true,
                        onPressed: () => showComingSoon(context),
                      ),
                    ),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(
                      child: MuButton.destructive(
                        label: l10n.suspendre2,
                        leading: PhosphorIcons.prohibit(),
                        size: MuButtonSize.xl,
                        fullWidth: true,
                        onPressed:
                            d.user.status == AdminUserStatus.suspended ||
                                d.user.status == AdminUserStatus.banned
                            ? null
                            : () => context.push(Routes.adminSuspend(userId)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  List<Widget> _body(BuildContext context, MuColors c, AdminUserDetail d) {
    final u = d.user;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    Widget stat(String value, String label, {Color? color, bool first = false}) => Expanded(
      child: Container(
        padding: EdgeInsetsDirectional.fromSTEB(
          first ? MuSpace.s4 : MuSpace.s3,
          MuSpace.s3,
          MuSpace.s2,
          MuSpace.s3,
        ),
        decoration: BoxDecoration(
          border: first ? null : BorderDirectional(start: BorderSide(color: c.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: MuType.numL.copyWith(color: color ?? c.text)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: caption),
          ],
        ),
      ),
    );
    Widget fact(String label, Widget value) => Container(
      constraints: const BoxConstraints(minHeight: MuSize.controlL),
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: MuType.body.copyWith(color: c.textSecondary)),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Align(alignment: AlignmentDirectional.centerEnd, child: value),
          ),
        ],
      ),
    );
    Widget verified(String text, {bool number = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: (number ? MuType.numS : MuType.body).copyWith(color: c.text),
          ),
        ),
        const SizedBox(width: MuSpace.s2 - 2),
        MuStatusBadge(
          status: MuStatus.verified,
          label: l10n.verifie,
          iconOnly: true,
          size: MuBadgeSize.s,
        ),
      ],
    );
    final suspended = u.status == AdminUserStatus.suspended || u.status == AdminUserStatus.banned;

    return [
      // Profile.
      DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: MuRadius.mdAll,
          boxShadow: MuElevation.of(context).level1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s5, MuSpace.s4, MuSpace.s4),
              child: Row(
                children: [
                  MuAvatar(name: u.name, size: MuAvatarSize.l, level: d.level),
                  const SizedBox(width: MuSpace.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(u.name, style: MuType.h2.copyWith(color: c.text)),
                        ),
                        const SizedBox(height: MuSpace.s1),
                        Text(
                          '${d.handle} · ${u.roleLine}',
                          style: MuType.body.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: MuSpace.s1),
                        Wrap(
                          spacing: MuSpace.s2 - 2,
                          runSpacing: MuSpace.s1,
                          children: [
                            if (suspended)
                              MuStatusBadge(
                                status: MuStatus.cancelled,
                                label: u.status == AdminUserStatus.banned ? l10n.banni : l10n.suspendu,
                                size: MuBadgeSize.s,
                              )
                            else
                              MuStatusBadge(
                                status: MuStatus.failed,
                                label: l10n.signale,
                                size: MuBadgeSize.s,
                              ),
                            if (u.reliability != null)
                              MuReliabilityBadge(score: u.reliability!, size: MuBadgeSize.s),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    stat('${d.matches}', 'matchs', first: true),
                    stat('${d.noShows}', 'no-shows', color: c.errorText),
                    stat('${d.reports}', d.reports > 1 ? 'signalements' : 'signalement'),
                    stat(formatAmount(d.paid), l10n.payes(dtUnit)),
                  ],
                ),
              ),
            ),
            fact(l10n.email, verified(u.email)),
            fact(l10n.telephone, verified(ltr(formatPhone(u.phone)), number: true)),
            fact(
              l10n.niveau6,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MuSportIcon(d.sport, size: MuSize.iconXs),
                  const SizedBox(width: MuSpace.s2 - 2),
                  Text(
                    '${formatLevel(d.level)} · ${levelBand(d.level)}',
                    style: MuType.body.copyWith(color: c.text),
                  ),
                ],
              ),
            ),
            fact(l10n.inscrit, Text(d.joinedLine, style: MuType.body.copyWith(color: c.text))),
          ],
        ),
      ),
      const SizedBox(height: MuSpace.s6),
      MuBanner(
        tone: MuBannerTone.warning,
        icon: PhosphorIcons.calendarX(),
        title: d.alertTitle,
        detail: d.alertDetail,
      ),
      const SizedBox(height: MuSpace.s6),
      AdminSectionHead(title: l10n.signalementOuvert, end: AdminMuted(l10n.sur5)),
      const SizedBox(height: MuSpace.s2),
      MuCardSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                MuAvatar(name: d.reporter, size: MuAvatarSize.s),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: AdminTexts(title: l10n.signalePar(d.reporter), lines: [d.reporterLine]),
                ),
                MuStatusBadge(status: MuStatus.pending, label: l10n.ouvert, size: MuBadgeSize.s),
              ],
            ),
            const SizedBox(height: MuSpace.s3),
            Container(
              padding: const EdgeInsets.all(MuSpace.s3),
              decoration: BoxDecoration(color: c.bg, borderRadius: MuRadius.smAll),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.reportContext, style: MuType.labelS.copyWith(color: c.textSecondary)),
                  const SizedBox(height: MuSpace.s2 - 2),
                  Text(d.reportQuote, style: MuType.body.copyWith(color: c.text)),
                ],
              ),
            ),
            const SizedBox(height: MuSpace.s3),
            Row(
              children: [
                Expanded(
                  child: MuButton.secondary(
                    label: l10n.classer,
                    fullWidth: true,
                    onPressed: () => showComingSoon(context),
                  ),
                ),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: MuButton.secondary(
                    label: l10n.repondre,
                    leading: PhosphorIcons.chatCenteredText(),
                    fullWidth: true,
                    onPressed: () => showComingSoon(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: MuSpace.s6),
      AdminSectionHead(title: l10n.activiteRecente, end: AdminMuted(l10n.jours2)),
      const SizedBox(height: MuSpace.s2),
      _Timeline(items: d.activity),
      const SizedBox(height: MuSpace.s6),
      AdminSectionHead(title: l10n.paiements, end: AdminMuted(d.paymentCard)),
      const SizedBox(height: MuSpace.s2),
      MuTransactionList(children: [for (final t in d.payments) MuTransactionRow(tx: t)]),
      const SizedBox(height: MuSpace.s6),
      AdminSectionHead(title: l10n.sanctions),
      const SizedBox(height: MuSpace.s2),
      MuCardSurface(
        child: Row(
          children: [
            AdminIconTile(
              suspended ? PhosphorIcons.prohibit() : PhosphorIcons.shieldCheck(),
              tone: suspended ? AdminTileTone.error : AdminTileTone.success,
            ),
            const SizedBox(width: MuSpace.s3),
            Expanded(
              child: suspended
                  ? AdminTexts(
                      title: u.status == AdminUserStatus.banned
                          ? l10n.banniDefinitivement
                          : l10n.suspenduJusquAu(formatDay(u.suspendedUntil!), formatTime(u.suspendedUntil!)),
                      lines: [d.plan.playerReason],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.aucuneSanction, style: MuType.label.copyWith(color: c.text)),
                        Text(
                          l10n.niAvertissementNiSuspensionDepuis,
                          style: caption,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ];
  }
}

/// ud-time: dots on a 2 px rail.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.items});

  final List<AdminActivity> items;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        boxShadow: MuElevation.of(context).level1,
      ),
      child: Column(
        children: [
          for (final (i, a) in items.indexed)
            IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: MuSize.controlS,
                      child: Column(
                        children: [
                          SizedBox(
                            height: MuSpace.s2,
                            child: i == 0
                                ? null
                                : Center(child: Container(width: 2, color: c.border)),
                          ),
                          Container(
                            width: MuSize.controlS,
                            height: MuSize.controlS,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: a.kind == AdminActivityKind.noShow
                                  ? c.errorSoft
                                  : c.surfaceMuted,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              switch (a.kind) {
                                AdminActivityKind.booking => PhosphorIcons.calendarCheck(),
                                AdminActivityKind.review => PhosphorIcons.star(),
                                AdminActivityKind.joined => PhosphorIcons.userPlus(),
                                AdminActivityKind.noShow => PhosphorIcons.calendarX(),
                              },
                              size: MuSize.iconXs,
                              color: a.kind == AdminActivityKind.noShow ? c.errorText : c.text,
                            ),
                          ),
                          Expanded(
                            child: i == items.length - 1
                                ? const SizedBox()
                                : Center(child: Container(width: 2, color: c.border)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
                        child: AdminTexts(title: a.title, lines: [a.meta]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
