import { Body, Controller, Get, Param, ParseIntPipe, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import { AccepterDemandeDto, CreateDemandeDto, QueryDemandeDto, RefuserDemandeDto } from './remboursement.dto';
import { RemboursementService } from './remboursement.service';

/** /api/paiement/remboursements — demandes des joueurs (WAL-04, WAL-05) et file de l’admin. */
@ApiTags('remboursements')
@Controller('remboursements')
export class RemboursementController {
  constructor(private readonly service: RemboursementService) {}

  @Get()
  @ApiOperation({ summary: 'Liste (par utilisateur, paiement, statut)' })
  liste(@Query() q: QueryDemandeDto) {
    return this.service.liste(q);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Détail (suivi WAL-05)' })
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.service.findOne(id);
  }

  @Post()
  @ApiOperation({ summary: 'Demander un remboursement' })
  creer(@Body() body: CreateDemandeDto) {
    return this.service.creer(body);
  }

  @Post(':id/examiner')
  @ApiOperation({ summary: 'Passer en examen (admin)' })
  examiner(@Param('id', ParseIntPipe) id: number) {
    return this.service.examiner(id);
  }

  @Post(':id/accepter')
  @ApiOperation({ summary: 'Accepter et rembourser (admin)' })
  accepter(@Param('id', ParseIntPipe) id: number, @Body() body: AccepterDemandeDto) {
    return this.service.accepter(id, body);
  }

  @Post(':id/refuser')
  @ApiOperation({ summary: 'Refuser avec un motif (admin)' })
  refuser(@Param('id', ParseIntPipe) id: number, @Body() body: RefuserDemandeDto) {
    return this.service.refuser(id, body);
  }
}
