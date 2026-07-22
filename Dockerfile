FROM node:25-slim
WORKDIR /app

# ติดตั้ง mongodb-database-tools สำหรับ mongoimport/mongoexport
RUN apt-get update && apt-get install -y wget gnupg \
    && wget -qO- https://www.mongodb.org/static/pgp/server-8.0.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/mongodb-server-8.0.gpg \
    && echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | tee /etc/apt/sources.list.d/mongodb-org-8.0.list \
    && apt-get update && apt-get install -y mongodb-database-tools \
    && rm -rf /var/lib/apt/lists/*

# --- LaTeX engine (Tectonic) สำหรับ Dynamic Report แบบ LaTeX ---
# arch-aware musl static → รันได้ทั้ง amd64 (prod/coolify) และ arm64; ปิด shell-escape (\write18) โดย default
# NB: gnu(glibc) build ต้อง glibc>=2.38 แต่ base bookworm=2.36 → ใช้ musl static portable กว่า
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates wget fontconfig \
    && ARCH="$(dpkg --print-architecture)" \
    && case "$ARCH" in \
         amd64) T="x86_64-unknown-linux-musl" ;; \
         arm64) T="aarch64-unknown-linux-musl" ;; \
         *) echo "unsupported arch: $ARCH" >&2; exit 1 ;; \
       esac \
    && wget -qO /tmp/tectonic.tar.gz "https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.16.9/tectonic-0.16.9-${T}.tar.gz" \
    && tar xzf /tmp/tectonic.tar.gz -C /usr/local/bin \
    && rm /tmp/tectonic.tar.gz \
    && rm -rf /var/lib/apt/lists/*

# font Sarabun (OFL) — Debian ไม่มี ต้อง COPY เข้า image + fc-cache (fontspec \setmainfont{Sarabun} ชี้ผ่าน fontconfig by-name)
COPY assets/fonts/Sarabun.ttc /usr/share/fonts/truetype/sarabun/Sarabun.ttc
RUN fc-cache -f

# pre-warm: compile dummy ตอน build → ฝัง TeX package cache ใน image (compile prod แรกเร็ว ไม่ต้องพึ่งเน็ต)
ENV TECTONIC_CACHE_DIR=/opt/tectonic-cache
COPY assets/latex/prewarm.tex /tmp/prewarm.tex
RUN cd /tmp && tectonic prewarm.tex && rm -f prewarm.*

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
