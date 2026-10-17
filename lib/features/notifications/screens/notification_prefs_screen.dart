import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../data/notification_models.dart';
import '../data/notification_prefs.dart';
import '../../../l10n/l10n.dart';

/// NOT-10 · Préférences de notifications: pause (1 h, 8 h, 24 h), category × channel switches
/// (payments and security locked in the app), quiet hours and the email recap. Saved on the
/// device after every change.
class NotificationPrefsScreen extends ConsumerWidget {
  const NotificationPrefsScreen({super.key});

  static final _descriptions = {
    NotificationCategory.matches: l10n.invitationsPlacesLibereesRappels,
    NotificationCategory.bookings: l10n.confirmationsAnnulationsCheckIn,
    NotificationCategory.payments: l10n.partsAPayerRecusRemboursements,
    NotificationCategory.tournaments: l10n.inscriptionsTableauxResultats,
    NotificationCategory.training: l10n.plansIaRetoursDuCoach,
    NotificationCategory.community: l10n.reponsesMentionsModeration,
    NotificationCategory.security: l10n.connexionsMotDePasseAppareils,
  };

  // NOT-10: the switch columns are 52 wide.
  static const double _col = 52;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final prefs = ref.watch(notificationPrefsProvider);
    final ctrl = ref.read(notificationPrefsProvider.notifier);
    final now = ref.read(clockProvider)();
    final paused = prefs.pauseUntil != null && prefs.pauseUntil!.isAfter(now);
    final caption = MuType.caption.copyWith(color: c.textSecondary);

    String until(DateTime d) => d.difference(now) >= const Duration(hours: 24)
        ? l10n.jusquA3(formatDay(d), formatHour(d.hour * 60 + d.minute))
        : l10n.jusquA(formatHour(d.hour * 60 + d.minute));

