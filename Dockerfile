# Stage 1: Build
FROM node:24-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Stage 2: Production
FROM node:24-slim
WORKDIR /app

# ติดตั้งเครื่องมือ mongoimport/mongoexport สำหรับรันในโค้ด
RUN apt-get update && apt-get install -y wget gnupg \
    && wget -qO- https://www.mongodb.org/static/pgp/server-8.0.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/mongodb-server-8.0.gpg \
    && echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | tee /etc/apt/sources.list.d/mongodb-org-8.0.list \
    && apt-get update && apt-get install -y mongodb-database-tools \
    && rm -rf /var/lib/apt/lists/*

# ติดตั้งเฉพาะ production dependencies (เผื่อมี native modules ที่ bundle ไม่ได้)
COPY package*.json ./
RUN npm install --omit=dev

# คัดลอกโฟลเดอร์ dist ทั้งหมดมาไว้ที่ ./dist
COPY --from=builder /app/dist ./dist

# คัดลอกโฟลเดอร์ที่จำเป็นอื่นๆ มาไว้ที่ Root
COPY --from=builder /app/migrations ./migrations
COPY --from=builder /app/assets ./assets
COPY --from=builder /app/mongo-func.js ./mongo-func.js
COPY --from=builder /app/rollback.js ./rollback.js

ENV PORT=8080
ENV NODE_ENV=production
EXPOSE 8080

# รันไฟล์ที่ bundle แล้วโดยตรง ไม่ต้องผ่าน npm
CMD ["node", "dist/server.js"]