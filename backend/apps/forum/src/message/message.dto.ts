import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsBoolean, IsInt, IsOptional, IsString, Length } from 'class-validator';

import { LIMITES } from '../forum.constants';

/** FRM-04 reply bar. */
export class CreateMessageDto {
  @ApiProperty({ example: 1 })
  @IsInt()
  sujetId: number;

  @ApiProperty({ example: 2, description: 'id d’un utilisateur (module utilisateur)' })
  @IsInt()
  auteurId: number;

  @ApiProperty({ example: 'Prends des stabilisés (TF) ou des moulés courts (AG).', maxLength: LIMITES.reponseMax })
  @IsString()
  @Length(1, LIMITES.reponseMax, { message: `La réponse doit faire entre 1 et ${LIMITES.reponseMax} caractères.` })
  contenu: string;

  @ApiPropertyOptional({
    example: 7,
    description: 'Réponse à une réponse (« Répondre » sous un message). Une réponse de 2e niveau se range sous son parent de 1er niveau.',
  })
  @IsOptional()
  @IsInt()
  parentId?: number;

  @ApiPropertyOptional({
    default: false,
    description: 'true après l’alerte FRM-03 (« Publier quand même ») : la réponse est publiée masquée, en attente de modération.',
  })
  @IsOptional()
  @IsBoolean()
  confirmerMalgreAlerte?: boolean;
}

/** Edit by its author. */
export class UpdateMessageDto {
  @ApiProperty({ example: 2, description: 'Qui modifie : doit être l’auteur.' })
  @IsInt()
  utilisateurId: number;

  @ApiProperty()
  @IsString()
  @Length(1, LIMITES.reponseMax)
  contenu: string;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  confirmerMalgreAlerte?: boolean;
}

/** GET /messages?sujetId=&auteurId= */
export class QueryMessageDto {
  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  sujetId?: number;

  @ApiPropertyOptional({ example: 2, description: 'id d’un utilisateur (module utilisateur)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  auteurId?: number;
}
