import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class CreateSeanceDto {
  @ApiProperty({ example: 1 })
  @IsInt()
  programmeId: number;

  @ApiProperty({ example: 'Le lancer de balle' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  titre: string;

  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @IsInt()
  @Min(1)
  ordre?: number;

  @ApiPropertyOptional({ example: '3 séries de 10 services, en visant le T.' })
  @IsOptional()
  @IsString()
  contenu?: string;

  @ApiPropertyOptional({ example: 'https://exemple.tn/video.mp4' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  videoUrl?: string;

  @ApiPropertyOptional({ default: 45 })
  @IsOptional()
  @IsInt()
  @Min(1)
  dureeMinutes?: number;
}

/** Tous les champs sont facultatifs : on n’envoie que ce qui change. */
export class UpdateSeanceDto extends PartialType(CreateSeanceDto) {}

/** Filtres de la liste : GET /seances?programmeId=…  */
export class QuerySeanceDto {
  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  programmeId?: number;
}
