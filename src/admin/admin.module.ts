import { Module } from '@nestjs/common';
import { UserModule } from '../user/user.module';
import { AuthModule } from '../auth/auth.module';
import { AdminController } from './admin.controller';
import { AdminService } from './services/admin.service';
import { AdminRepository } from './repositories/admin.repository';

@Module({
  imports: [UserModule, AuthModule],
  controllers: [AdminController],
  providers: [AdminService, AdminRepository],
})
export class AdminModule {}