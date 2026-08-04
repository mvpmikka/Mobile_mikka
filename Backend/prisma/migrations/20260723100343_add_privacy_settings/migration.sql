-- CreateEnum
CREATE TYPE "check_in_visibility" AS ENUM ('PUBLIC', 'FRIENDS', 'PRIVATE');

-- NOTE: same recurring drift as every prior migration since docs/foundation.md
-- section 5 — the four hand-added GIN/GiST indexes have no declarative
-- equivalent in schema.prisma, so Prisma always proposes dropping them.
-- Intentionally not dropped.

-- CreateTable
CREATE TABLE "privacy_settings" (
    "userId" TEXT NOT NULL,
    "checkInVisibility" "check_in_visibility" NOT NULL DEFAULT 'FRIENDS',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "privacy_settings_pkey" PRIMARY KEY ("userId")
);

-- AddForeignKey
ALTER TABLE "privacy_settings" ADD CONSTRAINT "privacy_settings_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
