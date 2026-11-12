import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayMinSize, IsArray, IsBoolean, IsDateString, IsIn, IsInt, IsOptional } from 'class-validator';

import { ROLES_BENEFICIAIRE, RoleBeneficiaire, STATUTS_VERSEMENT } from './versement.entity';

export class CalculerVersementDto {
  @ApiProperty({ example: 7 })
  @IsInt()
  beneficiaireId: number;

  @ApiProperty({ enum: ROLES_BENEFICIAIRE, example: 'proprietaire' })
  @IsIn(ROLES_BENEFICIAIRE)
  role: RoleBeneficiaire;

  @ApiProperty({ example: '2026-10-01T00:00:00+01:00' })
  @IsDateString()
  du: string;

  @ApiProperty({ example: '2026-11-01T00:00:00+01:00', description: 'Exclu' })
  @IsDateString()
  au: string;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  apercu?: boolean;
}

export class ValiderVersementsDto {
  @ApiProperty({ example: [1, 2] })
  @IsArray()
  @ArrayMinSize(1)
  @IsInt({ each: true })
  ids: number[];
}

export class QueryVersementDto {
  @ApiPropertyOptional({ example: 7 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  beneficiaireId?: number;

  @ApiPropertyOptional({ enum: ROLES_BENEFICIAIRE })
  @IsOptional()
  @IsIn(ROLES_BENEFICIAIRE)
  role?: string;

  @ApiPropertyOptional({ enum: STATUTS_VERSEMENT })
  @IsOptional()
  @IsIn(STATUTS_VERSEMENT)
  statut?: string;
}
