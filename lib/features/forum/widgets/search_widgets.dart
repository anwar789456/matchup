import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/forum_providers.dart';
import '../controllers/messages_providers.dart';
import '../data/forum_repository.dart';
import '../data/messages_repository.dart';
import 'chat_format.dart';
import 'forum_actions.dart';
import 'forum_format.dart';

// ── FRM-02: the game short of players ───────────────────────────────────────────────────────

/// Where the story plays, one tap to fill the place.
const _places = ['Arena Five', 'Smash Padel Club', 'Hoop Zone'];

/// Sport, place, day and time, how many players, level range, price per player.
class SearchFields extends StatefulWidget {
  const SearchFields({super.key, required this.initial, required this.now, required this.onChanged});

  final PlayerSearch initial;
  final DateTime now;
  final ValueChanged<PlayerSearch> onChanged;

  /// A new « Cherche joueurs »: football tomorrow at 20h, 2 players, any level.
  static PlayerSearch starting(DateTime now, MuSport? sport) => PlayerSearch(
    sport: sport ?? MuSport.football,
    place: '',
    at: DateTime(now.year, now.month, now.day + 1, _defaultHour),
    needed: 2,
  );

  static const int _defaultHour = 20;

  @override
  State<SearchFields> createState() => _SearchFieldsState();
}

class _SearchFieldsState extends State<SearchFields> {
  late PlayerSearch _r = widget.initial;
  late final _place = TextEditingController(text: widget.initial.place);
  late final _price = TextEditingController(text: widget.initial.price == null ? '' : formatAmount(widget.initial.price!));
  late bool _anyLevel = widget.initial.levelMin == null && widget.initial.levelMax == null;

  static const int _days = 7;
  static const _hours = [8, 10, 12, 14, 16, 17, 18, 19, 20, 21, 22];
  static const double _levelFloor = 1;
  static const double _levelTop = 7;
  static const double _levelStep = 0.5;
  static const int _priceMax = 6;

  static final _bands = [
    MuRangeBand(1, 2.5, l10n.debutant),
    MuRangeBand(2.5, 4, l10n.intermediaire),
    MuRangeBand(4, 5.5, l10n.avance),
    MuRangeBand(5.5, 7, l10n.expert),
  ];

  @override
  void dispose() {
    _place.dispose();
    _price.dispose();
    super.dispose();
  }

  void _set(PlayerSearch r) {
    setState(() => _r = r);
    widget.onChanged(r);
  }

  PlayerSearch _with({
    MuSport? sport,
    String? place,
    DateTime? at,
    int? needed,
    double? Function()? levelMin,
    double? Function()? levelMax,
    double? Function()? price,
  }) => PlayerSearch(
    sport: sport ?? _r.sport,
    place: place ?? _r.place,
    at: at ?? _r.at,
    needed: needed ?? _r.needed,
    levelMin: levelMin != null ? levelMin() : _r.levelMin,
    levelMax: levelMax != null ? levelMax() : _r.levelMax,
    price: price != null ? price() : _r.price,
  );

  DateTime _day(int offset) => DateTime(widget.now.year, widget.now.month, widget.now.day + offset);

  int get _dayOffset {
    final d = DateTime(_r.at.year, _r.at.month, _r.at.day);
    return d.difference(_day(0)).inDays.clamp(0, _days - 1);
  }

