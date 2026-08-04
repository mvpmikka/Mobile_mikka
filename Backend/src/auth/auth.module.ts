import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import type { JwtSignOptions } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { UserModule } from '../user/user.module';
import { MailModule } from '../mail/mail.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { AuthIdentityRepository } from './repositories/auth-identity.repository';
import { RefreshTokenRepository } from './repositories/refresh-token.repository';
import { VerificationTokenRepository } from './repositories/verification-token.repository';
import { PasswordService } from './services/password.service';
import { TokenService } from './services/token.service';
import { GoogleAuthService } from './services/google-auth.service';
import { JwtStrategy } from './strategies/jwt.strategy';

// Factored out so it can appear in both `imports` and `exports` below —
// ChatModule's WebSocket gateway needs JwtService directly (to verify a
// token from a socket handshake, outside the normal HTTP Passport guard
// pipeline) rather than going through JwtAuthGuard.
const jwtModule = JwtModule.registerAsync({
  imports: [ConfigModule],
  inject: [ConfigService],
  useFactory: (configService: ConfigService) => ({
    secret: configService.getOrThrow<string>('JWT_ACCESS_SECRET'),
    signOptions: {
      // Validated as a plain string by Zod; cast to the library's
      // narrower literal type, which a runtime value like "15m" satisfies.
      expiresIn: configService.get<string>(
        'JWT_ACCESS_EXPIRES_IN',
        '15m',
      ) as JwtSignOptions['expiresIn'],
    },
  }),
});

@Module({
  imports: [UserModule, MailModule, PassportModule, jwtModule],
  controllers: [AuthController],
  providers: [
    AuthService,
    AuthIdentityRepository,
    RefreshTokenRepository,
    VerificationTokenRepository,
    PasswordService,
    TokenService,
    GoogleAuthService,
    JwtStrategy,
  ],
  // TokenService: AdminModule revokes a banned user's refresh tokens
  // immediately at ban time — see AdminService.banUser. JwtModule: so
  // ChatModule's gateway can inject JwtService — see docs/foundation.md.
  exports: [TokenService, jwtModule],
})
export class AuthModule {}
