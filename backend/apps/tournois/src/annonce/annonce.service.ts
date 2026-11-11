import { Injectable, NotFoundException } from '@nestjs/common';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { InjectRepository } from '@nestjs/typeorm';
import { IsBoolean, IsIn, IsInt, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';
import { In, Repository } from 'typeorm';

import { Equipe } from '../equipe/equipe.entity';
import { Tournoi } from '../tournoi/tournoi.entity';
import { Annonce } from './annonce.entity';

export class CreateAnnonceDto {
  @ApiProperty({ example: 'Changement d’horaire' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  titre: string;

  @ApiProperty({ example: 'Les demi-finales commencent à 18h au lieu de 17h.' })
  @IsString()
  @IsNotEmpty()
  message: string;

  @ApiPropertyOptional({ enum: ['toutes', 'confirmees', 'en_attente'], default: 'confirmees' })
  @IsOptional()
  @IsIn(['toutes', 'confirmees', 'en_attente'])
  destinataires?: string;

  @ApiPropertyOptional({ default: true, description: 'Envoyer aussi par email' })
  @IsOptional()
  @IsBoolean()
  email?: boolean;

  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @IsInt()
  auteurId?: number;
}

const STATUTS: Record<string, string[]> = {
  toutes: ['en_attente', 'confirmee'],
  confirmees: ['confirmee'],
  en_attente: ['en_attente'],
};

/**
 * Annonces de l’organisateur. Chaque annonce garde la liste des joueurs visés
 * (`destinatairesIds`) : le module de notifications / emails les lit pour envoyer.
 */
@Injectable()
export class AnnonceService {
  constructor(
    @InjectRepository(Annonce) private readonly repo: Repository<Annonce>,
    @InjectRepository(Tournoi) private readonly tournois: Repository<Tournoi>,
    @InjectRepository(Equipe) private readonly equipes: Repository<Equipe>,
  ) {}

  async liste(tournoiId: number): Promise<Annonce[]> {
    await this.tournoi(tournoiId);
    return this.repo.find({ where: { tournoiId }, order: { createdAt: 'DESC' } });
  }

  async creer(tournoiId: number, data: CreateAnnonceDto): Promise<Annonce> {
    const t = await this.tournoi(tournoiId);
    const destinataires = data.destinataires ?? 'confirmees';
    const equipes = await this.equipes.find({ where: { tournoiId, statut: In(STATUTS[destinataires]) } });
    const ids = [...new Set(equipes.flatMap((e) => e.joueursIds))];
    return this.repo.save(
      this.repo.create({
        ...data,
        tournoiId,
        destinataires,
        destinatairesIds: ids,
        auteurId: data.auteurId ?? t.organisateurId ?? null,
      }),
    );
  }

  async supprimer(tournoiId: number, id: number) {
    const a = await this.repo.findOne({ where: { id, tournoiId } });
    if (!a) throw new NotFoundException(`Annonce ${id} introuvable`);
    await this.repo.remove(a);
    return { deleted: true, id };
  }

  private async tournoi(id: number): Promise<Tournoi> {
    const t = await this.tournois.findOne({ where: { id } });
    if (!t) throw new NotFoundException(`Tournoi ${id} introuvable`);
    return t;
  }
}
