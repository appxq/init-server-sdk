# Deploy บน Coolify

คู่มือตั้งค่า deploy `init-server-sdk` ผ่าน Coolify

## ⚠️ ก่อน push ทุกครั้ง — ต้อง build dist ก่อน

repo นี้ deploy ด้วยไฟล์ที่ bundle แล้ว (`dist/server.js`) ซึ่ง **commit ติดมากับ repo** — source อยู่คนละที่ (`backend/src`)
Coolify build เฉพาะ Docker image จาก `dist/` ที่มีอยู่ มันไม่ได้ build จาก source ให้

ดังนั้น flow คือ:

```bash
# 1. build dist จาก source (ทำในโปรเจกต์ source)
# 2. commit dist ที่ build แล้วเข้า repo นี้
git add dist
git commit -m "build: <version>"
git push      # Coolify จับ push แล้ว build image ต่อ
```

ถ้าลืม build dist ใหม่ → Coolify จะ deploy โค้ดเวอร์ชันเก่า

---

## 1. สร้าง Resource

- **New Resource → Application**
- เลือก Git repo + branch `main`
- **Build Pack: `Dockerfile`** (ใช้ `Dockerfile` ที่อยู่ใน repo อยู่แล้ว)

## 2. Port

| ตั้งค่า | ค่า |
|---|---|
| Ports Exposes | `8080` |

server bind `0.0.0.0:8080` อยู่แล้ว (`HOST=0.0.0.0`, `PORT=8080` ตั้งใน Dockerfile)
ถ้าอยากเปลี่ยน port → ตั้ง env `PORT` แล้วแก้ Ports Exposes ให้ตรงกัน

## 3. Environment Variables

คัดลอกจาก [.env.example](.env.example) ไปวางใน Coolify (Environment Variables) แล้วใส่ค่าจริง

ค่าสำคัญที่ **ต้อง** ตั้งสำหรับ production:

| Key | หมายเหตุ |
|---|---|
| `HOST` | ต้องเป็น `0.0.0.0` |
| `PORT` | `8080` (ตรงกับ Ports Exposes) |
| `MONGODB_URL` `MONGODB_NAME` `MONGODB_USERNAME` `MONGODB_PASSWORD` | ชี้ไป MongoDB จริง |
| `JWT_SECRET` | สุ่มใหม่ อย่าใช้ค่า dev |
| `FRONTEND_URL` `DOMAIN_URL` `APP_URL` | โดเมน production (APP_URL = CORS allow-list) |
| `MAILER_*` | ตั้งถ้าต้องส่งเมล |
| `PUBLIC_KEY` / `PRIVATE_KEY` | multiline — Coolify ใส่ได้ตรงๆ |

> MongoDB เป็น external — ถ้าจะรันใน Coolify ด้วย ให้สร้าง MongoDB resource แยก แล้วเอา connection string มาใส่ `MONGODB_URL`

## 4. Persistent Storage (สำคัญ — ไม่งั้น uploads หายทุก deploy)

ตั้งใน **Storages** ของ application:

| Source (volume) | Destination (ใน container) | ใช้ทำอะไร |
|---|---|---|
| `init-sdk-assets` | `/app/assets` | ไฟล์ที่ user upload (image, sdform, users, export) |
| `init-sdk-logs` | `/app/logs` | log files |

> ไม่ต้อง mount `/app/dist` — มันมาจาก image ทุก deploy

## 5. Migration

`Dockerfile` รัน `node migrate.js` ให้อัตโนมัติก่อน start server ทุกครั้งที่ container ขึ้น
migration ที่รันไปแล้วถูกข้าม (เช็คจาก collection `log_migrations`) — รันซ้ำได้ปลอดภัย

ถ้า migrate fail (เช่น ต่อ DB ไม่ได้) container จะไม่ start และ restart วนจนกว่า DB พร้อม — ตั้งใจให้เป็นแบบนี้

## 6. Health Check

ใช้ **TCP check** ที่ port `8080` (ไม่มี HTTP `/health` endpoint)

- Dockerfile มี `HEALTHCHECK` แบบ TCP ในตัวแล้ว (เช็คว่า port เปิด)
- ใน Coolify Health Check ตั้งเป็น TCP / port `8080` ได้เลย ไม่ต้องตั้ง path

---

## สรุปไฟล์ที่เกี่ยวกับ deploy

| ไฟล์ | หน้าที่ |
|---|---|
| `Dockerfile` | build image + migrate + healthcheck + start |
| `.dockerignore` | กันไฟล์ที่ไม่ต้องเข้า image (logs, .env, .git) |
| `.env.example` | template สำหรับ copy ไปตั้ง env ใน Coolify |
| `migrate.js` | MongoDB migration (รันอัตโนมัติตอน start) |
