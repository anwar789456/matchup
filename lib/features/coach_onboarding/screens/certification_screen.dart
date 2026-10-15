import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/draft_file.dart';
import '../../common/data/pro_providers.dart';
import '../../common/data/upload_queue.dart';
import '../../common/widgets/pro_wizard_scaffold.dart';
import '../controllers/coach_controller.dart';
import '../data/coach_draft.dart';
import '../widgets/coach_wizard.dart';

/// COA-02 — the diploma: upload, the file's progress through the check, and what the coach can
/// do before and after it.
class CertificationScreen extends ConsumerStatefulWidget {
  const CertificationScreen({super.key});

  @override
  ConsumerState<CertificationScreen> createState() => _CertificationScreenState();
}

class _CertificationScreenState extends ConsumerState<CertificationScreen> {
  // COA-02: PDF, JPG, PNG · 10 Mo max.
  static const _maxBytes = 10 * 1000 * 1000;

  late final UploadQueue _queue = UploadQueue(
    service: ref.read(uploadServiceProvider),
    maxBytes: _maxBytes,
    tooBig: (f) => (
      '${f.name} pèse ${formatFileSize(f.sizeBytes)} (max 10 Mo). Choisis un fichier plus léger.',
      'Fichier trop lourd',
    ),
    onDone: (file, _) async {
      final diploma = DraftFile(id: file.id, name: file.name, sizeBytes: file.sizeBytes);
      await ref.read(coachRepositoryProvider).submitDiploma(diploma);
      await _coach.edit(
        (d) => d.copyWith(diploma: diploma, diplomaSentAt: ref.read(clockProvider)()),
      );
    },
  )..addListener(_changed);

  String? _error;

  CoachController get _coach => ref.read(coachProvider.notifier);

  void _changed() => setState(() {});

  @override
  void dispose() {
    _queue
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final f = await ref.read(fileSourceProvider).pickOne(const ['pdf', 'jpg', 'jpeg', 'png']);
    if (f == null || !mounted) return;
    for (final old in _queue.files) {
      _queue.remove(old.id);
    }
    setState(() => _error = null);
    _queue.add(f);
  }

