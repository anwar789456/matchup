import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsArray, IsInt, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateEquipeDto {
  @ApiProperty({ example: 1 })
  @IsInt()
  tournoiId: number;

  @ApiProperty({ example: 'Les Smashers' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  nom: string;

  @ApiPropertyOptional({ example: 1, description: 'id d’un utilisateur (module utilisateur)' })
  @IsOptional()
  @IsInt()
  capitaineId?: number;

  @ApiPropertyOptional({ example: [1, 2], description: 'ids des joueurs (module utilisateur)' })
  @IsOptional()
  @IsArray()
  @IsInt({ each: true })
  joueursIds?: number[];
}

/** Tous les champs sont facultatifs : on n’envoie que ce qui change. */
export class UpdateEquipeDto extends PartialType(CreateEquipeDto) {}

/** Filtres de la liste : GET /equipes?tournoiId=…  */
export class QueryEquipeDto {
  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  tournoiId?: number;

  @ApiPropertyOptional({ example: 1, description: 'id d’un utilisateur (module utilisateur)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  capitaineId?: number;
}
