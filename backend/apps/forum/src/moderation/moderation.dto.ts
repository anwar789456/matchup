import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsBoolean, IsIn, IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

import { DECISIONS, LIMITES, TYPES_FILE } from '../forum.constants';
import type { Decision } from '../forum.constants';

/** ADM-09: GET /moderation/file?type=&q= */
export class QueryFileDto {
  @ApiPropertyOptional({ enum: TYPES_FILE, default: 'tout', description: 'Tout · Posts · Commentaires' })
  @IsOptional()
  @IsIn(TYPES_FILE)
  type?: (typeof TYPES_FILE)[number];

  @ApiPropertyOptional({ description: 'Mot, auteur (id) ou titre de discussion.' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  q?: string;
}

/** ADM-10 « Ta décision ». */
export class DecisionDto {
  @ApiProperty({ example: 10, description: 'id de l’admin (module utilisateur)' })
  @IsInt()
  moderateurId: number;

  @ApiProperty({ enum: DECISIONS, example: 'supprimer_avertir' })
  @IsIn(DECISIONS)
  decision: Decision;

  @ApiPropertyOptional({
    example: 'Propos insultants envers un joueur',
    description: 'Montré au membre averti ou suspendu. Par défaut : le motif des signalements.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  motif?: string;

  @ApiPropertyOptional({ default: LIMITES.joursSuspension, description: 'Pour `suspendre`.' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(365)
  jours?: number;
}

export class EpingleDto {
  @ApiProperty({ example: 10 })
  @IsInt()
  moderateurId: number;

  @ApiProperty({ example: true })
  @IsBoolean()
  epingle: boolean;
}

/** POST /ia/analyser */
export class AnalyserDto {
  @ApiProperty({ example: 'T’as jamais mis les pieds sur un synthétique, franchement t’es nul.' })
  @IsString()
  @MaxLength(LIMITES.contenuMax + LIMITES.titreMax + 1)
  texte: string;
}

/** POST /ia/tags */
export class SuggererTagsDto {
  @ApiProperty({ example: 'Bandeja croisée : vous visez où sur la vitre ?' })
  @IsString()
  @MaxLength(LIMITES.titreMax)
  titre: string;

  @ApiPropertyOptional({ example: 'Je travaille la bandeja… côté gauche.' })
  @IsOptional()
  @IsString()
  @MaxLength(LIMITES.contenuMax)
  contenu?: string;

  @ApiPropertyOptional({ type: [String], example: ['Padel', 'Bandeja'], description: 'Tags déjà ajoutés.' })
  @IsOptional()
  @IsString({ each: true })
  tags?: string[];
}
