import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Length,
  MaxLength,
  Min,
  ValidateIf,
} from 'class-validator';

import { CATEGORIES, LIMITES, SPORTS, TRIS_REPONSES, TRIS_SUJETS } from '../forum.constants';
import type { Categorie, Sport, TriReponses, TriSujets } from '../forum.constants';

/** « true » / « false » from a query string. */
const enBooleen = ({ value }: { value: unknown }) => (value === 'true' || value === true ? true : value === 'false' || value === false ? false : value);

/** « a,b » or ['a','b'] from a query string. */
const enListe = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.split(',').map((v) => v.trim()).filter(Boolean) : value;

/** FRM-02 « Publier ». */
export class CreateSujetDto {
  @ApiProperty({ example: 1, description: 'id d’un utilisateur (module utilisateur)' })
  @IsInt()
  auteurId: number;

  @ApiProperty({ example: 'Bandeja croisée : vous visez où sur la vitre ?', minLength: LIMITES.titreMin, maxLength: LIMITES.titreMax })
  @IsString()
  @Length(LIMITES.titreMin, LIMITES.titreMax, {
    message: `Le titre doit faire entre ${LIMITES.titreMin} et ${LIMITES.titreMax} caractères.`,
  })
  titre: string;

  @ApiProperty({
    example: 'Je travaille la bandeja avec le programme de Karim J. (séance 5 : **bandeja croisée**).',
    maxLength: LIMITES.contenuMax,
    description: 'Markdown léger : **gras**, *italique*, listes, citations « > », liens.',
  })
  @IsString()
  @Length(1, LIMITES.contenuMax, { message: `Le message doit faire entre 1 et ${LIMITES.contenuMax} caractères.` })
  contenu: string;

  @ApiProperty({ enum: CATEGORIES, example: 'conseils_technique' })
  @IsIn(CATEGORIES, { message: 'Choisis une catégorie.' })
  categorie: Categorie;

  @ApiPropertyOptional({ enum: SPORTS, nullable: true, description: 'Vide = tous les sports.' })
  @IsOptional()
  @IsIn(SPORTS)
  sport?: Sport | null;

  @ApiPropertyOptional({ type: [String], example: ['Padel', 'Bandeja'], maxItems: LIMITES.tags })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(LIMITES.tags, { message: `${LIMITES.tags} tags au maximum.` })
  @IsString({ each: true })
  @MaxLength(LIMITES.tagMax, { each: true })
  tags?: string[];

  @ApiPropertyOptional({ type: [String], description: 'URLs renvoyées par POST /images', maxItems: LIMITES.images })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(LIMITES.images, { message: `${LIMITES.images} images au maximum.` })
  @IsString({ each: true })
  images?: string[];

  @ApiPropertyOptional({
    default: false,
    description: 'true après l’alerte FRM-03 (« Publier quand même ») : le post est publié masqué, en attente de modération.',
  })
  @IsOptional()
  @IsBoolean()
  confirmerMalgreAlerte?: boolean;
}

/** Edit by its author. */
export class UpdateSujetDto {
  @ApiProperty({ example: 1, description: 'Qui modifie : doit être l’auteur.' })
  @IsInt()
  utilisateurId: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(LIMITES.titreMin, LIMITES.titreMax, {
    message: `Le titre doit faire entre ${LIMITES.titreMin} et ${LIMITES.titreMax} caractères.`,
  })
  titre?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(1, LIMITES.contenuMax)
  contenu?: string;

  @ApiPropertyOptional({ enum: CATEGORIES })
  @IsOptional()
  @IsIn(CATEGORIES)
  categorie?: Categorie;

  @ApiPropertyOptional({ enum: SPORTS, nullable: true })
  @IsOptional()
  @ValidateIf((_, v) => v !== null)
  @IsIn(SPORTS)
  sport?: Sport | null;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(LIMITES.tags)
  @IsString({ each: true })
  @MaxLength(LIMITES.tagMax, { each: true })
  tags?: string[];

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(LIMITES.images)
  @IsString({ each: true })
  images?: string[];

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  confirmerMalgreAlerte?: boolean;
}

/** FRM-01 list: GET /sujets?categorie=&sport=&tri=… */
export class QuerySujetDto {
  @ApiPropertyOptional({ enum: CATEGORIES })
  @IsOptional()
  @IsIn(CATEGORIES)
  categorie?: Categorie;

  @ApiPropertyOptional({ enum: SPORTS, description: 'Vide = tous les sports.' })
  @IsOptional()
  @IsIn(SPORTS)
  sport?: Sport;

  @ApiPropertyOptional({ enum: TRIS_SUJETS, default: 'tendance' })
  @IsOptional()
  @IsIn(TRIS_SUJETS)
  tri?: TriSujets;

  @ApiPropertyOptional({ description: 'Recherche dans le titre, le texte et les tags.' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  q?: string;

  @ApiPropertyOptional({ example: 'bandeja' })
  @IsOptional()
  @IsString()
  tag?: string;

  @ApiPropertyOptional({ description: 'Posts d’un membre.' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  auteurId?: number;

  @ApiPropertyOptional({ description: 'Qui regarde : son vote, ses favoris, ses blocages, ses posts masqués.' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  utilisateurId?: number;

  @ApiPropertyOptional({ example: 'yassine.b', description: 'Pseudo de qui regarde, pour « X t’a mentionné ».' })
  @IsOptional()
  @IsString()
  pseudo?: string;

  @ApiPropertyOptional({ description: 'Seulement les favoris de `utilisateurId`.' })
  @IsOptional()
  @Transform(enBooleen)
  @IsBoolean()
  favoris?: boolean;

  @ApiPropertyOptional({ default: 20, maximum: LIMITES.pageMax })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limite?: number;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  decalage?: number;
}

/** FRM-04: GET /sujets/:id?utilisateurId=&tri= */
export class QueryDetailDto {
  @ApiPropertyOptional({ description: 'Qui regarde.' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  utilisateurId?: number;

  @ApiPropertyOptional({ enum: TRIS_REPONSES, default: 'utiles' })
  @IsOptional()
  @IsIn(TRIS_REPONSES)
  tri?: TriReponses;
}

/** FRM-02 « Discussions similaires »: GET /sujets/similaires?titre=… */
export class QuerySimilairesDto {
  @ApiProperty({ example: 'Bandeja croisée : vous visez où sur la vitre ?' })
  @IsString()
  @MaxLength(LIMITES.titreMax)
  titre: string;

  @ApiPropertyOptional({ enum: SPORTS })
  @IsOptional()
  @IsIn(SPORTS)
  sport?: Sport;

  @ApiPropertyOptional({ example: 'Padel,Bandeja' })
  @IsOptional()
  @Transform(enListe)
  @IsArray()
  @IsString({ each: true })
  tags?: string[];

  @ApiPropertyOptional({ description: 'Ne pas proposer ce post (en modification).' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  exclureId?: number;

  @ApiPropertyOptional({ default: 3 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limite?: number;
}

export class MeilleureReponseDto {
  @ApiProperty({ example: 3, description: 'Doit être l’auteur du post.' })
  @IsInt()
  utilisateurId: number;

  @ApiProperty({ example: 12, nullable: true, description: 'null pour retirer la meilleure réponse.' })
  @ValidateIf((_, v) => v !== null)
  @IsInt()
  messageId: number | null;
}

/** Who does it, for routes where only that is needed (DELETE …?utilisateurId=). */
export class QueryUtilisateurDto {
  @ApiProperty({ example: 1 })
  @Type(() => Number)
  @IsInt()
  utilisateurId: number;
}
