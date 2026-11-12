import { Body, Controller, Delete, Get, Param, ParseIntPipe, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiProperty, ApiTags } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt } from 'class-validator';

import { NouvelleCarteDto } from '../commun/moyen.dto';
import { CarteService } from './carte.service';

export class AjouterCarteDto extends NouvelleCarteDto {
  @ApiProperty({ example: 1 })
  @IsInt()
  utilisateurId: number;
}

export class QueryCarteDto {
  @ApiProperty({ example: 1 })
  @Type(() => Number)
  @IsInt()
  utilisateurId: number;
}

/** /api/paiement/cartes — moyens de paiement enregistrés (SET, checkout). */
@ApiTags('cartes')
@Controller('cartes')
export class CarteController {
  constructor(private readonly service: CarteService) {}

  @Get()
  @ApiOperation({ summary: 'Cartes d’un utilisateur (par défaut d’abord, expireBientot)' })
  liste(@Query() q: QueryCarteDto) {
    return this.service.liste(q.utilisateurId);
  }

  @Post()
  @ApiOperation({ summary: 'Ajouter une carte (seuls la marque et les 4 derniers chiffres sont gardés)' })
  ajouter(@Body() body: AjouterCarteDto) {
    const { utilisateurId, ...carte } = body;
    return this.service.ajouter(utilisateurId, carte);
  }

  @Post(':id/par-defaut')
  @ApiOperation({ summary: 'En faire la carte par défaut' })
  parDefaut(@Param('id', ParseIntPipe) id: number) {
    return this.service.definirParDefaut(id);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Supprimer' })
  supprimer(@Param('id', ParseIntPipe) id: number) {
    return this.service.supprimer(id);
  }
}
