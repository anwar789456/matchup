import { Body, Controller, Delete, Get, Param, ParseIntPipe, Patch, Post } from '@nestjs/common';
import { ApiOperation, ApiProperty, ApiPropertyOptional, ApiTags, PartialType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsBoolean, IsDate, IsInt, IsNotEmpty, IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

import { CodePromoService } from './code-promo.service';

export class CreateCodePromoDto {
  @ApiProperty({ example: 'PADEL20' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  code: string;

  @ApiPropertyOptional({ example: 20, description: 'Pourcentage, ou bien montantFixe' })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  pourcentage?: number;

  @ApiPropertyOptional({ example: 5 })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 3 })
  @Min(0.001)
  montantFixe?: number;

  @ApiPropertyOptional({ example: 20, description: 'Montant minimum du panier' })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 3 })
  @Min(0)
  montantMin?: number;

  @ApiPropertyOptional({ example: '2026-10-01' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  debut?: Date;

  @ApiPropertyOptional({ example: '2026-12-31T23:59:59' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  fin?: Date;

  @ApiPropertyOptional({ example: 100 })
  @IsOptional()
  @IsInt()
  @Min(1)
  utilisationsMax?: number;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  actif?: boolean;
}

export class UpdateCodePromoDto extends PartialType(CreateCodePromoDto) {}

export class VerifierCodeDto {
  @ApiProperty({ example: 'bienvenue10' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  code: string;

  @ApiProperty({ example: 15 })
  @IsNumber({ maxDecimalPlaces: 3 })
  @Min(0.001)
  montant: number;
}

/** /api/paiement/codes-promo */
@ApiTags('codes-promo')
@Controller('codes-promo')
export class CodePromoController {
  constructor(private readonly service: CodePromoService) {}

  @Post('verifier')
  @ApiOperation({ summary: 'Le champ « Code promo » du checkout : remise et total, ou la raison du refus' })
  verifier(@Body() body: VerifierCodeDto) {
    return this.service.verifier(body.code, body.montant);
  }

  @Get()
  @ApiOperation({ summary: 'Liste (admin)' })
  findAll() {
    return this.service.findAll();
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.service.findOne(id);
  }

  @Post()
  @ApiOperation({ summary: 'Créer (admin) ; le code est mis en majuscules' })
  create(@Body() body: CreateCodePromoDto) {
    return this.service.create(body);
  }

  @Patch(':id')
  update(@Param('id', ParseIntPipe) id: number, @Body() body: UpdateCodePromoDto) {
    return this.service.update(id, body);
  }

  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.service.remove(id);
  }
}
