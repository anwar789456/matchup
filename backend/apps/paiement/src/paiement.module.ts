import { Module } from '@nestjs/common';

import { DatabaseModule } from '@app/common';
import { PaiementController } from './paiement/paiement.controller';
import { Paiement } from './paiement/paiement.entity';
import { PaiementService } from './paiement/paiement.service';

/**
 * Module paiement: tables in the `paiement` schema of the shared database.
 * Add an entity here (and in its folder) to get its table.
 */
@Module({
  imports: [DatabaseModule.forModule('paiement', [Paiement])],
  controllers: [PaiementController],
  providers: [PaiementService],
})
export class PaiementModule {}
