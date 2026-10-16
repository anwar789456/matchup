import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsDateString, IsIn, IsInt, IsNumber, IsOptional, Min } from 'class-validator';

export class CreateReservationDto {
  @ApiProperty({ example: 1 })
  @IsInt()
  terrainId: number;

  @ApiProperty({ example: 1, description: 'id d’un utilisateur (module utilisateur)' })
  @IsInt()
  utilisateurId: number;

  @ApiProperty({ example: '2026-10-18T20:00:00.000Z' })
  @IsDateString()
  debut: string;

  @ApiProperty({ example: '2026-10-18T21:00:00.000Z' })
  @IsDateString()
  fin: string;

  @ApiPropertyOptional({ default: 10 })
  @IsOptional()
  @IsInt()
  @Min(1)
  nbJoueurs?: number;

  @ApiProperty({ example: 150 })
  @IsNumber()
  @Min(0)
  prixTotal: number;

  @ApiPropertyOptional({ enum: ['en_attente', 'confirmee', 'annulee', 'terminee'], default: 'en_attente' })
  @IsOptional()
  @IsIn(['en_attente', 'confirmee', 'annulee', 'terminee'])
  statut?: string;
}

/** Tous les champs sont facultatifs : on n’envoie que ce qui change. */
export class UpdateReservationDto extends PartialType(CreateReservationDto) {}

/** Filtres de la liste : GET /reservations?terrainId=…  */
export class QueryReservationDto {
  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  terrainId?: number;

  @ApiPropertyOptional({ example: 1, description: 'id d’un utilisateur (module utilisateur)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  utilisateurId?: number;

  @ApiPropertyOptional({ enum: ['en_attente', 'confirmee', 'annulee', 'terminee'] })
  @IsOptional()
  @IsIn(['en_attente', 'confirmee', 'annulee', 'terminee'])
  statut?: string;
}
