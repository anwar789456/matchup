import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { LIMITES } from '../forum.constants';
import { AnalyserDto, SuggererTagsDto } from '../moderation/moderation.dto';
import { Sujet } from '../sujet/sujet.entity';
import { analyserTexte, normaliser, suggererTags } from './ia.logic';

/** /api/forum/ia — the checks the app runs while the member types. */
@ApiTags('ia')
@Controller('ia')
export class IaController {
  constructor(@InjectRepository(Sujet) private readonly sujets: Repository<Sujet>) {}

  @Post('analyser')
  @HttpCode(200)
  @ApiOperation({
    summary: 'FRM-03 · Score de toxicité / spam, passages à surligner, reformulation quand c’est possible',
    description: `À partir de ${LIMITES.seuilAlerte}, l’app montre l’alerte avant de publier.`,
  })
  analyser(@Body() body: AnalyserDto) {
    return { ...analyserTexte(body.texte), seuilAlerte: LIMITES.seuilAlerte };
  }

  @Post('tags')
  @HttpCode(200)
  @ApiOperation({ summary: 'FRM-02 · « Suggérés par l’IA » : 3 tags d’après le titre et le texte' })
  async tags(@Body() body: SuggererTagsDto) {
    const rows = (await this.sujets.query(
      `SELECT lower(t) AS tag, COUNT(*) AS n FROM ${this.sujets.metadata.tablePath} s, unnest(s.tags) t
       WHERE s.statut = 'publie' GROUP BY 1`,
    )) as { tag: string; n: string }[];
    const frequents = new Map(rows.map((r) => [normaliser(r.tag), Number(r.n)]));
    return suggererTags(body.titre, body.contenu ?? '', body.tags ?? [], frequents);
  }
}
