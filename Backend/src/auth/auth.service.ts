import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomBytes } from 'node:crypto';
import {
  AuthProvider,
  VerificationTokenPurpose,
} from '../../generated/prisma/client';
import type { User, VerificationToken } from '../../generated/prisma/client';
import { hashToken } from '../common/crypto/hash-token';
import { UserService } from '../user/user.service';
import { MailService } from '../mail/mail.service';
import { AuthIdentityRepository } from './repositories/auth-identity.repository';
import { VerificationTokenRepository } from './repositories/verification-token.repository';
import { PasswordService } from './services/password.service';
import { TokenService } from './services/token.service';
import { GoogleAuthService } from './services/google-auth.service';
import { IssuedTokens } from './types/auth-tokens.type';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { outranks, resolveEnvRole } from './utils/env-role.util';

@Injectable()
export class AuthService {
  constructor(
    private readonly userService: UserService,
    private readonly authIdentityRepository: AuthIdentityRepository,
    private readonly verificationTokenRepository: VerificationTokenRepository,
    private readonly passwordService: PasswordService,
    private readonly tokenService: TokenService,
    private readonly googleAuthService: GoogleAuthService,
    private readonly mailService: MailService,
    private readonly configService: ConfigService,
  ) {}

  async register(dto: RegisterDto): Promise<IssuedTokens> {
    const [existingEmail, existingUsername] = await Promise.all([
      this.userService.findByEmail(dto.email),
      this.userService.findByUsername(dto.username),
    ]);

    if (existingEmail) {
      throw new ConflictException('An account with this email already exists');
    }
    if (existingUsername) {
      throw new ConflictException('This username is already taken');
    }

    const passwordHash = await this.passwordService.hash(dto.password);

    const user = await this.userService.create({
      email: dto.email,
      username: dto.username,
      usernameUpdatedAt: new Date(),
    });

    await this.authIdentityRepository.create({
      user: { connect: { id: user.id } },
      provider: AuthProvider.LOCAL,
      passwordHash,
    });

    await this.sendVerificationEmail(user.id, user.email);
    await this.syncRoleFromEnv(user);

    return this.tokenService.issueTokenPair(user.id);
  }

  async login(dto: LoginDto): Promise<IssuedTokens> {
    const user = await this.userService.findByEmail(dto.email);
    const identity = user
      ? await this.authIdentityRepository.findByUserAndProvider(
          user.id,
          AuthProvider.LOCAL,
        )
      : null;

    if (!user || !identity?.passwordHash) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const passwordMatches = await this.passwordService.verify(
      identity.passwordHash,
      dto.password,
    );
    if (!passwordMatches) {
      throw new UnauthorizedException('Invalid email or password');
    }

    if (user.isBanned) {
      throw new ForbiddenException('Your account has been banned');
    }

    await this.syncRoleFromEnv(user);

    return this.tokenService.issueTokenPair(user.id);
  }

  // ADMIN_EMAILS / SUPER_ADMIN_EMAILS bootstrap: promotes on every
  // successful register/login rather than only once at creation, so
  // adding an email to env config later still takes effect on that
  // person's next login — no manual DB write required. Never demotes.
  private async syncRoleFromEnv(user: User): Promise<void> {
    const envRole = resolveEnvRole(
      user.email,
      this.configService.get<string>('ADMIN_EMAILS', ''),
      this.configService.get<string>('SUPER_ADMIN_EMAILS', ''),
    );
    if (outranks(envRole, user.role)) {
      await this.userService.update(user.id, { role: envRole });
    }
  }

  async loginWithGoogle(idToken: string): Promise<IssuedTokens> {
    const profile = await this.googleAuthService.verifyIdToken(idToken);

    const existingIdentity = await this.authIdentityRepository.findByProvider(
      AuthProvider.GOOGLE,
      profile.providerUserId,
    );
    if (existingIdentity) {
      const existingUser = await this.userService.findById(
        existingIdentity.userId,
      );
      if (existingUser?.isBanned) {
        throw new ForbiddenException('Your account has been banned');
      }
      if (existingUser) {
        await this.syncRoleFromEnv(existingUser);
      }
      return this.tokenService.issueTokenPair(existingIdentity.userId);
    }

    let user = await this.userService.findByEmail(profile.email);

    // A verified account with this email already exists, but this provider
    // can't vouch for the email — never auto-link (see docs/foundation.md).
    if (user && !profile.emailVerified) {
      throw new ConflictException('An account with this email already exists');
    }

    if (!user) {
      user = await this.userService.create({
        email: profile.email,
        fullName: profile.fullName,
        avatarUrl: profile.avatarUrl,
        isEmailVerified: profile.emailVerified,
      });
    }

    await this.authIdentityRepository.create({
      user: { connect: { id: user.id } },
      provider: AuthProvider.GOOGLE,
      providerUserId: profile.providerUserId,
    });

    const profileCompleted = this.userService.computeProfileCompleted(user);
    if (profileCompleted !== user.profileCompleted) {
      await this.userService.update(user.id, { profileCompleted });
    }

    if (user.isBanned) {
      throw new ForbiddenException('Your account has been banned');
    }

    await this.syncRoleFromEnv(user);

    return this.tokenService.issueTokenPair(user.id);
  }

