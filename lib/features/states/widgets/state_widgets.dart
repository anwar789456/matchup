import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../data/account_status.dart';
import '../../../l10n/l10n.dart';

/// STA-01 · Hors ligne: the strip on top of a screen showing cached data, with « Réessayer ».
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.cachedAt, this.onRetry});

  /// When the cached data was fetched (« ven. 16 oct. à 17h42 »).
  final DateTime cachedAt;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => MuBanner(
    variant: MuBannerVariant.strip,
    tone: MuBannerTone.warning,
    icon: PhosphorIcons.wifiSlash(),
    title: l10n.tuEsHorsLigne,
    detail:
        l10n.tuVoisTesDonneesDu(formatDay(cachedAt), formatTime(cachedAt)),
    action: onRetry == null ? null : MuAction(l10n.reessayer, onRetry!),
  );
}

/// STA-01: the QR code stays available without network.
class OfflineQrNote extends StatelessWidget {
  const OfflineQrNote({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Row(
      children: [
        Icon(PhosphorIcons.qrCode(), size: MuSize.iconXs, color: c.successText),
        const SizedBox(width: MuSpace.s2),
        Expanded(
          child: Text(
            l10n.tonQrCodeDAcces,
            style: MuType.caption.copyWith(color: c.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// A check line of what did not change (STA-02) or what stays (STA-07).
class _KeptLine extends StatelessWidget {
  const _KeptLine(this.span);

  final InlineSpan span;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
            size: MuSize.iconS,
            color: c.successText,
          ),
          const SizedBox(width: MuSpace.s2),
          Expanded(child: Text.rich(span, style: MuType.body.copyWith(color: c.text))),
        ],
      ),
    );
  }
}

/// STA-02 · Erreur serveur: what failed, what did not change, « Réessayer » and the reference.
class ServerErrorState extends StatelessWidget {
  const ServerErrorState({
    super.key,
    required this.title,
    required this.kept,
    required this.onRetry,
    this.status = 503,
    this.reference = 'MU-7F3A-2C',
    this.icon,
  });

  /// « Tes matchs ne se chargent pas ».
  final String title;

  /// The reassurance lines (« Tes réservations … sont toujours là »).
  final List<InlineSpan> kept;
  final VoidCallback onRetry;
  final int status;
  final String reference;
  final IconData? icon;

  // STA-02: the illustration circle is 96, its status badge 32.
  static const double _circle = 96;
  static const double _badge = 32;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return ListView(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s16, MuSpace.s4, MuSpace.s8),
      children: [
        Center(
          child: SizedBox.square(
            dimension: _circle,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(color: c.errorSoft, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(
                    icon ?? PhosphorIcons.calendarX(),
                    size: MuSize.iconL,
                    color: c.errorText,
                  ),
                ),
                PositionedDirectional(
                  end: -MuSpace.s1,
                  bottom: MuSpace.s1,
                  child: Container(
                    width: _badge,
                    height: _badge,
                    decoration: BoxDecoration(
                      color: c.surface,
                      shape: BoxShape.circle,
                      boxShadow: MuElevation.of(context).level1,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
                      size: MuSize.iconS,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: MuSpace.s5),
        Text(
          title,
          textAlign: TextAlign.center,
          style: MuType.h3.copyWith(color: c.text),
        ),
        const SizedBox(height: MuSpace.s2),
        Text(
          l10n.nosServeursOntUnSouci,
          textAlign: TextAlign.center,
          style: MuType.body.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: MuSpace.s5),
        MuCardSurface(
          child: Column(children: [for (final k in kept) _KeptLine(k)]),
        ),
        const SizedBox(height: MuSpace.s5),
        MuButton.primary(
          label: l10n.reessayer,
          leading: PhosphorIcons.arrowClockwise(),
          size: MuButtonSize.l,
          fullWidth: true,
          onPressed: onRetry,
        ),
        const SizedBox(height: MuSpace.s3),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: l10n.erreurRef(status)),
              TextSpan(text: reference, style: MuType.numXs.copyWith(color: c.text)),
              TextSpan(text: l10n.notreEquipeEstPrevenue),
            ],
          ),
          textAlign: TextAlign.center,
          style: MuType.caption.copyWith(color: c.textSecondary),
        ),
      ],
    );
  }
}

/// STA-03 · Page introuvable: the empty state, the dead link, « Trouver une autre partie » and
/// alternatives under it.
class NotFoundState extends StatelessWidget {
  const NotFoundState({
    super.key,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    this.link,
    this.alternativesTitle,
    this.alternatives = const [],
  });

