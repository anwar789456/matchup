import '../../../l10n/l10n.dart';
import 'forum_models.dart';

/// The forum's "AI" on the phone, the same rules as the backend (backend/apps/forum/src/ia/
/// ia.logic.ts): toxicity / spam score with the passages to highlight (FRM-03), a calmer rewrite
/// when one can be made, tag suggestions (FRM-02) and similar discussions. Rule-based French and
/// Tunisian derja; it never hides anything by itself.
abstract final class ForumAi {
  /// Lower case, accents and curly apostrophes removed, one character for one character, so an
  /// index in the normalised text is the same index in the original.
  static String normalize(String text) {
    final out = StringBuffer();
    for (final unit in text.codeUnits) {
      final ch = String.fromCharCode(unit);
      out.write(_fold[ch] ?? ch.toLowerCase());
    }
    return out.toString();
  }

  static const _fold = {
    '’': "'",
    '‘': "'",
    'ʼ': "'",
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'á': 'a',
    'À': 'a',
    'Â': 'a',
    'Ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'É': 'e',
    'È': 'e',
    'Ê': 'e',
    'Ë': 'e',
    'î': 'i',
    'ï': 'i',
    'Î': 'i',
    'Ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'Ô': 'o',
    'Ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'Ù': 'u',
    'Û': 'u',
    'Ü': 'u',
    'ç': 'c',
    'Ç': 'c',
    'œ': 'o',
    'Œ': 'o',
    'ÿ': 'y',
  };

  static final _stop =
      ('a au aux avec ce ces c ca cela cet cette d dans de des du elle en es est et etre eux il ils '
              'j je l la le les leur lui m ma mais me meme mes moi mon n ne ni nos notre nous on ou par pas '
              'pour qu que qui quoi s sa se ses si son sur t ta te tes toi ton tu un une vos votre vous y '
              'quel quelle quels quelles comment ai as avez avons ont suis sont fait faire bien tres '
              'plus moins aussi alors donc car comme chez entre sans sous apres avant')
          .split(' ')
          .toSet();

  /// Meaningful words, accents removed, light plural stemming.
  static List<String> keywords(String text) => [
    for (final w in normalize(text).split(RegExp('[^a-z0-9]+')))
      if (w.length > 1 && !_stop.contains(w)) w.length > 4 && RegExp(r'[sx]$').hasMatch(w) ? w.substring(0, w.length - 1) : w,
  ];

  // ── Toxicity and spam ─────────────────────────────────────────────────────────────────────

  static final _strong = [
    RegExp(r"\b(connard|connasse|salope|pute|encule|enculer|fdp|fils de pute|ntm|nique ta|niquer|batard|tafiole|pd)\b"),
    RegExp(r'\b(zebi|zabi|nayek|nik ommek|mnayek|kahba|9a7ba|miboun|t7a7na|zamel)\b'),
    RegExp(r'\bta gueule\b|\bva te faire\b|\bferme[- ]la\b'),
  ];

  static final _mild = [
    (
      RegExp(
        r"\b(t'?es|tu es|vous etes|t'?etais|c'?est un|quel|espece d'?|sale)\s+(vraiment\s+|trop\s+|completement\s+|grave\s+)?(nul|nulle|nuls|idiot|idiote|debile|abruti|cretin|imbecile|bouffon|boufon|naze|nase|teube|clown|guignol|mahboul|bhim|tache|loser|minable|pathetique|ridicule|incapable)\b",
      ),
      0.62,
    ),
    (RegExp(r'\b(idiot|debile|abruti|cretin|imbecile|bouffon|guignol|minable|pathetique|mahboul|bhim)s?\b'), 0.55),
  ];

  static final _aggressive = [
    RegExp(r"\bt'?as jamais\b"),
    RegExp(r'\barrete de (raconter|dire|parler|poster)\b'),
    RegExp(r"\bn'?importe quoi\b"),
    RegExp(r"\btu (n'?y )?connais rien\b|\btu sais (meme )?pas\b"),
    RegExp(r'\btout le monde sait (ca|que)\b'),
    RegExp(r"\bc'?est (une )?(blague|honte)\b"),
    RegExp(r'\b(achetes|vendus|corrompus|truques)\b'),
  ];

