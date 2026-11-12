import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

import { SIMULATIONS, Simulation } from './banque';

/** Une carte tapée dans le checkout. Seuls la marque et les 4 derniers chiffres sont gardés. */
export class NouvelleCarteDto {
  @ApiProperty({ example: '4242 4242 4242 4242', description: 'Cartes de test : 4242… succès, 4000 0025 0000 3155 3-D Secure, 4000 0000 0000 0002 refusée, 4000 0000 0000 9995 fonds insuffisants' })
  @IsString()
  @Matches(/^[\d ]{13,23}$/, { message: 'Numéro de carte invalide.' })
  numero: string;

  @ApiProperty({ example: 8 })
  @IsInt()
  @Min(1)
  @Max(12)
  moisExp: number;

  @ApiProperty({ example: 2027 })
  @IsInt()
  @Min(2024)
  @Max(2100)
  anneeExp: number;

  @ApiPropertyOptional({ example: 'Yassine Ben Ali' })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  titulaire?: string;

  @ApiPropertyOptional({ default: false, description: '« Enregistrer cette carte »' })
  @IsOptional()
  @IsBoolean()
  enregistrer?: boolean;
}

/** Comment on paie : une carte enregistrée ou nouvelle, avec ou sans le solde. */
export class MoyenPaiementDto {
  @ApiPropertyOptional({ example: 1, description: 'Carte enregistrée (sinon la carte par défaut)' })
  @IsOptional()
  @IsInt()
  carteId?: number;

  @ApiPropertyOptional({ type: NouvelleCarteDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => NouvelleCarteDto)
  nouvelleCarte?: NouvelleCarteDto;

  @ApiPropertyOptional({ default: false, description: '« Utiliser mon solde » : le solde paie d’abord, la carte le reste' })
  @IsOptional()
  @IsBoolean()
  utiliserSolde?: boolean;

  @ApiPropertyOptional({ enum: SIMULATIONS, description: 'Réponse de la banque simulée (le menu debug de l’app)' })
  @IsOptional()
  @IsIn(SIMULATIONS)
  simulation?: Simulation;
}
