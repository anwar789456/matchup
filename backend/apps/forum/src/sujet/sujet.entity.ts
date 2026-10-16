import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

/** Sujet — table `forum.sujet`. */
@Entity('sujet')
export class Sujet {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  auteurId: number;

  @Column({ type: 'varchar', length: 255 })
  titre: string;

  @Column({ type: 'text' })
  contenu: string;

  @Index()
  @Column({ type: 'varchar', length: 40, default: 'general' })
  categorie: string;

  @Column({ type: 'boolean', default: false })
  epingle: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