  bool _validate() {
    final d = ref.read(coachProvider).requireValue;
    setState(() {
      _error = _queue.busy
          ? 'Attends la fin de l’envoi.'
          : (d.diploma == null ? 'Ajoute ton diplôme pour lancer la vérification.' : null);
    });
    return _error == null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final d = ref.watch(coachProvider).requireValue;
    final sent = d.diplomaSentAt;
    final deadline = sent?.add(CoachCatalog.review);
    final diploma = d.diploma;
    final files = [
      if (diploma != null)
        MuUploadFile(id: diploma.id, name: diploma.name, sizeBytes: diploma.sizeBytes),
      ..._queue.files,
    ];

    final upload = MuFileUpload.dropzone(
      label: 'Diplôme ou certificat',
      title: 'Glisse ou choisis un fichier',
      linkPart: null,
      hint: 'PDF, JPG, PNG · 10 Mo max',
      files: files,
      error: _error,
      onAdd: _pick,
      onRemove: (f) {
        if (f.id == diploma?.id) {
          _coach.edit((d) => d.copyWith(clearDiploma: true));
        } else {
          _queue.remove(f.id);
        }
      },
      onRetry: (_) => _pick(),
    );

    final file = _Dossier(sentAt: sent);

    return CoachWizard(
      step: 1,
      title: 'Ta certification',
      lead:
          'Un diplôme vérifié affiche le badge « Coach vérifié » : les élèves réservent en '
          'confiance.',
      validate: _validate,
      body: ProFormCard(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sent == null
                  ? const MuBanner(
                      tone: MuBannerTone.neutral,
                      title: 'Vérification sous 48 h',
                      detail:
                          'Envoie ton diplôme : on le vérifie auprès de la fédération et tu '
                          'reçois un email dès que c’est validé.',
                    )
                  : MuBanner(
                      tone: MuBannerTone.info,
                      icon: PhosphorIcons.hourglassMedium(),
                      title: 'Vérification en cours · 48 h',
                      detail:
                          'On vérifie ton diplôme auprès de la fédération. Tu reçois un email '
                          'dès que c’est validé, au plus tard le ${withFullStop(formatDay(deadline!))}',
                    ),
              const SizedBox(height: MuSpace.s6),
              if (MediaQuery.sizeOf(context).width < _stackBelow)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    upload,
                    const SizedBox(height: MuSpace.s5),
                    file,
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: upload),
                    const SizedBox(width: MuSpace.s5),
                    Expanded(child: file),
                  ],
                ),
            ],
          ),
          ProFieldGrid(
            children: [
              _Checklist(
                title: 'En attendant, tu peux déjà',
                icon: PhosphorIcons.check(),
                color: c.successText,
                items: const [
                  'Créer et préparer tes programmes',
                  'Compléter ton profil et tes tarifs',
                  'Inviter tes élèves actuels',
                ],
              ),
              _Checklist(
                title: 'Après la validation',
                icon: PhosphorIcons.lockSimple(),
                color: c.textSecondary,
                items: const [
                  'Publier tes programmes',
                  'Recevoir les paiements de tes élèves',
                  'Apparaître dans la recherche de coachs',
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const double _stackBelow = 720;
}

/// « Ton dossier »: the status and the three stages of the check.
class _Dossier extends StatelessWidget {
  const _Dossier({required this.sentAt});

  final DateTime? sentAt;

  // COA-02 source: 2 px connector at least 16 high; 2 px between the lines.
  static const double _connector = 2;
  static const double _connectorMin = 16;
  static const double _lineGap = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final sent = sentAt != null;
    final stages = [
      (
        sent ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill) : PhosphorIcons.circleDashed(),
        sent ? c.successText : c.textSecondary,
        sent ? 'Diplôme envoyé' : 'Diplôme à envoyer',
        sent ? formatDateTime(sentAt!) : 'PDF, JPG ou PNG',
        true,
      ),
      (
        sent ? PhosphorIcons.hourglassMedium() : PhosphorIcons.circleDashed(),
        sent ? c.warningText : c.textSecondary,
        'En vérification',
        'Réponse sous 48 h',
        sent,
      ),
      (
        PhosphorIcons.circleDashed(),
        c.textSecondary,
        'Coach vérifié',
        'Badge sur ton profil',
        false,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(MuSpace.s4),
      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('Ton dossier', style: MuType.label.copyWith(color: c.text)),
          ),
          const SizedBox(height: MuSpace.s2),
          sent
              ? const MuStatusBadge(status: MuStatus.pending, label: 'En attente')
              : const MuStatusBadge(status: MuStatus.draft, label: 'À envoyer'),
          const SizedBox(height: MuSpace.s4),
          for (final (i, (icon, color, title, detail, active)) in stages.indexed)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Icon(icon, size: MuSize.iconM, color: color),
                      if (i < stages.length - 1) ...[
                        const SizedBox(height: MuSpace.s1),
                        Expanded(
                          child: Container(
                            width: _connector,
                            constraints: const BoxConstraints(minHeight: _connectorMin),
                            decoration: BoxDecoration(
                              color: c.border,
                              borderRadius: MuRadius.fullAll,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: MuSpace.s3),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: i < stages.length - 1 ? MuSpace.s3 : 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: MuType.label.copyWith(color: active ? c.text : c.textSecondary),
                          ),
                          const SizedBox(height: _lineGap),
                          Text(detail, style: MuType.caption.copyWith(color: c.textSecondary)),
                        ],
                      ),
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

class _Checklist extends StatelessWidget {
  const _Checklist({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: MuType.label.copyWith(color: c.text)),
        ),
        const SizedBox(height: MuSpace.s3),
        for (final (i, item) in items.indexed) ...[
          if (i > 0) const SizedBox(height: MuSpace.s2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: MuSize.iconS, color: color),
              const SizedBox(width: MuSpace.s2),
              Expanded(
                child: Text(item, style: MuType.body.copyWith(color: c.text)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
