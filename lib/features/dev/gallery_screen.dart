import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/connectivity.dart';
import '../../core/format.dart';
import '../../theme/theme.dart';
import '../../ui/ui.dart';
import '../common/data/story_data.dart';
import '../explore/controllers/explore_controller.dart';
import '../games/widgets/claim_takeover.dart';
import '../home/controllers/home_providers.dart';

/// Debug-only widget gallery: every Mu* widget, in Light and Night match side by side on wide
/// screens (a toggle on phones), with a right-to-left switch.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

enum _ThemeChoice { light, dark }

class _GalleryScreenState extends State<GalleryScreen> {
  _ThemeChoice _choice = _ThemeChoice.light;
  bool _rtl = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final both = constraints.maxWidth >= MuLayout.bpExpanded;
      Widget pane(ThemeData theme) => Theme(
            data: theme,
            child: Builder(
              builder: (context) => Material(
                color: context.mu.bg,
                child: Directionality(
                  textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
                  child: const _GalleryBody(),
                ),
              ),
            ),
          );

      return Scaffold(
        appBar: AppBar(
          title: const Text('Galerie des widgets'),
          actions: [
            if (!both)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: MuSpace.s2),
                child: MuChip(
                  label: _choice == _ThemeChoice.light ? 'Light' : 'Night match',
                  icon: _choice == _ThemeChoice.light ? PhosphorIcons.sun() : PhosphorIcons.moon(),
                  onSelected: (_) => setState(() => _choice = _choice == _ThemeChoice.light
                      ? _ThemeChoice.dark
                      : _ThemeChoice.light),
                ),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: MuSpace.s4),
              child: MuChip(
                label: 'RTL',
                selected: _rtl,
                onSelected: (v) => setState(() => _rtl = v),
              ),
            ),
          ],
        ),
        body: both
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: pane(MuTheme.light())),
                  Expanded(child: pane(MuTheme.dark())),
                ],
              )
            : pane(_choice == _ThemeChoice.light ? MuTheme.light() : MuTheme.dark()),
      );
    });
  }
}

class _GalleryBody extends StatefulWidget {
  const _GalleryBody();

  @override
  State<_GalleryBody> createState() => _GalleryBodyState();
}

class _GalleryBodyState extends State<_GalleryBody> {
  bool _toggle = true;
  bool? _consent = false;
  bool? _tri;
  bool _consentError = true;
  final Set<MuSport> _sports = {MuSport.football, MuSport.padel};
  String _experience = '6 mois à 2 ans';
  final Set<String> _filters = {'Ce soir'};
  String _slot = 'Soir';
  bool _loading = false;
  bool _success = false;
  int _step = 2;
  bool _showBanner = true;
  final List<String> _places = ['La Marsa', 'Lac 2'];
  String? _otpError;
  bool _verifying = false;
  String? _otpSuccess;
  final _otp = TextEditingController();
  final _email = TextEditingController(text: 'yassine.b@email.tn');
  bool _lights = true;
  String _courtType = 'Extérieur';
  String? _surface = 'Gazon synthétique';
  MuBillingPeriod _period = MuBillingPeriod.month;
  RangeValues _price = const RangeValues(10, 25);
  RangeValues _level = const RangeValues(3, 4.5);
  bool _favourite = false;
  String? _pin = Story.arenaFive.id;
  MuSlotRange? _slot2 = const MuSlotRange('t1', 1, 2);
  DateTime _day = Story.at(21, 0);
  int _spots = 4;
  int _stars = 4;
  int _tab = 0;

  @override
  void dispose() {
    _otp.dispose();
    _email.dispose();
    super.dispose();
  }

