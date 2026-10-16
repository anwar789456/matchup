import { ValueTransformer } from 'typeorm';

/** Postgres returns `numeric` columns as strings; this hands them back as numbers. */
export const decimal: ValueTransformer = {
  to: (value?: number | null) => value,
  from: (value?: string | null) => (value == null ? value : Number(value)),
};
