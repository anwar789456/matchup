import { Body, Controller, Get, Param, ParseIntPipe, Post, Put, Query } from '@nestjs/common';
import { ApiOperation, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsIn, IsInt, IsOptional } from 'class-validator';

import { SPORTS } from '../forum.constants';
import type { Sport } from '../forum.constants';
import { SujetService } from '../sujet/sujet.service';
import { InterrupteurDto, VisiteDto } from './interaction.dto';
import { InteractionService } from './interaction.service';

class QueryLecteurDto {
  @ApiPropertyOptional({ description: 'Qui regarde.' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  utilisateurId?: number;
}

class QueryCategoriesDto extends QueryLecteurDto {
  @ApiPropertyOptional({ enum: SPORTS })
  @IsOptional()
  @IsIn(SPORTS)
  sport?: Sport;
}

/** /api/forum — categories, visits and members. */
@Controller()
export class InteractionController {
  constructor(
    private readonly service: InteractionService,
    private readonly sujets: SujetService,
  ) {}

  @Get('categories')
  @ApiTags('communauté')
  @ApiOperation({ summary: 'FRM-01 · Catégories : nombre de discussions et « nouveaux depuis ta dernière visite »' })
  categories(@Query() query: QueryCategoriesDto) {
    return this.sujets.categories(query.utilisateurId, query.sport);
  }

  @Post('visites')
  @ApiTags('communauté')
  @ApiOperation({ summary: 'Enregistre la visite (à appeler en quittant la Communauté) et renvoie la précédente' })
  visite(@Body() body: VisiteDto) {
    return this.service.visite(body.utilisateurId);
  }

  @Get('membres/:id')
  @ApiTags('membres')
  @ApiOperation({ summary: 'Profil forum d’un membre : posts, réponses, votes reçus, meilleures réponses, abonnés, suspension' })
  membre(@Param('id', ParseIntPipe) id: number, @Query() query: QueryLecteurDto) {
    return this.service.membre(id, query.utilisateurId);
  }

  @Put('membres/:id/suivi')
  @ApiTags('membres')
  @ApiOperation({ summary: 'FRM-04 « Suivre » un membre' })
  suivre(@Param('id', ParseIntPipe) id: number, @Body() body: InterrupteurDto) {
    return this.service.suivre('membre', id, body.utilisateurId, body.actif);
  }

  @Put('membres/:id/blocage')
  @ApiTags('membres')
  @ApiOperation({ summary: 'FRM-05 « Ne plus voir les messages de … » (actif: false pour les revoir)' })
  bloquer(@Param('id', ParseIntPipe) id: number, @Body() body: InterrupteurDto) {
    return this.service.bloquer(id, body.utilisateurId, body.actif);
  }

  @Get('membres/:id/blocages')
  @ApiTags('membres')
  @ApiOperation({ summary: 'Les membres que ce membre ne veut plus voir (Paramètres)' })
  blocages(@Param('id', ParseIntPipe) id: number) {
    return this.service.listeBloques(id);
  }

  @Get('membres/:id/abonnements')
  @ApiTags('membres')
  @ApiOperation({ summary: 'Membres et discussions suivis' })
  abonnements(@Param('id', ParseIntPipe) id: number) {
    return this.service.abonnements(id);
  }
}
