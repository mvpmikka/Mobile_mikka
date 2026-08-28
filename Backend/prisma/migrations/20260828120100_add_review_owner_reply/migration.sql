-- AlterTable
ALTER TABLE "reviews" ADD COLUMN "ownerReply" TEXT,
ADD COLUMN "ownerRepliedAt" TIMESTAMP(3);
