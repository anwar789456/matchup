import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format.dart';
import '../../../core/search.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../home/controllers/home_providers.dart';
import '../../matches/data/bookings_repository.dart';
import '../controllers/booking_controller.dart';
import '../data/teammates_repository.dart';
import '../widgets/booking_scaffold.dart';

final _suggestedProvider = FutureProvider.family<List<Teammate>, String>(
  (ref, venueId) => ref.watch(teammatesRepositoryProvider).suggested(venueId),
);

final _nextReferenceProvider = FutureProvider<String>(
  (ref) => ref.watch(bookingsRepositoryProvider).nextReference(),
);

/// BKG-03 · Réservation 2/3, invités: search a friend, the invited chips, suggested teammates to
/// tick, or the share link. Each invited friend pays their share on accepting.
class BookingInvitesScreen extends ConsumerStatefulWidget {
  const BookingInvitesScreen({super.key, this.afterBooking = false});

  /// Opened from BKG-05 « Inviter des joueurs »: the button goes back instead of to the summary.
  final bool afterBooking;

  @override
  ConsumerState<BookingInvitesScreen> createState() => _BookingInvitesScreenState();
}

class _BookingInvitesScreenState extends ConsumerState<BookingInvitesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final draft = ref.watch(bookingProvider);
    final booking = ref.read(bookingProvider.notifier);
    final zone = ref.watch(meProvider).value?.zone ?? 'La Marsa';
    final reference = draft.confirmed?.id ?? ref.watch(_nextReferenceProvider).value;
    final link = reference == null ? null : 'matchup.tn/r/$reference';
    final n = draft.invited.length;
    final left = draft.capacity - draft.team;

    return BookingStepScaffold(
      step: 2,
      title: 'Tes invités',
      bottomBar: [
        MuButton.primary(
          label: n == 0
              ? 'Continuer sans inviter'
              : 'Inviter $n ${n == 1 ? 'ami' : 'amis'} et continuer',
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: () {
            if (widget.afterBooking) {
              MuToast.show(context, title: 'Invitations envoyées', tone: MuToastTone.success);
              context.pop();
            } else {
              context.push(Routes.bookingSummary);
            }
          },
        ),
      ],
      body: (context, d, s) {
        final mates = ref.watch(_suggestedProvider(s.venue.venue.id)).value ?? const [];
        final q = foldAccents(_query.trim());
        final shown = [
          for (final m in mates)
            if (q.isEmpty || foldAccents(m.name).contains(q)) m,
        ];
        final share = s.price / d.capacity;
        return [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text('Invite tes amis', style: MuType.h2.copyWith(color: c.text)),
              ),
              const SizedBox(height: MuSpace.s1),
              Text(
                'Partie ${d.type == BookingType.private ? 'privée' : 'publique'} · ${s.court.name} · '
                '${formatDay(s.start)} · ${formatTime(s.start)}. Chacun paie '
                '${formatDT(d.type == BookingType.private ? share : d.share)} en acceptant.',
                style: MuType.body.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          MuSearchField<void>(
            label: 'Rechercher un ami',
            placeholder: 'Nom, pseudo ou numéro',
            onChanged: (v) => setState(() => _query = v),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        n == 0
                            ? 'Aucun ami invité'
                            : '$n ${n == 1 ? 'ami invité' : 'amis invités'}',
                        style: MuType.labelL.copyWith(color: c.text),
                      ),
                    ),
                  ),
                  Text(
                    'Il reste $left ${left == 1 ? 'place' : 'places'} sur ${d.capacity}',
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
              if (n > 0) ...[
                const SizedBox(height: MuSpace.s3),
                Wrap(
                  spacing: MuSpace.s2,
                  runSpacing: MuSpace.s2,
                  children: [
                    for (final name in d.invited)
                      MuChip(
                        label: name,
                        kind: MuChipKind.input,
                        onRemove: () => booking.toggleInvite(name),
                        removeLabel: 'Retirer $name',
                      ),
                  ],
                ),
              ],
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text('Coéquipiers suggérés', style: MuType.labelL.copyWith(color: c.text)),
              ),
              Text(
                'Ils ont déjà joué avec toi à ${s.venue.venue.name} ou près de $zone.',
                style: MuType.caption.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: MuSpace.s2),
              for (final (i, m) in shown.indexed) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: c.border),
                _MateRow(
                  mate: m,
                  zone: zone,
                  invited: d.invited.contains(m.name),
                  full: left == 0 && !d.invited.contains(m.name),
                  onChanged: () => booking.toggleInvite(m.name),
                ),
              ],
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
                  child: Text(
                    'Aucun coéquipier ne s’appelle « $_query ». Partage le lien ci-dessous.',
                    style: MuType.body.copyWith(color: c.textSecondary),
                  ),
                ),
            ],
          ),
          if (link != null) _ShareLink(link: link, slot: s),
        ];
      },
    );
  }
}

class _MateRow extends StatelessWidget {
  const _MateRow({
    required this.mate,
    required this.zone,
    required this.invited,
    required this.full,
    required this.onChanged,
  });

  final Teammate mate;
  final String zone;
  final bool invited;

  /// No place left: only invited rows can change.
  final bool full;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return InkWell(
      onTap: full ? null : onChanged,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
        child: Row(
          children: [
            MuAvatar(name: mate.name, level: mate.level),
            const SizedBox(width: MuSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mate.name, style: MuType.label.copyWith(color: c.text)),
                  Text(mate.meta(zone), style: MuType.caption.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            MuCheckbox(
              value: invited,
              semanticLabel: 'Inviter ${mate.name}',
              onChanged: full ? null : (_) => onChanged(),
            ),
          ],
        ),
      ),
    );
  }
}

/// « Ou partage le lien »: the link, « Copier le lien » and « WhatsApp ».
class _ShareLink extends StatelessWidget {
  const _ShareLink({required this.link, required this.slot});

  final String link;
  final PickedSlot slot;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final message =
        'Rejoins-moi au ${slot.venue.venue.sport.label.toLowerCase()} : ${slot.title}, '
        '${formatDateTime(slot.start)}. https://$link';
    return Container(
      padding: const EdgeInsets.all(MuSpace.s4),
      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('Ou partage le lien', style: MuType.labelL.copyWith(color: c.text)),
          ),
          Text(
            'Seules les personnes qui ont le lien peuvent rejoindre.',
            style: MuType.caption.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: MuSpace.s3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s3),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: MuRadius.smAll,
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.link(), size: MuSize.iconXs, color: c.textSecondary),
                const SizedBox(width: MuSpace.s2),
                Expanded(
                  child: SelectableText(link, style: MuType.body.copyWith(color: c.text)),
                ),
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          Row(
            children: [
              Expanded(
                child: MuButton.secondary(
                  label: 'Copier le lien',
                  leading: PhosphorIcons.copy(),
                  fullWidth: true,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: 'https://$link'));
                    if (context.mounted) {
                      MuToast.show(context, title: 'Lien copié', tone: MuToastTone.success);
                    }
                  },
                ),
              ),
              const SizedBox(width: MuSpace.s2),
              Expanded(
                child: MuButton.secondary(
                  label: 'WhatsApp',
                  leading: PhosphorIcons.whatsappLogo(),
                  fullWidth: true,
                  onPressed: () => launchUrl(
                    Uri.https('wa.me', '/', {'text': message}),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
