import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/pro_providers.dart';
import '../../common/data/upload_queue.dart';
import '../../common/widgets/pro_wizard_scaffold.dart';
import '../controllers/owner_controller.dart';
import '../data/owner_draft.dart';
import '../data/owner_repository.dart';
import '../widgets/owner_wizard.dart';

/// Keeps the 20 RIB digits, grouped 2-3-13-2 as on the bank certificate (« 08 006 0123456789012 34 »).
class RibFormatter extends TextInputFormatter {
  static const _groups = [2, 3, 13, 2];

  static String digitsOf(String text) {
    final d = text.replaceAll(RegExp(r'\D'), '');
    return d.length > 20 ? d.substring(0, 20) : d;
  }

  static String group(String digits) {
    final b = StringBuffer();
    var i = 0;
    for (final g in _groups) {
      if (i >= digits.length) break;
      if (i > 0) b.write(' ');
      final end = (i + g).clamp(0, digits.length);
      b.write(digits.substring(i, end));
      i = end;
    }
    return b.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = digitsOf(newValue.text);
    final before = digitsOf(
      newValue.text.substring(0, newValue.selection.end.clamp(0, newValue.text.length)),
    ).length;
    final text = group(digits);
    final offset = group(digits.substring(0, before.clamp(0, digits.length))).length;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// OWN-07 — where the revenue goes: account holder, bank, RIB (checked), the RIB certificate.
class PayoutScreen extends ConsumerStatefulWidget {
  const PayoutScreen({super.key});

  @override
  ConsumerState<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends ConsumerState<PayoutScreen> {
  // OWN-07: PDF, JPG, PNG · 5 Mo max.
  static const _maxBytes = 5 * 1000 * 1000;

  late final _d = ref.read(ownerProvider).requireValue;
  late final _holder = TextEditingController(text: _d.holder);
  late final _rib = TextEditingController(text: RibFormatter.group(_d.rib));
  late String _bank = _d.bank;

  String? _holderError;
  String? _bankError;
  String? _ribError;
  String? _ribSuccess;
  String? _fileError;
  bool _checking = false;

  late final UploadQueue _queue = UploadQueue(
    service: ref.read(uploadServiceProvider),
    maxBytes: _maxBytes,
    tooBig: (f) => (
      '${f.name} pèse ${formatFileSize(f.sizeBytes)} (max 5 Mo). Choisis un fichier plus léger.',
      'Fichier trop lourd',
    ),
    onDone: (file, _) => _owner.edit(
      (d) => d.copyWith(
        ribCertificate: DraftFile(id: file.id, name: file.name, sizeBytes: file.sizeBytes),
      ),
    ),
  )..addListener(_changed);

  OwnerController get _owner => ref.read(ownerProvider.notifier);

  void _changed() => setState(() {});

  @override
  void initState() {
    super.initState();
    if (_d.rib.length == 20) _check(_d.rib);
  }

  @override
  void dispose() {
    _holder.dispose();
    _rib.dispose();
    _queue
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  Future<bool> _check(String digits) async {
    setState(() {
      _checking = true;
      _ribError = null;
      _ribSuccess = null;
    });
    final result = await ref.read(ownerRepositoryProvider).checkRib(_bank, digits);
    if (!mounted || RibFormatter.digitsOf(_rib.text) != digits) return result.valid;
    setState(() {
      _checking = false;
      _ribError = result.error;
      _ribSuccess = result.valid ? '20 chiffres · clé RIB valide' : null;
    });
    return result.valid;
  }

  Future<void> _pick() async {
    final f = await ref.read(fileSourceProvider).pickOne(const ['pdf', 'jpg', 'jpeg', 'png']);
    if (f == null || !mounted) return;
    for (final old in _queue.files) {
      _queue.remove(old.id);
    }
    setState(() => _fileError = null);
    _queue.add(f);
  }

  Future<bool> _validate() async {
    final digits = RibFormatter.digitsOf(_rib.text);
    final d = ref.read(ownerProvider).requireValue;
    setState(() {
      _holderError = _holder.text.trim().isEmpty ? 'Indique le titulaire du compte.' : null;
      _bankError = _bank.isEmpty ? 'Choisis ta banque.' : null;
      _ribError = digits.length == 20 ? _ribError : 'Le RIB compte 20 chiffres.';
      _fileError = _queue.busy
          ? 'Attends la fin de l’envoi.'
          : (d.ribCertificate == null ? 'Ajoute ton attestation de RIB.' : null);
    });
    final ribOk = digits.length == 20 && (_ribSuccess != null || await _check(digits));
    return ribOk && _holderError == null && _bankError == null && _fileError == null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final d = ref.watch(ownerProvider).requireValue;
    final legal = d.legalName.trim().isEmpty ? d.venueName : d.legalName.trim();
    final digits = RibFormatter.digitsOf(_rib.text);
    final cert = d.ribCertificate;
    final files = [
      if (cert != null) MuUploadFile(id: cert.id, name: cert.name, sizeBytes: cert.sizeBytes),
      ..._queue.files,
    ];

    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MuTextField(
          label: 'Titulaire du compte',
          controller: _holder,
          size: MuFieldSize.m,
          helper: 'Comme sur ton relevé bancaire.',
          error: _holderError,
          onChanged: (v) {
            if (_holderError != null) setState(() => _holderError = null);
            _owner.edit((d) => d.copyWith(holder: v));
          },
        ),
        const SizedBox(height: MuSpace.s5),
        MuSelect<String>(
          label: 'Banque',
          size: MuFieldSize.m,
          value: _bank.isEmpty ? null : _bank,
          placeholder: 'Choisis ta banque',
          error: _bankError,
          options: [
            for (final (id, name) in OwnerCatalog.banks) MuSelectOption(value: id, label: name),
          ],
          onChanged: (v) {
            setState(() {
              _bank = v;
              _bankError = null;
            });
            _owner.edit((d) => d.copyWith(bank: v));
            if (digits.length == 20) _check(digits);
          },
        ),
        const SizedBox(height: MuSpace.s5),
        MuTextField(
          label: 'RIB',
          controller: _rib,
          size: MuFieldSize.m,
          leadingIcon: PhosphorIcons.bank(),
          keyboardType: TextInputType.number,
          inputFormatters: [RibFormatter()],
          autocorrect: false,
          error: _ribError,
          success: _ribSuccess,
          helper: _checking ? 'Vérification du RIB…' : null,
          onChanged: (v) {
            final digits = RibFormatter.digitsOf(v);
            setState(() {
              _ribError = null;
              _ribSuccess = null;
            });
            _owner.edit((d) => d.copyWith(rib: digits));
            if (digits.length == 20) _check(digits);
          },
        ),
      ],
    );

    final upload = MuFileUpload.dropzone(
      label: 'Attestation de RIB',
      title: 'Glisse ou choisis ton attestation',
      linkPart: null,
      hint: 'PDF, JPG, PNG · 5 Mo max',
      files: files,
      error: _fileError,
      onAdd: _pick,
      onRemove: (f) {
        if (f.id == cert?.id) {
          _owner.edit((d) => d.copyWith(clearRibCertificate: true));
        } else {
          _queue.remove(f.id);
        }
      },
      onRetry: (f) => _pick(),
    );

    return OwnerWizard(
      step: 6,
      title: 'Où verser tes revenus ?',
      lead:
          'Chaque lundi, MatchUp vire sur ce compte les réservations payées en ligne la semaine '
          'passée.',
      validate: _validate,
      body: ProFormCard(
        divided: false,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MuBanner(
                tone: MuBannerTone.info,
                icon: PhosphorIcons.hourglassMedium(),
                title: 'Vérifié sous 48 h',
                detail:
                    'On vérifie que le compte est bien au nom ${elideDe(legal)}. Tes réservations '
                    's’ouvrent sans attendre, les versements partent dès la validation.',
              ),
              const SizedBox(height: MuSpace.s6),
              _TwoColumns(start: fields, end: upload),
              const SizedBox(height: MuSpace.s6),
              Container(
                padding: const EdgeInsets.all(MuSpace.s4),
                decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(PhosphorIcons.lock(), size: MuSize.iconS, color: c.text),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tes coordonnées bancaires sont chiffrées',
                            style: MuType.label.copyWith(color: c.text),
                          ),
                          const SizedBox(height: _TwoColumns.lineGap),
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text:
                                      'Après l’enregistrement, seuls les 4 derniers chiffres '
                                      'restent visibles : ',
                                ),
                                TextSpan(
                                  // Kept on one line, as in the design.
                                  text:
                                      '${OwnerCatalog.bankName(_bank)} · ${OwnerSteps.maskRib(digits)}'
                                          .replaceAll(' ', '\u00A0'),
                                  style: MuType.label.copyWith(color: c.text),
                                ),
                                const TextSpan(
                                  text: '. MatchUp ne prélève jamais rien sur ce compte.',
                                ),
                              ],
                            ),
                            style: MuType.body.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fields beside the upload (gap 24), stacked below 720.
class _TwoColumns extends StatelessWidget {
  const _TwoColumns({required this.start, required this.end});

  final Widget start;
  final Widget end;

  static const double _stackBelow = 720;
  static const double lineGap = 2;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < _stackBelow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          start,
          const SizedBox(height: MuSpace.s6),
          end,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: start),
        const SizedBox(width: MuSpace.s6),
        Expanded(child: end),
      ],
    );
  }
}
