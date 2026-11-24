-- Backfills schema that previously only existed via `prisma db push`
-- (shorts, short_likes, place verification). Without it a fresh database
-- fails at 20261110000000_add_short_save ("relation shorts does not exist").
-- On a database that already has these objects, mark this migration as
-- applied instead: `npx prisma migrate resolve --applied 20261109000000_add_shorts_and_place_verification`.

-- CreateEnum
CREATE TYPE "place_verification_status" AS ENUM ('NONE', 'PENDING', 'APPROVED', 'REJECTED');

-- AlterTable
ALTER TABLE "places" ADD COLUMN     "verificationDocPath" TEXT,
ADD COLUMN     "verificationRejectReason" TEXT,
ADD COLUMN     "verificationReviewedAt" TIMESTAMP(3),
ADD COLUMN     "verificationStatus" "place_verification_status" NOT NULL DEFAULT 'NONE',
ADD COLUMN     "verificationSubmittedAt" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX "places_verificationStatus_idx" ON "places"("verificationStatus");

-- CreateTable
CREATE TABLE "shorts" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "caption" TEXT,
    "videoUrl" TEXT NOT NULL,
    "thumbnailUrl" TEXT,
    "placeId" TEXT,
    "visibility" "content_visibility" NOT NULL DEFAULT 'FRIENDS',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "shorts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "short_likes" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "shortId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "short_likes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "shorts_userId_idx" ON "shorts"("userId");

-- CreateIndex
CREATE INDEX "shorts_deletedAt_idx" ON "shorts"("deletedAt");

-- CreateIndex
CREATE INDEX "shorts_createdAt_idx" ON "shorts"("createdAt");

-- CreateIndex
CREATE INDEX "short_likes_shortId_idx" ON "short_likes"("shortId");

-- CreateIndex
CREATE UNIQUE INDEX "short_likes_userId_shortId_key" ON "short_likes"("userId", "shortId");

-- AddForeignKey
ALTER TABLE "shorts" ADD CONSTRAINT "shorts_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shorts" ADD CONSTRAINT "shorts_placeId_fkey" FOREIGN KEY ("placeId") REFERENCES "places"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "short_likes" ADD CONSTRAINT "short_likes_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "short_likes" ADD CONSTRAINT "short_likes_shortId_fkey" FOREIGN KEY ("shortId") REFERENCES "shorts"("id") ON DELETE CASCADE ON UPDATE CASCADE;
