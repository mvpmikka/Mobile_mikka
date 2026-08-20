import type { User } from '../../../generated/prisma/client';
import type { PrivateProfile, PublicProfile } from '../types/profile.type';

interface FollowCounts {
  followersCount: number;
  followingCount: number;
}

export function toPrivateProfile(
  user: User,
  counts: FollowCounts,
): PrivateProfile {
  return {
    id: user.id,
    email: user.email,
    isEmailVerified: user.isEmailVerified,
    username: user.username,
    fullName: user.fullName,
    bio: user.bio,
    gender: user.gender,
    birthDate: user.birthDate,
    avatarUrl: user.avatarUrl,
    profileCompleted: user.profileCompleted,
    role: user.role,
    followersCount: counts.followersCount,
    followingCount: counts.followingCount,
    createdAt: user.createdAt,
  };
}

export function toPublicProfile(
  user: User & { username: string },
  counts: FollowCounts,
  isFollowedByMe: boolean,
): PublicProfile {
  return {
    id: user.id,
    username: user.username,
    fullName: user.fullName,
    bio: user.bio,
    avatarUrl: user.avatarUrl,
    followersCount: counts.followersCount,
    followingCount: counts.followingCount,
    isFollowedByMe,
    createdAt: user.createdAt,
  };
}
