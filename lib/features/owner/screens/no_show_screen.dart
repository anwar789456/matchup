import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/owner_controllers.dart';
import '../data/owner_repository.dart';
import '../widgets/owner_labels.dart';
import '../../../l10n/l10n.dart';

/// A player's record of honoured games, for the « Sa fiabilité baisse » line (OWN-24).
(int, int) _record(String player) => switch (player) {
  'Rami S.' => (19, 20),
  'Sarra B.' => (27, 28),
  _ => (19, 20),
};

/// OWN-24 · Signaler un no-show: who didn't come (the players still expected), what happens to
/// them (reliability, share kept, they can contest), an optional note, then confirm.
class NoShowScreen extends ConsumerStatefulWidget {
  const NoShowScreen({super.key, required this.bookingRef});

  final String bookingRef;

  @override
  ConsumerState<NoShowScreen> createState() => _NoShowScreenState();
}

class _NoShowScreenState extends ConsumerState<NoShowScreen> {
  final _picked = <String>{};
  final _note = TextEditingController();
  bool _saving = false;
  bool _initialised = false;

  // OWN-24: the note is capped at 200 characters.
  static const int _noteMax = 200;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _confirm(OwnerBooking b) async {
    if (_picked.isEmpty || _saving) return;
    setState(() => _saving = true);
    final players = _picked.toList();
    await ref.read(ownerActionsProvider).markNoShow(b.ref, players);
    if (!mounted) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    goBack(context, Routes.ownerCheckIn);
    MuToast.show(
      overlay.context,
      overlay: overlay,
      tone: MuToastTone.success,
      title: players.length == 1 ? l10n.noShowSignale : l10n.noShowsSignales(players.length),
      description:
          '${players.join(', ')} ${players.length == 1 ? l10n.estPrevenu : l10n.sontPrevenus}. Tu peux retirer ce signalement pendant 24 h.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final b = ref.watch(ownerBookingProvider(widget.bookingRef)).value;
    if (b != null && !_initialised) {
      _initialised = true;
      // One player missing: picked already (OWN-24 « Rami S. »).
      if (b.expected.length == 1) _picked.add(b.expected.single);
    }
    final subtitle = b == null
        ? null
        : '${courtName(b.court)} · ${formatDay(b.start)} · ${hourLong(b.start.hour)}';
    final first = _picked.isEmpty ? null : (_picked.length == 1 ? _picked.single : null);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuTopAppBar.compact(
              title: l10n.signalerUnNoShow,
              subtitle: subtitle,
              backLabel: l10n.retourAuCheckIn,
              onBack: () => goBack(context, Routes.ownerCheckIn),
            ),
            Expanded(
              child: b == null
                  ? const Center(child: MuSpinner())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        MuSpace.s4,
                        MuSpace.s2,
                        MuSpace.s4,
                        MuSpace.s8,
                      ),
                      children: _content(context, b),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: b == null
          ? null
          : StickyActionBar(
              children: [
                MuButton(
                  label: _picked.isEmpty
                      ? l10n.choisisLeJoueurAbsent
                      : first != null
                      ? l10n.marquerAbsent(first)
                      : l10n.marquerJoueursAbsents(_picked.length),
                  variant: MuButtonVariant.destructive,
                  leading: PhosphorIcons.userMinus(),
                  size: MuButtonSize.xl,
                  fullWidth: true,
                  loading: _saving,
                  onPressed: _picked.isEmpty ? null : () => _confirm(b),
                ),
                const SizedBox(height: MuSpace.s2),
                MuButton.tertiary(
                  label: l10n.annuler,
                  size: MuButtonSize.l,
                  fullWidth: true,
                  onPressed: () => goBack(context, Routes.ownerCheckIn),
                ),
              ],
            ),
    );
  }

