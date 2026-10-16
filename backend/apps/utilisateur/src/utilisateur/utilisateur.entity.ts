import { Exclude } from 'class-transformer';
import { decimal } from '@app/common';
import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

/** Utilisateur — table `utilisateur.utilisateur`. */
@Entity('utilisateur')
export class Utilisateur {
  @PrimaryGeneratedColumn()
  id: number;

  /** Filled in at the end of the player onboarding (PLY-10), so empty right after sign-up. */
  @Column({ type: 'varchar', length: 255, nullable: true })
  prenom?: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  nom?: string | null;

  /** Public handle (« @yassine.b »), unique. */
  @Index()
  @Column({ type: 'varchar', length: 40, nullable: true, unique: true })
  pseudo?: string | null;

  @Index()
  @Column({ type: 'varchar', length: 255, unique: true })
  email: string;

  @Exclude()
  @Column({ type: 'varchar', length: 255, select: false })
  motDePasse: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  telephone?: string | null;

  @Index()
  @Column({ type: 'varchar', length: 40, default: 'joueur' })
  role: string;

  @Index()
  @Column({ type: 'varchar', length: 255, nullable: true })
  ville?: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  avatarUrl?: string | null;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal, nullable: true })
  niveau?: number | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
