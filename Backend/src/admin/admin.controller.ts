import {
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../auth/strategies/jwt.strategy';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { Role } from '../../generated/prisma/client';
import { AdminService } from './services/admin.service';
import { listAdminUsersSchema } from './dto/list-admin-users.dto';
import type { ListAdminUsersDto } from './dto/list-admin-users.dto';

// Every route here is ADMIN-only — gated at the class level rather than
// per-method, since there's no public/self-service route in this
// controller to carve out (contrast Place/Review, where only the
// write routes need @Roles).
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('stats')
  getStats() {
    return this.adminService.getStats();
  }

  // Operational dashboard — SUPER_ADMIN can see it too since that role is
  // a superset of ADMIN, not a separate silo.
  @Get('dashboard')
  @Roles(Role.ADMIN, Role.SUPER_ADMIN)
  getDashboard() {
    return this.adminService.getDashboard();
  }

  // Platform-oversight dashboard (role/moderation counts, growth, regional
  // spread) — SUPER_ADMIN only, unlike the route above.
  @Get('super-dashboard')
  @Roles(Role.SUPER_ADMIN)
  getSuperDashboard() {
    return this.adminService.getSuperDashboard();
  }

  // Static route before the dynamic :id routes below — same ordering
  // reason as UserController.
  @Get('users')
  listUsers(
    @Query(new ZodValidationPipe(listAdminUsersSchema))
    query: ListAdminUsersDto,
  ) {
    return this.adminService.listUsers(query.page, query.limit, query.search);
  }

  @Get('users/:id')
  getUser(@Param('id') id: string) {
    return this.adminService.getUser(id);
  }

  @Post('users/:id/ban')
  banUser(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.adminService.banUser(id, currentUser.id);
  }

  @Delete('users/:id/ban')
  @HttpCode(HttpStatus.NO_CONTENT)
  async unbanUser(@Param('id') id: string): Promise<void> {
    await this.adminService.unbanUser(id);
  }
}
