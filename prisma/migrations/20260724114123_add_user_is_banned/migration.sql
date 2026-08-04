-- NOTE: same recurring drift as every prior migration since docs/foundation.md
-- section 5 — the four hand-added GIN/GiST indexes have no declarative
-- equivalent in schema.prisma. Intentionally not dropped.

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "isBanned" BOOLEAN NOT NULL DEFAULT false;
