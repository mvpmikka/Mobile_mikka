import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type {
  ContentVisibility,
  Post,
  Prisma,
} from '../../../generated/prisma/client';
import type { CreatePostDto } from '../dto/create-post.dto';
import type { MemoryItem, PostFeedItem } from '../types/post.type';

const postInclude = {
  user: {
    select: { id: true, username: true, fullName: true, avatarUrl: true },
  },
  place: { select: { id: true, name: true } },
  images: { orderBy: { position: 'asc' } },
} as const;

type PostRow = Prisma.PostGetPayload<{ include: typeof postInclude }>;

function toFeedItem(row: PostRow): PostFeedItem {
  return {
    id: row.id,
    user: row.user,
    caption: row.caption,
    place: row.place,
    visibility: row.visibility,
    images: row.images.map((image) => ({
      id: image.id,
      url: image.url,
      thumbnailUrl: image.thumbnailUrl,
      position: image.position,
    })),
    createdAt: row.createdAt,
  };
}

@Injectable()
export class PostRepository {
  constructor(private readonly prisma: PrismaService) {}

  findById(id: string): Promise<Post | null> {
    return this.prisma.post.findUnique({ where: { id, deletedAt: null } });
  }

  create(userId: string, dto: CreatePostDto): Promise<PostFeedItem> {
    return this.prisma.post
      .create({
        data: {
          user: { connect: { id: userId } },
          caption: dto.caption,
          visibility: dto.visibility,
          ...(dto.placeId ? { place: { connect: { id: dto.placeId } } } : {}),
          images: {
            create: dto.images.map((image, index) => ({
              url: image.url,
              thumbnailUrl: image.thumbnailUrl,
              position: index,
            })),
          },
        },
        include: postInclude,
      })
      .then(toFeedItem);
  }

  softDelete(id: string): Promise<Post> {
    return this.prisma.post.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  // `allowedVisibilities` is resolved by PostService from the
  // viewer/owner relationship (self, friend, stranger) — Post carries its
  // own per-row visibility (unlike CheckIn/Story, which gate on a single
  // user-level PrivacySettings value), so the filter has to be a set
  // rather than one canView() call.
  async findManyByUser(
    userId: string,
    allowedVisibilities: ContentVisibility[],
    page: number,
    limit: number,
  ): Promise<{ items: PostFeedItem[]; total: number }> {
    const where: Prisma.PostWhereInput = {
      userId,
      deletedAt: null,
      visibility: { in: allowedVisibilities },
    };
    const [rows, total] = await Promise.all([
      this.prisma.post.findMany({
        where,
        include: postInclude,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.post.count({ where }),
    ]);
    return { items: rows.map(toFeedItem), total };
  }

  // "Memories" tab: the owner's own expired Stories, viewed only by
  // themself — this is Story data, not Post data, but the plan groups it
  // under this module's controller for API-shape reasons. Kept as a
  // minimal local read against a table this module doesn't own, per the
  // module-independence principle (same approach as findUserIdByUsername
  // in Badge/Follow/Story).
  async findExpiredStoriesByUser(
    userId: string,
    page: number,
    limit: number,
  ): Promise<{ items: MemoryItem[]; total: number }> {
    const where: Prisma.StoryWhereInput = {
      userId,
      deletedAt: null,
      expiresAt: { lte: new Date() },
    };
    const [rows, total] = await Promise.all([
      this.prisma.story.findMany({
        where,
        include: { place: { select: { id: true, name: true } } },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.story.count({ where }),
    ]);
    return {
      items: rows.map((row) => ({
        id: row.id,
        text: row.text,
        imageUrl: row.imageUrl,
        place: row.place,
        createdAt: row.createdAt,
        expiresAt: row.expiresAt,
      })),
      total,
    };
  }

  // Read-only against `places`/`users` — kept minimal and local to this
  // module rather than importing PlaceModule/UserModule, per CLAUDE.md's
  // module-independence principle (same approach Story/Review/CheckIn use).
  async placeExists(placeId: string): Promise<boolean> {
    const place = await this.prisma.place.findUnique({
      where: { id: placeId, deletedAt: null },
      select: { id: true },
    });
    return place !== null;
  }

  async findUserIdByUsername(username: string): Promise<string | null> {
    const user = await this.prisma.user.findUnique({
      where: { username, deletedAt: null },
      select: { id: true },
    });
    return user?.id ?? null;
  }
}
