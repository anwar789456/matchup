import { Body, Controller, Delete, Get, Param, ParseIntPipe, Patch, Post, Put, Query } from '@nestjs/common';
import { ApiOperation, ApiParam, ApiTags, ApiUnprocessableEntityResponse } from '@nestjs/swagger';

import { ReactionPipe } from '../commun/reaction.pipe';
import { REACTIONS } from '../forum.constants';
import type { TypeReaction } from '../forum.constants';
import { InterrupteurDto, SignalementDto, VoteDto } from '../interaction/interaction.dto';
import { InteractionService } from '../interaction/interaction.service';
import { ModerationService } from '../moderation/moderation.service';
import { QueryUtilisateurDto } from '../sujet/sujet.dto';
import { CreateMessageDto, QueryMessageDto, UpdateMessageDto } from './message.dto';
import { MessageService } from './message.service';

const ALERTE = 'Texte potentiellement blessant (FRM-03) : `{ code: "ALERTE_MODERATION", message, analyse }`. Renvoyer avec `confirmerMalgreAlerte: true` pour publier masqué.';

/** /api/forum/messages — replies (FRM-04). The thread itself comes from GET /sujets/:id. */
@ApiTags('messages')
@Controller('messages')
export class MessageController {
  constructor(
    private readonly service: MessageService,
    private readonly interactions: InteractionService,
    private readonly moderation: ModerationService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'Réponses publiées (sujetId, auteurId), les plus anciennes d’abord' })
  findAll(@Query() query: QueryMessageDto) {
    return this.service.findAll(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Une réponse publiée' })
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.service.findOne(id);
  }

  @Post()
  @ApiOperation({ summary: 'FRM-04 · Répondre au post (ou à une réponse avec parentId) → { message, notifier }' })
  @ApiUnprocessableEntityResponse({ description: ALERTE })
  create(@Body() body: CreateMessageDto) {
    return this.service.create(body);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Modifier sa réponse' })
  @ApiUnprocessableEntityResponse({ description: ALERTE })
  update(@Param('id', ParseIntPipe) id: number, @Body() body: UpdateMessageDto) {
    return this.service.update(id, body);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Supprimer sa réponse (?utilisateurId=) — devient « Message supprimé » si elle a des réponses' })
  remove(@Param('id', ParseIntPipe) id: number, @Query() query: QueryUtilisateurDto) {
    return this.service.remove(id, query.utilisateurId);
  }

  @Put(':id/vote')
  @ApiOperation({ summary: 'Voter pour (1), contre (−1) ou retirer (0)' })
  voter(@Param('id', ParseIntPipe) id: number, @Body() body: VoteDto) {
    return this.interactions.voter('message', id, body.utilisateurId, body.valeur);
  }

  @Put(':id/reactions/:type')
  @ApiParam({ name: 'type', enum: REACTIONS })
  @ApiOperation({ summary: '« Utile » / « Merci » (actif: true / false)' })
  reagir(@Param('id', ParseIntPipe) id: number, @Param('type', ReactionPipe) type: TypeReaction, @Body() body: InterrupteurDto) {
    return this.interactions.reagir('message', id, type, body.utilisateurId, body.actif);
  }

  @Post(':id/signalements')
  @ApiOperation({ summary: 'FRM-05 · Signaler la réponse (masquée pour tous au 3e signalement)' })
  signaler(@Param('id', ParseIntPipe) id: number, @Body() body: SignalementDto) {
    return this.moderation.signaler('message', id, body);
  }
}
