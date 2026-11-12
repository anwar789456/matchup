import { Body, Controller, Get, Param, ParseIntPipe, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsDate, IsIn, IsNotEmpty, IsNumber, IsOptional, IsString, Max, MaxLength, Min, NotEquals, ValidateNested } from 'class-validator';

import { MoyenPaiementDto } from '../commun/moyen.dto';
import { PaiementService } from '../paiement/paiement.service';
import { TYPES_MOUVEMENT } from './portefeuille.entity';
import { PortefeuilleService } from './portefeuille.service';

/** Recharge du solde : de 5 à 500 DT (WAL-02). */
export const RECHARGE_MIN = 5;
export const RECHARGE_MAX = 500;

export class RechargerDto {
  @ApiProperty({ example: 50 })
  @IsNumber({ maxDecimalPlaces: 3 })
  @Min(RECHARGE_MIN)
  @Max(RECHARGE_MAX)
  montant: number;

  @ApiPropertyOptional({ type: MoyenPaiementDto, description: 'Une carte : le solde ne recharge pas le solde' })
  @IsOptional()
  @ValidateNested()
  @Type(() => MoyenPaiementDto)
  moyen?: MoyenPaiementDto;
}

export class AjusterDto {
  @ApiProperty({ example: 10, description: 'Signé : +10 crédite, −10 débite' })
  @IsNumber({ maxDecimalPlaces: 3 })
  @NotEquals(0)
  montant: number;

  @ApiProperty({ example: 'Geste commercial · terrain fermé' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  libelle: string;
}

export class QueryMouvementDto {
  @ApiPropertyOptional({ enum: TYPES_MOUVEMENT })
  @IsOptional()
  @IsIn(TYPES_MOUVEMENT)
  type?: string;

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

/** /api/paiement/portefeuilles/:utilisateurId — le solde MatchUp (WAL-01). */
@ApiTags('portefeuilles')
@Controller('portefeuilles')
export class PortefeuilleController {
  constructor(
    private readonly service: PortefeuilleService,
    private readonly paiements: PaiementService,
  ) {}

  @Get(':utilisateurId')
  @ApiOperation({ summary: 'Solde' })
  solde(@Param('utilisateurId', ParseIntPipe) utilisateurId: number) {
    return this.service.solde(utilisateurId);
  }

  @Get(':utilisateurId/mouvements')
  @ApiOperation({ summary: 'Historique du solde (soldeApres sur chaque ligne)' })
  mouvements(@Param('utilisateurId', ParseIntPipe) utilisateurId: number, @Query() q: QueryMouvementDto) {
    return this.service.historique(utilisateurId, q);
  }

  @Post(':utilisateurId/recharger')
  @ApiOperation({ summary: 'Recharger par carte (WAL-02) : crédité dès que le paiement passe' })
  recharger(@Param('utilisateurId', ParseIntPipe) utilisateurId: number, @Body() body: RechargerDto) {
    return this.paiements.payer({
      utilisateurId,
      objet: 'recharge',
      libelle: 'Recharge du solde',
      montant: body.montant,
      moyen: body.moyen,
    });
  }

  @Post(':utilisateurId/ajuster')
  @ApiOperation({ summary: 'Ajustement par l’admin (geste commercial, correction)' })
  ajuster(@Param('utilisateurId', ParseIntPipe) utilisateurId: number, @Body() body: AjusterDto) {
    return this.service.ajuster(utilisateurId, body.montant, body.libelle);
  }
}
