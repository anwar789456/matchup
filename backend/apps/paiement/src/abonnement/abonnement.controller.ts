import { Body, Controller, Get, Param, ParseIntPipe, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import { AnnulerAbonnementDto, ChangerAbonnementDto, PreleverDto, QueryAbonnementDto, SouscrireDto } from './abonnement.dto';
import { AbonnementService } from './abonnement.service';

/** /api/paiement/abonnements — Premium, Starter, Pro, Coach (SUB-01 à SUB-07). */
@ApiTags('abonnements')
@Controller('abonnements')
export class AbonnementController {
  constructor(private readonly service: AbonnementService) {}

  @Get('plans')
  @ApiOperation({ summary: 'Les plans, prix mensuel / annuel et économie' })
  plans() {
    return this.service.plans();
  }

  @Get()
  @ApiOperation({ summary: 'Liste (par utilisateur, statut)' })
  liste(@Query() q: QueryAbonnementDto) {
    return this.service.liste(q);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Détail (prix actuel, rappel, jours d’essai)' })
  detail(@Param('id', ParseIntPipe) id: number) {
    return this.service.detail(id);
  }

  @Post()
  @ApiOperation({ summary: 'S’abonner (14 jours d’essai la première fois)' })
  souscrire(@Body() body: SouscrireDto) {
    return this.service.souscrire(body);
  }

  @Post(':id/changer')
  @ApiOperation({ summary: 'Changer de plan ou de période (prorata ; apercu: true pour seulement calculer)' })
  changer(@Param('id', ParseIntPipe) id: number, @Body() body: ChangerAbonnementDto) {
    return this.service.changer(id, body);
  }

  @Post(':id/annuler')
  @ApiOperation({ summary: 'Résilier : propose d’abord l’offre −30 %, puis confirmer: true' })
  annuler(@Param('id', ParseIntPipe) id: number, @Body() body: AnnulerAbonnementDto) {
    return this.service.annuler(id, body);
  }

  @Post(':id/accepter-offre')
  @ApiOperation({ summary: 'Accepter l’offre de rétention' })
  accepterOffre(@Param('id', ParseIntPipe) id: number) {
    return this.service.accepterOffre(id);
  }

  @Post(':id/reactiver')
  @ApiOperation({ summary: 'Annuler la résiliation avant la fin de l’accès' })
  reactiver(@Param('id', ParseIntPipe) id: number) {
    return this.service.reactiver(id);
  }

  @Post(':id/prelever')
  @ApiOperation({ summary: 'Prélèvement de l’échéance (cron, menu debug ; forcer: true pour la démo)' })
  prelever(@Param('id', ParseIntPipe) id: number, @Body() body: PreleverDto) {
    return this.service.prelever(id, body);
  }
}
