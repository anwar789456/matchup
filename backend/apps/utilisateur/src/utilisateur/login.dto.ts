import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString } from 'class-validator';

export class LoginUtilisateurDto {
  @ApiProperty({ example: 'skander.t@email.tn' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'motdepasse123' })
  @IsString()
  motDePasse: string;
}
