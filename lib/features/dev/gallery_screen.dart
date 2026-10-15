import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../theme/theme.dart';
import '../../ui/ui.dart';

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
