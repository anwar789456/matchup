import { DynamicModule, Logger, Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataSource, DataSourceOptions, EntitySchema } from 'typeorm';
import { PostgresConnectionOptions } from 'typeorm/driver/postgres/PostgresConnectionOptions';

import { ModuleName } from './modules';

// eslint-disable-next-line @typescript-eslint/no-unsafe-function-type
type EntityClass = Function | EntitySchema;

/**
 * Connects a module to the local PostgreSQL database (settings from backend/.env). The database
 * itself (DB_NAME, default `matchup`) is created on the first start if it does not exist yet.
 *
 * Every module keeps its tables in its own schema (`reservation.terrain`, `forum.sujet`…), so
 * modules never step on each other's tables. Link to another module's rows by id
 * (`utilisateurId`), not with a foreign key.
 *
 * Tables are created/updated from the entities when DB_SYNC names this module (or `all`).
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
            username: config.get<string>('DB_USER', 'postgres'),
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
            const dataSource = await initializeCreatingDatabase(rest as PostgresConnectionOptions);
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

/** PostgreSQL's "database does not exist" error. */
const INVALID_CATALOG_NAME = '3D000';
/**
 * PostgreSQL's "database already exists" errors: 42P04 when it existed before, 23505 (unique
 * pg_database_datname_index) when another module created it at the same moment.
 */
const DATABASE_EXISTS = ['42P04', '23505'];

/**
 * Opens the connection; if the database does not exist yet, creates it through the built-in
 * `postgres` database (same user) and connects again. Two modules starting at the same time may
 * both try to create it: the loser's "already exists" is ignored.
 */
async function initializeCreatingDatabase(options: PostgresConnectionOptions): Promise<DataSource> {
  try {
    return await new DataSource(options).initialize();
  } catch (error) {
    if ((error as { code?: string }).code !== INVALID_CATALOG_NAME) throw error;
  }
  const name = String(options.database);
  const admin = await new DataSource({
    ...options,
    database: 'postgres',
    schema: undefined,
    entities: [],
  }).initialize();
  try {
    await admin.query(`CREATE DATABASE "${name.replace(/"/g, '""')}"`);
    new Logger('Database').log(`Database "${name}" created`);
  } catch (error) {
    if (!DATABASE_EXISTS.includes((error as { code?: string }).code ?? '')) throw error;
  } finally {
    await admin.destroy();
  }
  return new DataSource(options).initialize();
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
