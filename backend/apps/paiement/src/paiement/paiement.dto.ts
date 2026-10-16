import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsIn, IsInt, IsNumber, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class CreatePaiementDto {
  @ApiProperty({ example: 1, description: 'id d’un utilisateur (module utilisateur)' })
  @IsInt()
  utilisateurId: number;

  @ApiPropertyOptional({ example: 1, description: 'id d’une réservation (module reservation)' })
  @IsOptional()
  @IsInt()
  reservationId?: number;

  @ApiProperty({ example: 15, description: 'Montant en DT' })
  @IsNumber()
  @Min(0)
  montant: number;

  @ApiPropertyOptional({ enum: ['carte', 'especes', 'portefeuille', 'virement'], default: 'carte' })
  @IsOptional()
  @IsIn(['carte', 'especes', 'portefeuille', 'virement'])
  methode?: string;

  @ApiPropertyOptional({ enum: ['en_attente', 'paye', 'echoue', 'rembourse'], default: 'en_attente' })
  @IsOptional()
  @IsIn(['en_attente', 'paye', 'echoue', 'rembourse'])
  statut?: string;

  @ApiPropertyOptional({ example: 'PAY-2026-0001' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  reference?: string;
}

/** Tous les champs sont facultatifs : on n’envoie que ce qui change. */
export class UpdatePaiementDto extends PartialType(CreatePaiementDto) {}

/** Filtres de la liste : GET /paiements?utilisateurId=…  */
export class QueryPaiementDto {
  @ApiPropertyOptional({ example: 1, description: 'id d’un utilisateur (module utilisateur)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  utilisateurId?: number;

  @ApiPropertyOptional({ example: 1, description: 'id d’une réservation (module reservation)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  reservationId?: number;

  @ApiPropertyOptional({ enum: ['carte', 'especes', 'portefeuille', 'virement'] })
  @IsOptional()
  @IsIn(['carte', 'especes', 'portefeuille', 'virement'])
  methode?: string;

  @ApiPropertyOptional({ enum: ['en_attente', 'paye', 'echoue', 'rembourse'] })
  @IsOptional()
  @IsIn(['en_attente', 'paye', 'echoue', 'rembourse'])
  statut?: string;
}
