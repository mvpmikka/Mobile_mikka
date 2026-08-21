import { Injectable, NotFoundException } from '@nestjs/common';
import { FriendshipRepository } from '../repositories/friendship.repository';
import { PresenceService } from '../../presence/presence.service';
import type {
  FriendActivityItem,
  FriendItem,
  LatestCheckInItem,
  PaginatedResult,
} from '../types/friendship.type';

const EARTH_RADIUS_METERS = 6_371_000;

function toRadians(degrees: number): number {
  return (degrees * Math.PI) / 180;
}

// Great-circle distance between two lat/lng points — deliberately not
// PostGIS ST_Distance here: both points come from CheckIn history (already
// plain floats in application memory), not a places table row, so a
// round-trip to the DB just to compare two numbers would be wasteful.
function haversineMeters(
  a: { latitude: number; longitude: number },
  b: { latitude: number; longitude: number },
): number {
  const dLat = toRadians(b.latitude - a.latitude);
  const dLon = toRadians(b.longitude - a.longitude);
  const lat1 = toRadians(a.latitude);
  const lat2 = toRadians(b.latitude);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  return 2 * EARTH_RADIUS_METERS * Math.asin(Math.sqrt(h));
}

@Injectable()
export class FriendshipService {
  constructor(
    private readonly friendshipRepository: FriendshipRepository,
    private readonly presenceService: PresenceService,
  ) {}

  async list(
    userId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<FriendItem>> {
    const { items, total } = await this.friendshipRepository.findManyByUser(
      userId,
      page,
      limit,
    );
    return { items, total, page, limit };
  }

  async remove(userId: string, friendUserId: string): Promise<void> {
    const deleted = await this.friendshipRepository.deletePair(
      userId,
      friendUserId,
    );
    if (!deleted) {
      throw new NotFoundException('You are not friends with this user');
    }
  }

  async getActivity(
    userId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<FriendActivityItem>> {
    const { items: friends, total } =
      await this.friendshipRepository.findManyByUser(userId, page, limit);

    const friendIds = friends.map((friend) => friend.id);
    const [myLatest, friendsLatest] = await Promise.all([
      this.friendshipRepository.findLatestCheckIns([userId]),
      this.friendshipRepository.findLatestCheckIns(friendIds),
    ]);
    const myLocation = myLatest[0] ?? null;
    const latestByFriendId = new Map<string, LatestCheckInItem>(
      friendsLatest.map((row) => [row.userId, row]),
    );

    const items: FriendActivityItem[] = friends.map((friend) => {
      const latest = latestByFriendId.get(friend.id) ?? null;
      return {
        id: friend.id,
        username: friend.username,
        fullName: friend.fullName,
        avatarUrl: friend.avatarUrl,
        lastCheckIn: latest
          ? { placeName: latest.placeName, createdAt: latest.createdAt }
          : null,
        distanceMeters:
          myLocation && latest ? haversineMeters(myLocation, latest) : null,
        online: this.presenceService.isOnline(friend.id),
      };
    });

    return { items, total, page, limit };
  }
}