  String _dayLabel(int offset) => switch (offset) {
    0 => l10n.msgAujourdhui,
    1 => l10n.msgDemain,
    _ => formatDay(_day(offset)),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final past = !_r.at.isAfter(widget.now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MuFieldLabel(label: l10n.msgSport),
        const SizedBox(height: MuSpace.s2),
        Wrap(
          spacing: MuSpace.s2,
          runSpacing: MuSpace.s2,
          children: [
            for (final s in MuSport.values) MuChip.sport(s, selected: s == _r.sport, onSelected: (_) => _set(_with(sport: s))),
          ],
        ),
        const SizedBox(height: MuSpace.s4),
        MuTextField(
          label: l10n.msgLieu,
          controller: _place,
          placeholder: l10n.msgLieuPlaceholder,
          leadingIcon: PhosphorIcons.mapPin(),
          onChanged: (v) => _set(_with(place: v)),
        ),
        const SizedBox(height: MuSpace.s2),
        Wrap(
          spacing: MuSpace.s2,
          runSpacing: MuSpace.s2,
          children: [
            for (final p in _places)
              MuChip(
                label: p,
                size: MuChipSize.s,
                selected: _place.text == p,
                onSelected: (_) {
                  _place.text = p;
                  _set(_with(place: p));
                },
              ),
          ],
        ),
        const SizedBox(height: MuSpace.s4),
        MuFieldLabel(label: l10n.msgQuand),
        const SizedBox(height: MuSpace.s2),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var d = 0; d < _days; d++)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: MuSpace.s2),
                  child: MuChip(
                    kind: MuChipKind.choice,
                    label: _dayLabel(d),
                    selected: d == _dayOffset,
                    onSelected: (_) => _set(_with(at: _day(d).add(Duration(hours: _r.at.hour)))),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: MuSpace.s2),
        Wrap(
          spacing: MuSpace.s2,
          runSpacing: MuSpace.s2,
          children: [
            for (final h in _hours)
              MuChip(
                kind: MuChipKind.choice,
                label: formatHour(h * Duration.minutesPerHour),
                selected: h == _r.at.hour,
                onSelected: (_) => _set(_with(at: _day(_dayOffset).add(Duration(hours: h)))),
              ),
          ],
        ),
        if (past) ...[
          const SizedBox(height: MuSpace.s2),
          Text(l10n.msgHeurePassee, style: MuType.caption.copyWith(color: c.errorText)),
        ],
        const SizedBox(height: MuSpace.s5),
        MuStepper(
          label: l10n.cjJoueursRecherches,
          value: _r.needed,
          min: 1,
          max: 10,
          unit: l10n.cjJoueursUnit(_r.needed),
          decrementLabel: l10n.cjUnJoueurDeMoins,
          incrementLabel: l10n.cjUnJoueurDePlus,
          onChanged: (n) => _set(_with(needed: n)),
        ),
        const SizedBox(height: MuSpace.s5),
        MuSwitch(
          label: l10n.cjTousNiveaux,
          value: _anyLevel,
          onChanged: (on) {
            setState(() => _anyLevel = on);
            _set(on ? _with(levelMin: () => null, levelMax: () => null) : _with(levelMin: () => 2.5, levelMax: () => 4.5));
          },
        ),
        if (!_anyLevel) ...[
          const SizedBox(height: MuSpace.s3),
          MuRangeSlider(
            label: l10n.niveauDesJoueurs,
            values: RangeValues(_r.levelMin ?? 2.5, _r.levelMax ?? 4.5),
            min: _levelFloor,
            max: _levelTop,
            step: _levelStep,
            format: formatLevel,
            formatRange: (lo, hi) => '${formatLevel(lo)} – ${formatLevel(hi)}',
            bands: _bands,
            minLabel: l10n.niveauMinimum,
            maxLabel: l10n.niveauMaximum,
            onChanged: (v) => _set(_with(levelMin: () => v.start, levelMax: () => v.end)),
          ),
        ],
        const SizedBox(height: MuSpace.s5),
        MuTextField(
          label: l10n.cjPrixParJoueur,
          controller: _price,
          optional: true,
          placeholder: l10n.cjPrixParJoueurPlaceholder,
          suffixText: dtUnit,
          maxLength: _priceMax,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) {
            final p = double.tryParse(v.replaceAll(',', '.').trim());
            _set(_with(price: () => p == null || p <= 0 ? null : p));
          },
        ),
      ],
    );
  }
}

// ── The card and FRM-04 ─────────────────────────────────────────────────────────────────────

/// What a « Cherche joueurs » shows: « Cherche 2 joueurs », the day and time, the place, the
/// level and price, the places bar, the reader's level check, and « Je viens ».
class SearchSummary extends StatelessWidget {
  const SearchSummary({super.key, required this.search, required this.now, required this.mine, this.myLevel, this.onJoin, this.onLeave});

  final PlayerSearch search;
  final DateTime now;