  refresh(rawRefreshToken: string): Promise<IssuedTokens> {
    return this.tokenService.rotateRefreshToken(rawRefreshToken);
  }

  logout(rawRefreshToken: string): Promise<void> {
    return this.tokenService.revokeRefreshToken(rawRefreshToken);
  }

  async verifyEmail(rawToken: string): Promise<void> {
    const record = await this.consumeVerificationToken(
      rawToken,
      VerificationTokenPurpose.EMAIL_VERIFICATION,
    );
    await this.userService.update(record.userId, { isEmailVerified: true });
  }

  async resendVerification(email: string): Promise<void> {
    const user = await this.userService.findByEmail(email);
    if (!user || user.isEmailVerified) {
      return; // don't leak account existence or verification status
    }
    await this.sendVerificationEmail(user.id, user.email);
  }

  async forgotPassword(email: string): Promise<void> {
    const user = await this.userService.findByEmail(email);
    if (!user) {
      return; // identical response regardless of whether the email exists
    }

    const localIdentity =
      await this.authIdentityRepository.findByUserAndProvider(
        user.id,
        AuthProvider.LOCAL,
      );
    if (!localIdentity) {
      return; // Google-only account — nothing to reset, and we don't reveal that here
    }

    await this.verificationTokenRepository.invalidateOutstanding(
      user.id,
      VerificationTokenPurpose.PASSWORD_RESET,
    );
    const ttlMs =
      this.configService.get<number>('PASSWORD_RESET_EXPIRES_IN_MINUTES', 30) *
      60 *
      1000;
    const rawToken = await this.issueVerificationToken(
      user.id,
      VerificationTokenPurpose.PASSWORD_RESET,
      ttlMs,
    );
    await this.mailService.sendForgotPasswordEmail(user.email, rawToken);
  }

  async resetPassword(rawToken: string, newPassword: string): Promise<void> {
    const record = await this.consumeVerificationToken(
      rawToken,
      VerificationTokenPurpose.PASSWORD_RESET,
    );

    const identity = await this.authIdentityRepository.findByUserAndProvider(
      record.userId,
      AuthProvider.LOCAL,
    );
    if (!identity) {
      throw new BadRequestException('This account has no password to reset');
    }

    const passwordHash = await this.passwordService.hash(newPassword);
    await this.authIdentityRepository.updatePasswordHash(
      identity.id,
      passwordHash,
    );

    // Proving account ownership via email should kick out any attacker session.
    await this.tokenService.revokeAllForUser(record.userId);

    const user = await this.userService.findById(record.userId);
    if (user) {
      await this.mailService.sendPasswordChangedEmail(user.email);
    }
  }

  private async sendVerificationEmail(
    userId: string,
    email: string,
  ): Promise<void> {
    await this.verificationTokenRepository.invalidateOutstanding(
      userId,
      VerificationTokenPurpose.EMAIL_VERIFICATION,
    );
    const ttlMs =
      this.configService.get<number>(
        'EMAIL_VERIFICATION_EXPIRES_IN_HOURS',
        24,
      ) *
      60 *
      60 *
      1000;
    const rawToken = await this.issueVerificationToken(
      userId,
      VerificationTokenPurpose.EMAIL_VERIFICATION,
      ttlMs,
    );
    await this.mailService.sendVerificationEmail(email, rawToken);
  }

  private async issueVerificationToken(
    userId: string,
    purpose: VerificationTokenPurpose,
    ttlMs: number,
  ): Promise<string> {
    const rawToken = randomBytes(32).toString('hex');
    await this.verificationTokenRepository.create({
      user: { connect: { id: userId } },
      purpose,
      tokenHash: hashToken(rawToken),
      expiresAt: new Date(Date.now() + ttlMs),
    });
    return rawToken;
  }

  private async consumeVerificationToken(
    rawToken: string,
    purpose: VerificationTokenPurpose,
  ): Promise<VerificationToken> {
    const record = await this.verificationTokenRepository.findByTokenHash(
      hashToken(rawToken),
    );

    if (
      !record ||
      record.purpose !== purpose ||
      record.consumedAt ||
      record.expiresAt < new Date()
    ) {
      throw new BadRequestException('Invalid or expired token');
    }

    return this.verificationTokenRepository.consume(record.id);
  }
}
