import { Body, Controller, Get, Param, ParseIntPipe, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import { AuthentifierDto, PayerDto, QueryPaiementDto, RembourserDto } from './paiement.dto';
import { PaiementService } from './paiement.service';

/**
 * /api/paiement/paiements. Pas de POST/PATCH/DELETE « bruts » : un paiement ne passe à `paye`
 * qu’à travers la banque (simulée) ou le guichet.
 */
@ApiTags('paiements')
@Controller('paiements')
export class PaiementController {
  constructor(private readonly service: PaiementService) {}

  @Get()
  @ApiOperation({ summary: 'Liste (filtres facultatifs), le plus récent d’abord' })
  findAll(@Query() query: QueryPaiementDto) {
    return this.service.liste(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Détail' })
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.service.findOne(id);
  }

  @Get(':id/recu')
  @ApiOperation({ summary: 'Reçu d’un paiement passé (PAY-09)' })
  recu(@Param('id', ParseIntPipe) id: number) {
    return this.service.recu(id);
  }

  @Post()
  @ApiOperation({ summary: 'Payer (checkout PAY-01) : statut paye, a_authentifier (3-D Secure) ou echoue' })
  payer(@Body() body: PayerDto) {
    return this.service.payer(body);
  }

  @Post(':id/authentifier')
  @ApiOperation({ summary: 'Réponse 3-D Secure (PAY-07)' })
  authentifier(@Param('id', ParseIntPipe) id: number, @Body() body: AuthentifierDto) {
    return this.service.authentifier(id, body.approuve);
  }

  @Post(':id/rembourser')
  @ApiOperation({ summary: 'Rembourser tout ou partie (annulation, admin)' })
  rembourser(@Param('id', ParseIntPipe) id: number, @Body() body: RembourserDto) {
    return this.service.rembourser(id, body);
  }
}
