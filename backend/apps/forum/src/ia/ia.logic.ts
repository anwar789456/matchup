/**
 * The forum's "AI", as pure functions (no database, no network): toxicity / spam scoring with the
 * passages to highlight (FRM-03, ADM-09/10), a calmer rewrite when one can be made, tag
 * suggestions (FRM-02 « Suggérés par l’IA ») and similar-discussion matching (FRM-02
 * « Discussions similaires »).
 *
 * It is a rule-based first version: French, Tunisian derja written in Latin letters and the usual
 * spam signs. It never hides or deletes anything by itself — it only scores, and people decide.
 * Swap these functions for a language model later without touching the services.
 */

export type NiveauRisque = 'faible' | 'moyen' | 'eleve';

export interface Extrait {
  /** Index in the original text (UTF-16), end excluded: `texte.slice(debut, fin)`. */
  debut: number;
  fin: number;
  texte: string;
}

export interface Analyse {
  /** 0 → 1. From `LIMITES.seuilAlerte` (0,5) the author is asked to review the text. */
  score: number;
  niveau: NiveauRisque;
  /** Short reason shown to moderators, e.g. « Toxicité · insulte légère », « Spam · lien et contact ». */
  motif: string;
  /** Longer explanation for the review drawer (ADM-10). */
  explication: string;
  categorie: 'aucune' | 'insulte' | 'agressivite' | 'spam' | 'coordonnees';
  /** Passages to highlight in the text. */
  extraits: Extrait[];
  /** A calmer version that keeps the useful part, when there is one (FRM-03), else null. */
  reformulation: string | null;
}

// ---------------------------------------------------------------------------------------------
// Text helpers

/**
 * Lower case, accents and curly apostrophes removed, one character for one character, so an
 * index in the normalised text is the same index in the original.
 */
export function normaliser(texte: string): string {
  let out = '';
  for (const c of texte) {
    if (c === '’' || c === '‘' || c === 'ʼ') {
      out += "'";
      continue;
    }
    const base = c.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
    // Keep the 1-for-1 length (a surrogate pair stays 2 units, a ligature stays 1).
    out += base.length === c.length ? base : c.toLowerCase().slice(0, c.length).padEnd(c.length, ' ');
  }
  return out;
}

const MOTS_VIDES = new Set(
  (
    'a au aux avec ce ces c ca cela cet cette d dans de des du elle en es est et etre eux il ils ' +
    'j je l la le les leur lui m ma mais me meme mes moi mon n ne ni nos notre nous on ou par pas ' +
    'pour qu que qui quoi s sa se ses si son sur t ta te tes toi ton tu un une vos votre vous y ' +
    'quel quelle quels quelles comment est-ce ai as avez avons ont suis sont fait faire bien tres ' +
    'plus moins aussi alors donc car comme the and or is des chez entre sans sous apres avant'
  ).split(' '),
);

/** Meaningful words of a text, accents removed, light plural stemming. */
export function motsCles(texte: string): string[] {
  return normaliser(texte)
    .split(/[^a-z0-9]+/)
    .filter((m) => m.length > 1 && !MOTS_VIDES.has(m))
    .map((m) => (m.length > 4 && /[sx]$/.test(m) ? m.slice(0, -1) : m));
}

// ---------------------------------------------------------------------------------------------
// Toxicity and spam

interface Regle {
  motif: RegExp;
  poids: number;
}

/** Strong insults and slurs (French + derja). */
const INSULTES_FORTES: Regle[] = [
  /\b(connard|connasse|salope|pute|putain de toi|encule|enculer|fdp|fils de pute|ntm|nique ta|niquer|batard|tafiole|pd)\b/,
  /\b(zebi|zabi|nayek|nik ommek|mnayek|kahba|9a7ba|miboun|t7a7na|zamel)\b/,
  /\bta gueule\b|\bva te faire\b|\bferme[- ]la\b/,
].map((motif) => ({ motif, poids: 0.88 }));

