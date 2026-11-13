import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { FindOptionsWhere, Repository } from 'typeorm';

import { CrudService } from '@app/common';
import { Seance } from './seance.entity';

/** findAll, findOne, create, update, remove viennent de CrudService ; ajoute tes méthodes ici. */
@Injectable()
export class SeanceService extends CrudService<Seance> {
  constructor(@InjectRepository(Seance) repo: Repository<Seance>) {
    super(repo, 'Séance');
  }

  /** Les séances d’un programme dans leur ordre (ENT-03 « semaine par semaine »), pas par id. */
  override findAll(where?: FindOptionsWhere<Seance>): Promise<Seance[]> {
    return this.repo.find({ where, order: { programmeId: 'ASC', ordre: 'ASC', id: 'ASC' } });
  }
}
