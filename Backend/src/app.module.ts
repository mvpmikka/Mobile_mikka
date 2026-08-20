import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { validateEnv } from './config/env.validation';
import { PrismaModule } from './prisma/prisma.module';
import { MailModule } from './mail/mail.module';
import { UserModule } from './user/user.module';
import { AuthModule } from './auth/auth.module';
import { PlaceModule } from './place/place.module';
import { SearchModule } from './search/search.module';
import { ReviewModule } from './review/review.module';
import { UploadModule } from './upload/upload.module';
import { CheckInModule } from './check-in/check-in.module';
import { FriendshipModule } from './friendship/friendship.module';
import { PrivacyModule } from './privacy/privacy.module';
import { SavedPlaceModule } from './saved-place/saved-place.module';
import { AdminModule } from './admin/admin.module';
import { StoryModule } from './story/story.module';
import { ChatModule } from './chat/chat.module';
import { NotificationModule } from './notification/notification.module';
import { CallModule } from './call/call.module';
import { BadgeModule } from './badge/badge.module';
import { FollowModule } from './follow/follow.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validate: validateEnv,
    }),
    ThrottlerModule.forRoot([{ name: 'default', ttl: 60_000, limit: 20 }]),
    // Global so any module can inject EventEmitter2 to emit, or use
    // @OnEvent(...) to listen, without importing this module directly —
    // see FriendshipModule/ChatModule/StoryModule's emitters and
    // NotificationModule's listeners.
    EventEmitterModule.forRoot(),
    PrismaModule,
    MailModule,
    UserModule,
    AuthModule,
    PlaceModule,
    SearchModule,
    ReviewModule,
    UploadModule,
    CheckInModule,
    FriendshipModule,
    PrivacyModule,
    SavedPlaceModule,
    AdminModule,
    StoryModule,
    ChatModule,
    NotificationModule,
    CallModule,
    BadgeModule,
    FollowModule,
  ],
  controllers: [AppController],
  providers: [AppService, { provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
