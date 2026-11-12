import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { FindOptionsWhere, Not, Repository } from 'typeorm';

import { ContenusService } from '../commun/contenus.service';
import { extraireMentions } from '../ia/ia.logic';
import { Suivi } from '../interaction/interaction.entities';
import { CreateMessageDto, QueryMessageDto, UpdateMessageDto } from './message.dto';
import { Message } from './message.entity';

/** Who to tell about a new reply (for the notification system, which lives outside the forum). */
export interface ANotifier {
  /** Followers of the discussion (its author included), minus the one who replied. */
  abonnesIds: number[];
  /** The user being answered (« X t’a répondu »), if any. */
  repondA: number | null;
  /** `@pseudo` handles mentioned in the reply. */
  mentions: string[];
}

@Injectable()
export class MessageService {
  constructor(
    private readonly contenus: ContenusService,
    @InjectRepository(Message) private readonly repo: Repository<Message>,
    @InjectRepository(Suivi) private readonly suivis: Repository<Suivi>,
  ) {}

  /** Visible replies only (published), oldest first. The thread view is GET /sujets/:id. */
  findAll(q: QueryMessageDto): Promise<Message[]> {
    const where: FindOptionsWhere<Message> = { statut: 'publie' };
    if (q.sujetId) where.sujetId = q.sujetId;
    if (q.auteurId) where.auteurId = q.auteurId;
    return this.repo.find({ where, order: { createdAt: 'ASC', id: 'ASC' }, take: 200 });
  }

  async findOne(id: number): Promise<Message> {
    const m = await this.contenus.message(id);
    if (m.statut !== 'publie') throw new NotFoundException(`Réponse ${id} introuvable`);
    return m;
  }

  async create(data: CreateMessageDto): Promise<{ message: Message; notifier: ANotifier }> {
    const sujet = await this.contenus.sujet(data.sujetId);
    if (sujet.statut === 'supprime') throw new NotFoundException('Cette discussion a été supprimée.');
    if (sujet.statut === 'masque' && sujet.auteurId !== data.auteurId) {
      throw new ForbiddenException('Cette discussion est en cours de vérification.');
    }
    await this.contenus.verifierPeutEcrire(data.auteurId);

    // Two levels: answering a level-2 reply attaches to its level-1 parent.
    let parentId: number | null = null;
    let enReponseAId: number | null = null;
    if (data.parentId != null) {
      const parent = await this.contenus.message(data.parentId);
      if (parent.sujetId !== data.sujetId) throw new BadRequestException('Cette réponse n’est pas dans cette discussion.');
      if (parent.statut === 'supprime') throw new BadRequestException('Cette réponse a été supprimée.');
      parentId = parent.parentId ?? parent.id;
      enReponseAId = parent.auteurId;
    }

    const { analyse, masquer } = this.contenus.controler(data.contenu, data.confirmerMalgreAlerte);
    const message = await this.repo.save(
      this.repo.create({
        sujetId: data.sujetId,
        parentId,
        auteurId: data.auteurId,
        enReponseAId,
        contenu: data.contenu.trim(),
        mentions: extraireMentions(data.contenu),
        statut: masquer ? 'masque' : 'publie',
        publieMalgreAlerte: masquer,
        scoreIa: analyse.score,
        motifIa: analyse.score >= 0.15 ? analyse.motif : null,
      }),
    );
    if (masquer) await this.contenus.signalerParIa('message', message.id, analyse);
    await this.contenus.recompterReponses(data.sujetId, !masquer);

    const abonnes = masquer
      ? []
      : await this.suivis.find({ where: { type: 'sujet', cibleId: data.sujetId, utilisateurId: Not(data.auteurId) } });
    return {
      message,
      notifier: {
        abonnesIds: abonnes.map((s) => s.utilisateurId),
        repondA: !masquer && enReponseAId !== data.auteurId ? enReponseAId : null,
        mentions: masquer ? [] : message.mentions,
      },
    };
  }

  async update(id: number, data: UpdateMessageDto): Promise<Message> {
    const m = await this.contenus.message(id);
    if (m.auteurId !== data.utilisateurId) throw new ForbiddenException('Seul l’auteur peut modifier cette réponse.');
    if (m.statut === 'supprime') throw new NotFoundException('Cette réponse a été supprimée.');
    await this.contenus.verifierPeutEcrire(data.utilisateurId);

    const { analyse, masquer } = this.contenus.controler(data.contenu, data.confirmerMalgreAlerte);
    Object.assign(m, {
      contenu: data.contenu.trim(),
      mentions: extraireMentions(data.contenu),
      modifieLe: new Date(),
      scoreIa: analyse.score,
      motifIa: analyse.score >= 0.15 ? analyse.motif : null,
    });
    if (masquer && m.statut === 'publie') {
      Object.assign(m, { statut: 'masque', publieMalgreAlerte: true });
      await this.contenus.signalerParIa('message', id, analyse);
    }
    await this.repo.save(m);
    await this.contenus.recompterReponses(m.sujetId);
    return m;
  }

  /** By its author. Answers stay; the reply becomes « Message supprimé » in the thread. */
  async remove(id: number, utilisateurId: number) {
    const m = await this.contenus.message(id);
    if (m.auteurId !== utilisateurId) throw new ForbiddenException('Seul l’auteur peut supprimer cette réponse.');
    await this.repo.update(id, { statut: 'supprime' });
    // A deleted best answer is no longer the best answer.
    await this.contenus.sujets.update({ id: m.sujetId, meilleureReponseId: id }, { meilleureReponseId: null });
    await this.contenus.recompterReponses(m.sujetId);
    return { deleted: true, id };
  }
}
