import { Injectable } from '@nestjs/common';
import { AdminRepository } from '../repositories/admin.repository';
import { UserService } from '../../user/user.service';
import type { PaginatedResult } from '../../user/user.service';
import { TokenService } from '../../auth/services/token.service';
import type { AdminStats } from '../types/admin-stats.type';
import type { AdminUserView } from '../../user/types/admin-user.type';

@Injectable()
export class AdminService {
  constructor(
    private readonly adminRepository: AdminRepository,
    private readonly userService: UserService,
    private readonly tokenService: TokenService,
  ) {}

  getStats(): Promise<AdminStats> {
    return this.adminRepository.getStats();
  }

  listUsers(
    page: number,
    limit: number,
    search?: string,
  ): Promise<PaginatedResult<AdminUserView>> {
    return this.userService.listForAdmin(page, limit, search);
  }

  getUser(id: string): Promise<AdminUserView> {
    return this.userService.getForAdmin(id);
  }

  // Ban is a User-domain state change (UserService.ban, including the
  // "can't ban yourself" rule) plus an immediate session kill — revoking
  // every refresh token so the ban takes effect now, not whenever the
  // user's existing session would have naturally expired. The reach into
  // Auth's TokenService belongs here, not in UserService, since User has
  // no business knowing about refresh tokens — see docs/foundation.md.
  async banUser(
    id: string,
    requestedByUserId: string,
  ): Promise<AdminUserView> {
    const user = await this.userService.ban(id, requestedByUserId);
    await this.tokenService.revokeAllForUser(id);
    return user;
  }

  unbanUser(id: string): Promise<void> {
    return this.userService.unban(id);
  }
}