import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsBoolean, IsIn, IsInt, IsNotEmpty, IsNumber, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class CreateTerrainDto {
  @ApiProperty({ example: 'Terrain 1' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  nom: string;

  @ApiProperty({ example: 'Arena Five' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  etablissement: string;

  @ApiProperty({ example: 'football', enum: ['football', 'padel', 'basketball'] })
  @IsIn(['football', 'padel', 'basketball'])
  sport: string;

  @ApiPropertyOptional({ example: 'Gazon synthétique' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  surface?: string;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  interieur?: boolean;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  eclairage?: boolean;

  @ApiProperty({ example: 120, description: 'Prix du terrain à l’heure (DT)' })
  @IsNumber()
  @Min(0)
  prixHeure: number;

  @ApiProperty({ example: 'La Marsa' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  ville: string;

  @ApiPropertyOptional({ example: '12 rue Hédi Nouira' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  adresse?: string;

  @ApiPropertyOptional({ example: 1, description: 'id d’un utilisateur (module utilisateur)' })
  @IsOptional()
  @IsInt()
  proprietaireId?: number;
}

/** Tous les champs sont facultatifs : on n’envoie que ce qui change. */
export class UpdateTerrainDto extends PartialType(CreateTerrainDto) {}

/** Filtres de la liste : GET /terrains?etablissement=…  */
export class QueryTerrainDto {
  @ApiPropertyOptional({ example: 'Arena Five' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  etablissement?: string;

  @ApiPropertyOptional({ example: 'football', enum: ['football', 'padel', 'basketball'] })
  @IsOptional()
  @IsIn(['football', 'padel', 'basketball'])
  sport?: string;

  @ApiPropertyOptional({ example: 'La Marsa' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  ville?: string;

  @ApiPropertyOptional({ example: 1, description: 'id d’un utilisateur (module utilisateur)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  proprietaireId?: number;
}
