import { Controller, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';

import { DemoService } from './demo.service';

/** /api/forum/demo — development data (refused when NODE_ENV=production). */
@ApiTags('démo')
@Controller('demo')
export class DemoController {
  constructor(private readonly service: DemoService) {}

  @Post('remplir')
  @ApiQuery({ name: 'remplacer', required: false, type: Boolean, description: 'Efface tout le forum avant de remplir.' })
  @ApiOperation({ summary: 'Remplit le forum avec les discussions de l’histoire (STORY-DATA) : posts, réponses, votes, signalements' })
  remplir(@Query('remplacer') remplacer?: string) {
    return this.service.remplir(remplacer === 'true');
  }
}