  List<Widget> _content(BuildContext context, OwnerBooking b) {
    final c = context.mu;
    final arrived = b.arrived.length;
    final share = shareOf(b);
    final others = arrived;
    final focus = _picked.length == 1 ? _picked.single : null;
    Widget section(String t) => Padding(
      padding: const EdgeInsets.only(top: MuSpace.s5, bottom: MuSpace.s2),
      child: Semantics(
        header: true,
        child: Text(t, style: MuType.overline.copyWith(color: c.textSecondary)),
      ),
    );
    return [
      MuCardSurface(
        child: Row(
          children: [
            MuAvatarStack(
              people: [for (final p in b.arrived) MuPerson(p)],
              size: MuAvatarSize.xs,
              semanticLabel: l10n.arrives(arrived),
            ),
            const SizedBox(width: MuSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$arrived/${b.capacity}',
                          style: MuType.numM.copyWith(color: c.text),
                        ),
                        TextSpan(text: l10n.joueursArrives),
                      ],
                    ),
                    style: MuType.body.copyWith(color: c.text),
                  ),
                  Text(
                    l10n.debut2(b.ref, b.organiser, hourLong(b.start.hour)),
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      section(l10n.quiNEstPasVenu),
      if (b.expected.isEmpty)
        Text(
          b.noShows.isEmpty
              ? l10n.tousLesJoueursSontArrives
              : l10n.dejaSignale(b.noShows.join(', ')),
          style: MuType.body.copyWith(color: c.textSecondary),
        ),
      for (final p in b.expected) ...[
        _PlayerRow(
          name: p,
          share: share,
          picked: _picked.contains(p),
          onChanged: (v) => setState(() => v ? _picked.add(p) : _picked.remove(p)),
        ),
        const SizedBox(height: MuSpace.s2),
      ],
      Text(
        l10n.possibleDesMinApresLe(others),
        style: MuType.caption.copyWith(color: c.textSecondary),
      ),
      section(l10n.ceQuiVaSePasser2),
      MuCardSurface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _Consequence(
              icon: PhosphorIcons.shieldWarning(),
              tone: c.warningSoft,
              ink: c.warningText,
              title: focus == null ? l10n.leurFiabiliteBaisse : l10n.saFiabiliteBaisse,
              body: focus == null
                  ? 'Les organisateurs le voient sur leur profil.'
                  : () {
                      final (h, t) = _record(focus);
                      return '$h/$t → $h/${t + 1} matchs honorés. Les organisateurs le voient sur son profil.';
                    }(),
              extra: focus == null
                  ? null
                  : () {
                      final (h, t) = _record(focus);
                      return Row(
                        children: [
                          MuReliabilityBadge(score: (h * 100 / t).round(), size: MuBadgeSize.s),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
                            child: MuDirectionalIcon(
                              PhosphorIcons.arrowRight(),
                              size: MuSize.iconXs,
                              color: c.textSecondary,
                            ),
                          ),
                          MuReliabilityBadge(
                            score: (h * 100 / (t + 1)).round(),
                            size: MuBadgeSize.s,
                          ),
                        ],
                      );
                    }(),
            ),
            Divider(height: 1, color: c.border),
            _Consequence(
              icon: PhosphorIcons.wallet(),
              tone: c.surfaceMuted,
              ink: c.text,
              title: focus == null ? l10n.leurPartResteDue : l10n.saPartResteDue,
              body:
                  l10n.restentVersesASansRemboursement(formatDT(share), Story.arenaFive.name),
            ),
            Divider(height: 1, color: c.border),
            _Consequence(
              icon: PhosphorIcons.bell(),
              tone: c.surfaceMuted,
              ink: c.text,
              title: focus == null
                  ? l10n.ilsSontPrevenusEtPeuvent
                  : l10n.ilEstPrevenuEtPeut,
              body: l10n.ilAHPourRepondre,
            ),
          ],
        ),
      ),
      const SizedBox(height: MuSpace.s5),
      MuTextField(
        label: l10n.notePourMatchup,
        controller: _note,
        optional: true,
        multiline: true,
        minLines: 2,
        maxLength: _noteMax,
        placeholder: l10n.exInjoignablePersonneNA,
      ),
    ];
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.name,
    required this.share,
    required this.picked,
    required this.onChanged,
  });

  final String name;
  final num share;
  final bool picked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: MuRadius.mdAll,
        side: BorderSide(color: picked ? c.text : c.border, width: picked ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: MuRadius.mdAll,
        onTap: () => onChanged(!picked),
        child: Padding(
          padding: const EdgeInsets.all(MuSpace.s3),
          child: Row(
            children: [
              MuCheckbox(
                value: picked,
                semanticLabel: l10n.nEstPasVenu(name),
                onChanged: (v) => onChanged(v ?? false),
              ),
              const SizedBox(width: MuSpace.s2),
              MuAvatar(name: name),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: MuType.labelL.copyWith(color: c.text)),
                    Text(
                      l10n.partPayeePasDeBillet(formatDT(share)),
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              MuStatusBadge(
                status: MuStatus.pending,
                label: l10n.pasArrive,
                size: MuBadgeSize.s,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Consequence extends StatelessWidget {
  const _Consequence({
    required this.icon,
    required this.tone,
    required this.ink,
    required this.title,
    required this.body,
    this.extra,
  });

  final IconData icon;
  final Color tone;
  final Color ink;
  final String title;
  final String body;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsets.all(MuSpace.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: MuSize.controlS,
            height: MuSize.controlS,
            decoration: BoxDecoration(color: tone, borderRadius: MuRadius.smAll),
            alignment: Alignment.center,
            child: Icon(icon, size: MuSize.iconS, color: ink),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MuType.label.copyWith(color: c.text)),
                if (extra != null) ...[const SizedBox(height: MuSpace.s1), extra!],
                const SizedBox(height: MuSpace.s1),
                Text(body, style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
