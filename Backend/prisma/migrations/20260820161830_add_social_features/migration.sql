-- AlterTable
ALTER TABLE "users" ADD COLUMN "bio" TEXT;

-- AlterEnum
ALTER TYPE "notification_type" ADD VALUE 'FOLLOW';
ALTER TYPE "notification_type" ADD VALUE 'BADGE_EARNED';

-- CreateEnum
CREATE TYPE "badge_criteria_type" AS ENUM ('CHECKIN_CATEGORY_COUNT', 'CHECKIN_REGION_DISTINCT_COUNT', 'REVIEW_COUNT');

-- CreateTable
CREATE TABLE "follows" (
    "id" TEXT NOT NULL,
    "followerId" TEXT NOT NULL,
    "followingId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "follows_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "posts" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "caption" TEXT,
    "placeId" TEXT,
    "visibility" "content_visibility" NOT NULL DEFAULT 'FRIENDS',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "posts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "post_images" (
    "id" TEXT NOT NULL,
    "postId" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "thumbnailUrl" TEXT,
    "position" INTEGER NOT NULL,

    CONSTRAINT "post_images_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "badge_definitions" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "iconUrl" TEXT,
    "criteriaType" "badge_criteria_type" NOT NULL,
    "threshold" INTEGER NOT NULL,
    "criteriaParams" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "badge_definitions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_badges" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "badgeDefinitionId" TEXT NOT NULL,
    "earnedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_badges_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "follows_followerId_followingId_key" ON "follows"("followerId", "followingId");

-- CreateIndex
CREATE INDEX "follows_followingId_idx" ON "follows"("followingId");

-- CreateIndex
CREATE INDEX "posts_userId_idx" ON "posts"("userId");

-- CreateIndex
CREATE INDEX "posts_deletedAt_idx" ON "posts"("deletedAt");

-- CreateIndex
CREATE UNIQUE INDEX "post_images_postId_position_key" ON "post_images"("postId", "position");

-- CreateIndex
CREATE UNIQUE INDEX "badge_definitions_code_key" ON "badge_definitions"("code");

-- CreateIndex
CREATE UNIQUE INDEX "user_badges_userId_badgeDefinitionId_key" ON "user_badges"("userId", "badgeDefinitionId");

-- CreateIndex
CREATE INDEX "user_badges_userId_idx" ON "user_badges"("userId");

-- AddForeignKey
ALTER TABLE "follows" ADD CONSTRAINT "follows_followerId_fkey" FOREIGN KEY ("followerId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "follows" ADD CONSTRAINT "follows_followingId_fkey" FOREIGN KEY ("followingId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "posts" ADD CONSTRAINT "posts_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "posts" ADD CONSTRAINT "posts_placeId_fkey" FOREIGN KEY ("placeId") REFERENCES "places"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_images" ADD CONSTRAINT "post_images_postId_fkey" FOREIGN KEY ("postId") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_badges" ADD CONSTRAINT "user_badges_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_badges" ADD CONSTRAINT "user_badges_badgeDefinitionId_fkey" FOREIGN KEY ("badgeDefinitionId") REFERENCES "badge_definitions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Seed badge definitions achievable with data that already exists today
-- (Region is seeded with 14 real Uzbekistan viloyats; Review/CheckIn are
-- live tables). Category-based badges reference conventional slugs
-- ("coffee", "restaurant", "food") that don't exist in place_categories
-- yet (categories are admin-created, none seeded) — these badges simply
-- won't be earned until an admin creates categories with matching slugs;
-- nothing breaks in the meantime, by design (see BadgeDefinition comment
-- in schema.prisma).
INSERT INTO "badge_definitions" ("id", "code", "name", "description", "criteriaType", "threshold", "criteriaParams") VALUES
    (gen_random_uuid(), 'COFFEE_CONNOISSEUR', 'Coffee Connoisseur', '5+ check-ins at coffee places', 'CHECKIN_CATEGORY_COUNT', 5, '{"categorySlugs":["coffee"]}'),
    (gen_random_uuid(), 'FOODIE_EXPLORER', 'Foodie Explorer', '5+ check-ins at food places', 'CHECKIN_CATEGORY_COUNT', 5, '{"categorySlugs":["restaurant","food"]}'),
    (gen_random_uuid(), 'GLOBAL_TRAVELER', 'Global Traveler', 'Checked in across 3+ regions', 'CHECKIN_REGION_DISTINCT_COUNT', 3, NULL),
    (gen_random_uuid(), 'WORLD_EXPLORER', 'World Explorer', 'Checked in across 6+ regions', 'CHECKIN_REGION_DISTINCT_COUNT', 6, NULL),
    (gen_random_uuid(), 'TOP_REVIEWER', 'Top Reviewer', 'Written 10+ reviews', 'REVIEW_COUNT', 10, NULL);
