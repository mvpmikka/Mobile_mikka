import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { AdminStats } from '../types/admin-stats.type';

@Injectable()
export class AdminRepository {
  constructor(private readonly prisma: PrismaService) {}

  async getStats(): Promise<AdminStats> {
    const [totalUsers, totalPlaces, totalReviews, totalCheckIns] =
      await Promise.all([
        this.prisma.user.count({ where: { deletedAt: null } }),
        this.prisma.place.count({ where: { deletedAt: null } }),
        this.prisma.review.count({ where: { deletedAt: null } }),
        this.prisma.checkIn.count({ where: { deletedAt: null } }),
      ]);
    return { totalUsers, totalPlaces, totalReviews, totalCheckIns };
  }
}