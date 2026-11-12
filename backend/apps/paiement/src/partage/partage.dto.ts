import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
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
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

import { MoyenPaiementDto } from '../commun/moyen.dto';
import { STATUTS_PARTAGE } from './partage.entity';

export class JoueurPartDto {
  @ApiPropertyOptional({ example: 2, description: 'null pour un invité sans compte' })
  @IsOptional()
  @IsInt()
  joueurId?: number;

  @ApiProperty({ example: 'Lina F.' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  nom: string;

  @ApiPropertyOptional({ default: false, description: 'A rejoint par la partie publique' })
  @IsOptional()
  @IsBoolean()
  partiePublique?: boolean;
}

export class CreatePartageDto {
  @ApiProperty({ example: 'MU-48213' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  reservationId: string;

  @ApiProperty({ example: 1 })
  @IsInt()
  organisateurId: number;

  @ApiProperty({ example: 'Arena Five · Terrain 1' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  libelle: string;

  @ApiProperty({ example: 150 })
  @IsNumber({ maxDecimalPlaces: 3 })
  @Min(0.001)
  montantTotal: number;

  @ApiPropertyOptional({ example: 7, description: 'Propriétaire du terrain (versements)' })
  @IsOptional()
  @IsInt()
  beneficiaireId?: number;

  @ApiProperty({ example: '2026-10-21T14:00:00+01:00' })
  @IsDateString()
  debutMatch: string;

  @ApiProperty({ type: [JoueurPartDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(30)
  @ValidateNested({ each: true })
  @Type(() => JoueurPartDto)
  joueurs: JoueurPartDto[];
}

export class PayerPartDto {
  @ApiPropertyOptional({ example: 2, description: 'Par défaut : le joueur de la part' })
  @IsOptional()
  @IsInt()
  utilisateurId?: number;

  @ApiPropertyOptional({ type: MoyenPaiementDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => MoyenPaiementDto)
  moyen?: MoyenPaiementDto;
}

export class PayerResteDto {
  @ApiPropertyOptional({ example: 1, description: 'Par défaut : l’organisateur' })
  @IsOptional()
  @IsInt()
  utilisateurId?: number;

  @ApiPropertyOptional({ type: MoyenPaiementDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => MoyenPaiementDto)
  moyen?: MoyenPaiementDto;
}

export class RelancerDto {
  @ApiPropertyOptional({ example: [3], description: 'Par défaut : toutes les parts en attente' })
  @IsOptional()
  @IsArray()
  @IsInt({ each: true })
  partIds?: number[];
}

export class QueryPartageDto {
  @ApiPropertyOptional({ example: 'MU-48213' })
  @IsOptional()
  @IsString()
  reservationId?: string;

  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  organisateurId?: number;

  @ApiPropertyOptional({ example: 2, description: 'Les partages où ce joueur a une part' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  joueurId?: number;

  @ApiPropertyOptional({ enum: STATUTS_PARTAGE })
  @IsOptional()
  @IsIn(STATUTS_PARTAGE)
  statut?: string;
}
