import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsBoolean, IsIn, IsInt, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateSujetDto {
  @ApiProperty({ example: 1, description: 'id d’un utilisateur (module utilisateur)' })
  @IsInt()
  auteurId: number;

  @ApiProperty({ example: 'Qui pour un five ce soir à La Marsa ?' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  titre: string;

  @ApiProperty({ example: 'Il nous manque 2 joueurs, niveau 3 à 4.' })
  @IsString()
  @IsNotEmpty()
  contenu: string;

  @ApiPropertyOptional({ enum: ['general', 'football', 'padel', 'basketball', 'recherche_joueurs'], default: 'general' })
  @IsOptional()
  @IsIn(['general', 'football', 'padel', 'basketball', 'recherche_joueurs'])
  categorie?: string;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  epingle?: boolean;
}

/** Tous les champs sont facultatifs : on n’envoie que ce qui change. */
export class UpdateSujetDto extends PartialType(CreateSujetDto) {}

/** Filtres de la liste : GET /sujets?auteurId=…  */
export class QuerySujetDto {
  @ApiPropertyOptional({ example: 1, description: 'id d’un utilisateur (module utilisateur)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  auteurId?: number;

  @ApiPropertyOptional({ enum: ['general', 'football', 'padel', 'basketball', 'recherche_joueurs'] })
  @IsOptional()
  @IsIn(['general', 'football', 'padel', 'basketball', 'recherche_joueurs'])
  categorie?: string;
}
