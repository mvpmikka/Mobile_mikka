import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

// Global: every domain module's repository layer depends on PrismaService,
// unlike feature modules (e.g. Mail) which only specific consumers need.
@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
