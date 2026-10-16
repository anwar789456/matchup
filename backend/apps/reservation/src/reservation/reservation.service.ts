import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { CrudService } from '@app/common';
import { Reservation } from './reservation.entity';

/** findAll, findOne, create, update, remove viennent de CrudService ; ajoute tes méthodes ici. */
@Injectable()
export class ReservationService extends CrudService<Reservation> {
  constructor(@InjectRepository(Reservation) repo: Repository<Reservation>) {
    super(repo, 'Réservation');
  }
}
