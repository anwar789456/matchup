import { Module } from '@nestjs/common';

import { DatabaseModule } from '@app/common';
import { ContenusService } from './commun/contenus.service';
import { DemoController } from './demo/demo.controller';
import { DemoService } from './demo/demo.service';
import { IaController } from './ia/ia.controller';
import { ImageController } from './image/image.controller';
import { InteractionController } from './interaction/interaction.controller';
import { Blocage, Favori, Reaction, Suivi, Visite, Vote } from './interaction/interaction.entities';
import { InteractionService } from './interaction/interaction.service';
import { MessageController } from './message/message.controller';
import { Message } from './message/message.entity';
import { MessageService } from './message/message.service';
import { ModerationController } from './moderation/moderation.controller';
import { Sanction, Signalement } from './moderation/moderation.entities';
import { ModerationService } from './moderation/moderation.service';
import { SujetController } from './sujet/sujet.controller';
import { Sujet } from './sujet/sujet.entity';
import { SujetService } from './sujet/sujet.service';

/**
 * Module forum (brief, Module 6): tables in the `forum` schema of the shared database.
 * See apps/forum/README.md for the routes and the rules.
 */
@Module({
  imports: [
    DatabaseModule.forModule('forum', [Sujet, Message, Vote, Reaction, Favori, Suivi, Blocage, Visite, Signalement, Sanction]),
  ],
  controllers: [
    SujetController,
    MessageController,
    InteractionController,
    ModerationController,
    IaController,
    ImageController,
    DemoController,
  ],
  providers: [ContenusService, SujetService, MessageService, InteractionService, ModerationService, DemoService],
})
export class ForumModule {}
