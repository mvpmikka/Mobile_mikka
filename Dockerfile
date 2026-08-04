# ---- Build stage ----
FROM node:24-alpine AS builder
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npx prisma generate
RUN npm run build

# ---- Production stage ----
FROM node:24-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

COPY package*.json ./
RUN npm ci --omit=dev

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/generated ./generated
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/prisma.config.ts ./prisma.config.ts

EXPOSE 3000
# Applies pending migrations before booting — safe to run on every deploy,
# a no-op when the schema is already up to date.
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/main"]