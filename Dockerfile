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

# คัดลอกไฟล์ที่จำเป็น (dist build มาแล้ว commit ไว้ใน repo)
COPY dist ./dist
COPY migrations ./migrations
COPY assets ./assets
COPY mongo-func.js ./mongo-func.js
COPY migrate.js ./migrate.js
COPY rollback.js ./rollback.js

ENV PORT=8080
ENV NODE_ENV=production
EXPOSE 8080

# TCP health check — เช็คแค่ว่า port เปิด (ไม่พึ่ง curl/nc ที่ slim image ไม่มี)
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD node -e "require('net').connect(Number(process.env.PORT)||8080,'127.0.0.1').on('connect',()=>process.exit(0)).on('error',()=>process.exit(1))"

# รัน migration ก่อน แล้วค่อย start server (bundle ตรง ไม่ผ่าน npm)
CMD ["sh", "-c", "node migrate.js && node dist/server.js"]