  /// The reader organises it.
  final bool mine;
  final double? myLevel;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final r = search;
    final details = [
      if (r.levelMin != null || r.levelMax != null)
        l10n.cjNiveauX('${formatLevel(r.levelMin ?? 1)} – ${formatLevel(r.levelMax ?? 7)}')
      else
        l10n.cjTousNiveaux,
      if (r.price != null) l10n.cjPrixX(formatDT(r.price!)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            MuSportIcon(r.sport, size: MuSize.iconS),
            const SizedBox(width: MuSpace.s2),
            Expanded(
              child: Text(
                r.full ? l10n.cjEquipeComplete : l10n.cjChercheNJoueurs(r.left),
                style: MuType.label,
              ),
            ),
            _StatusBadge(search: r, now: now),
          ],
        ),
        const SizedBox(height: MuSpace.s2),
        _Line(icon: PhosphorIcons.calendarBlank(), text: formatDateTime(r.at)),
        _Line(icon: PhosphorIcons.mapPin(), text: r.place),
        _Line(icon: PhosphorIcons.chartLineUp(), text: details.join(' · ')),
        const SizedBox(height: MuSpace.s3),
        MuProgressBar(
          variant: MuProgressVariant.spots,
          value: r.players.length.toDouble().clamp(0, r.needed.toDouble()),
          max: r.needed.toDouble(),
          label: l10n.cjJoueursTrouves,
          valueLabel: l10n.cjNSurM(r.players.length.clamp(0, r.needed), r.needed),
          hint: r.waiting.isEmpty ? null : l10n.cjNEnAttente(r.waiting.length),
          people: [for (final p in r.players) MuPerson(p.name, imageUrl: p.imageUrl)],
          size: MuProgressSize.s,
        ),
        if (!mine && r.open(now)) ...[
          const SizedBox(height: MuSpace.s3),
          if (!r.fits(myLevel) && r.status == SearchStatus.out)
            Padding(
              padding: const EdgeInsets.only(bottom: MuSpace.s2),
              child: Row(
                children: [
                  Icon(PhosphorIcons.warning(), size: MuSize.iconXs, color: c.warningText),
                  const SizedBox(width: MuSpace.s1),
                  Expanded(
                    child: Text(l10n.cjHorsNiveau(formatLevel(myLevel!)), style: MuType.caption.copyWith(color: c.warningText)),
                  ),
                ],
              ),
            )
          else if (myLevel != null && r.status == SearchStatus.out && (r.levelMin != null || r.levelMax != null))
            Padding(
              padding: const EdgeInsets.only(bottom: MuSpace.s2),
              child: Row(
                children: [
                  Icon(PhosphorIcons.checkCircle(), size: MuSize.iconXs, color: c.successText),
                  const SizedBox(width: MuSpace.s1),
                  Text(l10n.cjTonNiveauCorrespond(formatLevel(myLevel!)), style: MuType.caption.copyWith(color: c.successText)),
                ],
              ),
            ),
          switch (r.status) {
            SearchStatus.out => MuButton.primary(
              label: r.full ? l10n.cjListeDAttente : l10n.cjJeViens,
              leading: r.full ? PhosphorIcons.hourglass() : PhosphorIcons.handWaving(),
              fullWidth: true,
              onPressed: onJoin,
            ),
            SearchStatus.playing => MuButton.secondary(
              label: l10n.cjTuJoues,
              leading: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
              fullWidth: true,
              onPressed: onLeave,
            ),
            SearchStatus.waiting => MuButton.secondary(
              label: l10n.cjEnAttenteN(r.waitingRank ?? 1),
              leading: PhosphorIcons.hourglass(),
              fullWidth: true,
              onPressed: onLeave,
            ),
          },
        ],
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsets.only(top: MuSpace.s1),
      child: Row(
        children: [
          Icon(icon, size: MuSize.iconXs, color: c.textSecondary),
          const SizedBox(width: MuSpace.s2),
          Expanded(child: Text(text, style: MuType.body.copyWith(color: c.textSecondary))),
        ],
      ),
    );
  }
}

/// « Ouverte », « Complet », « Fermée », « Terminé ».
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.search, required this.now});

  final PlayerSearch search;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final r = search;
    final (status, label) = r.past(now)
        ? (MuStatus.neutral, l10n.cjTermine)
        : r.closed
        ? (MuStatus.cancelled, l10n.cjFermee)
        : r.full
        ? (MuStatus.full, l10n.cjComplet)
        : (MuStatus.confirmed, l10n.cjOuverte);
    return MuStatusBadge(status: status, label: label, size: MuBadgeSize.s);
  }
}

/// FRM-04 under the post: who plays, who waits, and the organiser's actions — « Créer le groupe »
/// with the players, « Fermer la recherche » / « Rouvrir ».
class SearchPanel extends ConsumerWidget {
  const SearchPanel({super.key, required this.post, required this.onRun, required this.onJoin, required this.onLeave});

