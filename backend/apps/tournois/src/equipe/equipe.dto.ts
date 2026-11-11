import { ApiProperty, ApiPropertyOptional, OmitType, PartialType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsArray, IsIn, IsInt, IsNotEmpty, IsNumber, IsOptional, IsString, MaxLength, Min } from 'class-validator';

import { STATUTS_EQUIPE } from './equipe.entity';

/** Inscription d’une équipe (le capitaine est ajouté aux joueurs s’il n’y est pas). */
export class CreateEquipeDto {
  @ApiProperty({ example: 1 })
  @IsInt()
  tournoiId: number;

  @ApiProperty({ example: 'Les Smashers' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  nom: string;

  @ApiPropertyOptional({ example: 'https://…/logo.png' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  logoUrl?: string;

  @ApiProperty({ example: 1, description: 'id d’un utilisateur (module utilisateur)' })
  @IsInt()
  capitaineId: number;

  @ApiPropertyOptional({ example: [1, 2], description: 'ids des joueurs (module utilisateur)' })
  @IsOptional()
  @IsArray()
  @IsInt({ each: true })
  joueursIds?: number[];

  @ApiPropertyOptional({ example: 1, description: 'Tête de série (organisateur)' })
  @IsOptional()
  @IsInt()
  @Min(1)
  seed?: number;
}

/** Nom, logo, capitaine, joueurs, tête de série. Le tournoi ne change pas. */
export class UpdateEquipeDto extends PartialType(OmitType(CreateEquipeDto, ['tournoiId'] as const)) {}

/** Filtres de la liste : GET /equipes?tournoiId=…&joueurId=… */
export class QueryEquipeDto {
  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  tournoiId?: number;

  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  capitaineId?: number;

  @ApiPropertyOptional({ example: 2, description: 'Équipes dont ce joueur fait partie' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  joueurId?: number;

  @ApiPropertyOptional({ enum: STATUTS_EQUIPE })
  @IsOptional()
  @IsIn(STATUTS_EQUIPE)
  statut?: string;
}

export class JoueurDto {
  @ApiProperty({ example: 2 })
  @IsInt()
  joueurId: number;
}

export class RejoindreDto extends JoueurDto {
  @ApiProperty({ example: 'K7QX2M9P', description: 'Code du lien d’invitation' })
  @IsString()
  @IsNotEmpty()
  code: string;
}

export class PaiementEquipeDto {
  @ApiPropertyOptional({ example: 12, description: 'id du paiement (module paiement)' })
  @IsOptional()
  @IsInt()
  paiementId?: number;

  @ApiPropertyOptional({ example: 120, description: 'Par défaut : les frais du tournoi' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  montant?: number;
}

export class RefusDto {
  @ApiProperty({ example: 'Le tournoi est réservé aux joueurs de niveau 4 et plus.' })
  @IsString()
  @IsNotEmpty()
  motif: string;
}
