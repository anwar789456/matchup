import { Module } from '@nestjs/common';

import { DatabaseModule } from '@app/common';
import { SujetController } from './sujet/sujet.controller';
import { Sujet } from './sujet/sujet.entity';
import { SujetService } from './sujet/sujet.service';
import { MessageController } from './message/message.controller';
import { Message } from './message/message.entity';
import { MessageService } from './message/message.service';

/**
 * Module forum: tables in the `forum` schema of the shared database.
 * Add an entity here (and in its folder) to get its table.
 */
@Module({
  imports: [DatabaseModule.forModule('forum', [Sujet, Message])],
  controllers: [SujetController, MessageController],
  providers: [SujetService, MessageService],
})
export class ForumModule {}
