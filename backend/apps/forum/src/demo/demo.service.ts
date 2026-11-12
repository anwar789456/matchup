import { ConflictException, ForbiddenException, Injectable } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';

import { ContenusService } from '../commun/contenus.service';
import type { Categorie, Cible, MotifSignalement, Sport } from '../forum.constants';
import { analyserTexte, extraireMentions } from '../ia/ia.logic';
import { Blocage, Favori, Reaction, Suivi, Visite, Vote } from '../interaction/interaction.entities';
import { Message } from '../message/message.entity';
import { Sanction, Signalement } from '../moderation/moderation.entities';
import { Sujet } from '../sujet/sujet.entity';

/**
 * The story's people (design/screens/STORY-DATA.md) as user ids of the utilisateur module.
 * Create these users there (or map them) to see names in the app.
 */
export const PERSONNES = {
  yassine: 1, // Yassine B. · @yassine.b · 3,5
  ines: 2, // Ines M. · 4,0
  skander: 3, // Skander T. · @skander.t · 4,0
  mariem: 4, // Mariem K. · 4,0
  sami: 5, // Sami C. · Tunis Padel Series · 4,5
  hamza: 6, // Hamza R. · 3,5
  aziz: 7, // Aziz H. · 4,5
  omar: 8, // Omar D. · 3,5
  bonsPlans: 9, // Bons Plans Sport TN
  leila: 10, // Leila M. · admin
  promo: 11, // promo_crampons
  bilel: 12, // coach.bilel
  karim: 13, // Karim J. · coach
  rami: 14, // Rami S.
} as const;

/** Anonymous voters: ids far from real users, only to give the demo realistic counters. */
const FOULE = 100_000;

const heures = (h: number) => new Date(Date.now() - h * 3600 * 1000);

interface PostDemo {
  cle: string;
  auteurId: number;
  titre: string;
  contenu: string;
  categorie: Categorie;
  sport: Sport | null;
  tags: string[];
  il_y_a: number;
  votes: number;
  utile?: number;
  merci?: number;
  epingle?: boolean;
}

interface ReponseDemo {
  cle: string;
  post: string;
  parent?: string;
  auteurId: number;
  contenu: string;
  il_y_a: number;
  votes: number;
  utile?: number;
  masque?: boolean;
}

