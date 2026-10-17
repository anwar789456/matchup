import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../controllers/admin_controller.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_widgets.dart';
import '../../../l10n/l10n.dart';

enum _Kind { all, coaches, venues, done }

/// ADM-05 · Vérifications: coach and venue requests with their documents and the AI's reading
/// (which never validates on its own), then those handled this week.
class AdminVerificationsScreen extends ConsumerStatefulWidget {
  const AdminVerificationsScreen({super.key});

  @override
  ConsumerState<AdminVerificationsScreen> createState() => _AdminVerificationsScreenState();
}

class _AdminVerificationsScreenState extends ConsumerState<AdminVerificationsScreen> {
  _Kind _kind = _Kind.all;
  final Set<String> _busy = {};

  Future<void> _approve(AdminVerification v) async {
    setState(() => _busy.add(v.id));
    final now = ref.read(clockProvider)();
    final line = v.kind == AdminVerificationKind.coach
        ? '${v.line.split(' · ').first} · ${formatDay(now)}'
        : l10n.piecesVerifiees(formatDay(now));
    await ref.read(adminActionsProvider).approve(v.id, line);
    if (!mounted) return;
    setState(() => _busy.remove(v.id));
    MuToast.show(context, tone: MuToastTone.success, title: l10n.verifie3(v.name));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final all = ref.watch(adminVerificationsProvider).value;
    final open = [
      for (final v in all ?? const <AdminVerification>[])
        if (v.status != AdminVerificationStatus.approved) v,
    ];
    final done = [
      for (final v in all ?? const <AdminVerification>[])
        if (v.status == AdminVerificationStatus.approved) v,
    ];
    final coaches = open.where((v) => v.kind == AdminVerificationKind.coach).length;
    final venues = open.length - coaches;
    final oldest = open.isEmpty
        ? null
        : open.map((v) => v.sent).reduce((a, b) => a.isBefore(b) ? a : b);
    final shown = switch (_kind) {
      _Kind.all => open,
      _Kind.coaches => [
        for (final v in open)
          if (v.kind == AdminVerificationKind.coach) v,
      ],
      _Kind.venues => [
        for (final v in open)
          if (v.kind == AdminVerificationKind.venue) v,
      ],
      _Kind.done => const <AdminVerification>[],
    };

    return Scaffold(
      backgroundColor: c.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          AdminHeader(
            title: l10n.verifications2,
            subtitle: oldest == null
                ? l10n.aucuneDemandeEnAttente
                : l10n.demandesLaPlusAncienne(open.length, formatDay(oldest)),
          ),
          Semantics(
            container: true,
            label: l10n.typeDeDemande,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s1, MuSpace.s4, 0),
              child: Row(
                children: [
                  for (final (k, label, count) in [
                    (_Kind.all, l10n.tout, open.length),
                    (_Kind.coaches, l10n.coachs, coaches),
                    (_Kind.venues, l10n.terrains, venues),
                    (_Kind.done, l10n.traitees, 0),
                  ]) ...[
                    MuChip(
                      kind: MuChipKind.choice,
                      label: label,
                      count: count == 0 ? null : count,
                      selected: _kind == k,
                      onSelected: (_) => setState(() => _kind = k),
                    ),
                    const SizedBox(width: MuSpace.s2),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s5, MuSpace.s4, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (all == null)
                  const MuSkeleton(height: 320)
                else if (_kind != _Kind.done && shown.isEmpty)
                  MuEmptyState(compact: true, title: l10n.rienAVerifierPourL)
                else
                  for (final v in shown) ...[
                    _RequestCard(v: v, busy: _busy.contains(v.id), onApprove: () => _approve(v)),
                    const SizedBox(height: MuSpace.s4),
                  ],
                const SizedBox(height: MuSpace.s2),
                if (done.isNotEmpty) ...[
                  AdminSectionHead(title: l10n.traiteesCetteSemaine),
                  const SizedBox(height: MuSpace.s2),
                  AdminList(
                    inset: AdminList.tileInset,
                    children: [
                      for (final v in done)
                        AdminRow(
                          leading: _thumb(v),
                          end: const MuStatusBadge(status: MuStatus.verified, size: MuBadgeSize.s),
                          child: AdminTexts(title: v.name, lines: [v.doneLine ?? '']),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: MuSpace.s16 + MuSpace.s10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _thumb(AdminVerification v) => v.kind == AdminVerificationKind.coach
    ? MuAvatar(name: v.name)
    : ClipRRect(
        borderRadius: MuRadius.smAll,
        child: SizedBox.square(
          dimension: MuSize.controlM,
          child: MuCourtArt(sport: v.sport, variant: MuCourtArtVariant.pattern),
        ),
      );

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.v, required this.busy, required this.onApprove});

  final AdminVerification v;
  final bool busy;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final illegible = v.status == AdminVerificationStatus.illegible;
    return MuCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _thumb(v),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(v.name, style: MuType.labelL.copyWith(color: c.text)),
                    ),
                    const SizedBox(height: 2),
                    AdminMuted(v.line),
                    const SizedBox(height: 2),
                    AdminMuted(l10n.envoye2(formatDay(v.sent))),
                  ],
                ),
              ),
              const SizedBox(width: MuSpace.s2),
              MuStatusBadge(
                status: illegible ? MuStatus.failed : MuStatus.pending,
                label: illegible ? l10n.illisible : l10n.aVerifier,
                size: MuBadgeSize.s,
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          if (v.docs.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                borderRadius: MuRadius.smAll,
                border: Border.all(color: c.border),
              ),
              child: Column(
                children: [
                  for (final (i, d) in v.docs.indexed) ...[
                    if (i > 0) Divider(height: 1, thickness: 1, color: c.border),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: MuSize.controlXl - MuSpace.s1),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          MuSpace.s3,
                          MuSpace.s2,
                          MuSpace.s2,
                          MuSpace.s2,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: MuSize.controlS,
                              height: MuSize.controlS,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: d.bad ? c.errorSoft : c.surfaceMuted,
                                borderRadius: MuRadius.xsAll,
                              ),
                              child: Icon(
                                switch (d.kind) {
                                  AdminDocKind.pdf => PhosphorIcons.filePdf(),
                                  AdminDocKind.id => PhosphorIcons.identificationCard(),
                                  AdminDocKind.image => PhosphorIcons.image(),
                                },
                                size: MuSize.iconS,
                                color: d.bad ? c.errorText : c.text,
                              ),
                            ),
                            const SizedBox(width: MuSpace.s3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: MuType.label.copyWith(color: c.text),
                                  ),
                                  Text(
                                    d.meta,
                                    style: MuType.caption.copyWith(
                                      color: d.bad ? c.errorText : c.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            MuButton.tertiary(
                              label: l10n.ouvrir,
                              size: MuButtonSize.s,
                              onPressed: () => showComingSoon(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (v.checks.isNotEmpty) ...[
            Text(v.checksTitle ?? '', style: MuType.labelS.copyWith(color: c.textSecondary)),
            const SizedBox(height: MuSpace.s2),
            Wrap(
              spacing: MuSpace.s3,
              runSpacing: MuSpace.s2 - 2,
              children: [
                for (final check in v.checks)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                        size: MuSize.iconXs,
                        color: c.successText,
                      ),
                      const SizedBox(width: MuSpace.s1),
                      Text(check, style: MuType.body.copyWith(color: c.text)),
                    ],
                  ),
              ],
            ),
          ],
          const SizedBox(height: MuSpace.s3),
          Container(
            padding: const EdgeInsets.all(MuSpace.s3),
            decoration: BoxDecoration(color: c.aiSoft, borderRadius: MuRadius.smAll),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MuAiLabel(size: MuAiLabelSize.s, onAiSurface: true),
                    const SizedBox(width: MuSpace.s2),
                    Text(v.aiTitle, style: MuType.labelS.copyWith(color: c.aiText)),
                  ],
                ),
                const SizedBox(height: MuSpace.s2 - 2),
                Text(v.aiBody, style: MuType.body.copyWith(color: c.aiText)),
                if (v.aiNote != null) ...[
                  const SizedBox(height: MuSpace.s2 - 2),
                  Text(v.aiNote!, style: MuType.caption.copyWith(color: c.aiText)),
                ],
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          if (illegible) ...[
            MuButton.primary(
              label: l10n.demanderUnePhotoNette,
              leading: PhosphorIcons.envelopeSimple(),
              size: MuButtonSize.l,
              fullWidth: true,
              onPressed: () => showComingSoon(context),
            ),
            const SizedBox(height: MuSpace.s3),
            MuButton.secondary(
              label: l10n.refuserLaDemande,
              size: MuButtonSize.l,
              fullWidth: true,
              onPressed: () => showComingSoon(context),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: MuButton.secondary(
                    label: l10n.refuser,
                    size: MuButtonSize.l,
                    fullWidth: true,
                    onPressed: busy ? null : () => showComingSoon(context),
                  ),
                ),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: MuButton.primary(
                    label: l10n.approuver,
                    leading: PhosphorIcons.sealCheck(),
                    size: MuButtonSize.l,
                    fullWidth: true,
                    loading: busy,
                    onPressed: busy ? null : onApprove,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
