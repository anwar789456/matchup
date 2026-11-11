import { Body, Controller, Delete, Get, HttpCode, Param, ParseIntPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import {
  CreateEquipeDto,
  JoueurDto,
  PaiementEquipeDto,
  QueryEquipeDto,
  RefusDto,
  RejoindreDto,
  UpdateEquipeDto,
} from './equipe.dto';
import { EquipeService } from './equipe.service';

/** /api/tournois/equipes */
@ApiTags('equipes')
@Controller('equipes')
export class EquipeController {
  constructor(private readonly service: EquipeService) {}

  @Get()
  @ApiOperation({ summary: 'Liste (tournoiId, capitaineId, joueurId, statut)' })
  findAll(@Query() query: QueryEquipeDto) {
    return this.service.liste(query);
  }

  @Get('invitation/:code')
  @ApiOperation({ summary: 'Équipe d’un lien d’invitation' })
  parCode(@Param('code') code: string) {
    return this.service.parCode(code);
  }

  @Post('rejoindre')
  @HttpCode(200)
  @ApiOperation({ summary: 'Rejoindre une équipe avec le code d’invitation' })
  rejoindre(@Body() body: RejoindreDto) {
    return this.service.rejoindre(body.code, body.joueurId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Détail' })
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.service.findOne(id);
  }

  @Get(':id/matchs')
  @ApiOperation({ summary: 'Calendrier de l’équipe' })
  calendrier(@Param('id', ParseIntPipe) id: number) {
    return this.service.calendrier(id);
  }

  @Post()
  @ApiOperation({ summary: 'Inscrire une équipe (en attente de paiement et de validation)' })
  create(@Body() body: CreateEquipeDto) {
    return this.service.create(body);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Modifier (nom, logo, capitaine, joueurs, tête de série)' })
  update(@Param('id', ParseIntPipe) id: number, @Body() body: UpdateEquipeDto) {
    return this.service.update(id, body);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Supprimer (non payée, hors tableau)' })
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.service.remove(id);
  }

  @Post(':id/joueurs')
  @HttpCode(200)
  @ApiOperation({ summary: 'Ajouter un joueur' })
  ajouterJoueur(@Param('id', ParseIntPipe) id: number, @Body() body: JoueurDto) {
    return this.service.ajouterJoueur(id, body.joueurId);
  }

  @Delete(':id/joueurs/:joueurId')
  @ApiOperation({ summary: 'Retirer un joueur (pas le capitaine)' })
  retirerJoueur(@Param('id', ParseIntPipe) id: number, @Param('joueurId', ParseIntPipe) joueurId: number) {
    return this.service.retirerJoueur(id, joueurId);
  }

  @Post(':id/paiement')
  @HttpCode(200)
  @ApiOperation({ summary: 'Frais payés (après un paiement accepté du module paiement)' })
  payer(@Param('id', ParseIntPipe) id: number, @Body() body: PaiementEquipeDto) {
    return this.service.payer(id, body);
  }

  @Post(':id/valider')
  @HttpCode(200)
  @ApiOperation({ summary: 'Organisateur : valider l’inscription' })
  valider(@Param('id', ParseIntPipe) id: number) {
    return this.service.valider(id);
  }

  @Post(':id/refuser')
  @HttpCode(200)
  @ApiOperation({ summary: 'Organisateur : refuser (motif) ; remboursement si payé' })
  refuser(@Param('id', ParseIntPipe) id: number, @Body() body: RefusDto) {
    return this.service.refuser(id, body.motif);
  }

  @Post(':id/annuler')
  @HttpCode(200)
  @ApiOperation({ summary: 'Capitaine : retirer l’équipe avant le tirage ; remboursement si payé' })
  annuler(@Param('id', ParseIntPipe) id: number) {
    return this.service.annuler(id);
  }

  @Post(':id/rembourser')
  @HttpCode(200)
  @ApiOperation({ summary: 'Marquer le remboursement comme effectué' })
  rembourser(@Param('id', ParseIntPipe) id: number, @Body() body: PaiementEquipeDto) {
    return this.service.rembourser(id, body.paiementId);
  }
}
