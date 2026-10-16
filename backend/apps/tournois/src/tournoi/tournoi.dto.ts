import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsDateString, IsIn, IsInt, IsNotEmpty, IsNumber, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class CreateTournoiDto {
  @ApiProperty({ example: 'Padel Cup Lac 2' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  nom: string;

  @ApiProperty({ example: 'padel', enum: ['football', 'padel', 'basketball'] })
  @IsIn(['football', 'padel', 'basketball'])
  sport: string;

  @ApiPropertyOptional({ example: 'Tournoi en double, poules puis tableau final.' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: '2026-11-14T09:00:00.000Z' })
  @IsDateString()
  dateDebut: string;

  @ApiPropertyOptional({ example: '2026-11-15T19:00:00.000Z' })
  @IsOptional()
  @IsDateString()
  dateFin?: string;

  @ApiProperty({ example: 'Smash Padel Club' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  lieu: string;

  @ApiPropertyOptional({ default: 0, description: 'Par équipe (DT)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  fraisInscription?: number;

  @ApiPropertyOptional({ default: 16 })
  @IsOptional()
  @IsInt()
  @Min(2)
  nbEquipesMax?: number;

  @ApiPropertyOptional({ enum: ['brouillon', 'inscriptions_ouvertes', 'en_cours', 'termine'], default: 'brouillon' })
  @IsOptional()
  @IsIn(['brouillon', 'inscriptions_ouvertes', 'en_cours', 'termine'])
  statut?: string;

  @ApiPropertyOptional({ example: 1, description: 'id d’un utilisateur (module utilisateur)' })
  @IsOptional()
  @IsInt()
  organisateurId?: number;
}

/** Tous les champs sont facultatifs : on n’envoie que ce qui change. */
export class UpdateTournoiDto extends PartialType(CreateTournoiDto) {}

/** Filtres de la liste : GET /tournois?sport=…  */
export class QueryTournoiDto {
  @ApiPropertyOptional({ example: 'padel', enum: ['football', 'padel', 'basketball'] })
  @IsOptional()
  @IsIn(['football', 'padel', 'basketball'])
  sport?: string;

  @ApiPropertyOptional({ enum: ['brouillon', 'inscriptions_ouvertes', 'en_cours', 'termine'] })
  @IsOptional()
  @IsIn(['brouillon', 'inscriptions_ouvertes', 'en_cours', 'termine'])
  statut?: string;

  @ApiPropertyOptional({ example: 1, description: 'id d’un utilisateur (module utilisateur)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  organisateurId?: number;
}
