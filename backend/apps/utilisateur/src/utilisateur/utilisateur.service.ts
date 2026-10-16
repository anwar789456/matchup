import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { CrudService } from '@app/common';
import { CreateUtilisateurDto, UpdateUtilisateurDto } from './utilisateur.dto';
import { Utilisateur } from './utilisateur.entity';

/** findAll, findOne, create, update, remove viennent de CrudService ; ajoute tes méthodes ici. */
@Injectable()
export class UtilisateurService extends CrudService<Utilisateur> {
  constructor(@InjectRepository(Utilisateur) repo: Repository<Utilisateur>) {
    super(repo, 'Utilisateur');
  }

  /** Le mot de passe est haché avant d’être enregistré. */
  override async create(data: CreateUtilisateurDto): Promise<Utilisateur> {
    const exists = await this.repo.findOne({ where: { email: data.email } });
    if (exists) throw new BadRequestException('Un compte existe déjà avec cet email.');
    return super.create({ ...data, motDePasse: await bcrypt.hash(data.motDePasse, 10) });
  }

  override async update(id: number, data: UpdateUtilisateurDto): Promise<Utilisateur> {
    const changes = { ...data };
    if (changes.motDePasse) changes.motDePasse = await bcrypt.hash(changes.motDePasse, 10);
    return super.update(id, changes);
  }

  /** Vérifie email + mot de passe et renvoie l’utilisateur (pas de jeton : projet d’école). */
  async login(email: string, motDePasse: string): Promise<Utilisateur> {
    const user = await this.repo
      .createQueryBuilder('u')
      .addSelect('u.motDePasse')
      .where('u.email = :email', { email })
      .getOne();
    if (!user || !(await bcrypt.compare(motDePasse, user.motDePasse))) {
      throw new UnauthorizedException('Email ou mot de passe incorrect.');
    }
    return user;
  }
}
