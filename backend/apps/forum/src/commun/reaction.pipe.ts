import { BadRequestException, Injectable, PipeTransform } from '@nestjs/common';

import { REACTIONS } from '../forum.constants';
import type { TypeReaction } from '../forum.constants';

/** Checks the `:type` of …/reactions/:type (« utile » or « merci »). */
@Injectable()
export class ReactionPipe implements PipeTransform<string, TypeReaction> {
  transform(value: string): TypeReaction {
    if (!(REACTIONS as readonly string[]).includes(value)) {
      throw new BadRequestException(`Réaction inconnue « ${value} » : ${REACTIONS.join(' ou ')}.`);
    }
    return value as TypeReaction;
  }
}