  final String title;
  final String description;

  /// « matchup.tn/p/7Q2K9 · lien reçu sur WhatsApp ».
  final String? link;
  final String actionLabel;
  final VoidCallback onAction;
  final String? alternativesTitle;
  final List<Widget> alternatives;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return ListView(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s6, MuSpace.s4, MuSpace.s8),
      children: [
        MuEmptyState(title: title, description: description),
        if (link != null) ...[
          const SizedBox(height: MuSpace.s3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIcons.linkBreak(), size: MuSize.iconXs, color: c.textSecondary),
              const SizedBox(width: MuSpace.s1),
              Flexible(
                child: Text(ltr(link!), style: MuType.caption.copyWith(color: c.textSecondary)),
              ),
            ],
          ),
        ],
        const SizedBox(height: MuSpace.s5),
        MuButton.primary(
          label: actionLabel,
          leading: PhosphorIcons.magnifyingGlass(),
          size: MuButtonSize.l,
          fullWidth: true,
          onPressed: onAction,
        ),
        if (alternatives.isNotEmpty) ...[
          const SizedBox(height: MuSpace.s8),
          if (alternativesTitle != null)
            Text(alternativesTitle!, style: MuType.h3.copyWith(color: c.text)),
          const SizedBox(height: MuSpace.s3),
          for (final (i, w) in alternatives.indexed) ...[
            if (i > 0) const SizedBox(height: MuSpace.s3),
            w,
          ],
        ],
      ],
    );
  }
}

