import { Body, Controller, Delete, Get, HttpCode, Param, ParseIntPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';

import { AnnonceService, CreateAnnonceDto } from '../annonce/annonce.service';
import { TableauService } from '../tableau/tableau.service';
import {
  AnnulerTournoiDto,
  CreateTournoiDto,
  DashboardQueryDto,
  EchangeDto,
  EquipeQueryDto,
  GenererTableauDto,
  QueryTournoiDto,
  UpdateTournoiDto,
} from './tournoi.dto';
import { TournoiService } from './tournoi.service';

/** /api/tournois/tournois */
@ApiTags('tournois')
@Controller('tournois')
export class TournoiController {
  constructor(
    private readonly service: TournoiService,
    private readonly tableau: TableauService,
    private readonly annonces: AnnonceService,
  ) {}

  // --- Liste, détail, CRUD -------------------------------------------------------------------

  @Get()
  @ApiOperation({ summary: 'Liste avec filtres (sport, ville, dates, niveau, frais, places libres) et places restantes' })
  findAll(@Query() query: QueryTournoiDto) {
    return this.service.liste(query);
  }

  @Get('tableau-de-bord')
  @ApiOperation({ summary: 'Tableau de bord organisateur : tournois actifs, inscriptions, revenus, prochains matchs' })
  dashboard(@Query() query: DashboardQueryDto) {
    return this.service.tableauDeBord(query.organisateurId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Détail avec places restantes' })
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.service.detail(id);
  }

  @Post()
  @ApiOperation({ summary: 'Créer (en brouillon)' })
  create(@Body() body: CreateTournoiDto) {
    return this.service.create(body);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Modifier (champs envoyés seulement)' })
  update(@Param('id', ParseIntPipe) id: number, @Body() body: UpdateTournoiDto) {
    return this.service.update(id, body);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Supprimer (brouillon, annulé ou terminé)' })
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.service.remove(id);
  }

  // --- Cycle de vie --------------------------------------------------------------------------

  @Post(':id/publier')
  @HttpCode(200)
  @ApiOperation({ summary: 'Publier : brouillon → inscriptions ouvertes' })
  publier(@Param('id', ParseIntPipe) id: number) {
    return this.service.publier(id);
  }

  @Post(':id/cloturer')
  @HttpCode(200)
  @ApiOperation({ summary: 'Clôturer les inscriptions' })
  cloturer(@Param('id', ParseIntPipe) id: number) {
    return this.service.cloturer(id);
  }

  @Post(':id/rouvrir')
  @HttpCode(200)
  @ApiOperation({ summary: 'Rouvrir les inscriptions (avant le tableau)' })
  rouvrir(@Param('id', ParseIntPipe) id: number) {
    return this.service.rouvrir(id);
  }

  @Post(':id/annuler')
  @HttpCode(200)
  @ApiOperation({ summary: 'Annuler (motif) : les équipes payées passent « à rembourser »' })
  annuler(@Param('id', ParseIntPipe) id: number, @Body() body: AnnulerTournoiDto) {
    return this.service.annuler(id, body.motif);
  }

  // --- Tableau, classement, calendrier -------------------------------------------------------

  @Get(':id/tableau')
  @ApiOperation({ summary: 'Tableau (poules + phase finale) ; vide tant qu’il n’est pas publié' })
  @ApiQuery({ name: 'brouillon', required: false, description: 'true = voir le tableau non publié (organisateur)' })
  getTableau(
    @Param('id', ParseIntPipe) id: number,
    @Query() query: EquipeQueryDto,
    @Query('brouillon') brouillon?: string,
  ) {
    return this.tableau.tableau(id, { equipeId: query.equipeId, brouillon: brouillon === 'true' });
  }

  @Post(':id/tableau/generer')
  @HttpCode(200)
  @ApiOperation({ summary: 'Générer tableau + calendrier selon les contraintes (apercu: true = sans enregistrer)' })
  generer(@Param('id', ParseIntPipe) id: number, @Body() body: GenererTableauDto) {
    return this.tableau.generer(id, body);
  }

  @Post(':id/tableau/echanger')
  @HttpCode(200)
  @ApiOperation({ summary: 'Échanger la place de deux équipes (glisser-déposer)' })
  echanger(@Param('id', ParseIntPipe) id: number, @Body() body: EchangeDto) {
    return this.tableau.echanger(id, body.equipeA, body.equipeB);
  }

  @Post(':id/tableau/publier')
  @HttpCode(200)
  @ApiOperation({ summary: 'Publier le tableau aux joueurs' })
  publierTableau(@Param('id', ParseIntPipe) id: number) {
    return this.tableau.publier(id);
  }

  @Delete(':id/tableau')
  @ApiOperation({ summary: 'Supprimer le tableau (aucun match joué)' })
  supprimerTableau(@Param('id', ParseIntPipe) id: number) {
    return this.tableau.supprimer(id);
  }

  @Get(':id/classement')
  @ApiOperation({ summary: 'Classements de poule + classement général' })
  classement(@Param('id', ParseIntPipe) id: number, @Query() query: EquipeQueryDto) {
    return this.tableau.classement(id, query.equipeId);
  }

  @Get(':id/calendrier')
  @ApiOperation({ summary: 'Calendrier des matchs par jour (filtre équipe)' })
  calendrier(@Param('id', ParseIntPipe) id: number, @Query() query: EquipeQueryDto) {
    return this.tableau.calendrier(id, query.equipeId);
  }

  // --- Annonces ------------------------------------------------------------------------------

  @Get(':id/annonces')
  @ApiOperation({ summary: 'Annonces de l’organisateur, les plus récentes d’abord' })
  listeAnnonces(@Param('id', ParseIntPipe) id: number) {
    return this.annonces.liste(id);
  }

  @Post(':id/annonces')
  @ApiOperation({ summary: 'Envoyer une annonce (notification + email) aux équipes' })
  creerAnnonce(@Param('id', ParseIntPipe) id: number, @Body() body: CreateAnnonceDto) {
    return this.annonces.creer(id, body);
  }

  @Delete(':id/annonces/:annonceId')
  @ApiOperation({ summary: 'Supprimer une annonce' })
  supprimerAnnonce(@Param('id', ParseIntPipe) id: number, @Param('annonceId', ParseIntPipe) annonceId: number) {
    return this.annonces.supprimer(id, annonceId);
  }
}