const POSTS: PostDemo[] = [
  {
    cle: 'masters',
    auteurId: PERSONNES.sami,
    titre: 'Padel Masters Lac 2 : toutes les infos et vos questions',
    contenu:
      'Sam. 24 → lun. 26 oct. au Smash Padel Club. 16 équipes, 120 DT par équipe, dotation 1 500 DT (800 / 450 / 250 DT).\n\n' +
      '- Niveau 3,5 à 5,0\n- Poules puis phase finale le lundi dès 18h00\n- Inscriptions jusqu’au mer. 21 oct.\n\nPosez vos questions ici, je réponds à tout le monde.',
    categorie: 'tournois',
    sport: 'padel',
    tags: ['tournoi', 'lac2'],
    il_y_a: 72,
    votes: 41,
    utile: 15,
    epingle: true,
  },
  {
    cle: 'bandeja',
    auteurId: PERSONNES.ines,
    titre: 'Bandeja : je n’arrive pas à la placer croisée',
    contenu:
      'Elle part toujours au centre et finit dans la grille. @yassine.b tu bosses le programme de Karim J., tu as eu le même souci ?\n\n' +
      'Je joue à droite, niveau 4,0. J’ai essayé d’ouvrir les épaules plus tôt, sans grand changement.',
    categorie: 'conseils_technique',
    sport: 'padel',
    tags: ['bandeja', 'technique'],
    il_y_a: 2,
    votes: 16,
    utile: 4,
  },
  {
    cle: 'smash',
    auteurId: PERSONNES.mariem,
    titre: 'Avis Smash Padel Club après rénovation',
    contenu:
      'Nouvelles vitres sur les courts 1 et 2, éclairage LED et vestiaires refaits. Seul bémol : le parking est vite plein le samedi, venez 15 min avant.',
    categorie: 'terrains',
    sport: 'padel',
    tags: ['smashpadel', 'lac2'],
    il_y_a: 26,
    votes: 27,
    merci: 6,
  },
  {
    cle: 'five',
    auteurId: PERSONNES.yassine,
    titre: '5v5 dimanche soir à La Marsa, qui est chaud ?',
    contenu:
      'Il reste 2 places dim. 18 oct. à 20h00 à Arena Five, niveau 3,0 – 4,5. 15 DT par joueur, chasubles fournies. Réponds ici ou rejoins la partie dans Explorer.',
    categorie: 'discussions_libres',
    sport: 'football',
    tags: ['foot5', 'lamarsa'],
    il_y_a: 74,
    votes: 21,
  },
  {
    cle: 'crampons',
    auteurId: PERSONNES.skander,
    titre: 'Crampons pour synthétique ?',
    contenu:
      'Je joue deux fois par semaine à Arena Five, sur le synthétique. Mes crampons vissés glissent quand le gazon est sec et me tirent sur les genoux en fin de match.\n\n' +
      'Moulés, stabilisés (TF) ou autre chose ? Budget autour de **200 DT**.',
    categorie: 'equipement',
    sport: 'football',
    tags: ['crampons', 'synthétique', 'lamarsa'],
    il_y_a: 48,
    votes: 19,
    utile: 12,
    merci: 4,
  },
  {
    cle: 'vibora',
    auteurId: PERSONNES.mariem,
    titre: 'Bandeja ou vibora : laquelle sur une balle haute ?',
    contenu: 'Sur une balle haute qui sort de la vitre de fond, vous jouez quoi ? Je perds trop de points en vibora.',
    categorie: 'conseils_technique',
    sport: 'padel',
    tags: ['bandeja', 'vibora'],
    il_y_a: 14 * 24,
    votes: 32,
    utile: 10,
  },
  {
    cle: 'spam',
    auteurId: PERSONNES.promo,
    titre: 'Vends crampons pas cher, livraison partout',
    contenu: 'Vends crampons pas cher, livraison partout, lien en bio',
    categorie: 'equipement',
    sport: 'football',
    tags: [],
    il_y_a: 1,
    votes: 0,
  },
  {
    cle: 'bilel',
    auteurId: PERSONNES.bilel,
    titre: 'Cours de padel à 30 DT la séance',
    contenu: 'Cours de padel à 30 DT, appelle-moi au 98 ••• 214',
    categorie: 'conseils_technique',
    sport: 'padel',
    tags: [],
    il_y_a: 24,
    votes: 1,
  },
];

