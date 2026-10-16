import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { CrudService } from '@app/common';
import { Sujet } from './sujet.entity';

/** findAll, findOne, create, update, remove viennent de CrudService ; ajoute tes méthodes ici. */
@Injectable()
export class SujetService extends CrudService<Sujet> {
  constructor(@InjectRepository(Sujet) repo: Repository<Sujet>) {
    super(repo, 'Sujet');
  }
}
