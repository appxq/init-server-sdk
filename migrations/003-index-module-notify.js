/**
 * สร้าง index ให้ module_notify (เดิมไม่มี index เลย นอกจาก _id)
 *
 * บริบท: query notify (count/view) กรองด้วย xrstatx + mode + target/site/unit + created_at
 * หลัง refactor เลิกใช้ INDEXOF_ARRAY / DATE_FROM_STRING (ที่ทำ $expr → full scan) แล้ว
 * ทุก condition เป็น plain match/range → ใช้ index ได้ index ชุดนี้จึงปลดล็อกให้ query ไม่ scan ทั้ง collection
 *
 * index strategy (map ตาม query `$and[xrstatx, $or[broadcast|target|site|unit], created_at]`):
 *   - {created_at:1}        → range `created_at > lastAt` + sort created_at DESC (orderBy)
 *   - {mode:1, target:1}    → branch broadcast (prefix mode) + branch target (multikey บน array target)
 *   - {mode:1, site:1}      → branch site (multikey บน array site)
 *   - {mode:1, unit:1}      → branch unit (multikey บน array unit)
 * target/site/unit เป็น string[] → Mongo สร้าง multikey index อัตโนมัติ match element ใน array ได้
 *
 * @param {import('mongodb').Db} db
 */
exports.up = async function (db) {
	const col = db.collection('module_notify');
	// createIndex idempotent — รันซ้ำ spec เดิม = no-op
	await col.createIndexes([
		{ key: { created_at: 1 }, name: 'created_at_1' },
		{ key: { mode: 1, target: 1 }, name: 'mode_1_target_1' },
		{ key: { mode: 1, site: 1 }, name: 'mode_1_site_1' },
		{ key: { mode: 1, unit: 1 }, name: 'mode_1_unit_1' },
	]);
	console.log('✅ module_notify indexes created (created_at, mode+target, mode+site, mode+unit)');
};

exports.down = async function (db) {
	const col = db.collection('module_notify');
	for (const name of ['created_at_1', 'mode_1_target_1', 'mode_1_site_1', 'mode_1_unit_1']) {
		try {
			await col.dropIndex(name);
		} catch (e) {
			// index อาจไม่มี (ยังไม่เคยรัน up) — ข้าม
		}
	}
};