/// STA-04 · Session expirée: a bottom dialog that can't be dismissed; « Me reconnecter » signs
/// in again and comes back to the same screen.
Future<void> showSessionExpired(
  BuildContext context, {
  required String name,
  required String email,
  required num balance,
  required VoidCallback onReconnect,
}) {
  final c = context.mu;
  final nav = Navigator.of(context, rootNavigator: true);
  return MuDialog.show<void>(
    context,
    tone: MuDialogTone.info,
    icon: PhosphorIcons.lockKey(),
    dismissible: false,
    title: l10n.taSessionAExpire,
    description:
        l10n.pourProtegerTonSoldeEt,
    consequenceIcon: PhosphorIcons.shieldCheck(),
    consequence:
        l10n.rienNEstPerduTon(formatDT(balance)),
    content: Row(
      children: [
        MuAvatar(name: name, size: MuAvatarSize.s),
        const SizedBox(width: MuSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: MuType.label.copyWith(color: c.text)),
              Text(email, style: MuType.caption.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
      ],
    ),
    actions: [
      MuButton.primary(
        label: l10n.meReconnecter,
        leading: PhosphorIcons.signIn(),
        fullWidth: true,
        onPressed: () {
          nav.pop();
          onReconnect();
        },
      ),
    ],
  );
}

/// STA-05 · Permission refusée: why it is blocked, the steps to turn it on, « Ouvrir les
/// Réglages » and a manual fallback.
class PermissionDeniedState extends StatelessWidget {
  const PermissionDeniedState({
    super.key,
    required this.title,
    required this.description,
    required this.steps,
    required this.onOpenSettings,
    this.fallbackLabel,
    this.onFallback,
    this.icon,
  });

  final String title;
  final String description;

  /// « Ouvre les Réglages du téléphone », « Touche MatchUp », « Active Caméra, puis reviens ici ».
  final List<String> steps;
  final VoidCallback onOpenSettings;
  final String? fallbackLabel;
  final VoidCallback? onFallback;
  final IconData? icon;

  // STA-05: the blocked-camera medal is 88.
  static const double _medal = 88;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return ListView(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s8, MuSpace.s4, MuSpace.s8),
      children: [
        Center(
          child: Container(
            width: _medal,
            height: _medal,
            decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(
              icon ?? PhosphorIcons.cameraSlash(),
              size: MuSize.iconL,
              color: c.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: MuSpace.s4),
        Text(title, textAlign: TextAlign.center, style: MuType.h2.copyWith(color: c.text)),
        const SizedBox(height: MuSpace.s2),
        Text(
          description,
          textAlign: TextAlign.center,
          style: MuType.body.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: MuSpace.s5),
        MuCardSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.pourLActiverSecondes, style: MuType.labelL.copyWith(color: c.text)),
              const SizedBox(height: MuSpace.s2),
              for (final (i, s) in steps.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
                  child: Row(
                    children: [
                      Container(
                        width: MuSize.iconM,
                        height: MuSize.iconM,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: c.surfaceInverse, shape: BoxShape.circle),
                        child: Text(
                          '${i + 1}',
                          style: MuType.labelS.copyWith(color: c.textInverse),
                        ),
                      ),
                      const SizedBox(width: MuSpace.s3),
                      Expanded(child: Text(s, style: MuType.body.copyWith(color: c.text))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: MuSpace.s5),
        MuButton.primary(
          label: l10n.ouvrirLesReglages,
          trailing: PhosphorIcons.arrowSquareOut(),
          size: MuButtonSize.l,
          fullWidth: true,
          onPressed: onOpenSettings,
        ),
        if (fallbackLabel != null) ...[
          const SizedBox(height: MuSpace.s2),
          MuButton.tertiary(
            label: fallbackLabel!,
            leading: PhosphorIcons.keyboard(),
            size: MuButtonSize.l,
            fullWidth: true,
            onPressed: onFallback,
          ),
        ],
      ],
    );
  }
}

/// STA-06 · Email non vérifié: the banner of Home, « Renvoyer l’email », hidden until tomorrow.
class EmailNotVerifiedBanner extends StatelessWidget {
  const EmailNotVerifiedBanner({
    super.key,
    required this.email,
    required this.flags,
    required this.onResend,
    required this.onHide,
  });

  final String email;
  final AccountFlags flags;
  final VoidCallback onResend;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) => MuBanner(
    tone: MuBannerTone.warning,
    icon: PhosphorIcons.envelopeSimple(),
    title: l10n.verifieTonEmail,
    detail: flags.emailSentTo != null
        ? l10n.lienEnvoyeAIlTe('${flags.emailSentTo}')
        : l10n.confirmePourPouvoirRecupererTon(email),
    action: flags.emailSentTo != null ? null : MuAction(l10n.renvoyerLEmail, onResend),
    onDismiss: onHide,
    dismissLabel: l10n.masquerJusquADemain,
  );
}

/// STA-07 · Compte suspendu: Home of a suspended account — the reason, when play resumes, what
/// happens meanwhile and « Contester la décision ».
class SuspendedAccountView extends StatelessWidget {
  const SuspendedAccountView({
    super.key,
    required this.suspension,
    required this.now,
    required this.onContest,
  });

  final Suspension suspension;
  final DateTime now;
  final VoidCallback onContest;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final days = suspension.until.difference(now).inHours / 24;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    Widget item(IconData icon, Color ground, Color ink, String title, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: MuSize.controlS,
            height: MuSize.controlS,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: ground, shape: BoxShape.circle),
            child: Icon(icon, size: MuSize.iconXs, color: ink),
          ),
          const SizedBox(width: MuSpace.s3),
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
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MuBanner(
          tone: MuBannerTone.error,
          icon: PhosphorIcons.prohibit(),
          title: l10n.tonCompteEstSuspenduJours(days.ceil()),
          detail: l10n.raison2(suspension.reason),
        ),
        const SizedBox(height: MuSpace.s4),
        MuCardSurface(
          child: Row(
            children: [
              Icon(PhosphorIcons.hourglass(), size: MuSize.iconM, color: c.text),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.tuPourrasRejouerLe, style: caption),
                    Text(
                      '${formatDay(suspension.until)} · ${formatTime(suspension.until)}',
                      style: MuType.labelL.copyWith(color: c.text),
                    ),
                  ],
                ),
              ),
              MuStatusBadge(
                status: MuStatus.neutral,
                label: l10n.dansJours(days.ceil()),
                size: MuBadgeSize.s,
              ),
            ],
          ),
        ),
        const SizedBox(height: MuSpace.s4),
        MuCardSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.pendantLaSuspension, style: MuType.h3.copyWith(color: c.text)),
              const SizedBox(height: MuSpace.s2),
              item(
                PhosphorIcons.prohibit(),
                c.errorSoft,
                c.errorText,
                l10n.pasDePartieNiDe,
                l10n.tuPeuxToujoursParcourirExplorer,
              ),
              if (suspension.refunded > 0)
                item(
                  PhosphorIcons.wallet(),
                  c.successSoft,
                  c.successText,
                  l10n.remboursesSurTonSolde(formatDT(suspension.refunded)),
                  l10n.tesPartiesAVenirOnt(suspension.freedGames),
                ),
              item(
                PhosphorIcons.shieldCheck(),
                c.infoSoft,
                c.infoText,
                l10n.taFiabiliteRemonteraEnsuite,
                l10n.previensAuMoinsHAvant,
              ),
            ],
          ),
        ),
        const SizedBox(height: MuSpace.s4),
        MuButton.secondary(
          label: l10n.contesterLaDecision,
          leading: PhosphorIcons.chatCircleDots(),
          size: MuButtonSize.l,
          fullWidth: true,
          onPressed: onContest,
        ),
        const SizedBox(height: MuSpace.s2),
        Text(
          l10n.unMembreDeLEquipe,
          textAlign: TextAlign.center,
          style: caption,
        ),
      ],
    );
  }
}

