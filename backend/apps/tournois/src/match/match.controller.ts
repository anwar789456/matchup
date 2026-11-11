import { Body, Controller, Delete, Get, HttpCode, Param, ParseIntPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import { EvenementDto, ForfaitDto, QueryMatchDto, ScoreDto, TerminerDto, UpdateMatchDto } from './match.dto';
import { MatchService } from './match.service';

/** /api/tournois/matchs — créés par le générateur de tableau. */
@ApiTags('matchs')
@Controller('matchs')
export class MatchController {
  constructor(private readonly service: MatchService) {}

  @Get()
  @ApiOperation({ summary: 'Liste (tournoiId, equipeId, statut, phase, terrain, du, au)' })
  findAll(@Query() query: QueryMatchDto) {
    return this.service.liste(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Détail (scoreboard : score, sets, chronologie)' })
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.service.detail(id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Déplacer (heure, terrain) — vérifie les conflits' })
  update(@Param('id', ParseIntPipe) id: number, @Body() body: UpdateMatchDto) {
    return this.service.update(id, body);
  }

  @Post(':id/demarrer')
  @HttpCode(200)
  @ApiOperation({ summary: 'Coup d’envoi : EN DIRECT' })
  demarrer(@Param('id', ParseIntPipe) id: number) {
    return this.service.demarrer(id);
  }

  @Post(':id/score')
  @HttpCode(200)
  @ApiOperation({ summary: 'Score en direct' })
  score(@Param('id', ParseIntPipe) id: number, @Body() body: ScoreDto) {
    return this.service.score(id, body);
  }

  @Post(':id/evenements')
  @HttpCode(200)
  @ApiOperation({ summary: 'Ajouter un fait (but, panier, carton…) ; `points` met le score à jour' })
  ajouterEvenement(@Param('id', ParseIntPipe) id: number, @Body() body: EvenementDto) {
    return this.service.ajouterEvenement(id, body);
  }

  @Delete(':id/evenements/:evenementId')
  @ApiOperation({ summary: 'Annuler un fait saisi par erreur' })
  supprimerEvenement(@Param('id', ParseIntPipe) id: number, @Param('evenementId') evenementId: string) {
    return this.service.supprimerEvenement(id, evenementId);
  }

  @Post(':id/terminer')
  @HttpCode(200)
  @ApiOperation({ summary: 'Score final (confirme: true) : qualifie le vainqueur, termine le tournoi après la finale' })
  terminer(@Param('id', ParseIntPipe) id: number, @Body() body: TerminerDto) {
    return this.service.terminer(id, body);
  }

  @Post(':id/forfait')
  @HttpCode(200)
  @ApiOperation({ summary: 'Forfait d’une équipe' })
  forfait(@Param('id', ParseIntPipe) id: number, @Body() body: ForfaitDto) {
    return this.service.forfait(id, body.equipe);
  }

  @Get(':id/resume')
  @ApiOperation({ summary: 'Résumé d’après-match prêt à partager' })
  resume(@Param('id', ParseIntPipe) id: number) {
    return this.service.resume(id);
  }
}
