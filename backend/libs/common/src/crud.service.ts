import { NotFoundException } from '@nestjs/common';
import { DeepPartial, FindOptionsWhere, ObjectLiteral, Repository } from 'typeorm';

/**
 * The 5 CRUD operations every resource starts with. Extend it in your module's service and add
 * your own methods next to them.
 */
export class CrudService<T extends ObjectLiteral & { id: number }> {
  constructor(
    protected readonly repo: Repository<T>,
    private readonly label: string,
  ) {}

  findAll(where?: FindOptionsWhere<T>): Promise<T[]> {
    return this.repo.find({ where, order: { id: 'DESC' } as never });
  }

  async findOne(id: number): Promise<T> {
    const row = await this.repo.findOne({ where: { id } as FindOptionsWhere<T> });
    if (!row) throw new NotFoundException(`${this.label} ${id} introuvable`);
    return row;
  }

  create(data: DeepPartial<T>): Promise<T> {
    return this.repo.save(this.repo.create(data));
  }

  async update(id: number, data: DeepPartial<T>): Promise<T> {
    const row = await this.findOne(id);
    return this.repo.save(this.repo.merge(row, data));
  }

  async remove(id: number): Promise<{ deleted: true; id: number }> {
    const row = await this.findOne(id);
    await this.repo.remove(row);
    return { deleted: true, id };
  }
}
