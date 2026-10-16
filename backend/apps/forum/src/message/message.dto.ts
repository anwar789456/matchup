import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateMessageDto {
  @ApiProperty({ example: 1 })
  @IsInt()
  sujetId: number;

  @ApiProperty({ example: 2, description: 'id d’un utilisateur (module utilisateur)' })
  @IsInt()
  auteurId: number;

  @ApiProperty({ example: 'Je suis chaud, j’arrive à 20h !' })
  @IsString()
  @IsNotEmpty()
  contenu: string;
}

/** Tous les champs sont facultatifs : on n’envoie que ce qui change. */
export class UpdateMessageDto extends PartialType(CreateMessageDto) {}

/** Filtres de la liste : GET /messages?sujetId=…  */
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
