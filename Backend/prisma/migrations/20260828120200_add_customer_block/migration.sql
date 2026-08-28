-- CreateTable
CREATE TABLE "customer_blocks" (
    "id" TEXT NOT NULL,
    "placeId" TEXT NOT NULL,
    "customerPhone" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "customer_blocks_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "customer_blocks_placeId_customerPhone_key" ON "customer_blocks"("placeId", "customerPhone");

-- AddForeignKey
ALTER TABLE "customer_blocks" ADD CONSTRAINT "customer_blocks_placeId_fkey" FOREIGN KEY ("placeId") REFERENCES "places"("id") ON DELETE CASCADE ON UPDATE CASCADE;