/** Mild insults: mockery aimed at a person. */
const INSULTES_LEGERES: Regle[] = [
  /\b(t'?es|tu es|vous etes|t'?etais|c'?est un|quel|espece d'?|sale)\s+(vraiment\s+|trop\s+|completement\s+|grave\s+)?(nul|nulle|nuls|idiot|idiote|debile|abruti|cretin|imbecile|bouffon|boufon|naze|nase|teube|clown|guignol|mahboul|bhim|tache|loser|minable|pathetique|ridicule|incapable)\b/,
  /\b(idiot|debile|abruti|cretin|imbecile|bouffon|guignol|minable|pathetique|mahboul|bhim)s?\b/,
].map((motif, i) => ({ motif, poids: i === 0 ? 0.62 : 0.55 }));

/** Aggressive turns that are not insults on their own. */
const AGRESSIVITE: Regle[] = [
  /\bt'?as jamais\b/,
  /\barrete de (raconter|dire|parler|poster)\b/,
  /\bn'?importe quoi\b/,
  /\btu (n'?y )?connais rien\b|\btu sais (meme )?pas\b/,
  /\btout le monde sait (ca|que)\b/,
  /\bc'?est (une )?(blague|honte)\b/,
  /\b(achetes|vendus|corrompus|truques)\b/,
].map((motif) => ({ motif, poids: 0.22 }));

/** Spam and selling. */
const SPAM: Regle[] = [
  { motif: /\b(vends?|vente|a vendre|promo|promotion|pas cher|prix (cass|imbat)\w*|soldes?|livraison)\b/, poids: 0.3 },
  { motif: /\b(lien en bio|en bio|ecris[- ]moi en (prive|mp|dm)|en (mp|dm|prive)|contacte[- ]moi|whatsapp|insta(gram)?|telegram)\b/, poids: 0.35 },
  { motif: /(https?:\/\/|www\.)\S+|\b\S+\.(com|tn|net|shop|store|fr)\b/, poids: 0.4 },
  { motif: /!{2,}|\b(gratuit|offre|code promo)\b/, poids: 0.12 },
];

/** Personal contact data published in a post. */
const COORDONNEES: Regle[] = [
  { motif: /(\+?216[\s.]?)?\b[2-9]\d[\s.]?\d{3}[\s.]?\d{3}\b/, poids: 0.55 },
  { motif: /\b[2-9]\d[\s.]?[•*x]{2,}/, poids: 0.55 },
  { motif: /[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}/, poids: 0.5 },
];

/** Words that aim the sentence at someone (« t’es », « toi »…). */
const VISE_UNE_PERSONNE = /\b(t'?es|tu es|toi|t'?as|ton|ta|tes|vous etes)\b/;

/** `poids`: strongest rule plus a quarter of each other one; `somme`: every rule that matched. */
function trouver(regles: Regle[], texte: string): { poids: number; somme: number; extraits: Extrait[] } {
  let poids = 0;
  let somme = 0;
  const extraits: Extrait[] = [];
  for (const regle of regles) {
    const global = new RegExp(regle.motif.source, 'g');
    let m: RegExpExecArray | null;
    let touche = false;
    while ((m = global.exec(texte)) !== null) {
      if (m[0].length === 0) {
        global.lastIndex++;
        continue;
      }
      touche = true;
      extraits.push({ debut: m.index, fin: m.index + m[0].length, texte: '' });
    }
    if (touche) {
      poids = Math.max(poids, regle.poids) + (poids > 0 ? regle.poids * 0.25 : 0);
      somme += regle.poids;
    }
  }
  return { poids, somme, extraits };
}

function niveauDe(score: number): NiveauRisque {
  if (score >= 0.75) return 'eleve';
  if (score >= 0.5) return 'moyen';
  return 'faible';
}

const arrondi = (x: number) => Math.round(Math.min(0.99, Math.max(0, x)) * 100) / 100;

/** Merges overlapping passages and fills their original text. */
function fusionner(extraits: Extrait[], original: string): Extrait[] {
  const tries = [...extraits].sort((a, b) => a.debut - b.debut);
  const out: Extrait[] = [];
  for (const e of tries) {
    const dernier = out[out.length - 1];
    if (dernier && e.debut <= dernier.fin) dernier.fin = Math.max(dernier.fin, e.fin);
    else out.push({ ...e });
  }
  return out.map((e) => ({ ...e, texte: original.slice(e.debut, e.fin) }));
}

/**
 * Scores a text. Examples from the screens:
 * « … franchement t’es nul. Arrête de raconter n’importe quoi. » → 0,62 moyen, insulte légère;
 * « Vends crampons pas cher, livraison partout, lien en bio » → ≥ 0,9 élevé, spam.
 */
export function analyserTexte(texte: string): Analyse {
  const n = normaliser(texte);
  const fortes = trouver(INSULTES_FORTES, n);
  const legeres = trouver(INSULTES_LEGERES, n);
  const agressif = trouver(AGRESSIVITE, n);
  const spam = trouver(SPAM, n);
  const coord = trouver(COORDONNEES, n);
  const vise = VISE_UNE_PERSONNE.test(n);

  // Insults: the strongest rule wins. Aggressive turns alone never reach the alert.
  const insulte = Math.max(fortes.poids, legeres.poids);
  const agressivite = vise ? Math.min(0.45, agressif.poids * (1 + 0.3 * (agressif.extraits.length - 1))) : agressif.poids * 0.6;
  // Spam: one sign is not enough (« je vends mes crampons » is fine), different signs add up.
  const spamScore =
    spam.somme >= 0.6 ? Math.min(0.95, spam.somme + 0.06 * Math.max(0, spam.extraits.length - 2)) : spam.somme * 0.8;
  const coordScore = coord.poids + (spam.poids > 0 ? 0.1 : 0);

  const candidats: [Analyse['categorie'], number, Extrait[]][] = [
    ['insulte', insulte, [...fortes.extraits, ...legeres.extraits]],
    ['agressivite', agressivite, agressif.extraits],
    ['spam', spamScore, [...spam.extraits, ...coord.extraits]],
    ['coordonnees', coordScore, coord.extraits],
  ];
  const [categorie, brut, extraitsPrincipaux] = candidats.reduce((a, b) => (b[1] > a[1] ? b : a));
  const score = arrondi(brut);

  if (score < 0.15) {
    return {
      score,
      niveau: 'faible',
      motif: 'Aucune toxicité',
      explication: 'Rien de blessant ni de publicitaire détecté.',
      categorie: 'aucune',
      extraits: [],
      reformulation: null,
    };
  }

  const motifs: Record<Analyse['categorie'], string> = {
    aucune: 'Aucune toxicité',
    insulte: fortes.poids > 0 ? 'Toxicité · insulte' : 'Toxicité · insulte légère',
    agressivite: 'Ton agressif',
    spam: coord.poids > 0 || /lien|bio|https?|www|prive|\bmp\b|\bdm\b|whatsapp|insta|telegram/.test(n) ? 'Spam · lien et contact' : 'Spam · publicité',
    coordonnees: 'Coordonnées publiées',
  };
  const explications: Record<Analyse['categorie'], string> = {
    aucune: '',
    insulte:
      fortes.poids > 0
        ? 'Insulte grossière visant une personne.'
        : 'Moquerie entre joueurs, sans menace ni haine. L’IA peut se tromper sur le ton entre amis.',
    agressivite: 'Ton sec qui vise une personne plutôt que son avis. Pas d’insulte.',
    spam: 'Vente ou publicité avec un moyen de contact hors de MatchUp.',
    coordonnees: 'Numéro ou adresse publiés : à faire passer en message privé.',
  };

  const extraits = fusionner(extraitsPrincipaux, texte);

  return {
    score,
    niveau: niveauDe(score),
    motif: motifs[categorie],
    explication: explications[categorie],
    categorie,
    extraits,
    reformulation: categorie === 'insulte' || categorie === 'agressivite' ? reformuler(texte) : null,
  };
}

/**
 * Removes the clauses that attack someone and keeps the advice. Returns null when nothing useful
 * is left (then the screen offers only « Modifier mon message »).
 */
export function reformuler(texte: string): string | null {
  const morceaux = texte.match(/[^.!?;,]+[.!?;,]*/g) ?? [texte];
  const gardes = morceaux.filter((m) => {
    const n = normaliser(m);
    return ![...INSULTES_FORTES, ...INSULTES_LEGERES, ...AGRESSIVITE].some((r) => r.motif.test(n));
  });
  const resultat = gardes
    .join('')
    .replace(/\s+/g, ' ')
    .replace(/^[\s,;]+|[\s,;]+$/g, '')
    .trim();
  if (resultat.length < 15 || resultat === texte.trim()) return null;
  const phrase = resultat.charAt(0).toUpperCase() + resultat.slice(1);
  return /[.!?]$/.test(phrase) ? phrase : `${phrase}.`;
}

// ---------------------------------------------------------------------------------------------
// Tags

interface RegleTag {
  mots: RegExp;
  tag: string;
}

/** Words of the sports we host → the tag to suggest. */
const DICTIONNAIRE_TAGS: RegleTag[] = [
  // Padel
  { mots: /\bbandejas?\b/, tag: 'Bandeja' },
  { mots: /\bviboras?\b/, tag: 'Vibora' },
  { mots: /\bvitres?\b|\bvitre laterale\b/, tag: 'Vitre' },
  { mots: /\bgrilles?\b/, tag: 'Grille' },
  { mots: /\blobs?\b/, tag: 'Lob' },
  { mots: /\bvolees?\b|\bfilet\b/, tag: 'Volée' },
  { mots: /\bsmash(s|es)?\b/, tag: 'Smash' },
  { mots: /\bservices?\b|\bretours?\b/, tag: 'Service' },
  { mots: /\bcote gauche\b|\ba gauche\b|\bjoueur de gauche\b/, tag: 'Côté gauche' },
  { mots: /\bcote droit\b|\ba droite\b|\bjoueur de droite\b/, tag: 'Côté droit' },
  { mots: /\braquettes?\b|\bpala\b/, tag: 'Raquette' },
  // Football
  { mots: /\bcrampons?\b|\bvisses\b|\bmoules\b|\bstabilises\b/, tag: 'Crampons' },
  { mots: /\bsynthetiques?\b|\bgazon\b/, tag: 'Synthétique' },
  { mots: /\b(5v5|5 ?contre ?5|five|foot ?5)\b/, tag: 'Foot5' },
  { mots: /\bgardien\b|\bgoal\b/, tag: 'Gardien' },
  { mots: /\btactiques?\b|\bschema\b|\bpressing\b/, tag: 'Tactique' },
  // Basketball
  { mots: /\b3x3\b/, tag: '3x3' },
  { mots: /\bshoots?\b|\btirs? a 3\b|\blancers? francs?\b/, tag: 'Shoot' },
  { mots: /\bdribbles?\b/, tag: 'Dribble' },
  // Everyone
  { mots: /\b(technique|geste|placer|placement|travaille|frappe|armer|arme|contact)\b/, tag: 'Technique' },
  { mots: /\b(qui est chaud|il manque|il reste \d+ places?|cherche (des |un )?joueurs?|on cherche)\b/, tag: 'Cherche joueurs' },
  { mots: /\b(tournoi|poules?|inscriptions?|bracket|tableau)\b/, tag: 'Tournoi' },
  { mots: /\b(endurance|cardio|physique|souffle)\b/, tag: 'Physique' },
  { mots: /\b(blessure|genou|cheville|epaule|douleur|tendinite)\b/, tag: 'Blessure' },
  { mots: /\bdebutants?\b|\bje debute\b/, tag: 'Débutant' },
  { mots: /\b(la marsa|marsa)\b/, tag: 'LaMarsa' },
  { mots: /\b(lac ?2|les berges du lac)\b/, tag: 'Lac2' },
  { mots: /\b(ennasr|menzah|ariana|sousse|sfax|bizerte|nabeul|hammamet|monastir)\b/, tag: 'Ville' },
];

export interface SuggestionTag {
  tag: string;
  /** The word that made us suggest it (« d’après “vitre latérale” »). */
  raison: string;
}

/**
 * Up to `max` tags found in the title and text that the author did not add yet (FRM-02). The
 * title counts double, frequent forum tags break ties.
 */
export function suggererTags(
  titre: string,
  contenu: string,
  dejaLa: string[],
  frequents: Map<string, number> = new Map(),
  max = 3,
): SuggestionTag[] {
  const pris = new Set(dejaLa.map((t) => normaliser(t).replace(/\s+/g, '')));
  const nTitre = normaliser(titre);
  const nContenu = normaliser(contenu);
  const scores: { tag: string; raison: string; score: number }[] = [];
  for (const { mots, tag } of DICTIONNAIRE_TAGS) {
    if (pris.has(normaliser(tag).replace(/\s+/g, ''))) continue;
    if (tag === 'Ville') {
      const m = mots.exec(nTitre) ?? mots.exec(nContenu);
      if (!m) continue;
      const nom = m[0].charAt(0).toUpperCase() + m[0].slice(1);
      if (pris.has(normaliser(nom))) continue;
      scores.push({ tag: nom, raison: m[0], score: 1 });
      continue;
    }
    const dansTitre = mots.exec(nTitre);
    const dansTexte = mots.exec(nContenu);
    if (!dansTitre && !dansTexte) continue;
    const source = dansTitre ? titre : contenu;
    const m = (dansTitre ?? dansTexte)!;
    scores.push({
      tag,
      raison: source.slice(m.index, m.index + m[0].length),
      score: (dansTitre ? 2 : 0) + (dansTexte ? 1 : 0) + Math.min(1, (frequents.get(normaliser(tag)) ?? 0) / 20),
    });
  }
  return scores
    .sort((a, b) => b.score - a.score)
    .slice(0, max)
    .map(({ tag, raison }) => ({ tag, raison }));
}

/** Cleans a list of tags: trimmed, no « # », no duplicates (case and accents ignored), ≤ max. */
export function nettoyerTags(tags: string[] | undefined, max: number, longueur: number): string[] {
  const vus = new Set<string>();
  const out: string[] = [];
  for (const brut of tags ?? []) {
    const tag = brut.replace(/^#+/, '').replace(/\s+/g, ' ').trim().slice(0, longueur);
    const cle = normaliser(tag).replace(/\s+/g, '');
    if (!tag || vus.has(cle)) continue;
    vus.add(cle);
    out.push(tag);
    if (out.length === max) break;
  }
  return out;
}

// ---------------------------------------------------------------------------------------------
// Similar discussions

/**
 * How close a candidate is to what is being typed, 0 → 1: shared title words count most, shared
 * tags and the same sport add a little.
 */
export function similarite(
  requete: { titre: string; tags?: string[]; sport?: string | null },
  candidat: { titre: string; tags: string[]; sport: string | null; contenu?: string },
): number {
  const a = new Set(motsCles(requete.titre));
  if (a.size === 0) return 0;
  const bTitre = new Set(motsCles(candidat.titre));
  const bTexte = new Set(motsCles(candidat.contenu ?? ''));
  let communs = 0;
  for (const m of a) {
    if (bTitre.has(m)) communs += 1;
    else if (bTexte.has(m)) communs += 0.35;
  }
  let score = communs / Math.max(2, Math.min(a.size, bTitre.size || 1));
  const tagsA = new Set((requete.tags ?? []).map((t) => normaliser(t)));
  if (candidat.tags.some((t) => tagsA.has(normaliser(t)) || a.has(normaliser(t)))) score += 0.15;
  if (requete.sport && candidat.sport === requete.sport) score += 0.05;
  return Math.min(1, Math.round(score * 100) / 100);
}

// ---------------------------------------------------------------------------------------------
// Mentions

/** `@pseudo` handles in a text (lower case, no « @ », unique), as stored by the utilisateur module. */
export function extraireMentions(texte: string): string[] {
  const out = new Set<string>();
  for (const m of texte.matchAll(/(^|[^a-z0-9._@])@([a-z0-9][a-z0-9._]{1,38}[a-z0-9])/gi)) {
    out.add(m[2].toLowerCase());
  }
  return [...out];
}
