import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsArray, IsBoolean, IsDateString, IsIn, IsInt, IsNotEmpty, IsOptional, IsString, MaxLength, Min } from 'class-validator';

/** Filtres : GET /matchs?tournoiId=1&statut=en_direct */
export class QueryMatchDto {
  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  tournoiId?: number;

  @ApiPropertyOptional({ example: 3, description: 'Matchs de cette équipe' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  equipeId?: number;

  @ApiPropertyOptional({ enum: ['a_jouer', 'en_direct', 'termine'] })
  @IsOptional()
  @IsIn(['a_jouer', 'en_direct', 'termine'])
  statut?: string;

  @ApiPropertyOptional({ enum: ['poule', 'elimination'] })
  @IsOptional()
  @IsIn(['poule', 'elimination'])
  phase?: string;

  @ApiPropertyOptional({ example: 'Court 1' })
  @IsOptional()
  @IsString()
  terrain?: string;

  @ApiPropertyOptional({ example: '2026-11-14T00:00:00.000Z' })
  @IsOptional()
  @IsDateString()
  du?: string;

  @ApiPropertyOptional({ example: '2026-11-15T00:00:00.000Z' })
  @IsOptional()
  @IsDateString()
  au?: string;
}

/** Déplacer un match dans le calendrier (glisser-déposer). */
export class UpdateMatchDto {
  @ApiPropertyOptional({ example: '2026-11-14T10:00:00.000Z' })
  @IsOptional()
  @IsDateString()
  debut?: string;

  @ApiPropertyOptional({ example: 'Court 2' })
  @IsOptional()
  @IsString()
  @MaxLength(60)
  terrain?: string;
}

/** Score en direct (bord de terrain). */
export class ScoreDto {
  @ApiProperty({ example: 2 })
  @IsInt()
  @Min(0)
  score1: number;

  @ApiProperty({ example: 1 })
  @IsInt()
  @Min(0)
  score2: number;

  @ApiPropertyOptional({ example: [[6, 4], [3, 6], [2, 1]], description: 'Padel : jeux par set (le dernier est en cours)' })
  @IsOptional()
  @IsArray()
  @IsArray({ each: true })
  sets?: number[][];

  @ApiPropertyOptional({ example: '34’' })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  minute?: string;

  @ApiPropertyOptional({ example: '2e mi-temps' })
  @IsOptional()
  @IsString()
  @MaxLength(40)
  periode?: string;
}

export class EvenementDto {
  @ApiProperty({ example: 'But', description: '« But », « Panier », « Set », « Carton jaune », « Temps mort », « Mi-temps »…' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  type: string;

  @ApiPropertyOptional({ example: 1, enum: [1, 2], description: 'Absent pour un fait neutre' })
  @IsOptional()
  @IsIn([1, 2])
  equipe?: 1 | 2;

  @ApiPropertyOptional({ example: 1, description: 'Points ajoutés au score de l’équipe (but = 1, panier = 2 ou 3)' })
  @IsOptional()
  @IsInt()
  @Min(0)
  points?: number;

  @ApiPropertyOptional({ example: '34’' })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  minute?: string;

  @ApiPropertyOptional({ example: 7 })
  @IsOptional()
  @IsInt()
  joueurId?: number;

  @ApiPropertyOptional({ example: 'Yassine B.' })
  @IsOptional()
  @IsString()
  @MaxLength(80)
  joueur?: string;

  @ApiPropertyOptional({ example: 'Frappe du gauche en lucarne' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  texte?: string;
}

/** Score final : `confirme: true` est obligatoire (confirmation avant d’enregistrer). */
export class TerminerDto extends ScoreDto {
  @ApiPropertyOptional({ example: 5, description: 'Obligatoire en cas d’égalité en phase finale (tirs au but)' })
  @IsOptional()
  @IsInt()
  vainqueurId?: number;

  @ApiPropertyOptional({ example: 't.a.b. 4–3' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  note?: string;

  @ApiProperty({ example: true, description: 'L’organisateur a confirmé le score final' })
  @IsBoolean()
  confirme: boolean;
}

export class ForfaitDto {
  @ApiProperty({ example: 2, enum: [1, 2], description: 'L’équipe qui déclare forfait' })
  @IsIn([1, 2])
  equipe: 1 | 2;
}
