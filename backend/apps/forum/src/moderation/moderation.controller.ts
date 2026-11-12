import { BadRequestException, Body, Controller, Get, Param, ParseIntPipe, PipeTransform, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiParam, ApiTags } from '@nestjs/swagger';

import { CIBLES } from '../forum.constants';
import type { Cible } from '../forum.constants';
import { DecisionDto, EpingleDto, QueryFileDto } from './moderation.dto';
import { ModerationService } from './moderation.service';

/** `sujets` / `messages` in the URL → the target type. */
class CiblePipe implements PipeTransform<string, Cible> {
  transform(value: string): Cible {
    const cible = value.replace(/s$/, '');
    if (!(CIBLES as readonly string[]).includes(cible)) throw new BadRequestException('Type inconnu : sujets ou messages.');
    return cible as Cible;
  }
}

/** /api/forum/moderation — the admin side (ADM-09, ADM-10). */
@ApiTags('modération')
@Controller('moderation')
export class ModerationController {
  constructor(private readonly service: ModerationService) {}

  @Get('file')
  @ApiOperation({ summary: 'ADM-09 · Contenus signalés, score IA décroissant, compteurs et « traités cette semaine »' })
  file(@Query() query: QueryFileDto) {
    return this.service.file(query);
  }

  @Get(':type/:id')
  @ApiParam({ name: 'type', enum: ['sujets', 'messages'] })
  @ApiOperation({ summary: 'ADM-10 · Revue : contenu, contexte, analyse IA, signalements, dossier de l’auteur' })
  revue(@Param('type', CiblePipe) cible: Cible, @Param('id', ParseIntPipe) id: number) {
    return this.service.revue(cible, id);
  }

  @Post(':type/:id/decision')
  @ApiParam({ name: 'type', enum: ['sujets', 'messages'] })
  @ApiOperation({ summary: 'ADM-10 · Approuver, supprimer, supprimer et avertir (3e avertissement → 7 jours), suspendre' })
  decider(@Param('type', CiblePipe) cible: Cible, @Param('id', ParseIntPipe) id: number, @Body() body: DecisionDto) {
    return this.service.decider(cible, id, body);
  }

  @Post('sujets/:id/epingle')
  @ApiOperation({ summary: 'Épingler / désépingler un post' })
  epingler(@Param('id', ParseIntPipe) id: number, @Body() body: EpingleDto) {
    return this.service.epingler(id, body.epingle);
  }

  @Get('membres/:id/sanctions')
  @ApiOperation({ summary: 'Avertissements et suspensions d’un membre' })
  sanctions(@Param('id', ParseIntPipe) id: number) {
    return this.service.sanctionsDe(id);
  }

  @Get('membres/:id/dossier')
  @ApiOperation({ summary: 'Dossier d’un membre : fiabilité, avertissements, suspension en cours' })
  dossier(@Param('id', ParseIntPipe) id: number) {
    return this.service.dossier(id);
  }
}
