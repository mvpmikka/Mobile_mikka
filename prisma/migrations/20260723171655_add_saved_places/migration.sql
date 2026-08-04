-- NOTE: same recurring drift as every prior migration since docs/foundation.md
-- section 5 — the four hand-added GIN/GiST indexes have no declarative
-- equivalent in schema.prisma. Intentionally not dropped.

-- CreateTable
CREATE TABLE "saved_places" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "placeId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "saved_places_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "saved_places_placeId_idx" ON "saved_places"("placeId");

-- CreateIndex
CREATE UNIQUE INDEX "saved_places_userId_placeId_key" ON "saved_places"("userId", "placeId");

-- AddForeignKey
ALTER TABLE "saved_places" ADD CONSTRAINT "saved_places_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_places" ADD CONSTRAINT "saved_places_placeId_fkey" FOREIGN KEY ("placeId") REFERENCES "places"("id") ON DELETE CASCADE ON UPDATE CASCADE;
