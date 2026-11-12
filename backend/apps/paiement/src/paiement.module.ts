import { Module } from '@nestjs/common';

import { DatabaseModule } from '@app/common';
import { AbonnementController } from './abonnement/abonnement.controller';
import { Abonnement } from './abonnement/abonnement.entity';
import { AbonnementService } from './abonnement/abonnement.service';
import { CarteController } from './carte/carte.controller';
import { Carte } from './carte/carte.entity';
import { CarteService } from './carte/carte.service';
import { CodePromoController } from './code-promo/code-promo.controller';
import { CodePromo } from './code-promo/code-promo.entity';
import { CodePromoService } from './code-promo/code-promo.service';
import { FinanceController, FinanceService } from './finance/finance.controller';
import { PaiementController } from './paiement/paiement.controller';
import { Paiement } from './paiement/paiement.entity';
import { PaiementService } from './paiement/paiement.service';
import { PartageController } from './partage/partage.controller';
import { Part, Partage } from './partage/partage.entity';
import { PartageService } from './partage/partage.service';
import { PortefeuilleController } from './portefeuille/portefeuille.controller';
import { Mouvement, Portefeuille } from './portefeuille/portefeuille.entity';
import { PortefeuilleService } from './portefeuille/portefeuille.service';
import { DemandeRemboursement } from './remboursement/demande-remboursement.entity';
import { RemboursementController } from './remboursement/remboursement.controller';
import { RemboursementService } from './remboursement/remboursement.service';
import { VersementController } from './versement/versement.controller';
import { Versement } from './versement/versement.entity';
import { VersementService } from './versement/versement.service';

/**
 * Module paiement (brief, Module 5 et section 10) : checkout, 3-D Secure, solde, cartes, codes
 * promo, paiement partagé, remboursements, abonnements, versements, finance. Tables dans le
 * schéma `paiement` ; voir README.md.
 */
@Module({
  imports: [
    DatabaseModule.forModule('paiement', [
      Paiement,
      Portefeuille,
      Mouvement,
      Carte,
      CodePromo,
      Partage,
      Part,
      DemandeRemboursement,
      Abonnement,
      Versement,
    ]),
  ],
  controllers: [
    PaiementController,
    PortefeuilleController,
    CarteController,
    CodePromoController,
    PartageController,
    RemboursementController,
    AbonnementController,
    VersementController,
    FinanceController,
  ],
  providers: [
    PaiementService,
    PortefeuilleService,
    CarteService,
    CodePromoService,
    PartageService,
    RemboursementService,
    AbonnementService,
    VersementService,
    FinanceService,
  ],
})
export class PaiementModule {}
