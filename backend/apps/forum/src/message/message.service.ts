import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { FindOptionsWhere, Repository } from 'typeorm';

import { CrudService } from '@app/common';
import { Message } from './message.entity';

/** findAll, findOne, create, update, remove viennent de CrudService ; ajoute tes méthodes ici. */
@Injectable()
export class MessageService extends CrudService<Message> {
  constructor(@InjectRepository(Message) repo: Repository<Message>) {
    super(repo, 'Message');
  }

  /** Oldest first, like a chat thread. */
  override findAll(where?: FindOptionsWhere<Message>): Promise<Message[]> {
    return this.repo.find({ where, order: { id: 'ASC' } });
  }
}
