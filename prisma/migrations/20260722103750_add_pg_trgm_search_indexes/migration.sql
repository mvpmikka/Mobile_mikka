-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Trigram indexes for fuzzy/partial text search (Search module). Like the
-- PostGIS GiST index on `location`, these have no declarative equivalent
-- in schema.prisma (no @@index option for gin_trgm_ops) — future
-- `prisma migrate dev` runs may see them as unexpected drift and generate
-- a DROP INDEX for them. Always check generated migration.sql by hand
-- before applying; see docs/foundation.md.
CREATE INDEX "places_name_trgm_idx" ON "places" USING GIN ("name" gin_trgm_ops);
CREATE INDEX "place_categories_name_trgm_idx" ON "place_categories" USING GIN ("name" gin_trgm_ops);