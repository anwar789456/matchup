import { DynamicModule, Logger, Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataSource, DataSourceOptions, EntitySchema } from 'typeorm';

import { ModuleName } from './modules';

// eslint-disable-next-line @typescript-eslint/no-unsafe-function-type
type EntityClass = Function | EntitySchema;

/**
 * Connects a module to the shared PostgreSQL database (settings from backend/.env).
 *
 * Every module keeps its tables in its own schema (`reservation.terrain`, `forum.sujet`…), so
 * modules never step on each other's tables. Link to another module's rows by id
 * (`utilisateurId`), not with a foreign key.
 *
 * Tables are created/updated from the entities when DB_SYNC names this module (or `all`).
 * Keep DB_SYNC on YOUR module only on your laptop: running an old copy of someone else's
 * module with sync on would rewrite their tables.
 */
@Module({})
export class DatabaseModule {
  static forModule(module: ModuleName, entities: EntityClass[]): DynamicModule {
    return {
      module: DatabaseModule,
      imports: [
        ConfigModule.forRoot({ isGlobal: true, envFilePath: ['.env'] }),
        TypeOrmModule.forRootAsync({
          inject: [ConfigService],
          useFactory: (config: ConfigService) => ({
            type: 'postgres' as const,
            host: config.get<string>('DB_HOST', 'localhost'),
            port: Number(config.get('DB_PORT', 5432)),
            username: config.get<string>('DB_USER', 'matchup'),
            password: config.get<string>('DB_PASSWORD', ''),
            database: config.get<string>('DB_NAME', 'matchup'),
            schema: module,
            entities,
            synchronize: false,
            logging: config.get('DB_LOGGING') === 'true',
            extra: { max: 5 },
            // Settings read back by the factory below.
            syncSchema: shouldSync(config.get<string>('DB_SYNC', 'none'), module),
          }),
          dataSourceFactory: async (options) => {
            const { syncSchema, ...rest } = options as DataSourceOptions & { syncSchema: boolean };
            const dataSource = await new DataSource(rest as DataSourceOptions).initialize();
            await dataSource.query(`CREATE SCHEMA IF NOT EXISTS "${module}"`);
            if (syncSchema) {
              await dataSource.synchronize();
              new Logger('Database').log(`Tables of "${module}" synchronised with the entities`);
            }
            return dataSource;
          },
        }),
        TypeOrmModule.forFeature(entities),
      ],
      exports: [TypeOrmModule],
    };
  }
}

/** `all`, `none`, or a comma-separated list of modules (`reservation,paiement`). */
export function shouldSync(setting: string, module: ModuleName): boolean {
  const value = setting.trim().toLowerCase();
  if (value === 'all') return true;
  return value
    .split(',')
    .map((m) => m.trim())
    .includes(module);
}
