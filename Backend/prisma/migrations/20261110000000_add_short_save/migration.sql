-- CreateTable
CREATE TABLE "short_saves" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "shortId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "short_saves_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "short_saves_shortId_idx" ON "short_saves"("shortId");

-- CreateIndex
CREATE UNIQUE INDEX "short_saves_userId_shortId_key" ON "short_saves"("userId", "shortId");

-- AddForeignKey
ALTER TABLE "short_saves" ADD CONSTRAINT "short_saves_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "short_saves" ADD CONSTRAINT "short_saves_shortId_fkey" FOREIGN KEY ("shortId") REFERENCES "shorts"("id") ON DELETE CASCADE ON UPDATE CASCADE;
