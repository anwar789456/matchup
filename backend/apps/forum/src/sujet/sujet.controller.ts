import { Body, Controller, Delete, Get, Param, ParseIntPipe, Patch, Post, Put, Query } from '@nestjs/common';
import { ApiOperation, ApiParam, ApiTags, ApiUnprocessableEntityResponse } from '@nestjs/swagger';

import { REACTIONS } from '../forum.constants';
import type { TypeReaction } from '../forum.constants';
import { InterrupteurDto, SignalementDto, VoteDto } from '../interaction/interaction.dto';
import { InteractionService } from '../interaction/interaction.service';
import { ModerationService } from '../moderation/moderation.service';
import { ReactionPipe } from '../commun/reaction.pipe';
import {
  CreateSujetDto,
  MeilleureReponseDto,
  QueryDetailDto,
  QuerySimilairesDto,
  QuerySujetDto,
  QueryUtilisateurDto,
  UpdateSujetDto,
} from './sujet.dto';
import { SujetService } from './sujet.service';

const ALERTE = 'Texte potentiellement blessant (FRM-03) : `{ code: "ALERTE_MODERATION", message, analyse }`. Renvoyer avec `confirmerMalgreAlerte: true` pour publier masqué.';

/** /api/forum/sujets — the discussions (FRM-01, FRM-02, FRM-04). */
@ApiTags('sujets')
@Controller('sujets')
export class SujetController {
  constructor(
    private readonly service: SujetService,
    private readonly interactions: InteractionService,
    private readonly moderation: ModerationService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'FRM-01 · Liste paginée { total, sujets } (catégorie, sport, tri, recherche, tag, favoris)' })
  liste(@Query() query: QuerySujetDto) {
    return this.service.liste(query);
  }

  @Get('similaires')
  @ApiOperation({ summary: 'FRM-02 · Discussions similaires au titre en cours de saisie' })
  similaires(@Query() query: QuerySimilairesDto) {
    return this.service.similaires(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'FRM-04 · Discussion : post, meilleure réponse, réponses sur 2 niveaux' })
  detail(@Param('id', ParseIntPipe) id: number, @Query() query: QueryDetailDto) {
    return this.service.detail(id, query);
  }

  @Post()
  @ApiOperation({ summary: 'FRM-02 · Publier un post' })
  @ApiUnprocessableEntityResponse({ description: ALERTE })
  create(@Body() body: CreateSujetDto) {
    return this.service.create(body);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Modifier son post' })
  @ApiUnprocessableEntityResponse({ description: ALERTE })
  update(@Param('id', ParseIntPipe) id: number, @Body() body: UpdateSujetDto) {
    return this.service.update(id, body);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Supprimer son post (?utilisateurId=)' })
  remove(@Param('id', ParseIntPipe) id: number, @Query() query: QueryUtilisateurDto) {
    return this.service.remove(id, query.utilisateurId);
  }

  @Post(':id/meilleure-reponse')
  @ApiOperation({ summary: 'FRM-04 · Choisir (ou retirer avec null) la meilleure réponse — auteur du post seulement' })
  meilleureReponse(@Param('id', ParseIntPipe) id: number, @Body() body: MeilleureReponseDto) {
    return this.service.meilleureReponse(id, body);
  }

  @Put(':id/vote')
  @ApiOperation({ summary: 'Voter pour (1), contre (−1) ou retirer (0)' })
  voter(@Param('id', ParseIntPipe) id: number, @Body() body: VoteDto) {
    return this.interactions.voter('sujet', id, body.utilisateurId, body.valeur);
  }

  @Put(':id/reactions/:type')
  @ApiParam({ name: 'type', enum: REACTIONS })
  @ApiOperation({ summary: '« Utile » / « Merci » (actif: true / false)' })
  reagir(@Param('id', ParseIntPipe) id: number, @Param('type', ReactionPipe) type: TypeReaction, @Body() body: InterrupteurDto) {
    return this.interactions.reagir('sujet', id, type, body.utilisateurId, body.actif);
  }

  @Put(':id/favori')
  @ApiOperation({ summary: 'Enregistrer / retirer des favoris' })
  favori(@Param('id', ParseIntPipe) id: number, @Body() body: InterrupteurDto) {
    return this.interactions.favori(id, body.utilisateurId, body.actif);
  }

  @Put(':id/suivi')
  @ApiOperation({ summary: 'Suivre la discussion (cloche) : prévenu des nouvelles réponses' })
  suivre(@Param('id', ParseIntPipe) id: number, @Body() body: InterrupteurDto) {
    return this.interactions.suivre('sujet', id, body.utilisateurId, body.actif);
  }

  @Post(':id/signalements')
  @ApiOperation({ summary: 'FRM-05 · Signaler le post (masqué pour tous au 3e signalement)' })
  signaler(@Param('id', ParseIntPipe) id: number, @Body() body: SignalementDto) {
    return this.moderation.signaler('sujet', id, body);
  }
}
