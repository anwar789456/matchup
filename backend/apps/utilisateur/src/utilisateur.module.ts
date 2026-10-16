import { Module } from '@nestjs/common';

import { DatabaseModule } from '@app/common';
import { UtilisateurController } from './utilisateur/utilisateur.controller';
import { Utilisateur } from './utilisateur/utilisateur.entity';
import { UtilisateurService } from './utilisateur/utilisateur.service';

/**
 * Module utilisateur: tables in the `utilisateur` schema of the shared database.
 * Add an entity here (and in its folder) to get its table.
 */
@Module({
  imports: [DatabaseModule.forModule('utilisateur', [Utilisateur])],
  controllers: [UtilisateurController],
  providers: [UtilisateurService],
})
export class UtilisateurModule {}
