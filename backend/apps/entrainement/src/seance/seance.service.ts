import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { CrudService } from '@app/common';
import { Seance } from './seance.entity';

/** findAll, findOne, create, update, remove viennent de CrudService ; ajoute tes méthodes ici. */
@Injectable()
export class SeanceService extends CrudService<Seance> {
  constructor(@InjectRepository(Seance) repo: Repository<Seance>) {
    super(repo, 'Séance');
  }
}
