import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsDateString,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

import { FORMATS, SPORTS, STATUTS_TOURNOI, TYPES_TOURNOI } from './tournoi.entity';

export class PrixDto {
  @ApiProperty({ example: 1 })
  @IsInt()
  @Min(1)
  rang: number;

  @ApiProperty({ example: '600 DT + trophée' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  libelle: string;
}

export class CreateTournoiDto {
  @ApiProperty({ example: 'Padel Cup Lac 2' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  nom: string;

  @ApiPropertyOptional({ enum: TYPES_TOURNOI, default: 'tournoi' })
  @IsOptional()
  @IsIn(TYPES_TOURNOI)
  type?: string;

  @ApiProperty({ example: 'padel', enum: SPORTS })
  @IsIn(SPORTS)
  sport: string;

  @ApiPropertyOptional({ example: 'Tournoi en double, poules puis tableau final.' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ example: 'https://…/affiche.jpg' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  afficheUrl?: string;

  @ApiPropertyOptional({ enum: FORMATS, default: 'elimination_directe' })
  @IsOptional()
  @IsIn(FORMATS)
  format?: string;

  @ApiPropertyOptional({ example: 'Matchs en 2 sets gagnants, super tie-break au 3e.' })
  @IsOptional()
  @IsString()
  reglement?: string;

  @ApiPropertyOptional({ example: 3, description: 'Niveau MatchUp de 1 à 7' })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(7)
  niveauMin?: number;

  @ApiPropertyOptional({ example: 5 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(7)
  niveauMax?: number;

  @ApiProperty({ example: '2026-11-14T09:00:00.000Z' })
  @IsDateString()
  dateDebut: string;

  @ApiPropertyOptional({ example: '2026-11-15T19:00:00.000Z' })
  @IsOptional()
  @IsDateString()
  dateFin?: string;

  @ApiPropertyOptional({ example: '2026-11-12T23:59:00.000Z' })
  @IsOptional()
  @IsDateString()
  dateLimiteInscription?: string;

  @ApiProperty({ example: 'Smash Padel Club' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  lieu: string;

  @ApiPropertyOptional({ example: 'Les Berges du Lac' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  ville?: string;

  @ApiPropertyOptional({ example: 1, description: 'id du terrain (module réservation)' })
  @IsOptional()
  @IsInt()
  terrainId?: number;

  @ApiPropertyOptional({ example: ['Court 1', 'Court 2'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  terrains?: string[];

  @ApiPropertyOptional({ default: 0, description: 'Par équipe (DT)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  fraisInscription?: number;

  @ApiPropertyOptional({ default: 0, example: 1000, description: 'Dotation totale (DT)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  dotation?: number;

  @ApiPropertyOptional({ type: [PrixDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PrixDto)
  prix?: PrixDto[];

  @ApiPropertyOptional({ default: 16 })
  @IsOptional()
  @IsInt()
  @Min(2)
  nbEquipesMax?: number;

  @ApiPropertyOptional({ default: 1, example: 2, description: 'Joueurs minimum par équipe' })
  @IsOptional()
  @IsInt()
  @Min(1)
  joueursParEquipe?: number;

  @ApiPropertyOptional({ example: 3, description: 'Remplaçants compris' })
  @IsOptional()
  @IsInt()
  @Min(1)
  joueursMaxParEquipe?: number;

  @ApiPropertyOptional({ example: 2 })
  @IsOptional()
  @IsInt()
  @Min(1)
  nbPoules?: number;

  @ApiPropertyOptional({ default: 2 })
  @IsOptional()
  @IsInt()
  @Min(1)
  qualifiesParPoule?: number;

  @ApiPropertyOptional({ default: 60 })
  @IsOptional()
  @IsInt()
  @Min(5)
  dureeMatchMinutes?: number;

  @ApiPropertyOptional({ default: 15 })
  @IsOptional()
  @IsInt()
  @Min(0)
  reposMinutes?: number;

  @ApiPropertyOptional({
    enum: STATUTS_TOURNOI,
    default: 'brouillon',
    description: 'Préfère les routes /publier, /cloturer, /annuler qui vérifient les règles.',
  })
  @IsOptional()
  @IsIn(STATUTS_TOURNOI)
  statut?: string;

  @ApiPropertyOptional({ example: 1, description: 'id d’un utilisateur (module utilisateur)' })
  @IsOptional()
  @IsInt()
  organisateurId?: number;
}

/** Tous les champs sont facultatifs : on n’envoie que ce qui change. */
export class UpdateTournoiDto extends PartialType(CreateTournoiDto) {}

/** Filtres de la liste : GET /tournois?sport=padel&ville=…&fraisMax=50 */
export class QueryTournoiDto {
  @ApiPropertyOptional({ enum: SPORTS })
  @IsOptional()
  @IsIn(SPORTS)
  sport?: string;

  @ApiPropertyOptional({ enum: TYPES_TOURNOI })
  @IsOptional()
  @IsIn(TYPES_TOURNOI)
  type?: string;

  @ApiPropertyOptional({ enum: STATUTS_TOURNOI })
  @IsOptional()
  @IsIn(STATUTS_TOURNOI)
  statut?: string;

  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  organisateurId?: number;

  @ApiPropertyOptional({ example: 'La Marsa', description: 'Ville (sans tenir compte des majuscules)' })
  @IsOptional()
  @IsString()
  ville?: string;

  @ApiPropertyOptional({ example: '2026-11-01', description: 'Tournois qui commencent à partir de cette date' })
  @IsOptional()
  @IsDateString()
  du?: string;

  @ApiPropertyOptional({ example: '2026-11-30' })
  @IsOptional()
  @IsDateString()
  au?: string;

  @ApiPropertyOptional({ example: 3.5, description: 'Tournois ouverts à ce niveau' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  niveau?: number;

  @ApiPropertyOptional({ example: 50, description: 'Frais d’inscription maximum (DT)' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  fraisMax?: number;

  @ApiPropertyOptional({ description: 'Recherche dans le nom et le lieu' })
  @IsOptional()
  @IsString()
  q?: string;

  @ApiPropertyOptional({ description: 'true = seulement ceux où il reste des places' })
  @IsOptional()
  @Type(() => String)
  @IsIn(['true', 'false'])
  placesLibres?: string;
}

export class AnnulerTournoiDto {
  @ApiProperty({ example: 'Pas assez d’équipes inscrites.' })
  @IsString()
  @IsNotEmpty()
  motif: string;
}

export class CreneauDto {
  @ApiProperty({ example: '2026-11-14T08:00:00.000Z' })
  @IsDateString()
  debut: string;

  @ApiProperty({ example: '2026-11-14T20:00:00.000Z' })
  @IsDateString()
  fin: string;
}

/** Contraintes du générateur de tableau et de calendrier. */
export class GenererTableauDto {
  @ApiPropertyOptional({ example: ['Court 1', 'Court 2'], description: 'Par défaut : les terrains du tournoi' })
  @IsOptional()
  @IsArray()
  @ArrayMinSize(1)
  @IsString({ each: true })
  terrains?: string[];

  @ApiPropertyOptional({ type: [CreneauDto], description: 'Plages horaires ; par défaut 9h–21h chaque jour du tournoi' })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreneauDto)
  creneaux?: CreneauDto[];

  @ApiPropertyOptional({ example: 45 })
  @IsOptional()
  @IsInt()
  @Min(5)
  dureeMatchMinutes?: number;

  @ApiPropertyOptional({ example: 15, description: 'Repos minimum entre deux matchs d’une équipe' })
  @IsOptional()
  @IsInt()
  @Min(0)
  reposMinutes?: number;

  @ApiPropertyOptional({ example: 2 })
  @IsOptional()
  @IsInt()
  @Min(1)
  nbPoules?: number;

  @ApiPropertyOptional({ example: 2 })
  @IsOptional()
  @IsInt()
  @Min(1)
  qualifiesParPoule?: number;

  @ApiPropertyOptional({ default: false, description: 'Tirage au sort au lieu des têtes de série' })
  @IsOptional()
  @IsBoolean()
  melanger?: boolean;

  @ApiPropertyOptional({ default: false, description: 'true = aperçu seulement, rien n’est enregistré' })
  @IsOptional()
  @IsBoolean()
  apercu?: boolean;
}

export class DashboardQueryDto {
  @ApiProperty({ example: 1 })
  @Type(() => Number)
  @IsInt()
  organisateurId: number;
}

/** Marque « Ton équipe » dans le tableau, le classement et le calendrier. */
export class EquipeQueryDto {
  @ApiPropertyOptional({ example: 3 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  equipeId?: number;
}

export class EchangeDto {
  @ApiProperty({ example: 3 })
  @IsInt()
  equipeA: number;

  @ApiProperty({ example: 5 })
  @IsInt()
  equipeB: number;
}
