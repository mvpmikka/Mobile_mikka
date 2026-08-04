-- NOTE: same recurring drift as every prior migration since docs/foundation.md
-- section 5 — the four hand-added GIN/GiST indexes have no declarative
-- equivalent in schema.prisma. Intentionally not dropped.

-- Rewritten by hand: Prisma's generated diff for the CheckInVisibility ->
-- ContentVisibility rename was DROP COLUMN "checkInVisibility" + re-ADD +
-- DROP TYPE "check_in_visibility" — destructive, would have discarded
-- every existing checkInVisibility value. A plain RENAME preserves the
-- column and its data untouched; only the type's name changes.
ALTER TYPE "check_in_visibility" RENAME TO "content_visibility";

-- AlterTable
ALTER TABLE "privacy_settings" ADD COLUMN     "storyVisibility" "content_visibility" NOT NULL DEFAULT 'FRIENDS';

-- CreateTable
CREATE TABLE "stories" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "text" TEXT,
    "imageUrl" TEXT,
    "placeId" TEXT,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "stories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "story_views" (
    "id" TEXT NOT NULL,
    "storyId" TEXT NOT NULL,
    "viewerId" TEXT NOT NULL,
    "viewedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "story_views_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "stories_userId_idx" ON "stories"("userId");

-- CreateIndex
CREATE INDEX "stories_expiresAt_idx" ON "stories"("expiresAt");

-- CreateIndex
CREATE UNIQUE INDEX "story_views_storyId_viewerId_key" ON "story_views"("storyId", "viewerId");

-- AddForeignKey
ALTER TABLE "stories" ADD CONSTRAINT "stories_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stories" ADD CONSTRAINT "stories_placeId_fkey" FOREIGN KEY ("placeId") REFERENCES "places"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "story_views" ADD CONSTRAINT "story_views_storyId_fkey" FOREIGN KEY ("storyId") REFERENCES "stories"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "story_views" ADD CONSTRAINT "story_views_viewerId_fkey" FOREIGN KEY ("viewerId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;