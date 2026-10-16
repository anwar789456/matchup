import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { CrudService } from '@app/common';
import { Programme } from './programme.entity';

/** findAll, findOne, create, update, remove viennent de CrudService ; ajoute tes méthodes ici. */
@Injectable()
export class ProgrammeService extends CrudService<Programme> {
  constructor(@InjectRepository(Programme) repo: Repository<Programme>) {
    super(repo, 'Programme');
  }
}