/// STA-08 · Profil incomplet: the completion ring, what is missing and « Compléter mon profil ».
class ProfileCompletionCard extends StatelessWidget {
  const ProfileCompletionCard({
    super.key,
    required this.percent,
    required this.items,
    required this.onComplete,
    required this.onLater,
  });

  final int percent;

  /// (label, done).
  final List<(String, bool)> items;
  final VoidCallback onComplete;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return MuCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MuProgressRing(value: percent.toDouble(), label: l10n.profilComplete),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tonProfilEstCompletA(ltr('$percent %')),
                      style: MuType.labelL.copyWith(color: c.text),
                    ),
                    Text(
                      l10n.avecUnePhotoEtUne,
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Wrap(
            spacing: MuSpace.s2,
            runSpacing: MuSpace.s2,
            children: [
              for (final (label, done) in items)
                MuChip(
                  label: label,
                  kind: MuChipKind.input,
                  size: MuChipSize.s,
                  icon: done
                      ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                      : PhosphorIcons.circle(),
                ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Row(
            children: [
              Expanded(
                child: MuButton.primary(
                  label: l10n.completerMonProfil,
                  fullWidth: true,
                  onPressed: onComplete,
                ),
              ),
              const SizedBox(width: MuSpace.s2),
              MuButton.tertiary(label: l10n.plusTard, onPressed: onLater),
            ],
          ),
        ],
      ),
    );
  }
}

/// STA-09 · fin de liste: « C’est tout pour l’instant » and a way to see more.
class EndOfList extends StatelessWidget {
  const EndOfList({
    super.key,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s6, horizontal: MuSpace.s4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: c.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
                child: Icon(PhosphorIcons.flag(), size: MuSize.iconXs, color: c.textSecondary),
              ),
              Expanded(child: Divider(color: c.border)),
            ],
          ),
          const SizedBox(height: MuSpace.s2),
          Text(l10n.cEstToutPourL, style: MuType.labelL.copyWith(color: c.text)),
          const SizedBox(height: MuSpace.s1),
          Text(
            description,
            textAlign: TextAlign.center,
            style: MuType.body.copyWith(color: c.textSecondary),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: MuSpace.s3),
            MuButton.secondary(
              label: actionLabel!,
              leading: PhosphorIcons.calendarBlank(),
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

/// STA-09 · rafraîchir: pull to refresh with the MatchUp spinner and « Mise à jour … ».
class MuRefresh extends StatelessWidget {
  const MuRefresh({super.key, required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: c.text,
      backgroundColor: c.surface,
      semanticsLabel: l10n.miseAJour,
      child: child,
    );
  }
}
