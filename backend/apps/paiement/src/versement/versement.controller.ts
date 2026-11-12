import { Body, Controller, Delete, Get, Param, ParseIntPipe, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import { CalculerVersementDto, QueryVersementDto, ValiderVersementsDto } from './versement.dto';
import { VersementService } from './versement.service';

/** /api/paiement/versements — virements aux propriétaires, coachs et organisateurs (ADM-07). */
@ApiTags('versements')
@Controller('versements')
export class VersementController {
  constructor(private readonly service: VersementService) {}

  @Get()
  @ApiOperation({ summary: 'Liste (par bénéficiaire, rôle, statut)' })
  liste(@Query() q: QueryVersementDto) {
    return this.service.liste(q);
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.service.findOne(id);
  }

  @Get(':id/paiements')
  @ApiOperation({ summary: 'Les paiements inclus' })
  paiements(@Param('id', ParseIntPipe) id: number) {
    return this.service.paiementsDe(id);
  }

  @Post('calculer')
  @ApiOperation({ summary: 'Calculer le versement d’une période (apercu: true pour ne rien réserver)' })
  calculer(@Body() body: CalculerVersementDto) {
    return this.service.calculer(body);
  }

  @Post('valider')
  @ApiOperation({ summary: 'Valider une sélection de versements (admin)' })
  valider(@Body() body: ValiderVersementsDto) {
    return this.service.valider(body.ids);
  }

  @Post(':id/envoyer')
  @ApiOperation({ summary: 'Marquer le virement comme envoyé' })
  envoyer(@Param('id', ParseIntPipe) id: number) {
    return this.service.envoyer(id);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Supprimer un versement en attente (ses paiements sont libérés)' })
  supprimer(@Param('id', ParseIntPipe) id: number) {
    return this.service.supprimer(id);
  }
}
