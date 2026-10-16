import { Body, Controller, Delete, Get, Param, ParseIntPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import { CreateSeanceDto, UpdateSeanceDto, QuerySeanceDto } from './seance.dto';
import { SeanceService } from './seance.service';

/** /api/entrainement/seances */
@ApiTags('seances')
@Controller('seances')
export class SeanceController {
  constructor(private readonly service: SeanceService) {}

  @Get()
  @ApiOperation({ summary: 'Liste (filtres facultatifs en query)' })
  findAll(@Query() query: QuerySeanceDto) {
    return this.service.findAll(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Détail' })
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.service.findOne(id);
  }

  @Post()
  @ApiOperation({ summary: 'Créer' })
  create(@Body() body: CreateSeanceDto) {
    return this.service.create(body);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Modifier (champs envoyés seulement)' })
  update(@Param('id', ParseIntPipe) id: number, @Body() body: UpdateSeanceDto) {
    return this.service.update(id, body);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Supprimer' })
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.service.remove(id);
  }
}
