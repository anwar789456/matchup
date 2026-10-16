import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { CrudService } from '@app/common';
import { Equipe } from './equipe.entity';

/** findAll, findOne, create, update, remove viennent de CrudService ; ajoute tes méthodes ici. */
@Injectable()
export class EquipeService extends CrudService<Equipe> {
  constructor(@InjectRepository(Equipe) repo: Repository<Equipe>) {
    super(repo, 'Équipe');
  }
}
