import { Module } from '@nestjs/common';

import { DatabaseModule, MailModule } from '@app/common';
import { CodeEmail } from './compte/code-email.entity';
import { CompteController } from './compte/compte.controller';
import { CompteService } from './compte/compte.service';
import { UtilisateurController } from './utilisateur/utilisateur.controller';
import { Utilisateur } from './utilisateur/utilisateur.entity';
import { UtilisateurService } from './utilisateur/utilisateur.service';

/**
 * Module utilisateur: tables in the `utilisateur` schema of the shared database.
 * Add an entity here (and in its folder) to get its table.
 */
@Module({
  imports: [DatabaseModule.forModule('utilisateur', [Utilisateur, CodeEmail]), MailModule],
  controllers: [UtilisateurController, CompteController],
  providers: [UtilisateurService, CompteService],
})
export class UtilisateurModule {}
