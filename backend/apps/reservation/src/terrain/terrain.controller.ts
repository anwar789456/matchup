import { Body, Controller, Delete, Get, Param, ParseIntPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import { CreateTerrainDto, UpdateTerrainDto, QueryTerrainDto } from './terrain.dto';
import { TerrainService } from './terrain.service';

/** /api/reservation/terrains */
@ApiTags('terrains')
@Controller('terrains')
export class TerrainController {
  constructor(private readonly service: TerrainService) {}

  @Get()
  @ApiOperation({ summary: 'Liste (filtres facultatifs en query)' })
  findAll(@Query() query: QueryTerrainDto) {
    return this.service.findAll(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Détail' })
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.service.findOne(id);
  }

  @Post()
  @ApiOperation({ summary: 'Créer' })
  create(@Body() body: CreateTerrainDto) {
    return this.service.create(body);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Modifier (champs envoyés seulement)' })
  update(@Param('id', ParseIntPipe) id: number, @Body() body: UpdateTerrainDto) {
    return this.service.update(id, body);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Supprimer' })
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.service.remove(id);
  }
}
