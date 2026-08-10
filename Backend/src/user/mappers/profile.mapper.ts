import type { User } from '../../../generated/prisma/client';
import type { PrivateProfile, PublicProfile } from '../types/profile.type';

export function toPrivateProfile(user: User): PrivateProfile {
  return {
    id: user.id,
    email: user.email,
    isEmailVerified: user.isEmailVerified,
    username: user.username,
    fullName: user.fullName,
    gender: user.gender,
    birthDate: user.birthDate,
    avatarUrl: user.avatarUrl,
    profileCompleted: user.profileCompleted,
    role: user.role,
    createdAt: user.createdAt,
  };
}

export function toPublicProfile(
  user: User & { username: string },
): PublicProfile {
  return {
    username: user.username,
    fullName: user.fullName,
    avatarUrl: user.avatarUrl,
    createdAt: user.createdAt,
  };
}