  static final _spam = [
    (RegExp(r'\b(vends?|vente|a vendre|promo|promotion|pas cher|prix (cass|imbat)\w*|soldes?|livraison)\b'), 0.3),
    (
      RegExp(r'\b(lien en bio|en bio|ecris[- ]moi en (prive|mp|dm)|en (mp|dm|prive)|contacte[- ]moi|whatsapp|insta(gram)?|telegram)\b'),
      0.35,
    ),
    (RegExp(r'(https?://|www\.)\S+|\b\S+\.(com|tn|net|shop|store|fr)\b'), 0.4),
    (RegExp(r'!{2,}|\b(gratuit|offre|code promo)\b'), 0.12),
  ];

  static final _contact = [
    RegExp(r'(\+?216[\s.]?)?\b[2-9]\d[\s.]?\d{3}[\s.]?\d{3}\b'),
    RegExp(r'\b[2-9]\d[\s.]?[•*x]{2,}'),
    RegExp(r'[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}'),
  ];

  static final _aimed = RegExp(r"\b(t'?es|tu es|toi|t'?as|ton|ta|tes|vous etes)\b");

  static ({double weight, double sum, List<TextExcerpt> hits}) _find(List<(RegExp, double)> rules, String text) {
    var weight = 0.0;
    var sum = 0.0;
    final hits = <TextExcerpt>[];
    for (final (re, w) in rules) {
      final matches = re.allMatches(text).where((m) => m.end > m.start).toList();
      if (matches.isEmpty) continue;
      hits.addAll([for (final m in matches) TextExcerpt(m.start, m.end)]);
      weight = (weight > w ? weight : w) + (weight > 0 ? w * 0.25 : 0);
      sum += w;
    }
    return (weight: weight, sum: sum, hits: hits);
  }

  static List<TextExcerpt> _merge(List<TextExcerpt> hits) {
    final sorted = [...hits]..sort((a, b) => a.start.compareTo(b.start));
    final out = <TextExcerpt>[];
    for (final h in sorted) {
      if (out.isNotEmpty && h.start <= out.last.end) {
        final last = out.removeLast();
        out.add(TextExcerpt(last.start, h.end > last.end ? h.end : last.end));
      } else {
        out.add(h);
      }
    }
    return out;
  }

  static double _round(double x) => ((x.clamp(0, 0.99)) * 100).round() / 100;

  /// Scores [text]. « … franchement t’es nul. Arrête de raconter n’importe quoi. » → 0,62.
  static ModerationAnalysis analyze(String text) {
    final n = normalize(text);
    final strong = _find([for (final r in _strong) (r, 0.88)], n);
    final mild = _find(_mild, n);
    final aggressive = _find([for (final r in _aggressive) (r, 0.22)], n);
    final spam = _find(_spam, n);
    final contact = _find([for (final r in _contact) (r, 0.55)], n);
    final aimed = _aimed.hasMatch(n);

    final insult = strong.weight > mild.weight ? strong.weight : mild.weight;
    final aggression = aimed
        ? (aggressive.weight * (1 + 0.3 * (aggressive.hits.length - 1))).clamp(0, 0.45).toDouble()
        : aggressive.weight * 0.6;
    final spamScore = spam.sum >= 0.6 ? (spam.sum + 0.06 * (spam.hits.length - 2).clamp(0, 99)).clamp(0, 0.95).toDouble() : spam.sum * 0.8;
    final contactScore = contact.weight + (spam.weight > 0 ? 0.1 : 0);

    final candidates = [
      ('insult', insult, [...strong.hits, ...mild.hits]),
      ('aggression', aggression, aggressive.hits),
      ('spam', spamScore, [...spam.hits, ...contact.hits]),
      ('contact', contactScore, contact.hits),
    ];
    final best = candidates.reduce((a, b) => b.$2 > a.$2 ? b : a);
    final score = _round(best.$2);
    if (score < 0.15) {
      return ModerationAnalysis(score: score, level: RiskLevel.low, reason: l10n.forumIaAucune, explanation: l10n.forumIaAucuneExplication);
    }
    final kind = best.$1;
    final offPlatform = contact.weight > 0 || RegExp(r'lien|bio|https?|www|prive|\bmp\b|\bdm\b|whatsapp|insta|telegram').hasMatch(n);
    final (reason, explanation) = switch (kind) {
      'insult' when strong.weight > 0 => (l10n.forumIaInsulte, l10n.forumIaInsulteExplication),
      'insult' => (l10n.forumIaInsulteLegere, l10n.forumIaInsulteLegereExplication),
      'aggression' => (l10n.forumIaTonAgressif, l10n.forumIaTonAgressifExplication),
      'spam' => (offPlatform ? l10n.forumIaSpamContact : l10n.forumIaSpamPub, l10n.forumIaSpamExplication),
      _ => (l10n.forumIaCoordonnees, l10n.forumIaCoordonneesExplication),
    };
    return ModerationAnalysis(
      score: score,
      level: score >= 0.75 ? RiskLevel.high : (score >= 0.5 ? RiskLevel.medium : RiskLevel.low),
      reason: reason,
      explanation: explanation,
      excerpts: _merge(best.$3),
      rewrite: kind == 'insult' || kind == 'aggression' ? rewrite(text) : null,
    );
  }

