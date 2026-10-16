import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { CrudService } from '@app/common';
import { Paiement } from './paiement.entity';

/** findAll, findOne, create, update, remove viennent de CrudService ; ajoute tes méthodes ici. */
@Injectable()
export class PaiementService extends CrudService<Paiement> {
  constructor(@InjectRepository(Paiement) repo: Repository<Paiement>) {
    super(repo, 'Paiement');
  }
}
