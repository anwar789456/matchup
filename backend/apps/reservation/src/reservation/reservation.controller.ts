import { Body, Controller, Delete, Get, Param, ParseIntPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import { CreateReservationDto, UpdateReservationDto, QueryReservationDto } from './reservation.dto';
import { ReservationService } from './reservation.service';

/** /api/reservation/reservations */
@ApiTags('reservations')
@Controller('reservations')
export class ReservationController {
  constructor(private readonly service: ReservationService) {}

  @Get()
  @ApiOperation({ summary: 'Liste (filtres facultatifs en query)' })
  findAll(@Query() query: QueryReservationDto) {
    return this.service.findAll(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Détail' })
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.service.findOne(id);
  }

  @Post()
  @ApiOperation({ summary: 'Créer' })
  create(@Body() body: CreateReservationDto) {
    return this.service.create(body);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Modifier (champs envoyés seulement)' })
  update(@Param('id', ParseIntPipe) id: number, @Body() body: UpdateReservationDto) {
    return this.service.update(id, body);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Supprimer' })
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.service.remove(id);
  }
}
