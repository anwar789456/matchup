import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { CrudService } from '@app/common';
import { Message } from './message.entity';

/** findAll, findOne, create, update, remove viennent de CrudService ; ajoute tes méthodes ici. */
@Injectable()
export class MessageService extends CrudService<Message> {
  constructor(@InjectRepository(Message) repo: Repository<Message>) {
    super(repo, 'Message');
  }
}
