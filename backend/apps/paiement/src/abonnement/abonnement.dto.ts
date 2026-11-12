import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsBoolean, IsIn, IsInt, IsNotEmpty, IsOptional, IsString, MaxLength, ValidateNested } from 'class-validator';

import { SIMULATIONS, Simulation } from '../commun/banque';
import { MoyenPaiementDto } from '../commun/moyen.dto';
import { PERIODES, Periode, STATUTS_ABONNEMENT } from './abonnement.entity';
import { PLANS } from './plans';

const CODES_PLANS = Object.keys(PLANS);

export class SouscrireDto {
  @ApiProperty({ example: 1 })
  @IsInt()
  utilisateurId: number;

  @ApiProperty({ enum: CODES_PLANS, example: 'joueur_premium' })
  @IsIn(CODES_PLANS)
  plan: string;

  @ApiProperty({ enum: PERIODES, example: 'mensuel' })
  @IsIn(PERIODES)
  periode: Periode;

  @ApiPropertyOptional({ type: MoyenPaiementDto, description: 'La carte des prélèvements (gardée même sans « enregistrer »)' })
  @IsOptional()
  @ValidateNested()
  @Type(() => MoyenPaiementDto)
  moyen?: MoyenPaiementDto;
}

export class ChangerAbonnementDto {
  @ApiPropertyOptional({ enum: CODES_PLANS, example: 'joueur_premium' })
  @IsOptional()
  @IsIn(CODES_PLANS)
  plan?: string;

  @ApiPropertyOptional({ enum: PERIODES, example: 'annuel' })
  @IsOptional()
  @IsIn(PERIODES)
  periode?: Periode;

  @ApiPropertyOptional({ default: false, description: 'Calcule le prorata sans rien changer' })
  @IsOptional()
  @IsBoolean()
  apercu?: boolean;

  @ApiPropertyOptional({ enum: SIMULATIONS })
  @IsOptional()
  @IsIn(SIMULATIONS)
  simulation?: Simulation;
}

export class AnnulerAbonnementDto {
  @ApiProperty({ example: 'trop_cher', description: 'trop_cher, pas_assez_utilise, bug, autre…' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  motif: string;

  @ApiPropertyOptional({ example: 'Je joue moins cet hiver.' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;

  @ApiPropertyOptional({ default: false, description: '« Non merci, résilier » après l’offre' })
  @IsOptional()
  @IsBoolean()
  confirmer?: boolean;
}

export class PreleverDto {
  @ApiPropertyOptional({ enum: SIMULATIONS })
  @IsOptional()
  @IsIn(SIMULATIONS)
  simulation?: Simulation;

  @ApiPropertyOptional({ default: false, description: 'Prélever sans attendre l’échéance (démo)' })
  @IsOptional()
  @IsBoolean()
  forcer?: boolean;
}

export class QueryAbonnementDto {
  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  utilisateurId?: number;

  @ApiPropertyOptional({ enum: STATUTS_ABONNEMENT })
  @IsOptional()
  @IsIn(STATUTS_ABONNEMENT)
  statut?: string;
}
