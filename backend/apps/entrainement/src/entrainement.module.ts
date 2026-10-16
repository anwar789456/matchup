import { Module } from '@nestjs/common';

import { DatabaseModule } from '@app/common';
import { ProgrammeController } from './programme/programme.controller';
import { Programme } from './programme/programme.entity';
import { ProgrammeService } from './programme/programme.service';
import { SeanceController } from './seance/seance.controller';
import { Seance } from './seance/seance.entity';
import { SeanceService } from './seance/seance.service';

/**
 * Module entrainement: tables in the `entrainement` schema of the shared database.
 * Add an entity here (and in its folder) to get its table.
 */
@Module({
  imports: [DatabaseModule.forModule('entrainement', [Programme, Seance])],
  controllers: [ProgrammeController, SeanceController],
  providers: [ProgrammeService, SeanceService],
})
export class EntrainementModule {}
