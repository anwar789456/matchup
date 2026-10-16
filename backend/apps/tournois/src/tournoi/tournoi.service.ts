import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { CrudService } from '@app/common';
import { Tournoi } from './tournoi.entity';

/** findAll, findOne, create, update, remove viennent de CrudService ; ajoute tes méthodes ici. */
@Injectable()
export class TournoiService extends CrudService<Tournoi> {
  constructor(@InjectRepository(Tournoi) repo: Repository<Tournoi>) {
    super(repo, 'Tournoi');
  }
}
