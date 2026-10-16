import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { IsEmail, IsIn, IsNumber, IsOptional, IsString, Matches, Max, MaxLength, Min, MinLength } from 'class-validator';

export class CreateUtilisateurDto {
  @ApiPropertyOptional({ example: 'Skander' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  prenom?: string;

  @ApiPropertyOptional({ example: 'T.' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  nom?: string;

  @ApiPropertyOptional({ example: 'skander.t', description: '3 à 20 caractères : lettres, chiffres, . et _' })
  @IsOptional()
  @Matches(/^[a-zA-Z0-9._]{3,20}$/)
  pseudo?: string;

  @ApiProperty({ example: 'skander.t@email.tn' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'motdepasse123', description: 'Au moins 8 caractères ; jamais renvoyé par l’API' })
  @IsString()
  @MinLength(8)
  motDePasse: string;

  @ApiPropertyOptional({ example: '98123456' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  telephone?: string;

  @ApiPropertyOptional({ enum: ['joueur', 'proprietaire', 'coach', 'organisateur', 'admin'], default: 'joueur' })
  @IsOptional()
  @IsIn(['joueur', 'proprietaire', 'coach', 'organisateur', 'admin'])
  role?: string;

  @ApiPropertyOptional({ example: 'La Marsa' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  ville?: string;

  @ApiPropertyOptional({ example: 'https://exemple.tn/avatar.jpg' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  avatarUrl?: string;

  @ApiPropertyOptional({ example: 3.5, description: 'Niveau de jeu, de 1 à 7' })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(7)
  niveau?: number;
}

/** Tous les champs sont facultatifs : on n’envoie que ce qui change. */
export class UpdateUtilisateurDto extends PartialType(CreateUtilisateurDto) {}

/** Filtres de la liste : GET /utilisateurs?email=…  */
export class QueryUtilisateurDto {
  @ApiPropertyOptional({ example: 'skander.t' })
  @IsOptional()
  @IsString()
  pseudo?: string;

  @ApiPropertyOptional({ example: 'skander.t@email.tn' })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ enum: ['joueur', 'proprietaire', 'coach', 'organisateur', 'admin'] })
  @IsOptional()
  @IsIn(['joueur', 'proprietaire', 'coach', 'organisateur', 'admin'])
  role?: string;

  @ApiPropertyOptional({ example: 'La Marsa' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  ville?: string;
}