    Widget overline(String s) => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s4, MuSpace.s6, MuSpace.s4, MuSpace.s2),
      child: Semantics(
        header: true,
        child: Text(s.toUpperCase(), style: MuType.overline.copyWith(color: c.textSecondary)),
      ),
    );

    Widget square(IconData icon) => Container(
      width: MuSize.controlS,
      height: MuSize.controlS,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
      child: Icon(icon, size: MuSize.iconS, color: c.text),
    );

    Widget card(Widget child, {EdgeInsets padding = const EdgeInsets.all(MuSpace.s4)}) =>
        MuCardSurface(padding: padding, child: child);

    Widget lockLine(String text) => Row(
      children: [
        Icon(PhosphorIcons.lockSimple(), size: MuSize.iconXs, color: c.text),
        const SizedBox(width: MuSpace.s1),
        Flexible(
          child: Text(text, style: MuType.labelS.copyWith(color: c.text)),
        ),
      ],
    );

    Future<void> pickTime(int current, ValueChanged<int> set) async {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );
      if (t != null) set(t.hour * 60 + t.minute);
    }

    Widget timeRow(IconData icon, String label, int minutes, ValueChanged<int> set) => InkWell(
      onTap: () => pickTime(minutes, set),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: MuSize.controlXl),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
          child: Row(
            children: [
              square(icon),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Text(label, style: MuType.label.copyWith(color: c.text)),
              ),
              Text(formatHour(minutes), style: MuType.body.copyWith(color: c.textSecondary)),
              const SizedBox(width: MuSpace.s2),
              Icon(PhosphorIcons.caretRight(), size: MuSize.iconS, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: l10n.notifications,
            onBack: () => goBack(context, Routes.settings),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s8),
              children: [
                overline(l10n.pause),
                card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          square(PhosphorIcons.pause()),
                          const SizedBox(width: MuSpace.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.toutMettreEnPause,
                                  style: MuType.label.copyWith(color: c.text),
                                ),
                                Text(
                                  l10n.plusDePushNiD,
                                  style: MuType.body.copyWith(color: c.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: MuSpace.s4),
                      if (paused) ...[
                        Row(
                          children: [
                            Icon(
                              PhosphorIcons.pauseCircle(),
                              size: MuSize.iconS,
                              color: c.warningText,
                            ),
                            const SizedBox(width: MuSpace.s2),
                            Expanded(
                              child: Text(
                                l10n.enPause(until(prefs.pauseUntil!)),
                                style: MuType.label.copyWith(color: c.text),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: MuSpace.s3),
                        MuButton.secondary(
                          label: l10n.reprendreMaintenant,
                          leading: PhosphorIcons.play(),
                          fullWidth: true,
                          onPressed: () => ctrl.pause(null),
                        ),
                      ] else
                        Row(
                          children: [
                            for (final (i, h) in [1, 8, 24].indexed) ...[
                              if (i > 0) const SizedBox(width: MuSpace.s2),
                              Expanded(
                                child: MuButton.secondary(
                                  label: '$h h',
                                  fullWidth: true,
                                  onPressed: () => ctrl.pause(now.add(Duration(hours: h))),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
                overline(l10n.parCategorie),
                card(
                  padding: EdgeInsets.zero,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        color: c.surfaceMuted,
                        padding: const EdgeInsets.symmetric(
                          horizontal: MuSpace.s4,
                          vertical: MuSpace.s3,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.tuChoisisOuChaqueCategorie,
                                style: MuType.labelS.copyWith(color: c.textSecondary),
                              ),
                            ),
                            for (final (icon, label) in [
                              (PhosphorIcons.bell(), l10n.inApp),
                              (PhosphorIcons.deviceMobile(), l10n.push),
                              (PhosphorIcons.envelopeSimple(), l10n.email),
                            ])
                              SizedBox(
                                width: _col,
                                child: Column(
                                  children: [
                                    Icon(icon, size: MuSize.iconXs, color: c.textSecondary),
                                    Text(label, style: caption),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      for (final (i, cat) in NotificationCategory.values.indexed) ...[
                        if (i > 0)
                          Divider(height: 1, thickness: 1, color: c.border, indent: MuSpace.s4),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            MuSpace.s4,
                            MuSpace.s3,
                            MuSpace.s4,
                            MuSpace.s3,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              square(cat.icon),
                              const SizedBox(width: MuSpace.s3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cat.label, style: MuType.label.copyWith(color: c.text)),
                                    Text(_descriptions[cat]!, style: caption),
                                    if (cat.locked) lockLine(l10n.toujoursDansLApp),
                                  ],
                                ),
                              ),
                              for (final ch in NotificationChannel.values)
                                SizedBox(
                                  width: _col,
                                  child: Center(
                                    child: MuSwitch(
                                      size: MuSwitchSize.s,
                                      value: prefs.isOn(cat, ch),
                                      semanticLabel:
                                          '${cat.label} · ${switch (ch) {
                                            NotificationChannel.app => l10n.inApp,
                                            NotificationChannel.push => l10n.push,
                                            NotificationChannel.email => l10n.email,
                                          }}${cat.locked && ch == NotificationChannel.app ? l10n.toujoursActive : ''}',
                                      onChanged: cat.locked && ch == NotificationChannel.app
                                          ? null
                                          : (v) => ctrl.toggle(cat, ch, v),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(PhosphorIcons.lockSimple(), size: MuSize.iconXs, color: c.textSecondary),
                      const SizedBox(width: MuSpace.s2),
                      Expanded(
                        child: Text(
                          l10n.toujoursActiveObligatoirePourTon,
                          style: caption,
                        ),
                      ),
                    ],
                  ),
                ),
                overline(l10n.heuresCalmes),
                card(
                  padding: EdgeInsets.zero,
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(MuSpace.s4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            square(PhosphorIcons.moon()),
                            const SizedBox(width: MuSpace.s3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.heuresCalmes,
                                    style: MuType.label.copyWith(color: c.text),
                                  ),
                                  Text(
                                    l10n.aucunPushLaNuitTout,
                                    style: MuType.body.copyWith(color: c.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            MuSwitch(
                              value: prefs.quietHours,
                              semanticLabel: l10n.heuresCalmes,
                              onChanged: ctrl.setQuiet,
                            ),
                          ],
                        ),
                      ),
                      if (prefs.quietHours) ...[
                        Divider(height: 1, thickness: 1, color: c.border, indent: MuSpace.s4),
                        timeRow(
                          PhosphorIcons.moonStars(),
                          l10n.debut,
                          prefs.quietStart,
                          ctrl.setQuietStart,
                        ),
                        Divider(height: 1, thickness: 1, color: c.border, indent: MuSpace.s4),
                        timeRow(PhosphorIcons.sun(), l10n.fin, prefs.quietEnd, ctrl.setQuietEnd),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                  child: Text(
                    l10n.tousLesJoursHeureDe,
                    style: caption,
                  ),
                ),
                overline(l10n.recapParEmail),
                card(
                  MuRadioGroup<EmailDigest>(
                    label: l10n.recapParEmail,
                    hideLabel: true,
                    options: [
                      MuRadioOption(
                        value: EmailDigest.weekly,
                        label: l10n.hebdoDimanche10h00,
                        description: l10n.tesMatchsDeLaSemaine,
                      ),
                      MuRadioOption(
                        value: EmailDigest.never,
                        label: l10n.jamais,
                        description: l10n.lesRecusEtLesAlertes,
                      ),
                    ],
                    value: prefs.digest,
                    onChanged: ctrl.setDigest,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
