import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Brackets, In, Repository } from 'typeorm';

import { ContenusService } from '../commun/contenus.service';
import type { EtatLecteur } from '../commun/contenus.service';
import { CATEGORIES, LIMITES } from '../forum.constants';
import type { Categorie, Sport, TriReponses } from '../forum.constants';
import { extraireMentions, nettoyerTags, normaliser, similarite } from '../ia/ia.logic';
import { Favori, Suivi, Visite } from '../interaction/interaction.entities';
import { Message } from '../message/message.entity';
import { CreateSujetDto, MeilleureReponseDto, QueryDetailDto, QuerySimilairesDto, QuerySujetDto, UpdateSujetDto } from './sujet.dto';
import { Sujet } from './sujet.entity';

/** A post as the app shows it (FRM-01 card, FRM-04 header). */
export interface SujetVue {
  id: number;
  auteurId: number;
  titre: string;
  /** Full text in the detail; null in a list and when masked for this reader. */
  contenu: string | null;
  /** About 160 characters of plain text for the card, null when masked for this reader. */
  extrait: string | null;
  categorie: Categorie;
  sport: Sport | null;
  tags: string[];
  images: string[];
  epingle: boolean;
  statut: Sujet['statut'];
  /** Masked by moderation: others see the placeholder, the author sees « seul toi vois ce post ». */
  masque: boolean;
  meilleureReponseId: number | null;
  score: number;
  nbReponses: number;
  nbUtile: number;
  nbMerci: number;
  /** « Ines M. t’a mentionné » above the card. */
  mentionneMoi: boolean;
  createdAt: Date;
  modifieLe: Date | null;
  derniereActivite: Date;
  moi: EtatLecteur & { favori: boolean; suivi: boolean };
}

/** A reply as FRM-04 shows it. Level-1 replies carry their level-2 answers in `reponses`. */
export interface MessageVue {
  id: number;
  sujetId: number;
  parentId: number | null;
  auteurId: number;
  enReponseAId: number | null;
  /** null when masked for this reader, deleted, or from a blocked author. */
  contenu: string | null;
  statut: Message['statut'];
  masque: boolean;
  supprime: boolean;
  /** Kept only as a placeholder because it has answers and its author is blocked by the reader. */
  bloque: boolean;
  /** « Auteur » badge: written by the post's author. */
  auteurDuSujet: boolean;
  meilleureReponse: boolean;
  score: number;
  nbUtile: number;
  nbMerci: number;
  createdAt: Date;
  modifieLe: Date | null;
  moi: EtatLecteur;
  reponses: MessageVue[];
}

export interface DetailSujet {
  sujet: SujetVue;
  meilleureReponse: MessageVue | null;
  reponses: MessageVue[];
  tri: TriReponses;
}

