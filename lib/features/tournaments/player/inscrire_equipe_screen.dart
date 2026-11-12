import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../home/controllers/home_providers.dart';
import '../../payments/controllers/checkout_controller.dart';
import '../controllers/tournoi_providers.dart';
import '../data/tournoi_repository.dart';
import '../organizer/org_widgets.dart';

/// TRN-04 + TRN-05 · Créer l'équipe: name, me as captain, the teammates I already know (the
/// others join with the invite code), then « Payer l'inscription » through our checkout
/// (PAY-01). The team exists before paying, so an interrupted payment can be retried.
class InscrireEquipeScreen extends ConsumerStatefulWidget {
  const InscrireEquipeScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<InscrireEquipeScreen> createState() => _InscrireEquipeScreenState();
}

class _InscrireEquipeScreenState extends ConsumerState<InscrireEquipeScreen> {
  final _nom = TextEditingController();
  final _coequipiers = <TextEditingController>[];
  String? _nomError;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_nom, ..._coequipiers]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _inscrire(Tournoi t) async {
    if (_nom.text.trim().length < 2) {
      setState(() => _nomError = l10n.trnNomEquipeRequis);
      return;
    }
    setState(() {
      _nomError = null;
      _busy = true;
    });
    final repo = ref.read(tournoiRepositoryProvider);
    try {
      final me = await ref.read(meProvider.future);
      final team = await repo.inscrire(
        widget.id,
        nom: _nom.text,
        capitaineNom: me.displayName,
        coequipiers: [
          for (final c in _coequipiers)
            if (c.text.trim().isNotEmpty) (repo.invite(), c.text.trim()),
        ],
      );
      refreshTournoi(ref, widget.id);
      if (!mounted) return;
      if (team.paye) {
        context.go(Routes.tournoiEquipe(widget.id));
      } else {
        payerInscription(context, ref, t, team);
      }
    } on TournoiRefus catch (e) {
      if (mounted) toastRefus(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TournoiLoader(
        id: widget.id,
        builder: (context, t) {
          final c = context.mu;
          final me = ref.watch(meProvider).value;
          final others = t.draft.joueursParEquipe - 1;
          while (_coequipiers.length < others) {
            _coequipiers.add(TextEditingController());
          }
          return OrgPage(
            title: l10n.trnCreerEquipe,
            subtitle: t.draft.nom,
            back: Routes.tournoi(widget.id),
            bottom: MuButton.primary(
              label: t.draft.fraisEquipe == 0 ? l10n.trnInscrireEquipe : l10n.trnPayerInscription,
              price: t.draft.fraisEquipe == 0 ? null : formatDT(t.draft.fraisEquipe),
              size: MuButtonSize.l,
              fullWidth: true,
              loading: _busy,
              onPressed: _busy ? null : () => _inscrire(t),
            ),
            children: [
              Text(l10n.trnCreeTonEquipe, style: MuType.h2.copyWith(color: c.text)),
              const SizedBox(height: MuSpace.s2),
              Text(l10n.trnCreeTonEquipeLead, style: MuType.body.copyWith(color: c.textSecondary)),
              const SizedBox(height: MuSpace.s5),
              MuTextField(
                label: l10n.trnNomEquipe,
                controller: _nom,
                error: _nomError,
                inputFormatters: [LengthLimitingTextInputFormatter(24)],
              ),
              const SizedBox(height: MuSpace.s5),
              Text(l10n.trnCapitaine, style: MuType.label.copyWith(color: c.text)),
              const SizedBox(height: MuSpace.s2),
              Row(children: [
                MuAvatar(name: me?.displayName ?? '?', size: MuAvatarSize.s),
                const SizedBox(width: MuSpace.s3),
                Text(l10n.trnToi(me?.displayName ?? ''), style: MuType.body.copyWith(color: c.text)),
              ]),
              if (others > 0) ...[
                const SizedBox(height: MuSpace.s5),
                Text(l10n.trnCoequipiers(others), style: MuType.label.copyWith(color: c.text)),
                const SizedBox(height: MuSpace.s2),
                for (final (i, ctl) in _coequipiers.take(others).indexed)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: MuSpace.s3),
                    child: MuTextField(label: l10n.trnJoueurN(i + 2), controller: ctl, optional: true),
                  ),
                Text(l10n.trnCoequipiersNote, style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
              const SizedBox(height: MuSpace.s4),
              Text(l10n.trnRembourseSiRefus, style: MuType.caption.copyWith(color: c.textSecondary)),
            ],
          );
        },
      );
}

/// Opens PAY-01 for [team]'s fee; once paid, the team is marked paid and TRN-06 opens.
void payerInscription(BuildContext context, WidgetRef ref, Tournoi t, Equipe team) {
  final d = t.draft;
  ref.read(checkoutRequestProvider.notifier).start(
        CheckoutRequest(
          kind: CheckoutKind.share,
          eyebrow: l10n.trnInscriptionEyebrow(team.nom),
          title: d.nom,
          subtitle: '${formatDateRange(d.debut, d.fin)} · ${d.etablissement}',
          amount: d.fraisEquipe,
          lineLabel: l10n.trnParEquipeDe(d.joueursParEquipe),
          sport: d.sport,
          promoAllowed: false,
          detailRows: [
            (l10n.trnEquipes, team.nom, team.membres.map((m) => m.$2).join(' · ')),
            (l10n.trnLieu, d.etablissement, d.lieu),
            (l10n.trnDates, formatDateRange(d.debut, d.fin), null),
          ],
          successRoute: Routes.tournoiEquipe(t.id),
          onPaid: (receipt, fromBalance) async {
            await ref.read(tournoiRepositoryProvider).marquerPaye(team.id);
            refreshTournoi(ref, t.id);
          },
        ),
      );
  context.push(Routes.checkout);
}
