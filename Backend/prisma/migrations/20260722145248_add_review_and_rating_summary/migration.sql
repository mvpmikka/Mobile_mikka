-- CreateTable
CREATE TABLE "reviews" (
    "id" TEXT NOT NULL,
    "placeId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "rating" INTEGER NOT NULL,
    "comment" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "reviews_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "place_rating_summaries" (
    "placeId" TEXT NOT NULL,
    "averageRating" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "reviewCount" INTEGER NOT NULL DEFAULT 0,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "place_rating_summaries_pkey" PRIMARY KEY ("placeId")
);

-- CreateIndex
CREATE INDEX "reviews_placeId_idx" ON "reviews"("placeId");

-- CreateIndex
CREATE INDEX "reviews_deletedAt_idx" ON "reviews"("deletedAt");

-- One review per (user, place), but only among non-deleted rows — a user
-- who deletes their review must be able to write a new one later. Not
-- expressible via Prisma's `@@unique`, so added by hand; see schema.prisma.
CREATE UNIQUE INDEX "reviews_userId_placeId_active_key" ON "reviews"("userId", "placeId") WHERE "deletedAt" IS NULL;

-- AddForeignKey
ALTER TABLE "reviews" ADD CONSTRAINT "reviews_placeId_fkey" FOREIGN KEY ("placeId") REFERENCES "places"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reviews" ADD CONSTRAINT "reviews_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "place_rating_summaries" ADD CONSTRAINT "place_rating_summaries_placeId_fkey" FOREIGN KEY ("placeId") REFERENCES "places"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Maintains place_rating_summaries entirely at the DB level — fires on any
-- insert/update/delete of a review, regardless of which code path touched
-- the table. A place with zero active reviews simply has no summary row.
CREATE OR REPLACE FUNCTION sync_place_rating_summary() RETURNS TRIGGER AS $$
DECLARE
  target_place_id TEXT;
BEGIN
  IF TG_OP = 'DELETE' THEN
    target_place_id := OLD."placeId";
  ELSE
    target_place_id := NEW."placeId";
  END IF;

  INSERT INTO "place_rating_summaries" ("placeId", "averageRating", "reviewCount", "updatedAt")
  SELECT
    target_place_id,
    COALESCE(AVG(rating), 0),
    COUNT(*),
    now()
  FROM "reviews"
  WHERE "placeId" = target_place_id AND "deletedAt" IS NULL
  ON CONFLICT ("placeId") DO UPDATE SET
    "averageRating" = EXCLUDED."averageRating",
    "reviewCount" = EXCLUDED."reviewCount",
    "updatedAt" = EXCLUDED."updatedAt";

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER review_rating_summary_sync
  AFTER INSERT OR DELETE OR UPDATE OF "rating", "deletedAt" ON "reviews"
  FOR EACH ROW
  EXECUTE FUNCTION sync_place_rating_summary();