/** Strips light Markdown for the card excerpt. */
export function texteBrut(markdown: string): string {
  return markdown
    .replace(/!\[[^\]]*\]\([^)]*\)/g, '')
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
    .replace(/(\*\*|__|\*|_|`)/g, '')
    .replace(/^\s{0,3}(>|[-*+]|\d+\.)\s+/gm, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function extrait(markdown: string, longueur = 160): string {
  const t = texteBrut(markdown);
  if (t.length <= longueur) return t;
  const coupe = t.slice(0, longueur);
  return `${coupe.slice(0, Math.max(coupe.lastIndexOf(' '), longueur - 20)).trimEnd()}…`;
}

/** « Tendance »: votes, replies and reactions, fading with time since the last activity. */
const TENDANCE = `("s"."score" + 2 * "s"."nbReponses" + "s"."nbUtile" + "s"."nbMerci" + 1)
  / POWER(EXTRACT(EPOCH FROM (now() - "s"."derniereActivite")) / 3600 + 2, 1.3)`;

@Injectable()
export class SujetService {
  constructor(
    private readonly contenus: ContenusService,
    @InjectRepository(Sujet) private readonly repo: Repository<Sujet>,
    @InjectRepository(Message) private readonly messages: Repository<Message>,
    @InjectRepository(Favori) private readonly favoris: Repository<Favori>,
    @InjectRepository(Suivi) private readonly suivis: Repository<Suivi>,
    @InjectRepository(Visite) private readonly visites: Repository<Visite>,
  ) {}

  // --- FRM-01 -------------------------------------------------------------------------------

  /** The list, with `total` for « 248 discussions ». Pinned posts first. */
  async liste(q: QuerySujetDto): Promise<{ total: number; sujets: SujetVue[] }> {
    const lecteur = q.utilisateurId;
    if (q.favoris && !lecteur) throw new BadRequestException('Les favoris demandent utilisateurId.');
    const qb = this.repo.createQueryBuilder('s');

    // Published, plus the reader's own masked posts.
    qb.where(
      new Brackets((w) => {
        w.where(`s.statut = 'publie'`);
        if (lecteur) w.orWhere(`(s.statut = 'masque' AND s.auteurId = :lecteur)`, { lecteur });
      }),
    );
    const bloques = await this.contenus.bloques(lecteur);
    if (bloques.size) qb.andWhere('s.auteurId NOT IN (:...bloques)', { bloques: [...bloques] });
    if (q.categorie) qb.andWhere('s.categorie = :categorie', { categorie: q.categorie });
    if (q.sport) qb.andWhere('s.sport = :sport', { sport: q.sport });
    if (q.auteurId) qb.andWhere('s.auteurId = :auteurId', { auteurId: q.auteurId });
    if (q.tag) {
      qb.andWhere(`EXISTS (SELECT 1 FROM unnest(s.tags) t WHERE lower(t) = lower(:tag))`, { tag: q.tag.replace(/^#/, '') });
    }
    if (q.q?.trim()) {
      qb.andWhere(
        new Brackets((w) =>
          w
            .where('s.titre ILIKE :q')
            .orWhere('s.contenu ILIKE :q')
            .orWhere(`EXISTS (SELECT 1 FROM unnest(s.tags) t WHERE t ILIKE :q)`),
        ),
        { q: `%${q.q.trim().replace(/[%_]/g, '\\$&')}%` },
      );
    }
    if (q.favoris) {
      qb.andWhere(`s.id IN (SELECT f."sujetId" FROM ${this.favoris.metadata.tablePath} f WHERE f."utilisateurId" = :lecteur)`, { lecteur });
    }

    const total = await qb.getCount();
    const tri = q.tri ?? 'tendance';
    qb.orderBy('s.epingle', 'DESC');
    if (tri === 'tendance') qb.addSelect(TENDANCE, 'tendance').addOrderBy('tendance', 'DESC');
    else if (tri === 'top') qb.addOrderBy('s.score', 'DESC').addOrderBy('s.nbReponses', 'DESC');
    qb.addOrderBy('s.createdAt', 'DESC').addOrderBy('s.id', 'DESC');
    qb.offset(q.decalage ?? 0).limit(Math.min(q.limite ?? 20, LIMITES.pageMax));

    const sujets = await qb.getMany();
    return { total, sujets: await this.vues(sujets, lecteur, q.pseudo, false) };
  }

  /**
   * Categories with their post count and « nouveaux depuis ta dernière visite » (posts by others
   * created after the reader's last visit, see POST /visites).
   */
  async categories(utilisateurId?: number, sport?: Sport) {
    const visite = utilisateurId ? await this.visites.findOne({ where: { utilisateurId } }) : null;
    const qb = this.repo
      .createQueryBuilder('s')
      .select('s.categorie', 'categorie')
      .addSelect('COUNT(*)', 'n')
      .where(`s.statut = 'publie'`)
      .groupBy('s.categorie');
    if (sport) qb.andWhere('s.sport = :sport', { sport });
    if (visite) {
      qb.addSelect(`COUNT(*) FILTER (WHERE s."createdAt" > :depuis AND s."auteurId" <> :lecteur)`, 'nouveaux').setParameters({
        depuis: visite.derniereVisite,
        lecteur: utilisateurId,
      });
    }
    const rows = (await qb.getRawMany()) as { categorie: Categorie; n: string; nouveaux?: string }[];
    const categories = CATEGORIES.map((categorie) => {
      const r = rows.find((x) => x.categorie === categorie);
      return { categorie, nbSujets: Number(r?.n ?? 0), nouveaux: Number(r?.nouveaux ?? 0) };
    });
    return {
      total: categories.reduce((a, c) => a + c.nbSujets, 0),
      derniereVisite: visite?.derniereVisite ?? null,
      categories,
    };
  }

  // --- FRM-02 -------------------------------------------------------------------------------

  /** « Discussions similaires » while typing the title. */
  async similaires(q: QuerySimilairesDto) {
    const mots = [...new Set(normaliser(q.titre).split(/[^a-z0-9]+/).filter((m) => m.length > 3))].slice(0, 8);
    if (mots.length === 0) return [];
    // Pre-filter in SQL on any shared word (accents folded without the `unaccent` extension),
    // then score in JS.
    const titreSansAccents = `translate(lower("s"."titre"), 'àâäéèêëîïôöùûüçœ', 'aaaeeeeiioouuuco')`;
    const qb = this.repo
      .createQueryBuilder('s')
      .where(`s.statut = 'publie'`)
      .andWhere(
        new Brackets((w) => {
          mots.forEach((m, i) => w.orWhere(`${titreSansAccents} LIKE :m${i}`, { [`m${i}`]: `%${m}%` }));
        }),
      );
    if (q.exclureId) qb.andWhere('s.id <> :exclure', { exclure: q.exclureId });
    const candidats = await qb.orderBy('s.score', 'DESC').limit(100).getMany();

    return candidats
      .map((s) => ({ s, score: similarite(q, s) }))
      .filter((x) => x.score >= 0.25)
      .sort((a, b) => b.score - a.score || b.s.score - a.s.score)
      .slice(0, q.limite ?? 3)
      .map(({ s, score }) => ({
        id: s.id,
        titre: s.titre,
        categorie: s.categorie,
        sport: s.sport,
        auteurId: s.auteurId,
        score: s.score,
        nbReponses: s.nbReponses,
        aMeilleureReponse: s.meilleureReponseId != null,
        createdAt: s.createdAt,
        similarite: score,
      }));
  }

  async create(data: CreateSujetDto): Promise<SujetVue> {
    await this.contenus.verifierPeutEcrire(data.auteurId);
    const { analyse, masquer } = this.contenus.controler(`${data.titre}\n${data.contenu}`, data.confirmerMalgreAlerte);
    const sujet = await this.repo.save(
      this.repo.create({
        auteurId: data.auteurId,
        titre: data.titre.trim(),
        contenu: data.contenu.trim(),
        categorie: data.categorie,
        sport: data.sport ?? null,
        tags: nettoyerTags(data.tags, LIMITES.tags, LIMITES.tagMax),
        images: data.images ?? [],
        mentions: extraireMentions(data.contenu),
        statut: masquer ? 'masque' : 'publie',
        publieMalgreAlerte: masquer,
        scoreIa: analyse.score,
        motifIa: analyse.score >= 0.15 ? analyse.motif : null,
      }),
    );
    if (masquer) await this.contenus.signalerParIa('sujet', sujet.id, analyse);
    // Authors follow their own posts.
    await this.suivis.upsert({ utilisateurId: data.auteurId, type: 'sujet', cibleId: sujet.id }, ['utilisateurId', 'type', 'cibleId']);
    return (await this.vues([sujet], data.auteurId, undefined, true))[0];
  }

  async update(id: number, data: UpdateSujetDto): Promise<SujetVue> {
    const sujet = await this.contenus.sujet(id);
    this.verifierAuteur(sujet, data.utilisateurId);
    if (sujet.statut === 'supprime') throw new NotFoundException('Cette discussion a été supprimée.');
    await this.contenus.verifierPeutEcrire(data.utilisateurId);

    const titre = data.titre?.trim() ?? sujet.titre;
    const contenu = data.contenu?.trim() ?? sujet.contenu;
    if (data.titre !== undefined || data.contenu !== undefined) {
      const { analyse, masquer } = this.contenus.controler(`${titre}\n${contenu}`, data.confirmerMalgreAlerte);
      Object.assign(sujet, { scoreIa: analyse.score, motifIa: analyse.score >= 0.15 ? analyse.motif : null });
      if (masquer && sujet.statut === 'publie') {
        Object.assign(sujet, { statut: 'masque', publieMalgreAlerte: true });
        await this.contenus.signalerParIa('sujet', id, analyse);
      }
    }
    Object.assign(sujet, {
      titre,
      contenu,
      mentions: extraireMentions(contenu),
      modifieLe: new Date(),
      ...(data.categorie && { categorie: data.categorie }),
      ...(data.sport !== undefined && { sport: data.sport }),
      ...(data.tags && { tags: nettoyerTags(data.tags, LIMITES.tags, LIMITES.tagMax) }),
      ...(data.images && { images: data.images }),
    });
    await this.repo.save(sujet);
    return (await this.vues([sujet], data.utilisateurId, undefined, true))[0];
  }

  /** By its author. Kept in the database (moderation history), gone from every list. */
  async remove(id: number, utilisateurId: number) {
    const sujet = await this.contenus.sujet(id);
    this.verifierAuteur(sujet, utilisateurId);
    await this.repo.update(id, { statut: 'supprime' });
    return { deleted: true, id };
  }

  // --- FRM-04 -------------------------------------------------------------------------------

  async detail(id: number, q: QueryDetailDto): Promise<DetailSujet> {
    const lecteur = q.utilisateurId;
    const sujet = await this.contenus.sujet(id);
    if (sujet.statut === 'supprime') throw new NotFoundException('Cette discussion a été supprimée.');
    const [vue] = await this.vues([sujet], lecteur, undefined, true);

    const tri = q.tri ?? 'utiles';
    const tous = await this.messages.find({ where: { sujetId: id }, order: { createdAt: 'ASC', id: 'ASC' } });
    const bloques = await this.contenus.bloques(lecteur);
    const etats = await this.contenus.etats(lecteur, 'message', tous);

    const vueMessage = (m: Message): MessageVue => {
      const masquePourMoi = m.statut === 'masque' && m.auteurId !== lecteur;
      const bloque = bloques.has(m.auteurId);
      return {
        id: m.id,
        sujetId: m.sujetId,
        parentId: m.parentId,
        auteurId: m.auteurId,
        enReponseAId: m.enReponseAId,
        contenu: m.statut === 'supprime' || masquePourMoi || bloque ? null : m.contenu,
        statut: m.statut,
        masque: m.statut === 'masque',
        supprime: m.statut === 'supprime',
        bloque,
        auteurDuSujet: m.auteurId === sujet.auteurId,
        meilleureReponse: m.id === sujet.meilleureReponseId,
        score: m.score,
        nbUtile: m.nbUtile,
        nbMerci: m.nbMerci,
        createdAt: m.createdAt,
        modifieLe: m.modifieLe,
        moi: etats.get(m.id)!,
        reponses: [],
      };
    };
    /** Deleted replies and blocked authors stay only as placeholders for their answers. */
    const garder = (v: MessageVue) => !(v.supprime || v.bloque) || v.reponses.length > 0;

    const niveau1 = new Map<number, MessageVue>();
    for (const m of tous) if (m.parentId == null) niveau1.set(m.id, vueMessage(m));
    for (const m of tous) {
      if (m.parentId == null) continue;
      const v = vueMessage(m);
      if (garder(v)) niveau1.get(m.parentId)?.reponses.push(v);
    }

    const poids = (v: MessageVue) => v.score + v.nbUtile;
    const liste = [...niveau1.values()].filter(garder);
    if (tri === 'utiles') liste.sort((a, b) => poids(b) - poids(a) || +a.createdAt - +b.createdAt);
    else if (tri === 'recentes') liste.sort((a, b) => +b.createdAt - +a.createdAt);

    const meilleure = liste.find((v) => v.meilleureReponse && v.statut === 'publie') ?? null;
    return { sujet: vue, meilleureReponse: meilleure, reponses: liste.filter((v) => v !== meilleure), tri };
  }

  /** Only the post's author picks (or clears) the best answer: a published level-1 reply by someone else. */
  async meilleureReponse(id: number, data: MeilleureReponseDto) {
    const sujet = await this.contenus.sujet(id);
    if (sujet.auteurId !== data.utilisateurId) throw new ForbiddenException('Seul l’auteur du post choisit la meilleure réponse.');
    if (data.messageId != null) {
      const m = await this.contenus.message(data.messageId);
      if (m.sujetId !== id) throw new BadRequestException('Cette réponse n’est pas dans cette discussion.');
      if (m.parentId != null) throw new BadRequestException('Choisis une réponse directe au post.');
      if (m.statut !== 'publie') throw new BadRequestException('Cette réponse n’est pas visible.');
      if (m.auteurId === sujet.auteurId) throw new BadRequestException('Tu ne peux pas choisir ta propre réponse.');
    }
    await this.repo.update(id, { meilleureReponseId: data.messageId });
    return { sujetId: id, meilleureReponseId: data.messageId };
  }

  // --- Helpers ------------------------------------------------------------------------------

  private verifierAuteur(sujet: Sujet, utilisateurId: number) {
    if (sujet.auteurId !== utilisateurId) throw new ForbiddenException('Seul l’auteur peut modifier ou supprimer ce post.');
  }

  /** Builds the views with the reader's votes, reactions, favourites and follows. */
  async vues(sujets: Sujet[], lecteur?: number, pseudo?: string, complet = false): Promise<SujetVue[]> {
    if (sujets.length === 0) return [];
    const ids = sujets.map((s) => s.id);
    const [etats, favoris, suivis] = await Promise.all([
      this.contenus.etats(lecteur, 'sujet', sujets),
      lecteur ? this.favoris.find({ where: { utilisateurId: lecteur, sujetId: In(ids) } }) : [],
      lecteur ? this.suivis.find({ where: { utilisateurId: lecteur, type: 'sujet', cibleId: In(ids) } }) : [],
    ]);
    const favori = new Set(favoris.map((f) => f.sujetId));
    const suivi = new Set(suivis.map((f) => f.cibleId));
    const handle = pseudo?.replace(/^@/, '').toLowerCase();
    return sujets.map((s) => {
      const masquePourMoi = s.statut === 'masque' && s.auteurId !== lecteur;
      return {
        id: s.id,
        auteurId: s.auteurId,
        titre: s.titre,
        contenu: complet && !masquePourMoi ? s.contenu : null,
        extrait: masquePourMoi ? null : extrait(s.contenu),
        categorie: s.categorie,
        sport: s.sport,
        tags: s.tags,
        images: masquePourMoi ? [] : s.images,
        epingle: s.epingle,
        statut: s.statut,
        masque: s.statut === 'masque',
        meilleureReponseId: s.meilleureReponseId,
        score: s.score,
        nbReponses: s.nbReponses,
        nbUtile: s.nbUtile,
        nbMerci: s.nbMerci,
        mentionneMoi: !!handle && s.auteurId !== lecteur && s.mentions.includes(handle),
        createdAt: s.createdAt,
        modifieLe: s.modifieLe,
        derniereActivite: s.derniereActivite,
        moi: { ...etats.get(s.id)!, favori: favori.has(s.id), suivi: suivi.has(s.id) },
      };
    });
  }
}
