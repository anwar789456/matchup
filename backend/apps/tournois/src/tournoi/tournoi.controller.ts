import { Body, Controller, Delete, Get, Param, ParseIntPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import { CreateTournoiDto, UpdateTournoiDto, QueryTournoiDto } from './tournoi.dto';
import { TournoiService } from './tournoi.service';

/** /api/tournois/tournois */
@ApiTags('tournois')
@Controller('tournois')
export class TournoiController {
  constructor(private readonly service: TournoiService) {}

  @Get()
  @ApiOperation({ summary: 'Liste (filtres facultatifs en query)' })
  findAll(@Query() query: QueryTournoiDto) {
    return this.service.findAll(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Détail' })
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.service.findOne(id);
  }

  @Post()
  @ApiOperation({ summary: 'Créer' })
  create(@Body() body: CreateTournoiDto) {
    return this.service.create(body);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Modifier (champs envoyés seulement)' })
  update(@Param('id', ParseIntPipe) id: number, @Body() body: UpdateTournoiDto) {
    return this.service.update(id, body);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Supprimer' })
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.service.remove(id);
  }
}
