import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsBoolean, IsIn, IsInt, IsNotEmpty, IsNumber, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class CreateProgrammeDto {
  @ApiProperty({ example: 1, description: 'id d’un utilisateur coach (module utilisateur)' })
  @IsInt()
  coachId: number;

  @ApiProperty({ example: 'Un service solide en 4 semaines' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  titre: string;

  @ApiPropertyOptional({ example: 'Des séances courtes pour fiabiliser ton service.' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: 'padel', enum: ['football', 'padel', 'basketball'] })
  @IsIn(['football', 'padel', 'basketball'])
  sport: string;

  @ApiPropertyOptional({ enum: ['debutant', 'intermediaire', 'avance', 'expert'], default: 'debutant' })
  @IsOptional()
  @IsIn(['debutant', 'intermediaire', 'avance', 'expert'])
  niveau?: string;

  @ApiPropertyOptional({ default: 4 })
  @IsOptional()
  @IsInt()
  @Min(1)
  dureeSemaines?: number;

  @ApiPropertyOptional({ default: 0, description: 'DT ; 0 = inclus dans Premium' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  prix?: number;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  publie?: boolean;
}

/** Tous les champs sont facultatifs : on n’envoie que ce qui change. */
export class UpdateProgrammeDto extends PartialType(CreateProgrammeDto) {}

/** Filtres de la liste : GET /programmes?coachId=…  */
export class QueryProgrammeDto {
  @ApiPropertyOptional({ example: 1, description: 'id d’un utilisateur coach (module utilisateur)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  coachId?: number;

  @ApiPropertyOptional({ example: 'padel', enum: ['football', 'padel', 'basketball'] })
  @IsOptional()
  @IsIn(['football', 'padel', 'basketball'])
  sport?: string;

  @ApiPropertyOptional({ enum: ['debutant', 'intermediaire', 'avance', 'expert'] })
  @IsOptional()
  @IsIn(['debutant', 'intermediaire', 'avance', 'expert'])
  niveau?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true')
  @IsBoolean()
  publie?: boolean;
}
