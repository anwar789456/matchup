import {
  BadRequestException,
  Controller,
  Get,
  NotFoundException,
  Param,
  Post,
  Req,
  Res,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBody, ApiConsumes, ApiOperation, ApiTags } from '@nestjs/swagger';
import { randomUUID } from 'crypto';
import type { Request, Response } from 'express';
import { existsSync, mkdirSync, writeFileSync } from 'fs';
import { join } from 'path';

/** Where images are kept on this PC (ignored by git): backend/apps/forum/uploads. */
export const DOSSIER_IMAGES = join(process.cwd(), 'apps', 'forum', 'uploads');

const TYPES: Record<string, string> = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };
const TAILLE_MAX = 5 * 1024 * 1024;

/** The part of multer's file we use (its types are not installed). */
interface Fichier {
  mimetype: string;
  size: number;
  buffer: Buffer;
}

/** /api/forum/images — FRM-02 « Images (facultatif) ». */
@ApiTags('images')
@Controller('images')
export class ImageController {
  @Post()
  @ApiOperation({ summary: 'Envoyer une image (JPEG, PNG ou WebP, 5 Mo max) → { url } à mettre dans `images` du post' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: { type: 'object', properties: { image: { type: 'string', format: 'binary' } }, required: ['image'] } })
  @UseInterceptors(FileInterceptor('image', { limits: { fileSize: TAILLE_MAX } }))
  envoyer(@UploadedFile() fichier: Fichier | undefined, @Req() req: Request) {
    if (!fichier) throw new BadRequestException('Ajoute une image (champ « image »).');
    const extension = TYPES[fichier.mimetype];
    if (!extension) throw new BadRequestException('Format accepté : JPEG, PNG ou WebP.');
    mkdirSync(DOSSIER_IMAGES, { recursive: true });
    const nom = `${randomUUID()}.${extension}`;
    writeFileSync(join(DOSSIER_IMAGES, nom), fichier.buffer);
    return { url: `${req.protocol}://${req.get('host')}/api/forum/images/${nom}`, taille: fichier.size };
  }

  @Get(':nom')
  @ApiOperation({ summary: 'Lire une image envoyée' })
  lire(@Param('nom') nom: string, @Res() res: Response) {
    // Only names we created: uuid + known extension (no « ../ »).
    if (!/^[0-9a-f-]{36}\.(jpg|png|webp)$/.test(nom)) throw new NotFoundException('Image introuvable');
    const chemin = join(DOSSIER_IMAGES, nom);
    if (!existsSync(chemin)) throw new NotFoundException('Image introuvable');
    res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    res.sendFile(chemin);
  }
}
