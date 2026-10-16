import { Module } from '@nestjs/common';

import { DatabaseModule } from '@app/common';
import { TerrainController } from './terrain/terrain.controller';
import { Terrain } from './terrain/terrain.entity';
import { TerrainService } from './terrain/terrain.service';
import { ReservationController } from './reservation/reservation.controller';
import { Reservation } from './reservation/reservation.entity';
import { ReservationService } from './reservation/reservation.service';

/**
 * Module reservation: tables in the `reservation` schema of the shared database.
 * Add an entity here (and in its folder) to get its table.
 */
@Module({
  imports: [DatabaseModule.forModule('reservation', [Terrain, Reservation])],
  controllers: [TerrainController, ReservationController],
  providers: [TerrainService, ReservationService],
})
export class ReservationModule {}
