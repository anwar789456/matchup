import { Body, Controller, Get, Header, HttpCode, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import { CodeDto, EmailDto, ReinitialisationDto } from './compte.dto';
import { CompteService } from './compte.service';
import { confirmationPage } from './emails';

/** /api/utilisateur/compte — the emails of AUTH-04 and AUTH-06 to 08. */
@ApiTags('compte')
@Controller('compte')
export class CompteController {
  constructor(private readonly service: CompteService) {}

  @Post('verification/envoyer')
  @HttpCode(202)
  @ApiOperation({ summary: 'Envoie (à nouveau) le lien de confirmation de l’email' })
  async sendVerification(@Body() body: EmailDto) {
    await this.service.sendVerification(body.email);
    return { envoye: true };
  }

  @Get('verification/confirmer')
  @Header('Content-Type', 'text/html; charset=utf-8')
  @ApiOperation({ summary: 'Page ouverte depuis le lien de l’email' })
  async confirm(@Query('token') token: string) {
    return confirmationPage(await this.service.confirm(token));
  }

  @Post('mot-de-passe/oublie')
  @HttpCode(202)
  @ApiOperation({ summary: 'AUTH-06 : envoie un code à 6 chiffres par email' })
  async forgot(@Body() body: EmailDto) {
    await this.service.sendResetCode(body.email);
    return { envoye: true };
  }

  @Post('mot-de-passe/verifier')
  @HttpCode(200)
  @ApiOperation({ summary: 'AUTH-07 : vérifie le code (400 + essaisRestants, 429 + reessayerA)' })
  async check(@Body() body: CodeDto) {
    await this.service.checkResetCode(body.email, body.code);
    return { valide: true };
  }

  @Post('mot-de-passe/reinitialiser')
  @HttpCode(200)
  @ApiOperation({ summary: 'AUTH-08 : nouveau mot de passe (409 s’il est identique à l’ancien)' })
  async reset(@Body() body: ReinitialisationDto) {
    await this.service.resetPassword(body.email, body.code, body.motDePasse);
    return { modifie: true };
  }
}
