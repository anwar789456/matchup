import { Module } from '@nestjs/common';

import { DatabaseModule } from '@app/common';
import { Annonce } from './annonce/annonce.entity';
import { AnnonceService } from './annonce/annonce.service';
import { EquipeController } from './equipe/equipe.controller';
import { Equipe } from './equipe/equipe.entity';
import { EquipeService } from './equipe/equipe.service';
import { MatchController } from './match/match.controller';
import { Match } from './match/match.entity';
import { MatchService } from './match/match.service';
import { TableauService } from './tableau/tableau.service';
import { TournoiController } from './tournoi/tournoi.controller';
import { Tournoi } from './tournoi/tournoi.entity';
import { TournoiService } from './tournoi/tournoi.service';

/**
 * Module tournois: tables in the `tournois` schema of the shared database.
 * Add an entity here (and in its folder) to get its table.
 */
@Module({
  imports: [DatabaseModule.forModule('tournois', [Tournoi, Equipe, Match, Annonce])],
  controllers: [TournoiController, EquipeController, MatchController],
  providers: [TournoiService, EquipeService, MatchService, TableauService, AnnonceService],
})
export class TournoisModule {}
