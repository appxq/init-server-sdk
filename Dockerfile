# Stage 1: Build
FROM node:25-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Production
FROM node:25-slim
WORKDIR /app

# ติดตั้ง mongodb-database-tools สำหรับ mongoimport/mongoexport
RUN apt-get update && apt-get install -y wget gnupg \
    && wget -qO- https://www.mongodb.org/static/pgp/server-8.0.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/mongodb-server-8.0.gpg \
    && echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | tee /etc/apt/sources.list.d/mongodb-org-8.0.list \
    && apt-get update && apt-get install -y mongodb-database-tools \
    && rm -rf /var/lib/apt/lists/*

# ติดตั้ง production dependencies
COPY package*.json ./
RUN npm install --omit=dev

# คัดลอกไฟล์ที่จำเป็น
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/migrations ./migrations
COPY --from=builder /app/assets ./assets
COPY --from=builder /app/mongo-func.js ./mongo-func.js
COPY --from=builder /app/migrate.js ./migrate.js
COPY --from=builder /app/rollback.js ./rollback.js

ENV PORT=8080
ENV NODE_ENV=production
EXPOSE 8080


CMD ["sh", "-c", "node migrate.js && node dist/server.js"]
