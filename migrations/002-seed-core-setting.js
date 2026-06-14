const fs = require('fs');
const path = require('path');
const { EJSON } = require('bson');

/**
 * Seed core_setting ด้วย native MongoDB driver (idempotent upsert)
 *
 * เหตุผล: 001 seed core_setting ผ่าน mongoimport CLI (mongo-func.js) ซึ่งพังบน production
 * เพราะ Coolify ตั้ง MONGODB_URL เป็น connection string เต็ม (user:pass@host) ทำให้
 * --host / --username ที่ประกอบเองผิด format. วิธีนี้ใช้ driver ตรงๆ ไม่ต้องพึ่ง CLI
 * จึงทำงานได้ทุก environment (local / Coolify / Atlas)
 *
 * @param {import('mongodb').Db} db
 */
exports.up = async function (db) {
	const fullPath = path.resolve(__dirname, 'seeds/core_setting.json');
	const docs = EJSON.parse(fs.readFileSync(fullPath, 'utf8')); // EJSON แปลง {$oid} → ObjectId

	if (!Array.isArray(docs) || docs.length === 0) {
		console.log('⚠️ core_setting.json ว่าง — ข้าม seed');
		return;
	}

	// upsert by _id — รันซ้ำได้ปลอดภัย (ไม่สร้าง duplicate)
	const ops = docs.map((doc) => ({
		replaceOne: { filter: { _id: doc._id }, replacement: doc, upsert: true },
	}));
	const res = await db.collection('core_setting').bulkWrite(ops);
	console.log(`✅ core_setting seeded: ${res.upsertedCount} inserted, ${res.modifiedCount} updated (total ${docs.length})`);
};

exports.down = async function () {
	// ไม่ลบ core_setting ตอน rollback — ปล่อยให้ 001 down จัดการ collection ทั้งก้อน
};
