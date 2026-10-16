import { Module } from '@nestjs/common';

import { DatabaseModule } from '@app/common';
import { TournoiController } from './tournoi/tournoi.controller';
import { Tournoi } from './tournoi/tournoi.entity';
import { TournoiService } from './tournoi/tournoi.service';
import { EquipeController } from './equipe/equipe.controller';
import { Equipe } from './equipe/equipe.entity';
import { EquipeService } from './equipe/equipe.service';

/**
 * Module tournois: tables in the `tournois` schema of the shared database.
 * Add an entity here (and in its folder) to get its table.
 */
@Module({
  imports: [DatabaseModule.forModule('tournois', [Tournoi, Equipe])],
  controllers: [TournoiController, EquipeController],
  providers: [TournoiService, EquipeService],
})
export class TournoisModule {}
