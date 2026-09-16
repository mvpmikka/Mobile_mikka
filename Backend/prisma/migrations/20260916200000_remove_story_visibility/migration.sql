-- Story feature's controller/service/gateway code has been removed from
-- this repo. `stories`/`story_views` tables and the `storyVisibility`
-- column were already dropped directly against production by an
-- unrelated, out-of-band migration (see 2026-09-16 incident: P3009 on
-- migration 20260901130000_remove_story, never part of this repo). This
-- migration is IF EXISTS/idempotent so it's a no-op there, while still
-- bringing a fresh database (or any other environment) in line with the
-- current schema.prisma.
-- NOTE: "stories" and "story_views" tables are intentionally NOT dropped
-- here — PostRepository.findExpiredStoriesByUser ("Memories" feature)
-- still reads from `stories`, so `model Story` stays in schema.prisma.

-- AlterTable
ALTER TABLE "privacy_settings" DROP COLUMN IF EXISTS "storyVisibility";

-- Notifications of the retired type must be gone before the enum can be
-- rebuilt without it.
DELETE FROM "notifications" WHERE "type" = 'STORY_UPDATE';

-- AlterEnum: Postgres has no DROP VALUE, so the type is rebuilt without
-- STORY_UPDATE, preserving every other value and all existing rows.
ALTER TYPE "notification_type" RENAME TO "notification_type_old";
CREATE TYPE "notification_type" AS ENUM ('FRIEND_REQUEST', 'NEW_MESSAGE', 'MISSED_CALL', 'FOLLOW', 'BADGE_EARNED');
ALTER TABLE "notifications" ALTER COLUMN "type" TYPE "notification_type" USING ("type"::text::"notification_type");
DROP TYPE "notification_type_old";
