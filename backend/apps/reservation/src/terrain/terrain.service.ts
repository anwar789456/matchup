import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { CrudService } from '@app/common';
import { Terrain } from './terrain.entity';

/** findAll, findOne, create, update, remove viennent de CrudService ; ajoute tes méthodes ici. */
@Injectable()
export class TerrainService extends CrudService<Terrain> {
  constructor(@InjectRepository(Terrain) repo: Repository<Terrain>) {
    super(repo, 'Terrain');
  }
}