  void _simulateLoading() {
    setState(() => _loading = true);
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = true;
      });
      Timer(MuMotion.success, () {
        if (mounted) setState(() => _success = false);
      });
    });
  }

  void _verifyOtp(String code) {
    setState(() {
      _verifying = true;
      _otpError = null;
    });
    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        if (code == '123456') {
          _otpSuccess = 'Numéro vérifié.';
        } else {
          _otpError = 'Code incorrect. Il te reste 2 essais.';
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return ListView(
      padding: const EdgeInsets.all(MuSpace.s4),
      children: [
        _Section('Logo', [
          const Wrap(
            spacing: MuSpace.s6,
            runSpacing: MuSpace.s4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MuLogo(),
              MuLogo(variant: MuLogoVariant.icon, height: MuSize.avatarL),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Container(
            padding: const EdgeInsets.all(MuSpace.s4),
            color: c.navBg,
            child: const Align(
              alignment: AlignmentDirectional.centerStart,
              child: MuLogo(tone: MuLogoTone.dark),
            ),
          ),
        ]),
        _Section('Button — variants', [
          Wrap(spacing: MuSpace.s2, runSpacing: MuSpace.s2, children: [
            MuButton.primary(label: 'Réserver', onPressed: () {}),
            MuButton.secondary(label: 'Voir le terrain', onPressed: () {}),
            MuButton.tertiary(label: 'Plus tard', onPressed: () {}),
            MuButton(
              label: 'Annuler la réservation',
              variant: MuButtonVariant.destructive,
              onPressed: () {},
            ),
            MuButton(
              label: 'Quitter la partie',
              variant: MuButtonVariant.destructiveOutline,
              onPressed: () {},
            ),
            MuButton.link(label: 'Politique d’annulation', onPressed: () {}),
          ]),
        ]),
        _Section('Button — sizes & content', [
          Wrap(
            spacing: MuSpace.s2,
            runSpacing: MuSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MuButton.primary(label: 'S', size: MuButtonSize.s, onPressed: () {}),
              MuButton.primary(label: 'M', onPressed: () {}),
              MuButton.primary(label: 'L', size: MuButtonSize.l, onPressed: () {}),
              MuButton.primary(label: 'XL', size: MuButtonSize.xl, onPressed: () {}),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          MuButton.primary(
            label: 'Rejoindre et payer',
            price: '15 DT',
            size: MuButtonSize.xl,
            fullWidth: true,
            onPressed: () {},
          ),
          const SizedBox(height: MuSpace.s3),
          MuButton.secondary(
            label: 'Réclamer la place',
            countdown: '14:59',
            size: MuButtonSize.l,
            leading: PhosphorIcons.handGrabbing(),
            onPressed: () {},
          ),
          const SizedBox(height: MuSpace.s3),
          Wrap(spacing: MuSpace.s2, runSpacing: MuSpace.s2, children: [
            MuButton.primary(
              label: 'Payer ma part',
              size: MuButtonSize.l,
              loading: _loading,
              success: _success,
              onPressed: _simulateLoading,
            ),
            const MuButton.primary(label: 'Désactivé', size: MuButtonSize.l, onPressed: null),
            const MuButton.secondary(label: 'Désactivé', size: MuButtonSize.l, onPressed: null),
          ]),
        ]),
        _Section('IconButton', [
          Wrap(
            spacing: MuSpace.s3,
            runSpacing: MuSpace.s3,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MuIconButton(icon: PhosphorIcons.arrowLeft(), label: 'Retour', onPressed: () {}),
              MuIconButton(
                icon: PhosphorIcons.funnelSimple(),
                label: 'Filtres',
                variant: MuIconButtonVariant.secondary,
                onPressed: () {},
              ),
              MuIconButton(
                icon: PhosphorIcons.plus(),
                label: 'Créer une partie',
                variant: MuIconButtonVariant.primary,
                size: MuIconButtonSize.l,
                onPressed: () {},
              ),
              MuIconButton(
                icon: PhosphorIcons.qrCode(),
                label: 'Afficher le QR code',
                variant: MuIconButtonVariant.inverse,
                onPressed: () {},
              ),
              MuIconButton(
                icon: PhosphorIcons.bell(),
                label: 'Notifications',
                badge: 3,
                onPressed: () {},
              ),
              MuIconButton(
                icon: PhosphorIcons.chatCircle(),
                label: 'Messages',
                dot: true,
                onPressed: () {},
              ),
              MuIconButton(
                icon: PhosphorIcons.heart(),
                selectedIcon: PhosphorIcons.heart(PhosphorIconsStyle.fill),
                label: 'Favori',
                pressed: _toggle,
                onPressed: () => setState(() => _toggle = !_toggle),
              ),
              MuIconButton(
                icon: PhosphorIcons.shareNetwork(),
                label: 'Partager',
                size: MuIconButtonSize.s,
                onPressed: () {},
              ),
              MuIconButton(icon: PhosphorIcons.trash(), label: 'Supprimer', onPressed: null),
            ],
          ),
        ]),
        _Section('TextField', [
          MuTextField(
            label: 'Email',
            controller: _email,
            leadingIcon: PhosphorIcons.envelopeSimple(),
            keyboardType: TextInputType.emailAddress,
            error: 'Un compte existe déjà avec cet email.',
            messageExtra: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('C’est le tien ? ', style: MuType.caption.copyWith(color: c.textSecondary)),
                MuButton.link(label: 'Se connecter', size: MuButtonSize.s, onPressed: () {}),
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s5),
          const MuTextField(
            label: 'Nom de l’équipe',
            placeholder: 'Ex. Les Requins de Lac 2',
            helper: 'Visible par les autres équipes.',
            clearable: true,
            optional: true,
          ),
          const SizedBox(height: MuSpace.s5),
          const MuTextField(
            label: 'Prix par joueur',
            suffixText: 'DT',
            keyboardType: TextInputType.number,
            size: MuFieldSize.m,
            success: 'Prix enregistré.',
          ),
          const SizedBox(height: MuSpace.s5),
          const MuTextField(
            label: 'Présentation',
            placeholder: 'Parle de ton jeu, de tes disponibilités…',
            multiline: true,
            maxLength: 280,
          ),
          const SizedBox(height: MuSpace.s5),
          const MuTextField(label: 'Ville', placeholder: 'Tunis', enabled: false),
        ]),
        _Section('PasswordField', [
          MuPasswordField(
            strength: true,
            rules: MuPasswordRules.standard,
            showRuleErrors: true,
            error: 'Ton mot de passe doit respecter les 3 règles.',
          ),
          const SizedBox(height: MuSpace.s5),
          MuPasswordField(
            labelAside: MuButton.link(
              label: 'Mot de passe oublié ?',
              size: MuButtonSize.s,
              onPressed: () {},
            ),
          ),
        ]),
        const _Section('PhoneField', [
          MuPhoneField(helper: 'On t’envoie un code à 6 chiffres par SMS.'),
        ]),
        _Section('OtpInput', [
          MuOtpInput(
            controller: _otp,
            helper: 'Tape 123456 pour réussir.',
            error: _otpError,
            success: _otpSuccess,
            verifying: _verifying,
            resendIn: const Duration(seconds: 45),
            onResend: () {},
            onChanged: (_) {
              if (_otpError != null) setState(() => _otpError = null);
            },
            onCompleted: _verifyOtp,
          ),
          const SizedBox(height: MuSpace.s3),
          MuButton.tertiary(
            label: 'Réinitialiser',
            size: MuButtonSize.s,
            onPressed: () => setState(() {
              _otp.clear();
              _otpError = null;
              _otpSuccess = null;
            }),
          ),
        ]),
        _Section('Checkbox', [
          MuCheckbox(
            value: _consent,
            error: _consentError ? 'Accepte les conditions pour continuer.' : null,
            label: 'J’accepte les conditions d’utilisation et la politique de confidentialité',
            onChanged: (v) => setState(() {
              _consent = v;
              _consentError = v != true;
            }),
          ),
          MuCheckbox(
            value: _tri,
            tristate: true,
            label: 'Tous les équipements',
            description: 'Vestiaires, douches, parking, éclairage',
            onChanged: (v) => setState(() => _tri = v),
          ),
          const MuCheckbox(value: true, label: 'Désactivé', onChanged: null),
        ]),
        _Section('ChoiceCard', [
          MuChoiceGroup(
            label: 'Depuis combien de temps tu joues ?',
            children: [
              for (final (title, desc) in [
                ('Moins de 6 mois', 'Je découvre le sport.'),
                ('6 mois à 2 ans', 'Je joue régulièrement entre amis.'),
                ('Plus de 2 ans', 'Je joue en club ou en tournoi.'),
              ])
                MuChoiceCard(
                  title: title,
                  description: desc,
                  selected: _experience == title,
                  onTap: () => setState(() => _experience = title),
                ),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          MuChoiceGroup(
            label: 'Quels sports tu joues ?',
            layout: MuChoiceLayout.tile,
            columns: 3,
            children: [
              for (final sport in MuSport.values)
                MuChoiceCard(
                  title: sport.label,
                  leading: MuSportTile(sport, size: MuMediaTileSize.tile),
                  layout: MuChoiceLayout.tile,
                  multi: true,
                  selected: _sports.contains(sport),
                  onTap: () => setState(() =>
                      _sports.contains(sport) ? _sports.remove(sport) : _sports.add(sport)),
                ),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          MuChoiceCard(
            title: 'Le soir',
            description: '18h – minuit, terrains éclairés',
            leading: MuSportTile.icon(PhosphorIcons.moonStars()),
            multi: true,
            selected: true,
            onTap: () {},
          ),
          const SizedBox(height: MuSpace.s3),
          const MuChoiceCard(title: 'Désactivé', selected: false, onTap: null),
        ]),
        _Section('Chip', [
          Wrap(spacing: MuSpace.s2, runSpacing: MuSpace.s2, children: [
            MuChip(
              label: 'Filtres',
              icon: PhosphorIcons.slidersHorizontal(),
              count: _filters.length,
              onSelected: (_) {},
            ),
            for (final f in ['Ce soir', 'Mixte', 'Éclairé'])
              MuChip(
                label: f,
                selected: _filters.contains(f),
                onSelected: (v) => setState(() => v ? _filters.add(f) : _filters.remove(f)),
              ),
            MuChip(label: 'Date', trailingIcon: PhosphorIcons.caretDown(), onSelected: (_) {}),
          ]),
          const SizedBox(height: MuSpace.s2),
          Wrap(spacing: MuSpace.s2, runSpacing: MuSpace.s2, children: [
            for (final s in ['Matin', 'Après-midi', 'Soir'])
              MuChip(
                label: s,
                kind: MuChipKind.choice,
                selected: _slot == s,
                onSelected: (_) => setState(() => _slot = s),
              ),
          ]),
          const SizedBox(height: MuSpace.s2),
          Wrap(
            spacing: MuSpace.s2,
            runSpacing: MuSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final sport in MuSport.values) MuChip.sport(sport),
              const MuChip.sport(MuSport.padel, size: MuChipSize.s),
              const MuChip.level(3.5),
              const MuChip(label: 'Désactivé', onSelected: null),
            ],
          ),
          const SizedBox(height: MuSpace.s2),
          Wrap(spacing: MuSpace.s2, runSpacing: MuSpace.s2, children: [
            for (final p in _places)
              MuChip(
                label: p,
                kind: MuChipKind.input,
                onRemove: () => setState(() => _places.remove(p)),
              ),
          ]),
        ]),
        _Section('StepIndicator', [
          MuStepIndicator(step: _step, total: 8, title: 'Tes sports'),
          const SizedBox(height: MuSpace.s4),
          Center(child: MuStepIndicator(step: (_step - 1) % 3 + 1, total: 3, variant: MuStepVariant.dots)),
          const SizedBox(height: MuSpace.s3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MuButton.tertiary(
                label: 'Précédent',
                size: MuButtonSize.s,
                onPressed: _step > 1 ? () => setState(() => _step--) : null,
              ),
              MuButton.secondary(
                label: 'Suivant',
                size: MuButtonSize.s,
                onPressed: _step < 8 ? () => setState(() => _step++) : null,
              ),
            ],
          ),
        ]),
        const _Section('ProgressBar', [
          MuProgressBar(value: 80, label: 'Profil complété', size: MuProgressSize.m),
          SizedBox(height: MuSpace.s4),
          MuProgressBar(
            value: 6,
            max: 10,
            variant: MuProgressVariant.segmented,
            size: MuProgressSize.l,
            label: 'Places réservées',
            unit: 'places',
          ),
          SizedBox(height: MuSpace.s4),
          MuProgressBar(
            value: 6,
            max: 10,
            pending: 2,
            variant: MuProgressVariant.spots,
            size: MuProgressSize.l,
            label: 'Joueurs',
            unit: 'joueurs',
            hint: '2 places libres',
          ),
          SizedBox(height: MuSpace.s4),
          MuProgressBar(
            value: 90,
            max: 150,
            valueLabel: '90/150 DT',
            tone: MuTone.error,
            label: 'Collecte',
            hint: 'Paiement refusé pour Hamza R. Relance-le avant 18h.',
          ),
          SizedBox(height: MuSpace.s4),
          MuProgressBar(value: 45, tone: MuTone.ai, label: 'Analyse de ton niveau'),
          SizedBox(height: MuSpace.s4),
          MuProgressBar(
            indeterminate: true,
            label: 'Envoi de la photo du terrain…',
            hint: 'terrain-arena-five.jpg',
          ),
        ]),
        _Section('AiLabel', [
          Wrap(
            spacing: MuSpace.s3,
            runSpacing: MuSpace.s3,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const MuAiLabel(),
              const MuAiLabel(size: MuAiLabelSize.s),
              const MuAiLabel(variant: MuAiLabelVariant.inline, text: 'Résumé généré par l’IA'),
              Container(
                padding: const EdgeInsets.all(MuSpace.s3),
                color: c.navBg,
                child: const MuAiLabel(variant: MuAiLabelVariant.media, size: MuAiLabelSize.s),
              ),
            ],
          ),
        ]),
        _Section('Banner', [
          if (_showBanner)
            MuBanner(
              title: 'Vérifie ton email pour sécuriser ton compte',
              detail: 'Lien envoyé à yassine.b@email.tn',
              action: MuAction('Renvoyer l’email', () {}),
              onDismiss: () => setState(() => _showBanner = false),
            )
          else
            MuButton.tertiary(
              label: 'Réafficher la bannière',
              size: MuButtonSize.s,
              onPressed: () => setState(() => _showBanner = true),
            ),
          const SizedBox(height: MuSpace.s3),
          MuBanner(
            tone: MuBannerTone.error,
            title: 'Le paiement de ton abonnement a échoué',
            detail: 'Ta carte Visa •••• 4821 a été refusée le 12 oct.',
            action: MuAction('Mettre à jour la carte', () {}),
          ),
          const SizedBox(height: MuSpace.s3),
          const MuBanner(
            tone: MuBannerTone.success,
            title: 'Paiement reçu',
            detail: '15 DT · Arena Five, sam. 18 oct. · 20h00',
          ),
          const SizedBox(height: MuSpace.s3),
          const MuBanner(
            tone: MuBannerTone.warning,
            variant: MuBannerVariant.strip,
            title: 'Tu es hors ligne',
            detail: 'Données en cache du 18 oct. à 20h00',
          ),
          const SizedBox(height: MuSpace.s3),
          const MuBanner(
            tone: MuBannerTone.neutral,
            title: 'Ta progression est enregistrée',
            detail: 'Tu peux reprendre plus tard.',
          ),
        ]),
        _Section('Switch', [
          MuSwitch(
            value: _lights,
            onChanged: (v) => setState(() => _lights = v),
            label: 'Éclairage',
            description: 'Projecteurs LED pour les matchs du soir',
          ),
          const SizedBox(height: MuSpace.s3),
          MuSwitch(
            value: _lights,
            size: MuSwitchSize.s,
            onChanged: (v) => setState(() => _lights = v),
            label: 'Éclairage',
          ),
          const SizedBox(height: MuSpace.s3),
          const MuSwitch(value: true, onChanged: null, label: 'Désactivé'),
        ]),
        _Section('RadioGroup', [
          MuRadioGroup<String>(
            label: 'Type',
            horizontal: true,
            value: _courtType,
            onChanged: (v) => setState(() => _courtType = v),
            options: const [
              MuRadioOption(value: 'Extérieur', label: 'Extérieur'),
              MuRadioOption(value: 'Intérieur', label: 'Intérieur'),
            ],
          ),
        ]),
        _Section('Select', [
          MuSelect<String>(
            label: 'Surface',
            value: _surface,
            onChanged: (v) => setState(() => _surface = v),
            options: const [
              MuSelectOption(value: 'Gazon synthétique', label: 'Gazon synthétique'),
              MuSelectOption(value: 'Béton poreux', label: 'Béton poreux'),
              MuSelectOption(value: 'Résine', label: 'Résine'),
              MuSelectOption(value: 'Parquet', label: 'Parquet'),
            ],
          ),
        ]),
        _Section('StatusBadge', [
          Wrap(
            spacing: MuSpace.s2,
            runSpacing: MuSpace.s2,
            children: [
              for (final s in MuStatus.values) MuStatusBadge(status: s),
              const MuStatusBadge(
                  status: MuStatus.pending, label: 'RIB en vérification', size: MuBadgeSize.s),
            ],
          ),
        ]),
        const _Section('WizardStepper', [
          MuWizardStepper(
            label: 'Espace propriétaire · étapes',
            current: 2,
            steps: [
              MuWizardStep('Entreprise', summary: 'Arena Five SARL'),
              MuWizardStep('Adresse', summary: 'La Marsa'),
              MuWizardStep('Terrains'),
              MuWizardStep('Horaires'),
            ],
          ),
          SizedBox(height: MuSpace.s4),
          MuWizardStepper(
            label: 'Espace propriétaire · étapes',
            variant: MuStepperVariant.compact,
            current: 2,
            steps: [
              MuWizardStep('Entreprise'),
              MuWizardStep('Adresse'),
              MuWizardStep('Terrains'),
              MuWizardStep('Horaires'),
            ],
          ),
        ]),
        _Section('FileUpload', [
          MuFileUpload.dropzone(
            label: 'Attestation de RIB',
            title: 'Glisse ou choisis ton attestation',
            linkPart: 'choisis ton attestation',
            hint: 'PDF, JPG, PNG · 5 Mo max',
            onAdd: () {},
            onRemove: (_) {},
            files: const [
              MuUploadFile(id: 'a', name: 'Attestation RIB Arena Five.pdf', sizeBytes: 420000),
              MuUploadFile(
                id: 'b',
                name: 'Relevé.pdf',
                sizeBytes: 900000,
                status: MuUploadStatus.uploading,
                progress: 0.6,
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          MuFileUpload.grid(
            label: 'Tes photos',
            maxFiles: 20,
            helper: 'La 1re photo sert de couverture.',
            onAdd: () {},
            onRemove: (_) {},
            files: const [
              MuUploadFile(id: '1', name: 'Terrain 1.jpg', sizeBytes: 2400000),
              MuUploadFile(
                id: '2',
                name: 'Vestiaires.jpg',
                sizeBytes: 1800000,
                status: MuUploadStatus.uploading,
                progress: 0.4,
              ),
              MuUploadFile(
                id: '3',
                name: 'Tribune de nuit.png',
                sizeBytes: 14200000,
                status: MuUploadStatus.error,
                shortError: 'Trop lourde',
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          MuFileUpload.avatar(
            label: 'Photo de profil',
            name: 'Skander T.',
            helper: 'JPG, PNG · visage bien visible',
            onAdd: () {},
          ),
        ]),
        _Section('PricingCard', [
          MuPricingCard(
            recommended: true,
            chosen: true,
            period: _period,
            savings: '2 mois offerts',
            onCta: () => setState(() => _period = _period == MuBillingPeriod.month
                ? MuBillingPeriod.year
                : MuBillingPeriod.month),
            plan: const MuPlan(
              name: 'Pro',
              audience: 'Propriétaire',
              pitch: 'Pour les complexes de plusieurs terrains.',
              monthly: 149,
              yearly: 1490,
              features: [('Terrains illimités', true), ('Comptes gérants', false)],
            ),
          ),
        ]),
        const _Section('KpiCard', [
          MuKpiCard(
              label: 'Taux d’occupation', value: '—', note: 'Calculé dès ta première réservation'),
          SizedBox(height: MuSpace.s3),
          MuKpiCard(
            label: 'Revenus du jour',
            value: '1 240',
            unit: 'DT',
            delta: 1,
            deltaText: '+12 %',
            period: 'vs mer. dernier',
          ),
        ]),
        _Section('EmptyState', [
          MuEmptyState(
            illustration: MuEmptyIllustration.bookings,
            compact: true,
            title: 'Aucune réservation pour l’instant',
            description: 'Publie ton premier créneau : il apparaîtra aux joueurs de La Marsa.',
            actions: [
              MuButton.secondary(label: 'Ouvrir le planning', onPressed: () {}),
            ],
          ),
        ]),
        _Section('AiSuggestionCard', [
          MuAiSuggestionCard(
            context: 'Assistant programme',
            title: 'L’IA peut proposer un plan de 4 semaines à partir de ta bio',
            content: 'Rien n’est publié sans toi : tu relis et modifies chaque séance.',
            reasonLead: 'Basé sur',
            reason: 'ta bio et tes spécialités.',
            primary: MuAction('Proposer un plan', () {}),
            primaryIcon: PhosphorIcons.sparkle(),
            secondary: MuAction('Plus tard', () {}),
            onDismiss: () {},
          ),
        ]),
        const _Section('Avatar', [
          Wrap(
            spacing: MuSpace.s5,
            runSpacing: MuSpace.s4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MuAvatar(name: 'Nour A.', size: MuAvatarSize.xs),
              MuAvatar(name: 'Mariem K.', size: MuAvatarSize.s, level: 2.0),
              MuAvatar(name: 'Yassine B.', level: 3.5, online: true),
              MuAvatar(name: 'Skander T.', size: MuAvatarSize.l, level: 4.5),
              MuAvatar(name: 'Ines M.', size: MuAvatarSize.xl, level: 5.5, online: true),
            ],
          ),
        ]),
        _Section('Debug — données', [
          Consumer(
            builder: (context, ref, _) => MuSwitch(
              value: ref.watch(simulatedOfflineProvider),
              label: 'Simuler hors ligne',
              description: 'Les listes d’Explorer et de l’Accueil échouent (EXP-07).',
              icon: PhosphorIcons.wifiSlash(),
              onChanged: (v) {
                ref.read(simulatedOfflineProvider.notifier).set(v);
                ref
                  ..invalidate(exploreGamesProvider)
                  ..invalidate(exploreVenuesProvider)
                  ..invalidate(exploreTournamentsProvider)
                  ..invalidate(recommendedGamesProvider)
                  ..invalidate(nearbyVenuesProvider)
                  ..invalidate(nearbyTournamentsProvider);
              },
            ),
          ),
        ]),
        _Section('GameCard', [
          MuGameCard(game: Story.g1, variant: MuGameCardVariant.featured, onJoin: () {}),
          const SizedBox(height: MuSpace.s3),
          MuGameCard(game: Story.g2, onJoin: () {}),
          const SizedBox(height: MuSpace.s3),
          MuGameCard(game: Story.g4, onWaitlist: () {}),
          const SizedBox(height: MuSpace.s3),
          MuGameCard(game: Story.more.first, onJoin: () {}),
          const SizedBox(height: MuSpace.s3),
          MuGameCard(
            game: MuGame(
              sport: MuSport.football,
              venue: 'Arena Five',
              court: 'Terrain 2',
              place: 'La Marsa',
              start: Story.at(18, 20),
              spotsTotal: 10,
              spotsLeft: 2,
              pricePerPlayer: 15,
              players: Story.g1.players,
              status: MuGameStatus.joined,
            ),
            onView: () {},
          ),
          const SizedBox(height: MuSpace.s3),
          MuGameCard(
            game: MuGame(
              sport: MuSport.football,
              venue: 'Arena Five',
              court: 'Terrain 2',
              place: 'La Marsa',
              start: Story.at(10, 20),
              spotsTotal: 10,
              spotsLeft: 4,
              pricePerPlayer: 15,
              status: MuGameStatus.cancelled,
              refund: 15,
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          MuGameCard(game: Story.g2, variant: MuGameCardVariant.compact, onTap: () {}),
          const SizedBox(height: MuSpace.s3),
          const MuSkeletonGroup(
            child: MuGameCard.loading(variant: MuGameCardVariant.featured),
          ),
        ]),
        _Section('BookingCard', [
          MuBookingCard(booking: Story.g1Booking, onShowQr: () {}, onDirections: () {}),
          const SizedBox(height: MuSpace.s3),
          MuBookingCard(
            booking: Story.myBooking,
            variant: MuBookingCardVariant.compact,
            onShowQr: () {},
          ),
          const SizedBox(height: MuSpace.s3),
          MuBookingCard(
            booking: MuBooking(
              sport: MuSport.padel,
              venue: 'Smash Padel Club',
              court: 'Court 3',
              place: 'Lac 2',
              start: Story.at(23, 19, 30),
              end: Story.at(23, 21),
              share: 25,
              status: MuBookingStatus.pendingPayment,
              payBefore: Story.at(23, 17),
              players: const [Story.mariem, Story.ines],
            ),
            onPay: () {},
            onDirections: () {},
          ),
          const SizedBox(height: MuSpace.s3),
          MuBookingCard(
            booking: MuBooking(
              sport: MuSport.padel,
              venue: 'Smash Padel Club',
              place: 'Lac 2',
              start: Story.at(9, 19),
              end: Story.at(9, 20, 30),
              share: 20,
              status: MuBookingStatus.past,
            ),
            onRate: () {},
          ),
          const SizedBox(height: MuSpace.s3),
          MuBookingCard(
            booking: MuBooking(
              sport: MuSport.football,
              venue: 'Arena Five',
              court: 'Terrain 2',
              place: 'La Marsa',
              start: Story.at(10, 20),
              end: Story.at(10, 21),
              share: 15,
              refund: 15,
              status: MuBookingStatus.cancelled,
            ),
            onRebook: () {},
          ),
          const SizedBox(height: MuSpace.s3),
          const MuSkeletonGroup(child: MuBookingCard.loading()),
        ]),
        _Section('VenueCard', [
          MuVenueCard(
            venue: Story.arenaFive,
            favourite: _favourite,
            onFavouriteChanged: (v) => setState(() => _favourite = v),
            onSlotTap: (_) {},
          ),
          const SizedBox(height: MuSpace.s3),
          MuVenueCard(
            venue: Story.smashPadel,
            variant: MuVenueCardVariant.compact,
            favourite: _favourite,
            onFavouriteChanged: (v) => setState(() => _favourite = v),
          ),
          const SizedBox(height: MuSpace.s3),
          const MuVenueCard(
            venue: MuVenue(
              id: 'closed',
              name: 'Hoop Zone',
              sports: [MuSport.basketball],
              place: 'Ennasr',
              distanceKm: 6.2,
              rating: 4.5,
              reviews: 41,
              slots: ['8h00', '9h30'],
              slotsDay: 'Demain',
              pricePerPerson: 9,
              courtPrice: 90,
              status: MuVenueStatus.closed,
              opensAt: '8h00',
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          const MuSkeletonGroup(
            child: MuVenueCard.loading(variant: MuVenueCardVariant.compact),
          ),
        ]),
        _Section('TournamentCard', [
          MuTournamentCard(tournament: Story.padelMasters, onRegister: () {}),
          const SizedBox(height: MuSpace.s3),
          MuTournamentCard(
            tournament: Story.padelMasters,
            variant: MuTournamentCardVariant.compact,
            onTap: () {},
          ),
          const SizedBox(height: MuSpace.s3),
          const MuSkeletonGroup(child: MuTournamentCard.loading()),
        ]),
        const _Section('Skeleton', [
          MuSkeletonGroup(
            label: 'Chargement des parties',
            child: Row(
              children: [
                MuSkeleton.circle(size: MuSize.avatarM),
                SizedBox(width: MuSpace.s3),
                Expanded(child: MuSkeleton.text(lines: 2)),
                SizedBox(width: MuSpace.s3),
                MuSkeleton.pill(width: MuSize.controlXl),
              ],
            ),
          ),
        ]),
        _Section('RangeSlider', [
          MuRangeSlider(
            label: 'Prix par personne',
            values: _price,
            min: 0,
            max: 50,
            format: (v) => formatDT(v.round()),
            minLabel: 'Prix minimum',
            maxLabel: 'Prix maximum',
            onChanged: (v) => setState(() => _price = v),
          ),
          const SizedBox(height: MuSpace.s4),
          MuRangeSlider(
            label: 'Niveau des joueurs',
            values: _level,
            min: 1,
            max: 7,
            step: 0.5,
            format: formatLevel,
            bands: const [
              MuRangeBand(1, 2.5, 'Débutant'),
              MuRangeBand(2.5, 4, 'Intermédiaire'),
              MuRangeBand(4, 5.5, 'Avancé'),
              MuRangeBand(5.5, 7, 'Expert'),
            ],
            minLabel: 'Niveau minimum',
            maxLabel: 'Niveau maximum',
            onChanged: (v) => setState(() => _level = v),
          ),
        ]),
        _Section('BottomSheet', [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: MuButton.secondary(
              label: 'Ouvrir « Comment partager ? »',
              onPressed: () => MuBottomSheet.show<void>(
                context,
                title: 'Comment partager ?',
                footer: MuButton.primary(
                  label: 'Continuer',
                  price: '15 DT',
                  size: MuButtonSize.xl,
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                child: Text(
                  'Chacun paie sa part : 15 DT par personne à 10.',
                  style: MuType.body.copyWith(color: c.text),
                ),
              ),
            ),
          ),
        ]),
        _Section('MapView — Explorer', [
          SizedBox(
            height: MuSize.controlXl * 7,
            child: ClipRRect(
              borderRadius: MuRadius.mdAll,
              child: MuMapView.explore(
                center: Story.me,
                user: Story.me,
                selectedId: _pin,
                onSelect: (id) => setState(() => _pin = id),
                onOpen: (_, _) {},
                onSearchArea: (_) {},
                venues: [
                  for (final v in Story.venues)
                    MuMapVenue(
                      id: v.id,
                      name: v.name,
                      sport: v.sport,
                      position: v.position!,
                      subtitle: v.placeLabel,
                      rating: v.rating,
                      reviews: v.reviews,
                      priceFrom: v.pricePerPerson,
                      slots: v.slots,
                    ),
                ],
              ),
            ),
          ),
        ]),
        _Section('SearchField — résultats', [
          MuSearchResults<String>(
            query: 'mar',
            recent: Story.recentSearches,
            onRemoveRecent: (_) {},
            onClearRecent: () {},
            groups: [
              MuSearchGroup(
                label: 'Terrains',
                items: [
                  MuSearchSuggestion(
                    value: Story.arenaFive.id,
                    title: 'Arena Five',
                    subtitle: 'Football · La Marsa',
                  ),
                ],
              ),
            ],
          ),
        ]),
        _Section('SlotGrid', [
          MuSlotGrid(
            label: 'Créneaux Arena Five',
            start: 20 * 60,
            padding: 0,
            value: _slot2,
            onChanged: (v) => setState(() => _slot2 = v),
            courts: const [
              MuSlotCourt(
                id: 't1',
                name: 'Terrain 1',
                detail: 'Éclairé',
                slots: [
                  MuSlot(price: 150, peak: true),
                  MuSlot(price: 150, peak: true),
                  MuSlot(price: 150, peak: true),
                  MuSlot(price: 120),
                ],
              ),
              MuSlotCourt(
                id: 't2',
                name: 'Terrain 2',
                detail: 'Éclairé',
                slots: [
                  MuSlot(status: MuSlotStatus.booked),
                  MuSlot(status: MuSlotStatus.booked),
                  MuSlot(status: MuSlotStatus.mine),
                  MuSlot(price: 96, discount: 20, oldPrice: 120),
                ],
              ),
              MuSlotCourt(
                id: 't3',
                name: 'Terrain 3',
                detail: 'Indoor',
                slots: [
                  MuSlot(status: MuSlotStatus.blocked, label: 'Tournoi'),
                  MuSlot(status: MuSlotStatus.blocked, label: 'Tournoi'),
                  MuSlot(price: 150, peak: true),
                  MuSlot(status: MuSlotStatus.booked),
                ],
              ),
            ],
          ),
        ]),
        _Section('DateStrip', [
          MuDateStrip(
            start: Story.at(16, 0),
            today: Story.at(16, 0),
            value: _day,
            bleed: 0,
            availability: (d) =>
                d.day == 17 || d.day == 24 ? MuDayAvailability.soldOut : MuDayAvailability.available,
            onChanged: (d) => setState(() => _day = d),
          ),
        ]),
        _Section('Stepper', [
          MuStepper(
            label: 'Places à compléter',
            value: _spots,
            min: 1,
            max: 4,
            helper: (n) => '${6 + n} joueurs · ${formatDT(150 / (6 + n))} chacun',
            onChanged: (v) => setState(() => _spots = v),
          ),
        ]),
        _Section('StarRating', [
          const MuStarRating.display(value: 4.7, count: 128),
          const SizedBox(height: MuSpace.s3),
          MuStarRating.input(
            value: _stars.toDouble(),
            label: 'Fair-play',
            onChanged: (v) => setState(() => _stars = v),
          ),
        ]),
        _Section('ProgressBar — places', [
          MuProgressBar(
            variant: MuProgressVariant.spots,
            label: 'Paiements',
            value: 1,
            pending: 5,
            max: 10,
            people: Story.myBooking.players,
            legend: true,
          ),
        ]),
        const _Section('Takeover — billet', [
          MuTicket(
            reference: 'MU-48213',
            sport: MuSport.football,
            venue: 'Arena Five · La Marsa',
            court: 'Terrain 1',
            date: 'mer. 21 oct.',
            time: '21h00',
            players: '6/10',
            paid: '15 DT',
          ),
        ]),
        _Section('TopAppBar — large / compact / media', [
          MuTopAppBar.large(
            title: 'Mes matchs',
            actions: [
              MuBarAction(icon: PhosphorIcons.calendarPlus(), label: 'Réserver un terrain'),
            ],
          ),
          MuTopAppBar.compact(
            title: 'Ma réservation',
            subtitle: 'Réf. MU-48213',
            onBack: () {},
            actions: [MuBarAction(icon: PhosphorIcons.shareNetwork(), label: 'Partager')],
          ),
          SizedBox(
            height: 120,
            child: MuCourtArt(
              sport: MuSport.football,
              variant: MuCourtArtVariant.photo,
              child: Align(
                alignment: Alignment.topCenter,
                child: MuTopAppBar.media(
                  onBack: () {},
                  actions: [
                    MuBarAction(icon: PhosphorIcons.shareNetwork(), label: 'Partager la partie'),
                    MuBarAction(icon: PhosphorIcons.dotsThreeVertical(), label: 'Plus d’actions'),
                  ],
                ),
              ),
            ),
          ),
        ]),
        _Section('Tabs', [
          MuTabs(
            label: 'Mes matchs',
            tabs: const [MuTab('À venir', count: 3), MuTab('Passés'), MuTab('Annulés')],
            index: _tab,
            fullWidth: true,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: MuSpace.s3),
          MuTabs(
            label: 'Filtre',
            variant: MuTabsVariant.pill,
            tabs: const [MuTab('Tous'), MuTab('Foot'), MuTab('Padel')],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
        ]),
        const _Section('StatusBadge — icon-only', [
          Row(children: [
            MuStatusBadge(status: MuStatus.confirmed, label: 'Vérifié', iconOnly: true),
            SizedBox(width: MuSpace.s2),
            MuStatusBadge(status: MuStatus.paid, label: 'Payé', iconOnly: true),
            SizedBox(width: MuSpace.s2),
            MuStatusBadge(status: MuStatus.cancelled, label: 'Annulée', iconOnly: true),
          ]),
        ]),
        const _Section('ReliabilityBadge', [
          Row(children: [
            MuReliabilityBadge(score: 96),
            SizedBox(width: MuSpace.s2),
            MuReliabilityBadge(score: 82, size: MuBadgeSize.s),
            SizedBox(width: MuSpace.s2),
            MuReliabilityBadge(score: 61, size: MuBadgeSize.s),
          ]),
          SizedBox(height: MuSpace.s3),
          MuReliabilityBadge(score: 96, detail: true, honored: 47, total: 49, period: '12 mois'),
        ]),
        _Section('MatchFitScore — ring', [
          MuMatchFitScore.ring(
            value: 85,
            factors: [
              MuFitFactor(
                icon: PhosphorIcons.gauge(),
                label: 'Niveau dans la fourchette',
                detail: 'Toi 3,0 · partie 3,0–4,5',
              ),
              MuFitFactor(
                icon: PhosphorIcons.usersThree(),
                label: 'Milieu recherché',
                detail: 'Ton poste habituel',
              ),
              MuFitFactor(
                icon: PhosphorIcons.mapPin(),
                label: 'À 1,4 km',
                detail: 'Arena Five · La Marsa',
              ),
            ],
            note: 'Recommandé car Skander cherche un milieu près de chez toi. L’IA peut se tromper.',
          ),
        ]),
        _Section('Lineup', [
          MuLineup(
            sport: MuSport.football,
            teams: const [
              MuLineupTeam(
                name: 'Blancs',
                players: [
                  MuLineupPlayer('Hamza R.', level: 3.5),
                  MuLineupPlayer('Nour A.', level: 3.0),
                  null,
                  MuLineupPlayer('Skander T.', level: 4.0, role: MuLineupRole.organizer),
                  MuLineupPlayer('Salma G.', level: 3.0),
                ],
              ),
              MuLineupTeam(
                name: 'Bleus',
                players: [
                  MuLineupPlayer('Omar D.', level: 3.5),
                  MuLineupPlayer('Lina F.', level: 3.5),
                  MuLineupPlayer('Ines M.', level: 4.0),
                  MuLineupPlayer('Aziz H.', level: 4.5),
                  null,
                ],
              ),
            ],
            onJoin: (team, slot, position) => MuToast.show(
              context,
              title: 'Équipe ${team + 1} · place ${slot + 1} · $position',
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          const MuLineup(
            sport: MuSport.padel,
            variant: MuLineupVariant.compact,
            header: false,
            teams: [
              MuLineupTeam(
                name: 'Toi / Mariem',
                players: [MuLineupPlayer('Yassine B.', you: true), MuLineupPlayer('Mariem K.')],
              ),
              MuLineupTeam(name: 'Ines / Nour', players: [MuLineupPlayer('Ines M.'), null]),
            ],
          ),
        ]),
        const _Section('MatchCard', [
          MuMatchCard(
            match: MuMatch(
              sport: MuSport.football,
              status: MuMatchStatus.finished,
              round: 'Sam. 3 oct.',
              court: 'Arena Five',
              teams: [
                MuMatchTeam(
                  name: 'Blancs · ton équipe',
                  shortName: 'Toi',
                  monogram: 'BL',
                  score: 5,
                  you: true,
                ),
                MuMatchTeam(name: 'Bleus', monogram: 'BE', score: 7),
              ],
            ),
            variant: MuMatchCardVariant.compact,
          ),
          SizedBox(height: MuSpace.s3),
          MuMatchCard(
            match: MuMatch(
              sport: MuSport.padel,
              status: MuMatchStatus.finished,
              round: 'Ven. 9 oct.',
              court: 'Smash Padel Club',
              teams: [
                MuMatchTeam(
                  name: 'Yassine B. / Mariem K.',
                  shortName: 'Toi / Mariem',
                  monogram: 'YM',
                  sets: [6, 6],
                  you: true,
                ),
                MuMatchTeam(
                  name: 'Ines M. / Nour A.',
                  shortName: 'Ines / Nour',
                  monogram: 'IN',
                  sets: [4, 3],
                ),
              ],
            ),
            variant: MuMatchCardVariant.compact,
          ),
          SizedBox(height: MuSpace.s3),
          MuMatchCard(
            match: MuMatch(
              sport: MuSport.basketball,
              status: MuMatchStatus.live,
              round: 'Demi-finale',
              court: 'Hoop Zone · Terrain A',
              minute: '34’',
              competition: 'Hoop Zone 3x3 Cup',
              target: 21,
              teams: [
                MuMatchTeam(name: 'Noirs', monogram: 'NO', score: 18),
                MuMatchTeam(name: 'Oranges', monogram: 'OR', score: 16),
              ],
            ),
          ),
          SizedBox(height: MuSpace.s3),
          MuMatchCard.loading(variant: MuMatchCardVariant.compact),
        ]),
        const _Section('Scoreboard', [
          MuScoreboard(
            sport: MuSport.padel,
            status: MuMatchStatus.finished,
            date: 'ven. 9 oct.',
            venue: 'Smash Padel Club · Court 3',
            teams: [
              MuScoreTeam(name: 'Toi / Mariem K.', players: ['Toi', 'Mariem K.'], you: true),
              MuScoreTeam(name: 'Ines M. / Nour A.', players: ['Ines M.', 'Nour A.']),
            ],
            sets: [(6, 4), (6, 3)],
          ),
          SizedBox(height: MuSpace.s3),
          MuScoreboard(
            sport: MuSport.basketball,
            status: MuMatchStatus.live,
            clock: '08:12',
            period: '2e mi-temps',
            venue: 'Hoop Zone',
            teams: [MuScoreTeam(name: 'Noirs', short: 'NO'), MuScoreTeam(name: 'Oranges', short: 'OR')],
            score: (18, 16),
          ),
          SizedBox(height: MuSpace.s3),
          MuScoreboard(
            sport: MuSport.football,
            status: MuMatchStatus.finished,
            variant: MuScoreboardVariant.compact,
            date: 'sam. 3 oct.',
            teams: [
              MuScoreTeam(name: 'Blancs', short: 'BL', you: true),
              MuScoreTeam(name: 'Bleus', short: 'BE'),
            ],
            score: (5, 7),
          ),
        ]),
        _Section('Dialog', [
          Wrap(
            spacing: MuSpace.s2,
            runSpacing: MuSpace.s2,
            children: [
              MuButton.destructive(
                label: 'Annuler la réservation',
                size: MuButtonSize.s,
                onPressed: () => MuDialog.show<bool>(
                  context,
                  tone: MuDialogTone.destructive,
                  icon: PhosphorIcons.calendarX(),
                  title: 'Annuler la réservation ?',
                  description:
                      'Arena Five · Terrain 1 · mer. 21 oct. · 21h00. Les joueurs et Arena Five seront prévenus.',
                  consequence:
                      'Les 6 joueurs seront remboursés : 15 DT chacun sur leur solde MatchUp.',
                  consequenceIcon: PhosphorIcons.wallet(),
                  actions: [
                    MuButton.secondary(
                      label: 'Garder la réservation',
                      size: MuButtonSize.l,
                      fullWidth: true,
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
                    ),
                    MuButton.destructive(
                      label: 'Annuler la réservation',
                      size: MuButtonSize.l,
                      fullWidth: true,
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
                    ),
                  ],
                ),
              ),
              MuButton.secondary(
                label: 'Centré · info',
                size: MuButtonSize.s,
                onPressed: () => MuDialog.show<void>(
                  context,
                  tone: MuDialogTone.info,
                  placement: MuDialogPlacement.center,
                  title: 'Score à confirmer',
                  description:
                      'Ines et Nour confirmeront le score. Sans réponse sous 48 h, il est validé.',
                  actions: [
                    MuButton.primary(
                      label: 'Compris',
                      size: MuButtonSize.l,
                      fullWidth: true,
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ]),
        _Section('Debug — place libérée (GAM-04)', [
          Consumer(
            builder: (context, ref, _) => MuButton.primary(
              label: 'Simuler une place libérée',
              leading: PhosphorIcons.hourglassMedium(),
              size: MuButtonSize.m,
              onPressed: () => showClaimTakeover(context, ref, Story.g1.id!),
            ),
          ),
          const SizedBox(height: MuSpace.s2),
          Text(
            'Ouvre le takeover GAM-04 sur G1 avec un vrai compte à rebours de 15 min ; '
            '« Réclamer la place » paie la part et ouvre GAM-05.',
            style: MuType.caption.copyWith(color: c.textSecondary),
          ),
        ]),
        _Section('Spinner', [
          Row(children: [
            MuSpinner(size: MuSize.iconXs, color: c.text),
            const SizedBox(width: MuSpace.s4),
            MuSpinner(size: MuSize.iconM, color: c.text, semanticLabel: 'Chargement'),
          ]),
        ]),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsets.only(bottom: MuSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title.toUpperCase(), style: MuType.overline.copyWith(color: c.textSecondary)),
          const SizedBox(height: MuSpace.s3),
          ...children,
        ],
      ),
    );
  }
}