  /// Drops the clauses that attack someone and keeps the advice, or null when nothing is left.
  static String? rewrite(String text) {
    final parts = RegExp(r'[^.!?;,]+[.!?;,]*').allMatches(text).map((m) => m[0]!).toList();
    final rules = [..._strong, for (final (r, _) in _mild) r, ..._aggressive];
    final kept = [
      for (final p in parts)
        if (!rules.any((r) => r.hasMatch(normalize(p)))) p,
    ];
    final result = kept.join().replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'^[\s,;]+|[\s,;]+$'), '').trim();
    if (result.length < 15 || result == text.trim()) return null;
    final sentence = result[0].toUpperCase() + result.substring(1);
    return RegExp(r'[.!?]$').hasMatch(sentence) ? sentence : '$sentence.';
  }

  // ── Tags ──────────────────────────────────────────────────────────────────────────────────

  static final _dictionary = <(RegExp, String)>[
    (RegExp(r'\bbandejas?\b'), 'Bandeja'),
    (RegExp(r'\bviboras?\b'), 'Vibora'),
    (RegExp(r'\bvitres?\b'), 'Vitre'),
    (RegExp(r'\bgrilles?\b'), 'Grille'),
    (RegExp(r'\blobs?\b'), 'Lob'),
    (RegExp(r'\bvolees?\b|\bfilet\b'), 'Volée'),
    (RegExp(r'\bsmash(s|es)?\b'), 'Smash'),
    (RegExp(r'\bservices?\b|\bretours?\b'), 'Service'),
    (RegExp(r'\bcote gauche\b|\ba gauche\b|\bjoueur de gauche\b'), 'Côté gauche'),
    (RegExp(r'\bcote droit\b|\ba droite\b|\bjoueur de droite\b'), 'Côté droit'),
    (RegExp(r'\braquettes?\b|\bpala\b'), 'Raquette'),
    (RegExp(r'\bcrampons?\b|\bvisses\b|\bmoules\b|\bstabilises\b'), 'Crampons'),
    (RegExp(r'\bsynthetiques?\b|\bgazon\b'), 'Synthétique'),
    (RegExp(r'\b(5v5|5 ?contre ?5|five|foot ?5)\b'), 'Foot5'),
    (RegExp(r'\bgardien\b|\bgoal\b'), 'Gardien'),
    (RegExp(r'\btactiques?\b|\bschema\b|\bpressing\b'), 'Tactique'),
    (RegExp(r'\b3x3\b'), '3x3'),
    (RegExp(r'\bshoots?\b|\btirs? a 3\b|\blancers? francs?\b'), 'Shoot'),
    (RegExp(r'\bdribbles?\b'), 'Dribble'),
    (RegExp(r'\b(technique|geste|placer|placement|travaille|frappe|armer|arme|contact)\b'), 'Technique'),
    (RegExp(r'\b(qui est chaud|il manque|il reste \d+ places?|cherche (des |un )?joueurs?|on cherche)\b'), 'Cherche joueurs'),
    (RegExp(r'\b(tournoi|poules?|inscriptions?|bracket|tableau)\b'), 'Tournoi'),
    (RegExp(r'\b(endurance|cardio|physique|souffle)\b'), 'Physique'),
    (RegExp(r'\b(blessure|genou|cheville|epaule|douleur|tendinite)\b'), 'Blessure'),
    (RegExp(r'\bdebutants?\b|\bje debute\b'), 'Débutant'),
    (RegExp(r'\b(la marsa|marsa)\b'), 'LaMarsa'),
    (RegExp(r'\b(lac ?2|les berges du lac)\b'), 'Lac2'),
  ];

  static String _key(String tag) => normalize(tag).replaceAll(RegExp(r'\s+'), '');

  /// Up to [max] tags from the title (counts double) and the text that are not there yet.
  static List<TagSuggestion> suggestTags(String title, String body, List<String> already, {int max = 3}) {
    final taken = {for (final t in already) _key(t)};
    final nt = normalize(title);
    final nb = normalize(body);
    final scored = <(TagSuggestion, int)>[];
    for (final (re, tag) in _dictionary) {
      if (taken.contains(_key(tag))) continue;
      final inTitle = re.firstMatch(nt);
      final inBody = re.firstMatch(nb);
      final m = inTitle ?? inBody;
      if (m == null) continue;
      final source = inTitle != null ? title : body;
      scored.add((TagSuggestion(tag, source.substring(m.start, m.end)), (inTitle != null ? 2 : 0) + (inBody != null ? 1 : 0)));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final (s, _) in scored.take(max)) s];
  }

  /// Trimmed, no « # », no duplicates (case and accents ignored), at most [max].
  static List<String> cleanTags(List<String> tags, {int max = 5, int length = 30}) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in tags) {
      var tag = raw.replaceAll(RegExp('^#+'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
      if (tag.length > length) tag = tag.substring(0, length);
      if (tag.isEmpty || !seen.add(_key(tag))) continue;
      out.add(tag);
      if (out.length == max) break;
    }
    return out;
  }

  /// « #lamarsa »: lower case, no spaces (ForumPostCard.md).
  static String hashtag(String tag) => '#${tag.toLowerCase().replaceAll(RegExp(r'\s+'), '')}';

  // ── Similar discussions ───────────────────────────────────────────────────────────────────

  /// 0 → 1: shared title words count most, shared tags and the same sport add a little.
  static double similarity(
    String title, {
    String? sport,
    List<String> tags = const [],
    required ForumPost candidate,
    String? candidateBody,
  }) {
    final a = keywords(title).toSet();
    if (a.isEmpty) return 0;
    final bTitle = keywords(candidate.title).toSet();
    final bBody = keywords(candidateBody ?? candidate.excerpt ?? '').toSet();
    var shared = 0.0;
    for (final w in a) {
      if (bTitle.contains(w)) {
        shared += 1;
      } else if (bBody.contains(w)) {
        shared += 0.35;
      }
    }
    final denominator = [
      2,
      [a.length, bTitle.isEmpty ? 1 : bTitle.length].reduce((x, y) => x < y ? x : y),
    ].reduce((x, y) => x > y ? x : y);
    var score = shared / denominator;
    final tagsA = {for (final t in tags) normalize(t)};
    if (candidate.tags.any((t) => tagsA.contains(normalize(t)) || a.contains(normalize(t)))) score += 0.15;
    if (sport != null && candidate.sport?.name == sport) score += 0.05;
    return ((score.clamp(0, 1)) * 100).round() / 100;
  }

  // ── Mentions ──────────────────────────────────────────────────────────────────────────────

  static final mentionPattern = RegExp(r'(^|[^a-zA-Z0-9._@])@([a-zA-Z0-9][a-zA-Z0-9._]{1,38}[a-zA-Z0-9])');

  /// `@pseudo` handles in [text], lower case, without « @ ».
  static List<String> mentions(String text) => {for (final m in mentionPattern.allMatches(text)) m[2]!.toLowerCase()}.toList();
}
