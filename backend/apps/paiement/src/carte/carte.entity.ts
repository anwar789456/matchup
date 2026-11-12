import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

/**
 * Carte enregistrée — table `paiement.carte`. Jamais le numéro complet ni le CVC : la marque, les
 * 4 derniers chiffres et la date d’expiration (ce que Stripe renverra plus tard).
 */
@Entity('carte')
export class Carte {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  utilisateurId: number;

  @Column({ type: 'varchar', length: 20 })
  marque: string;

  @Column({ type: 'varchar', length: 4 })
  derniersChiffres: string;

  @Column({ type: 'int' })
  moisExp: number;

  @Column({ type: 'int' })
  anneeExp: number;

  @Column({ type: 'varchar', length: 120, nullable: true })
  titulaire?: string | null;

  @Column({ type: 'boolean', default: false })
  parDefaut: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
