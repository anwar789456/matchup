import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, Length, MinLength } from 'class-validator';

export class EmailDto {
  @ApiProperty({ example: 'skander.t@email.tn' })
  @IsEmail()
  email: string;
}

export class CodeDto extends EmailDto {
  @ApiProperty({ example: '482913', description: 'Le code à 6 chiffres reçu par email' })
  @IsString()
  @Length(6, 6)
  code: string;
}

export class ReinitialisationDto extends CodeDto {
  @ApiProperty({ example: 'NouveauMotDePasse1' })
  @IsString()
  @MinLength(8)
  motDePasse: string;
}
