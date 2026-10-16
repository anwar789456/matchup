import { Body, Controller, Delete, Get, HttpCode, Param, ParseIntPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import { CreateUtilisateurDto, UpdateUtilisateurDto, QueryUtilisateurDto } from './utilisateur.dto';
import { UtilisateurService } from './utilisateur.service';
import { LoginUtilisateurDto } from './login.dto';

/** /api/utilisateur/utilisateurs */
@ApiTags('utilisateurs')
@Controller('utilisateurs')
export class UtilisateurController {
  constructor(private readonly service: UtilisateurService) {}

  @Post('login')
  @HttpCode(200)
  @ApiOperation({ summary: 'Connexion : email + mot de passe → l’utilisateur' })
  login(@Body() body: LoginUtilisateurDto) {
    return this.service.login(body.email, body.motDePasse);
  }

  @Get()
  @ApiOperation({ summary: 'Liste (filtres facultatifs en query)' })
  findAll(@Query() query: QueryUtilisateurDto) {
    return this.service.findAll(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Détail' })
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.service.findOne(id);
  }

  @Post()
  @ApiOperation({ summary: 'Créer' })
  create(@Body() body: CreateUtilisateurDto) {
    return this.service.create(body);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Modifier (champs envoyés seulement)' })
  update(@Param('id', ParseIntPipe) id: number, @Body() body: UpdateUtilisateurDto) {
    return this.service.update(id, body);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Supprimer' })
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.service.remove(id);
  }
}