const REPONSES: ReponseDemo[] = [
  // « Crampons pour synthétique ? » (FRM-04)
  {
    cle: 'tf',
    post: 'crampons',
    auteurId: PERSONNES.yassine,
    contenu:
      'Prends des stabilisés (TF) ou des moulés courts (AG). Les vissés, c’est pour l’herbe naturelle : sur synthétique ils accrochent trop et tirent sur les genoux. À Arena Five, les AG passent très bien, même quand c’est sec.',
    il_y_a: 47,
    votes: 24,
    utile: 9,
  },
  {
    cle: 'ag',
    post: 'crampons',
    auteurId: PERSONNES.hamza,
    contenu: 'J’ai pris des AG à **180 DT** il y a 6 mois. Zéro glisse à Arena Five, même le dimanche soir quand le terrain est arrosé.',
    il_y_a: 46,
    votes: 9,
  },
  { cle: 'ou', post: 'crampons', parent: 'ag', auteurId: PERSONNES.skander, contenu: 'Tu les as prises où ? Je passe en ville samedi.', il_y_a: 45, votes: 2 },
  {
    cle: 'marseille',
    post: 'crampons',
    parent: 'ou',
    auteurId: PERSONNES.hamza,
    contenu: '@skander.t Au centre-ville, rue de Marseille. Essaie-les avec tes chaussettes de match, ça taille petit.',
    il_y_a: 20,
    votes: 3,
  },
  {
    cle: 'pluie',
    post: 'crampons',
    auteurId: PERSONNES.aziz,
    contenu: 'Les TF, c’est top sur synthétique sec, mais ça glisse sous la pluie. Si tu joues aussi en extérieur l’hiver, garde des AG.',
    il_y_a: 22,
    votes: 6,
  },
  {
    cle: 'visses',
    post: 'crampons',
    auteurId: PERSONNES.omar,
    contenu: 'Les vissés c’est mieux, tout le monde sait ça. Les moulés c’est pour les débutants.',
    il_y_a: 21,
    votes: -3,
  },
  {
    cle: 'nul',
    post: 'crampons',
    parent: 'visses',
    auteurId: PERSONNES.yassine,
    contenu: 'T’as jamais mis les pieds sur un synthétique, franchement t’es nul. Arrête de raconter n’importe quoi.',
    il_y_a: 19,
    votes: 0,
    masque: true,
  },
  { cle: 'mariem', post: 'crampons', auteurId: PERSONNES.mariem, contenu: 'Moulés pour moi, et je les change tous les 8 mois.', il_y_a: 10, votes: 1 },
  {
    cle: 'bonsplans',
    post: 'crampons',
    auteurId: PERSONNES.bonsPlans,
    contenu: 'Vends crampons pas cher, toutes marques, livraison partout en Tunisie. Écris-moi en privé !!',
    il_y_a: 3,
    votes: 0,
  },
  // Others
  { cle: 'compte', post: 'five', auteurId: PERSONNES.hamza, contenu: 'Compte sur moi, on vient à deux.', il_y_a: 70, votes: 4 },
  {
    cle: 'karim',
    post: 'bandeja',
    auteurId: PERSONNES.karim,
    contenu:
      'Frappe la balle devant l’épaule, pas au-dessus de la tête, et finis le geste vers la vitre latérale. C’est exactement la séance 5 du programme : fais-la deux fois cette semaine.',
    il_y_a: 1,
    votes: 7,
    utile: 3,
  },
  {
    cle: 'arbitres',
    post: 'masters',
    auteurId: PERSONNES.rami,
    contenu: 'Les arbitres de ce tournoi sont achetés, c’est une blague.',
    il_y_a: 26,
    votes: -2,
  },
];

/** Open reports from people, as in ADM-09. */
const SIGNALEMENTS: { cible: Cible; cle: string; par: number[]; motif: MotifSignalement }[] = [
  { cible: 'sujet', cle: 'spam', par: [1, 2, 3, 4, 6], motif: 'spam' },
  { cible: 'message', cle: 'nul', par: [8, 7, 6], motif: 'insulte' },
  { cible: 'sujet', cle: 'bilel', par: [13, 4], motif: 'autre' },
  { cible: 'message', cle: 'arbitres', par: [5], motif: 'fausse_information' },
  { cible: 'message', cle: 'bonsplans', par: [4], motif: 'spam' },
];

/** POST /demo/remplir — the story's forum, for development only. */
@Injectable()
export class DemoService {
  constructor(
    private readonly contenus: ContenusService,
    @InjectDataSource() private readonly db: DataSource,
  ) {}

