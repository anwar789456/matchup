import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../../training/data/training_story.dart';
import '../coach_routes.dart';
import '../controllers/coach_providers.dart';
import '../data/coach_models.dart';
import '../data/coach_story.dart';
import 'builder_screen.dart';

enum _View { player, premium }

/// COA-08 · Prix et publication: how players get the program (sold, in Premium), the price with
/// the AI's advice and what the coach receives, the preview, the checklist, when to publish.
class PublishScreen extends ConsumerStatefulWidget {
  const PublishScreen({super.key});

  @override
  ConsumerState<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends ConsumerState<PublishScreen> {
  TextEditingController? _price;
  _View _view = _View.player;

  // COA-08: the AI's price range for a 4-week padel program around Lac 2.
  static const num _adviceMin = 30;
  static const num _adviceMax = 40;

  CoachDraftController get _ctl => ref.read(coachDraftProvider.notifier);

  @override
  void dispose() {
    _price?.dispose();
    super.dispose();
  }

  num? get _priceValue => num.tryParse((_price?.text ?? '').replaceAll(',', '.').trim());

  Future<void> _finish({required bool schedule}) async {
    final p = _priceValue;
    await _ctl.edit(
      (d) => d.copyWith(
        price: p ?? d.price,
        priceSet: true,
        status: schedule ? DraftStatus.scheduled : d.status,
      ),
    );
    if (!mounted) return;
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: schedule ? l10n.coaPublishScheduled : l10n.coaDraftSavedToast,
      description: schedule ? l10n.coaPublishScheduledText : null,
    );
    context.go(CoachRoutes.programs);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final d = ref.watch(coachDraftProvider).value;
    void back() => context.canPop() ? context.pop() : context.go(CoachRoutes.builder);
    if (d == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Column(
          children: [
            MuTopAppBar.compact(title: l10n.coaPriceTitle, onBack: back),
            const Expanded(child: Center(child: MuSpinner())),
          ],
        ),
      );
    }
    _price ??= TextEditingController(text: formatAmount(d.price));
    final price = _priceValue ?? 0;
    final commission = price * CoachStory.commission;
    final net = price - commission;
    final processing = d.sessions.where((s) => s.processing).toList();
    final premiumView = _view == _View.premium && d.premium;
    final now = ref.watch(clockProvider)();

    Widget section(String title, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.only(bottom: MuSpace.s3),
      child: Row(
        children: [
          Expanded(
            child: Semantics(header: true, child: Text(title, style: MuType.h3.copyWith(color: c.text))),
          ),
          ?trailing,
        ],
      ),
    );

