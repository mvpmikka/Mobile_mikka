-- NOTE: Prisma's diff engine doesn't see hand-added indexes (GiST/GIN have
-- no declarative equivalent in schema.prisma) as part of its migration
-- history, so `prisma migrate dev` generated DROP INDEX statements for
-- "place_categories_name_trgm_idx", "places_location_gist_idx" and
-- "places_name_trgm_idx" here. Those are real, load-bearing indexes from
-- earlier migrations — intentionally NOT dropped. See docs/foundation.md.

-- AlterTable
ALTER TABLE "places" ADD COLUMN     "regionId" TEXT;

-- CreateTable
CREATE TABLE "regions" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "boundary" geometry(MultiPolygon, 4326) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "regions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "regions_name_key" ON "regions"("name");

-- CreateIndex
CREATE INDEX "places_regionId_idx" ON "places"("regionId");

-- AddForeignKey
ALTER TABLE "places" ADD CONSTRAINT "places_regionId_fkey" FOREIGN KEY ("regionId") REFERENCES "regions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- GiST index for the point-in-polygon lookup (ST_Contains) that resolves
-- a coordinate to its region, both in the sync trigger below and in the
-- GET /places fallback-search query.
CREATE INDEX "regions_boundary_gist_idx" ON "regions" USING GIST ("boundary");

-- PLACEHOLDER seed data — rough bounding boxes, not real administrative
-- geometry. Good enough to prove the radius -> region-fallback mechanism
-- end to end; MUST be replaced with real boundary polygons (e.g. sourced
-- from OSM admin_level relations or GADM) before this is relied on in
-- production. See docs/foundation.md.
INSERT INTO "regions" ("id", "name", "boundary", "createdAt", "updatedAt") VALUES
  ('a1b2c3d4-0001-4000-8000-000000000001', 'Tashkent City', ST_Multi(ST_MakeEnvelope(69.15, 41.20, 69.35, 41.35, 4326)), now(), now()),
  ('a1b2c3d4-0001-4000-8000-000000000002', 'Samarkand Region', ST_Multi(ST_MakeEnvelope(66.70, 39.40, 67.20, 39.90, 4326)), now(), now());

-- Keeps `regionId` in sync with latitude/longitude at the database level,
-- mirroring sync_place_location above — application code never writes
-- regionId directly. NULL when no seeded region contains the point yet.
CREATE OR REPLACE FUNCTION sync_place_region() RETURNS TRIGGER AS $$
DECLARE
  matched_region_id TEXT;
BEGIN
  SELECT id INTO matched_region_id
  FROM "regions"
  WHERE ST_Contains("boundary", ST_SetSRID(ST_MakePoint(NEW."longitude", NEW."latitude"), 4326))
  LIMIT 1;

  NEW."regionId" := matched_region_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER place_region_sync
  BEFORE INSERT OR UPDATE OF "latitude", "longitude" ON "places"
  FOR EACH ROW
  EXECUTE FUNCTION sync_place_region();

-- Backfill any places inserted before this migration (none expected in a
-- fresh database, but correct regardless of when this runs).
UPDATE "places" p
SET "regionId" = (
  SELECT r.id FROM "regions" r
  WHERE ST_Contains(r."boundary", ST_SetSRID(ST_MakePoint(p."longitude", p."latitude"), 4326))
  LIMIT 1
);