  async remplir(remplacer = false) {
    if (process.env.NODE_ENV === 'production') throw new ForbiddenException('Pas de données de démo en production.');
    const sujets = this.db.getRepository(Sujet);
    if (!remplacer && (await sujets.count()) > 0) {
      throw new ConflictException('Le forum contient déjà des discussions. Ajoute ?remplacer=true pour tout effacer et recommencer.');
    }
    if (remplacer) {
      const tables = [Sujet, Message, Vote, Reaction, Favori, Suivi, Blocage, Visite, Signalement, Sanction]
        .map((e) => this.db.getMetadata(e).tablePath)
        .join(', ');
      await this.db.query(`TRUNCATE ${tables} RESTART IDENTITY CASCADE`);
    }

    const idPost = new Map<string, number>();
    for (const p of POSTS) {
      const analyse = analyserTexte(`${p.titre}\n${p.contenu}`);
      const s = await sujets.save(
        sujets.create({
          auteurId: p.auteurId,
          titre: p.titre,
          contenu: p.contenu,
          categorie: p.categorie,
          sport: p.sport,
          tags: p.tags,
          mentions: extraireMentions(p.contenu),
          epingle: !!p.epingle,
          scoreIa: analyse.score,
          motifIa: analyse.score >= 0.15 ? analyse.motif : null,
          createdAt: heures(p.il_y_a),
          derniereActivite: heures(p.il_y_a),
        }),
      );
      idPost.set(p.cle, s.id);
      await this.foule('sujet', s.id, p.votes, p.utile ?? 0, p.merci ?? 0);
      await this.db.getRepository(Suivi).save({ utilisateurId: p.auteurId, type: 'sujet', cibleId: s.id });
    }

    const messages = this.db.getRepository(Message);
    const idReponse = new Map<string, Message>();
    for (const r of REPONSES) {
      const parent = r.parent ? idReponse.get(r.parent)! : null;
      const analyse = analyserTexte(r.contenu);
      const m = await messages.save(
        messages.create({
          sujetId: idPost.get(r.post)!,
          parentId: parent ? (parent.parentId ?? parent.id) : null,
          enReponseAId: parent?.auteurId ?? null,
          auteurId: r.auteurId,
          contenu: r.contenu,
          mentions: extraireMentions(r.contenu),
          statut: r.masque ? 'masque' : 'publie',
          publieMalgreAlerte: !!r.masque,
          scoreIa: analyse.score,
          motifIa: analyse.score >= 0.15 ? analyse.motif : null,
          createdAt: heures(r.il_y_a),
        }),
      );
      idReponse.set(r.cle, m);
      if (r.masque) await this.contenus.signalerParIa('message', m.id, analyse);
      await this.foule('message', m.id, r.votes, r.utile ?? 0, 0);
    }

    // Best answer, last activity and reply counters.
    await sujets.update(idPost.get('crampons')!, { meilleureReponseId: idReponse.get('tf')!.id });
    for (const [cle, id] of idPost) {
      const derniere = REPONSES.filter((r) => r.post === cle).reduce((min, r) => Math.min(min, r.il_y_a), Infinity);
      if (Number.isFinite(derniere)) await sujets.update(id, { derniereActivite: heures(derniere) });
      await this.contenus.recompterReponses(id);
    }

    // Reports; 3 or more from people hide the content (« masqué au 3e »).
    const signalements = this.db.getRepository(Signalement);
    for (const s of SIGNALEMENTS) {
      const cibleId = s.cible === 'sujet' ? idPost.get(s.cle)! : idReponse.get(s.cle)!.id;
      for (const [i, signaleurId] of s.par.entries()) {
        await signalements.save(signalements.create({ cible: s.cible, cibleId, signaleurId, motif: s.motif, createdAt: heures(10 - i) }));
      }
      if (s.par.length >= 3) {
        await (s.cible === 'sujet' ? sujets : messages).update(cibleId, { statut: 'masque' });
      }
    }
    await this.contenus.recompterReponses(idPost.get('crampons')!);

    // Yassine saved the Masters post and follows Skander; last visit yesterday.
    await this.db.getRepository(Favori).save({ utilisateurId: PERSONNES.yassine, sujetId: idPost.get('masters')! });
    await this.db.getRepository(Suivi).save({ utilisateurId: PERSONNES.yassine, type: 'membre', cibleId: PERSONNES.skander });
    await this.db.getRepository(Visite).save({ utilisateurId: PERSONNES.yassine, derniereVisite: heures(30) });

    return {
      sujets: idPost.size,
      reponses: idReponse.size,
      signalements: SIGNALEMENTS.reduce((n, s) => n + s.par.length, 0),
      personnes: PERSONNES,
    };
  }

  /** Votes and reactions from anonymous ids, then the counters. */
  private async foule(cible: Cible, cibleId: number, votes: number, utile: number, merci: number) {
    const v = this.db.getRepository(Vote);
    const r = this.db.getRepository(Reaction);
    const n = Math.abs(votes);
    if (n) await v.insert(Array.from({ length: n }, (_, i) => ({ utilisateurId: FOULE + i, cible, cibleId, valeur: Math.sign(votes) })));
    if (utile) await r.insert(Array.from({ length: utile }, (_, i) => ({ utilisateurId: FOULE + i, cible, cibleId, type: 'utile' as const })));
    if (merci) await r.insert(Array.from({ length: merci }, (_, i) => ({ utilisateurId: FOULE + 500 + i, cible, cibleId, type: 'merci' as const })));
    await this.contenus.recompterVotes(cible, cibleId);
    await this.contenus.recompterReactions(cible, cibleId);
  }
}
