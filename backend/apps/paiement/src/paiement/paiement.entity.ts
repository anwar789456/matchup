import { decimal } from '@app/common';
import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

/** Ce que le paiement règle. `objetId` pointe vers une ligne d’un autre module (ou de celui-ci). */
export const OBJETS = [
  'reservation', // module reservation
  'partie', // une place dans une partie publique
  'tournoi', // frais d’inscription (module tournois)
  'programme', // module entrainement
  'abonnement', // paiement.abonnement
  'recharge', // crédite le porte-monnaie
  'part', // paiement.part (paiement partagé)
  'partage_reste', // « Payer le reste » d’un paiement partagé
] as const;
export type Objet = (typeof OBJETS)[number];

export const METHODES = ['carte', 'portefeuille', 'mixte', 'especes', 'virement'] as const;

/**
 * en_attente : créé, pas encore à la banque · a_authentifier : 3-D Secure en cours ·
 * paye · echoue (raisonEchec) · partiellement_rembourse · rembourse.
 */
export const STATUTS_PAIEMENT = ['en_attente', 'a_authentifier', 'paye', 'echoue', 'partiellement_rembourse', 'rembourse'] as const;
export type StatutPaiement = (typeof STATUTS_PAIEMENT)[number];

/** Statuts où l’argent a été encaissé. */
export const ENCAISSES: StatutPaiement[] = ['paye', 'partiellement_rembourse', 'rembourse'];

/** Une tentative de paiement (chaque essai refusé reste une ligne) — table `paiement.paiement`. */
@Entity('paiement')
export class Paiement {
  @PrimaryGeneratedColumn()
  id: number;

  /** Numéro du reçu « MU-R-2026-01482 », donné quand le paiement passe. */
  @Index({ unique: true })
  @Column({ type: 'varchar', length: 30, nullable: true })
  reference?: string | null;

  @Index()
  @Column({ type: 'int' })
  utilisateurId: number;

  @Index()
  @Column({ type: 'varchar', length: 20 })
  objet: Objet;

  /** « 12 », « MU-48213 »… */
  @Index()
  @Column({ type: 'varchar', length: 40, nullable: true })
  objetId?: string | null;

  /** « Part · Arena Five, mer. 21 oct. » */
  @Column({ type: 'varchar', length: 255 })
  libelle: string;

  /** Qui touche l’argent (propriétaire, coach, organisateur) : sert aux versements. */
  @Index()
  @Column({ type: 'int', nullable: true })
  beneficiaireId?: number | null;

  /** Avant code promo. */
  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal })
  montantBrut: number;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal, default: 0 })
  remise: number;

  @Column({ type: 'varchar', length: 40, nullable: true })
  codePromo?: string | null;

  /** Total payé = montantBrut − remise = montantPortefeuille + montantCarte. */
  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal })
  montant: number;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal, default: 0 })
  montantPortefeuille: number;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal, default: 0 })
  montantCarte: number;

  @Index()
  @Column({ type: 'varchar', length: 20, default: 'carte' })
  methode: string;

  @Column({ type: 'int', nullable: true })
  carteId?: number | null;

  /** « Visa •••• 4242 » (aussi pour une carte non enregistrée). */
  @Column({ type: 'varchar', length: 60, nullable: true })
  carteLibelle?: string | null;

  @Index()
  @Column({ type: 'varchar', length: 30, default: 'en_attente' })
  statut: StatutPaiement;

  /** « fonds insuffisants », « authentification annulée »… */
  @Column({ type: 'varchar', length: 120, nullable: true })
  raisonEchec?: string | null;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal, default: 0 })
  montantRembourse: number;

  @Column({ type: 'timestamptz', nullable: true })
  payeLe?: Date | null;

  @Column({ type: 'timestamptz', nullable: true })
  rembourseLe?: Date | null;

  /** Le versement au bénéficiaire qui inclut ce paiement. */
  @Index()
  @Column({ type: 'int', nullable: true })
  versementId?: number | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
