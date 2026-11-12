import { Body, Controller, Get, Param, ParseIntPipe, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import { CreatePartageDto, PayerPartDto, PayerResteDto, QueryPartageDto, RelancerDto } from './partage.dto';
import { PartageService } from './partage.service';

/** /api/paiement/partages — le paiement partagé d’une réservation (PAY-11, PAY-12). */
@ApiTags('partages')
@Controller('partages')
export class PartageController {
  constructor(private readonly service: PartageService) {}

  @Get()
  @ApiOperation({ summary: 'Liste (par réservation, organisateur, joueur, statut)' })
  liste(@Query() q: QueryPartageDto) {
    return this.service.liste(q);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Suivi des paiements : parts et résumé (collecté, reste, échéance)' })
  detail(@Param('id', ParseIntPipe) id: number) {
    return this.service.detail(id);
  }

  @Post()
  @ApiOperation({ summary: 'Partager une réservation : une part par joueur, échéance 3 h avant le match' })
  creer(@Body() body: CreatePartageDto) {
    return this.service.creer(body);
  }

  @Post(':id/parts/:partId/payer')
  @ApiOperation({ summary: 'Payer sa part' })
  payerPart(
    @Param('id', ParseIntPipe) id: number,
    @Param('partId', ParseIntPipe) partId: number,
    @Body() body: PayerPartDto,
  ) {
    return this.service.payerPart(id, partId, body);
  }

  @Post(':id/relancer')
  @ApiOperation({ summary: 'Relancer les parts en attente (renvoie les destinatairesIds à notifier)' })
  relancer(@Param('id', ParseIntPipe) id: number, @Body() body: RelancerDto) {
    return this.service.relancer(id, body);
  }

  @Post(':id/payer-le-reste')
  @ApiOperation({ summary: 'L’organisateur paie toutes les parts en attente (PAY-12)' })
  payerLeReste(@Param('id', ParseIntPipe) id: number, @Body() body: PayerResteDto) {
    return this.service.payerLeReste(id, body);
  }

  @Post(':id/verifier-echeance')
  @ApiOperation({ summary: 'Après l’échéance avec des parts en attente : annule et rembourse chacun sur son solde' })
  verifierEcheance(@Param('id', ParseIntPipe) id: number) {
    return this.service.verifierEcheance(id);
  }

  @Post(':id/annuler')
  @ApiOperation({ summary: 'Réservation annulée : rembourse toutes les parts payées sur les soldes' })
  annuler(@Param('id', ParseIntPipe) id: number) {
    return this.service.annuler(id);
  }
}
