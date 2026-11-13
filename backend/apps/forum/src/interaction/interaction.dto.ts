import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsIn, IsInt, IsOptional, IsString, MaxLength } from 'class-validator';

import { MOTIFS_SIGNALEMENT } from '../forum.constants';
import type { MotifSignalement } from '../forum.constants';

/** PUT …/vote */
export class VoteDto {
  @ApiProperty({ example: 1 })
  @IsInt()
  utilisateurId: number;

  @ApiProperty({ enum: [1, 0, -1], description: '1 pour, −1 contre, 0 retire le vote.' })
  @IsIn([1, 0, -1])
  valeur: 1 | 0 | -1;
}

/** PUT …/reactions/:type, …/favori, …/suivi, /membres/:id/suivi, /membres/:id/blocage */
export class InterrupteurDto {
  @ApiProperty({ example: 1 })
  @IsInt()
  utilisateurId: number;

  @ApiProperty({ example: true, description: 'true pour activer, false pour retirer.' })
  @IsBoolean()
  actif: boolean;
}

/** FRM-05 « Signaler ». */
export class SignalementDto {
  @ApiProperty({ example: 1, description: 'Qui signale. Jamais montré à l’auteur.' })
  @IsInt()
  signaleurId: number;

  @ApiProperty({ enum: MOTIFS_SIGNALEMENT, example: 'spam' })
  @IsIn(MOTIFS_SIGNALEMENT, { message: 'Choisis un motif.' })
  motif: MotifSignalement;

  @ApiPropertyOptional({ description: 'Précisions pour « Autre chose ».', maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  details?: string;

  @ApiPropertyOptional({ default: false, description: '« Ne plus voir les messages de … »' })
  @IsOptional()
  @IsBoolean()
  masquerAuteur?: boolean;
}

/** POST /visites */
export class VisiteDto {
  @ApiProperty({ example: 1 })
  @IsInt()
  utilisateurId: number;
}
