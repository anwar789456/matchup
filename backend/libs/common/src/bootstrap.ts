import { ClassSerializerInterceptor, Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory, Reflector } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

import { DbErrorsFilter } from './db-errors.filter';
import { MODULES, ModuleName } from './modules';

/**
 * Starts one module: routes under /api/<module>, Swagger at /api/<module>/docs, DTO validation,
 * CORS open to everyone (Flutter web, Postman, laptops).
 */
export async function bootstrapModule(module: ModuleName, appModule: unknown): Promise<void> {
  const app = await NestFactory.create(appModule as never);
  const { port: defaultPort, title } = MODULES[module];
  const port = Number(process.env.PORT ?? defaultPort);
  const prefix = `api/${module}`;

  app.setGlobalPrefix(prefix);
  app.enableCors();
  app.useGlobalPipes(
    new ValidationPipe({ whitelist: true, transform: true, forbidNonWhitelisted: false }),
  );
  // Hides @Exclude() fields (passwords) from every answer.
  app.useGlobalInterceptors(new ClassSerializerInterceptor(app.get(Reflector)));
  app.useGlobalFilters(new DbErrorsFilter());

  const config = new DocumentBuilder()
    .setTitle(`MatchUp · ${title}`)
    .setDescription(`API du module ${title}. Toutes les routes sont sous /${prefix}.`)
    .setVersion('1.0')
    .build();
  SwaggerModule.setup(`${prefix}/docs`, app, () => SwaggerModule.createDocument(app, config));

  await app.listen(port, '0.0.0.0');
  new Logger(title).log(`http://localhost:${port}/${prefix}  ·  docs: /${prefix}/docs`);
}
