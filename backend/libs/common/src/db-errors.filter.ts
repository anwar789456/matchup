import { ArgumentsHost, Catch, ExceptionFilter, HttpStatus } from '@nestjs/common';
import { Response } from 'express';
import { QueryFailedError } from 'typeorm';

/** Turns Postgres errors into readable 400/409 answers instead of a bare 500. */
@Catch(QueryFailedError)
export class DbErrorsFilter implements ExceptionFilter {
  catch(error: QueryFailedError & { code?: string; detail?: string }, host: ArgumentsHost) {
    const res = host.switchToHttp().getResponse<Response>();
    const [status, message] = (() => {
      switch (error.code) {
        case '23503':
          return [HttpStatus.BAD_REQUEST, 'Référence introuvable (vérifie l’id lié).'];
        case '23505':
          return [HttpStatus.CONFLICT, 'Cette valeur existe déjà.'];
        case '22P02':
        case '22007':
        case '22008':
          return [HttpStatus.BAD_REQUEST, 'Valeur invalide.'];
        default:
          return [HttpStatus.INTERNAL_SERVER_ERROR, 'Erreur de base de données.'];
      }
    })();
    res.status(status).json({ statusCode: status, message, detail: error.detail ?? error.message });
  }
}