    Widget line(String label, String value, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: (strong ? MuType.label : MuType.body).copyWith(color: strong ? c.text : c.textSecondary),
            ),
          ),
          Text(value, style: (strong ? MuType.numM : MuType.numS).copyWith(color: c.text)),
        ],
      ),
    );

    final checks = <(MuTone, IconData, String, String, VoidCallback?)>[
      (MuTone.success, PhosphorIcons.check(), l10n.coaCheckBasics, l10n.coaCheckBasicsOk, null),
      (
        MuTone.success,
        PhosphorIcons.sealCheck(),
        l10n.entVerifiedCoach,
        l10n.coaCheckCoachOk(TrainingStory.karim.certification ?? ''),
        null,
      ),
      if (processing.isNotEmpty)
        (
          MuTone.warning,
          PhosphorIcons.hourglassMedium(),
          l10n.coaCheckVideos(processing.length),
          l10n.coaCheckVideosDetail(d.numberOf(processing.first)),
          null,
        ),
      if (d.missingSessions > 0)
        (
          MuTone.warning,
          PhosphorIcons.warning(),
          l10n.coaCheckSessions(d.missingSessions),
          l10n.coaCheckSessionsDetail(d.weeks.length, d.sessionCount, d.targetSessions),
          () => context.canPop() ? context.pop() : context.go(CoachRoutes.builder),
        ),
    ];

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          CoachPageHeader(
            title: l10n.coaPriceTitle,
            saved: l10n.coaDraftOf(d.title),
            onBack: back,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s2),
            child: MuStepIndicator(step: 2, total: 2, title: l10n.coaPriceTitle, showLabel: true),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s4, MuSpace.s6),
              children: [
                section(l10n.coaHowPlayersGetIt),
                MuCardSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MuSwitch(
                        value: d.sell,
                        labelAtStart: true,
                        label: l10n.coaSell,
                        description: l10n.coaSellDetail,
                        onChanged: (v) => _ctl.edit((d) => d.copyWith(sell: v)),
                      ),
                      if (d.sell) ...[
                        const SizedBox(height: MuSpace.s3),
                        MuTextField(
                          label: l10n.coaPriceForStudent,
                          controller: _price,
                          suffixText: dtUnit,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
                          onChanged: (_) => setState(() {}),
                        ),
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
                                  Text(
                                    l10n.coaAdvisedPrice(ltr('${formatAmount(_adviceMin)} – ${formatDT(_adviceMax)}')),
                                    style: MuType.label.copyWith(color: c.text),
                                  ),
                                ],
                              ),
                              const SizedBox(height: MuSpace.s1),
                              Text(
                                l10n.coaAdvisedPriceWhy(
                                  CoachStory.zone,
                                  ltr('${formatLevel(d.levelMin)} – ${formatLevel(d.levelMax)}'),
                                ),
                                style: MuType.caption.copyWith(color: c.text),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: MuSpace.s3),
                        Semantics(
                          container: true,
                          label: l10n.coaWhatYouGet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3),
                            decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
                            child: Column(
                              children: [
                                line(l10n.coaPricePaid, formatDT(price)),
                                Divider(height: 1, thickness: 1, color: c.border),
                                line(
                                  l10n.coaCommission((CoachStory.commission * 100).round()),
                                  '−${formatDT(commission)}',
                                ),
                                Divider(height: 1, thickness: 1, color: c.border),
                                line(l10n.coaYouGetPerSale, formatDT(net), strong: true),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: MuSpace.s3),
                      Divider(height: 1, thickness: 1, color: c.border),
                      const SizedBox(height: MuSpace.s3),
                      MuSwitch(
                        value: d.premium,
                        labelAtStart: true,
                        label: l10n.coaInPremium,
                        description: l10n.coaInPremiumDetail,
                        onChanged: (v) => _ctl.edit((d) => d.copyWith(premium: v)),
                      ),
                      if (!d.sell && !d.premium) ...[
                        const SizedBox(height: MuSpace.s2),
                        Text(l10n.coaNoAccess, style: MuType.caption.copyWith(color: c.errorText)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s6),
                section(
                  l10n.coaPreview,
                  trailing: MuSegmentedControl<_View>(
                    semanticLabel: l10n.coaSeenBy,
                    size: MuSegmentedSize.s,
                    value: _view,
                    onChanged: (v) => setState(() => _view = v),
                    segments: [
                      MuSegment(value: _View.player, label: l10n.coaPlayer),
                      MuSegment(value: _View.premium, label: l10n.entPremium, icon: PhosphorIcons.crownSimple()),
                    ],
                  ),
                ),
                MuProgramCard(
                  program: MuProgram(
                    id: d.id,
                    title: d.title,
                    coach: TrainingStory.karim.ref,
                    sport: d.sport,
                    level: ((d.levelMin + d.levelMax) / 2 * 2).round() / 2,
                    weeks: d.weeks.length,
                    sessions: d.targetSessions,
                    minutesPerDay: d.sessionCount == 0
                        ? 0
                        : (d.sessions.fold<int>(0, (a, s) => a + s.minutes) / d.sessionCount).round(),
                    rating: 0,
                    reviews: 0,
                    price: d.sell ? price : 0,
                    premium: premiumView || (!d.sell && d.premium),
                  ),
                ),
                const SizedBox(height: MuSpace.s2),
                Text(
                  premiumView ? l10n.coaPreviewPremium : l10n.coaPreviewNoRating,
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: MuSpace.s6),
                section(l10n.coaBeforeOnline),
                MuCardSurface(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (i, (tone, icon, title, detail, onFix)) in checks.indexed) ...[
                        if (i > 0) Divider(height: 1, thickness: 1, color: c.border),
                        Padding(
                          padding: const EdgeInsets.all(MuSpace.s4),
                          child: Row(
                            children: [
                              Container(
                                width: MuSize.controlS,
                                height: MuSize.controlS,
                                decoration: BoxDecoration(color: tone.soft(c), shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: Icon(icon, size: MuSize.iconXs, color: tone.text(c)),
                              ),
                              const SizedBox(width: MuSpace.s3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: MuType.label.copyWith(color: c.text)),
                                    Text(detail, style: MuType.caption.copyWith(color: c.textSecondary)),
                                  ],
                                ),
                              ),
                              if (onFix != null)
                                MuButton.secondary(label: l10n.coaComplete, size: MuButtonSize.s, onPressed: onFix),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s6),
                section(l10n.coaWhenPublish),
                MuRadioGroup<PublishWhen>(
                  label: l10n.coaPublishDate,
                  value: d.when,
                  onChanged: (v) => _ctl.edit((d) => d.copyWith(when: v)),
                  options: [
                    MuRadioOption(
                      value: PublishWhen.ready,
                      label: l10n.coaWhenReady,
                      description: l10n.coaWhenReadyDetail(d.targetSessions),
                    ),
                    MuRadioOption(
                      value: PublishWhen.date,
                      label: formatDateTime(d.publishDate ?? now.add(const Duration(days: 10))),
                      description: l10n.coaWhenDateDetail,
                    ),
                  ],
                ),
              ],
            ),
          ),
          StickyActionBar(
            children: [
              MuButton.primary(
                label: l10n.coaSchedulePublish,
                leading: PhosphorIcons.calendarCheck(),
                size: MuButtonSize.xl,
                fullWidth: true,
                onPressed: !d.sell && !d.premium ? null : () => _finish(schedule: true),
              ),
              MuButton.tertiary(
                label: l10n.coaSaveDraft,
                size: MuButtonSize.l,
                fullWidth: true,
                onPressed: () => _finish(schedule: false),
              ),
              Text(
                l10n.coaCommissionLine((CoachStory.commission * 100).round()),
                textAlign: TextAlign.center,
                style: MuType.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
