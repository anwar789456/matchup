import { decimal } from '@app/common';
import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

/** Programme — table `entrainement.programme`. */
@Entity('programme')
export class Programme {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  coachId: number;

  @Column({ type: 'varchar', length: 255 })
  titre: string;

  @Column({ type: 'text', nullable: true })
  description?: string | null;

  @Index()
  @Column({ type: 'varchar', length: 40 })
  sport: string;

  @Index()
  @Column({ type: 'varchar', length: 40, default: 'debutant' })
  niveau: string;

  @Column({ type: 'int', default: 4 })
  dureeSemaines: number;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal, default: 0 })
  prix: number;

  @Index()
  @Column({ type: 'boolean', default: false })
  publie: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
