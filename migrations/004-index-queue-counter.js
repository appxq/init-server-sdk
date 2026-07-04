/**
 * สร้าง collection core_queue_counter + unique index สำหรับระบบ gen เลขคิว (visit_tran)
 *
 * บริบท: API checkin ขอเลขคิวผ่าน findOneAndUpdate {$inc: seq} + upsert
 * key = (unit_to, queue_date) → นับแยกต่อคลินิก และรีเซ็ตเป็น 1 เมื่อขึ้นวันใหม่เอง (ไม่มี job reset)
 * ตั้งใจเป็น collection ระบบล้วน (ไม่มี sdform ครอบ) — แก้ manual ทำผ่าน DB tool ตรงๆ
 *
 * unique index จำเป็น — ไม่มีแล้ว upsert พร้อมกันตอนเปิด counter วันใหม่
 * อาจสร้าง doc ซ้อน (Mongo upsert ไม่ atomic ข้าม doc ถ้าไม่มี unique constraint)
 * มี index แล้วตัวที่แพ้ race จะได้ E11000 ให้ฝั่ง API retry แทน
 *
 * @param {import('mongodb').Db} db
 */
exports.up = async function (db) {
	const col = db.collection('core_queue_counter');
	// createIndex idempotent — รันซ้ำ spec เดิม = no-op (และสร้าง collection ให้เองถ้ายังไม่มี)
	await col.createIndexes([
		{ key: { unit_to: 1, queue_date: 1 }, name: 'uniq_unit_to_queue_date', unique: true },
	]);
	console.log('✅ core_queue_counter unique index created (unit_to + queue_date)');
};

exports.down = async function (db) {
	const col = db.collection('core_queue_counter');
	try {
		await col.dropIndex('uniq_unit_to_queue_date');
	} catch (e) {
		// index อาจไม่มี (ยังไม่เคยรัน up) — ข้าม
	}
};
