import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsDate,
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
import { METHODES, OBJETS, STATUTS_PAIEMENT } from './paiement.entity';

/** Les objets qu’on paie directement par /paiements (les autres ont leur route). */
export const OBJETS_DIRECTS = ['reservation', 'partie', 'tournoi', 'programme'] as const;

/** POST /paiements : le checkout (PAY-01) d’une réservation, d’une place, d’un tournoi, d’un programme. */
export class PayerDto {
  @ApiProperty({ example: 1, description: 'Qui paie (module utilisateur)' })
  @IsInt()
  utilisateurId: number;

  @ApiProperty({ enum: OBJETS_DIRECTS, example: 'partie' })
  @IsIn(OBJETS_DIRECTS)
  objet: (typeof OBJETS_DIRECTS)[number];

  @ApiPropertyOptional({ example: 'g1', description: 'id de la réservation, partie, équipe ou programme' })
  @IsOptional()
  @IsString()
  @MaxLength(40)
  objetId?: string;

  @ApiProperty({ example: 'Part · Arena Five, dim. 18 oct.' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  libelle: string;

  @ApiProperty({ example: 15, description: 'Montant en DT avant code promo' })
  @IsNumber({ maxDecimalPlaces: 3 })
  @Min(0.001)
  montant: number;

  @ApiPropertyOptional({ example: 7, description: 'Propriétaire, coach ou organisateur payé (versements)' })
  @IsOptional()
  @IsInt()
  beneficiaireId?: number;

  @ApiPropertyOptional({ example: 'BIENVENUE10' })
  @IsOptional()
  @IsString()
  @MaxLength(40)
  codePromo?: string;

  @ApiPropertyOptional({ enum: ['carte', 'portefeuille', 'especes', 'virement'], default: 'carte', description: 'especes / virement : encaissé au guichet par le propriétaire' })
  @IsOptional()
  @IsIn(['carte', 'portefeuille', 'especes', 'virement'])
  methode?: 'carte' | 'portefeuille' | 'especes' | 'virement';

  @ApiPropertyOptional({ type: MoyenPaiementDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => MoyenPaiementDto)
  moyen?: MoyenPaiementDto;
}

export class AuthentifierDto {
  @ApiProperty({ example: true, description: '« Valider » (true) ou « Annuler » (false) dans la fenêtre de la banque' })
  @IsBoolean()
  approuve: boolean;
}

export class RembourserDto {
  @ApiPropertyOptional({ example: 7.5, description: 'Par défaut : tout ce qui reste' })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 3 })
  @Min(0.001)
  montant?: number;

  @ApiPropertyOptional({ enum: ['portefeuille', 'carte'], description: 'Par défaut : la carte si elle a payé, sinon le solde' })
  @IsOptional()
  @IsIn(['portefeuille', 'carte'])
  vers?: 'portefeuille' | 'carte';
}

/** GET /paiements?… (table des transactions de l’admin, historique d’un joueur). */
export class QueryPaiementDto {
  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  utilisateurId?: number;

  @ApiPropertyOptional({ example: 7 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  beneficiaireId?: number;

  @ApiPropertyOptional({ enum: OBJETS })
  @IsOptional()
  @IsIn(OBJETS)
  objet?: string;

  @ApiPropertyOptional({ example: 'MU-48213' })
  @IsOptional()
  @IsString()
  objetId?: string;

  @ApiPropertyOptional({ enum: STATUTS_PAIEMENT })
  @IsOptional()
  @IsIn(STATUTS_PAIEMENT)
  statut?: string;

  @ApiPropertyOptional({ enum: METHODES })
  @IsOptional()
  @IsIn(METHODES)
  methode?: string;

  @ApiPropertyOptional({ example: '2026-10-01' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  du?: Date;

  @ApiPropertyOptional({ example: '2026-10-31T23:59:59' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  au?: Date;
}
