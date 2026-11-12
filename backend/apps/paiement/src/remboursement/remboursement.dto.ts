import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsIn, IsInt, IsNotEmpty, IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

import { CIBLES_REMBOURSEMENT, MOTIFS_REMBOURSEMENT, STATUTS_DEMANDE } from './demande-remboursement.entity';

export class CreateDemandeDto {
  @ApiProperty({ example: 1 })
  @IsInt()
  utilisateurId: number;

  @ApiProperty({ example: 3 })
  @IsInt()
  paiementId: number;

  @ApiProperty({ enum: MOTIFS_REMBOURSEMENT, example: 'terrain_ferme' })
  @IsIn(MOTIFS_REMBOURSEMENT)
  motif: string;

  @ApiPropertyOptional({ example: 'Le terrain était fermé à notre arrivée.' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;

  @ApiProperty({ enum: CIBLES_REMBOURSEMENT, example: 'portefeuille' })
  @IsIn(CIBLES_REMBOURSEMENT)
  cible: string;

  @ApiPropertyOptional({ example: 1, description: 'Nombre de photos jointes' })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(5)
  photos?: number;

  @ApiPropertyOptional({ example: 9, description: 'Par défaut : tout ce qui reste sur le paiement' })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 3 })
  @Min(0.001)
  montant?: number;
}

export class AccepterDemandeDto {
  @ApiPropertyOptional({ example: 9, description: 'Par défaut : le montant demandé' })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 3 })
  @Min(0.001)
  montant?: number;
}

export class RefuserDemandeDto {
  @ApiProperty({ example: 'Le terrain était ouvert : les photos montrent un autre lieu.' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(1000)
  motif: string;
}

export class QueryDemandeDto {
  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  utilisateurId?: number;

  @ApiPropertyOptional({ example: 3 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  paiementId?: number;

  @ApiPropertyOptional({ enum: STATUTS_DEMANDE })
  @IsOptional()
  @IsIn(STATUTS_DEMANDE)
  statut?: string;
}
