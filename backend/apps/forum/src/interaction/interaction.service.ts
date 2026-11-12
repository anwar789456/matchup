import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';

import { ContenusService } from '../commun/contenus.service';
import type { Cible, TypeReaction } from '../forum.constants';
import { LIMITES } from '../forum.constants';
import { Message } from '../message/message.entity';
import { Sanction } from '../moderation/moderation.entities';
import { Sujet } from '../sujet/sujet.entity';
import { Blocage, Favori, Reaction, Suivi, Visite, Vote } from './interaction.entities';

/**
 * Votes, « Utile » / « Merci », saved posts, follows, blocked authors, last visits and a member's
 * forum profile. Every write is idempotent: sending the same state twice changes nothing.
 */
@Injectable()
export class InteractionService {
  constructor(
    private readonly contenus: ContenusService,
    @InjectRepository(Vote) private readonly votes: Repository<Vote>,
    @InjectRepository(Reaction) private readonly reactions: Repository<Reaction>,
    @InjectRepository(Favori) private readonly favoris: Repository<Favori>,
    @InjectRepository(Suivi) private readonly suivis: Repository<Suivi>,
    @InjectRepository(Blocage) private readonly blocages: Repository<Blocage>,
    @InjectRepository(Visite) private readonly visites: Repository<Visite>,
    @InjectRepository(Sanction) private readonly sanctions: Repository<Sanction>,
    @InjectRepository(Sujet) private readonly sujets: Repository<Sujet>,
    @InjectRepository(Message) private readonly messages: Repository<Message>,
  ) {}

  /** +1, −1, or 0 to remove. Not on your own content, not while suspended. */
  async voter(cible: Cible, cibleId: number, utilisateurId: number, valeur: 1 | 0 | -1) {
    const c = await this.contenus.contenuActif(cible, cibleId, true);
    if (c.auteurId === utilisateurId) throw new BadRequestException('Tu ne peux pas voter pour ton propre message.');
    await this.contenus.verifierPeutEcrire(utilisateurId);
    if (valeur === 0) await this.votes.delete({ utilisateurId, cible, cibleId });
    else await this.votes.upsert({ utilisateurId, cible, cibleId, valeur }, ['utilisateurId', 'cible', 'cibleId']);
    const score = await this.contenus.recompterVotes(cible, cibleId);
    return { cible, cibleId, score, monVote: valeur };
  }

  async reagir(cible: Cible, cibleId: number, type: TypeReaction, utilisateurId: number, actif: boolean) {
    const c = await this.contenus.contenuActif(cible, cibleId, true);
    if (c.auteurId === utilisateurId) throw new BadRequestException('Tu ne peux pas réagir à ton propre message.');
    await this.contenus.verifierPeutEcrire(utilisateurId);
    if (actif) await this.reactions.upsert({ utilisateurId, cible, cibleId, type }, ['utilisateurId', 'cible', 'cibleId', 'type']);
    else await this.reactions.delete({ utilisateurId, cible, cibleId, type });
    const compte = await this.contenus.recompterReactions(cible, cibleId);
    return { cible, cibleId, type, actif, ...compte };
  }

  async favori(sujetId: number, utilisateurId: number, actif: boolean) {
    await this.contenus.contenuActif('sujet', sujetId);
    if (actif) await this.favoris.upsert({ utilisateurId, sujetId }, ['utilisateurId', 'sujetId']);
    else await this.favoris.delete({ utilisateurId, sujetId });
    return { sujetId, favori: actif };
  }

  /** Follow a discussion (FRM-04 bell) or a member (« Suivre »). */
  async suivre(type: 'sujet' | 'membre', cibleId: number, utilisateurId: number, actif: boolean) {
    if (type === 'sujet') await this.contenus.contenuActif('sujet', cibleId);
    if (type === 'membre' && cibleId === utilisateurId) throw new BadRequestException('Tu ne peux pas te suivre toi-même.');
    if (actif) await this.suivis.upsert({ utilisateurId, type, cibleId }, ['utilisateurId', 'type', 'cibleId']);
    else await this.suivis.delete({ utilisateurId, type, cibleId });
    return { type, cibleId, suivi: actif };
  }

  async bloquer(bloqueId: number, utilisateurId: number, actif: boolean) {
    if (bloqueId === utilisateurId) throw new BadRequestException('Tu ne peux pas te masquer toi-même.');
    if (actif) await this.blocages.upsert({ utilisateurId, bloqueId }, ['utilisateurId', 'bloqueId']);
    else await this.blocages.delete({ utilisateurId, bloqueId });
    return { bloqueId, bloque: actif };
  }

  async listeBloques(utilisateurId: number) {
    return this.blocages.find({ where: { utilisateurId }, order: { createdAt: 'DESC' } });
  }

  /** Saves « now » as the last visit and returns the previous one. */
  async visite(utilisateurId: number) {
    const avant = await this.visites.findOne({ where: { utilisateurId } });
    const maintenant = new Date();
    await this.visites.save({ utilisateurId, derniereVisite: maintenant });
    return { utilisateurId, precedente: avant?.derniereVisite ?? null, derniereVisite: maintenant };
  }

  /**
   * A member's forum profile: what they wrote, the votes they received, best answers, followers,
   * and whether the reader follows or blocked them. `peutPublier` is false while suspended.
   */
  async membre(id: number, lecteur?: number) {
    const publie = { auteurId: id, statut: 'publie' as const };
    const [nbSujets, nbReponses, recus, nbMeilleures, nbAbonnes, suiviParMoi, bloqueParMoi, suspension, nbAvertissements] =
      await Promise.all([
        this.sujets.count({ where: publie }),
        this.messages.count({ where: publie }),
        Promise.all([
          this.sujets.sum('score', publie),
          this.messages.sum('score', publie),
        ]),
        this.sujets
          .createQueryBuilder('s')
          .innerJoin(Message, 'm', 'm.id = s.meilleureReponseId')
          .where('m.auteurId = :id', { id })
          .andWhere(`s.statut = 'publie'`)
          .getCount(),
        this.suivis.count({ where: { type: 'membre', cibleId: id } }),
        lecteur ? this.suivis.exist({ where: { utilisateurId: lecteur, type: 'membre', cibleId: id } }) : false,
        lecteur ? this.blocages.exist({ where: { utilisateurId: lecteur, bloqueId: id } }) : false,
        this.contenus.suspension(id),
        this.sanctions.count({ where: { utilisateurId: id, type: 'avertissement' } }),
      ]);
    return {
      utilisateurId: id,
      nbSujets,
      nbReponses,
      votesRecus: (recus[0] ?? 0) + (recus[1] ?? 0),
      nbMeilleuresReponses: nbMeilleures,
      nbAbonnes,
      suiviParMoi,
      bloqueParMoi,
      peutPublier: !suspension,
      suspenduJusquA: suspension?.jusquA ?? null,
      nbAvertissements,
      avertissementsAvantSuspension: LIMITES.avertissementsAvantSuspension,
    };
  }

  /** The members a user follows, for « Abonnements ». */
  async abonnements(utilisateurId: number) {
    const rows = await this.suivis.find({ where: { utilisateurId, type: In(['membre', 'sujet']) }, order: { createdAt: 'DESC' } });
    return {
      membres: rows.filter((r) => r.type === 'membre').map((r) => r.cibleId),
      sujets: rows.filter((r) => r.type === 'sujet').map((r) => r.cibleId),
    };
  }
}