  final ForumPost post;
  final Future<void> Function(Future<void> Function()) onRun;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  Future<void> _group(BuildContext context, WidgetRef ref) async {
    final r = post.search!;
    final chat = ref.read(messagesRepositoryProvider);
    final router = GoRouter.of(context);
    final ids = [for (final p in r.players) p.id];
    final String id;
    if (ids.length == 1) {
      id = await chat.openDirect(ids.single);
    } else {
      id = await chat.createGroup(l10n.cjNomDuGroupe(r.place.split('·').first.trim(), chatDayLabel(r.at, ref.read(clockProvider)())), ids);
    }
    await chat.sendMatch(id, ChatMatchDraft(sport: r.sport, place: r.place, at: r.at));
    ref.read(messagesChangesProvider.notifier).bump();
    router.push(Routes.chat(id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final r = post.search!;
    final now = ref.read(clockProvider)();
    final me = ref.watch(forumMeProvider).value;
    final mine = post.mine.author;
    return Container(
      padding: const EdgeInsets.all(MuSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.lgAll,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchSummary(search: r, now: now, mine: mine, myLevel: me?.level, onJoin: onJoin, onLeave: onLeave),
          const SizedBox(height: MuSpace.s4),
          Text(l10n.cjJoueurs, style: MuType.labelS.copyWith(color: c.textSecondary)),
          const SizedBox(height: MuSpace.s2),
          _Person(author: post.author, note: l10n.cjOrganisateur),
          for (final p in r.players) _Person(author: p, note: p.id == me?.id ? l10n.forumToi : null),
          for (var i = 0; i < r.left; i++) _FreeSpot(),
          if (r.waiting.isNotEmpty) ...[
            const SizedBox(height: MuSpace.s3),
            Text(l10n.cjListeDAttente, style: MuType.labelS.copyWith(color: c.textSecondary)),
            const SizedBox(height: MuSpace.s2),
            for (final (i, p) in r.waiting.indexed) _Person(author: p, note: l10n.cjNieme(i + 1)),
          ],
          if (mine) ...[
            const SizedBox(height: MuSpace.s4),
            if (r.players.isNotEmpty)
              MuButton.primary(
                label: l10n.cjCreerLeGroupe,
                leading: PhosphorIcons.chatsCircle(),
                fullWidth: true,
                onPressed: () => onRun(() => _group(context, ref)),
              ),
            if (!r.past(now)) ...[
              const SizedBox(height: MuSpace.s2),
              MuButton.secondary(
                label: r.closed ? l10n.cjRouvrir : l10n.cjFermerLaRecherche,
                leading: r.closed ? PhosphorIcons.lockOpen() : PhosphorIcons.lock(),
                fullWidth: true,
                onPressed: () => onRun(() async {
                  await ref.read(forumRepositoryProvider).closeSearch(post.id, closed: !r.closed);
                  ref.read(forumChangesProvider.notifier).bump();
                  if (context.mounted) {
                    MuToast.show(context, tone: MuToastTone.success, title: r.closed ? l10n.cjRechercheRouverte : l10n.cjRechercheFermeeToast);
                  }
                }),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Person extends StatelessWidget {
  const _Person({required this.author, this.note});

  final ForumAuthor author;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
      child: Row(
        children: [
          MuAvatar(name: author.name, imageUrl: author.imageUrl, level: author.level, size: MuAvatarSize.s),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(author.name, style: MuType.label),
                if (author.level != null) Text(forumAuthorLevel(author), style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
          if (note != null) Text(note!, style: MuType.labelS.copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }
}

class _FreeSpot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
      child: Row(
        children: [
          Container(
            width: MuSize.avatarS,
            height: MuSize.avatarS,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.borderStrong)),
            child: Icon(PhosphorIcons.plus(), size: MuSize.iconXs, color: c.textSecondary),
          ),
          const SizedBox(width: MuSpace.s3),
          Text(l10n.cjPlaceLibre, style: MuType.body.copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }
}

/// « Je viens » / « Je ne viens plus » from a card or FRM-04, with the outcome as a toast.
Future<void> toggleSearch(BuildContext context, WidgetRef ref, ForumPost post) async {
  final repo = ref.read(forumRepositoryProvider);
  final r = post.search!;
  try {
    if (r.status == SearchStatus.out) {
      final status = await repo.join(post.id);
      ref.read(forumChangesProvider.notifier).bump();
      if (!context.mounted) return;
      MuToast.show(
        context,
        tone: MuToastTone.success,
        title: status == SearchStatus.playing ? l10n.cjTuEsDansLEquipe : l10n.cjTuEsSurLaListe,
        description: status == SearchStatus.playing ? l10n.cjTuEsDansLEquipeDetail(post.author.name, formatDateTime(r.at)) : null,
      );
    } else {
      final ok = await MuDialog.show<bool>(
        context,
        tone: MuDialogTone.destructive,
        title: l10n.cjTuNeViensPlusQ,
        description: r.waiting.isNotEmpty && r.status == SearchStatus.playing ? l10n.cjTaPlaceIraA(r.waiting.first.name) : l10n.cjTaPlaceSeLibere,
        actions: [
          Builder(
            builder: (context) => MuButton.secondary(
              label: l10n.annuler,
              fullWidth: true,
              size: MuButtonSize.l,
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
            ),
          ),
          Builder(
            builder: (context) => MuButton.destructive(
              label: l10n.cjJeNeViensPlus,
              fullWidth: true,
              size: MuButtonSize.l,
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            ),
          ),
        ],
      );
      if (ok != true) return;
      await repo.leave(post.id);
      ref.read(forumChangesProvider.notifier).bump();
      if (context.mounted) MuToast.show(context, tone: MuToastTone.info, title: l10n.cjTuNeViensPlus);
    }
  } catch (e) {
    if (context.mounted) showForumError(context, e);
  }
}
