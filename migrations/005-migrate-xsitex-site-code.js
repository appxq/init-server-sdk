/**
 * ย้าย xsitex ของข้อมูลเก่าจากค่า default (00000/00) → รหัสโรงพยาบาลจริงจาก core_setting.sys_site_code
 *
 * บริบท: เดิมระบบ fix xsitex = {code:'00000', name:'Center'} ทุก record — พอเปิดใช้ site จริง
 * (ตั้ง sys_site_code) record ใหม่จะ stamp รหัสใหม่ แต่ข้อมูลเก่ายังเป็น 00000 → ฟอร์มที่
 * data_sharing = 'site' จะมองไม่เห็นข้อมูลเก่าทันที migration นี้ยกข้อมูลเก่าตามไปด้วย
 *
 * ลำดับการใช้: ตั้งค่า sys_site_code ใน Setting Manager ก่อน แล้วค่อยรัน `npm run migrate`
 * - ถ้ายังไม่ตั้ง sys_site_code → ข้าม (no-op) รันใหม่ทีหลังได้เพราะ filter เจาะเฉพาะค่า default เดิม
 * - พร้อมกันนี้ normalize unit code '00' → '00000' (โค้ดเดิมมี default ปนกันสองแบบ)
 *
 * @param {import('mongodb').Db} db
 */

const OLD_CODES = ['00000', '00'];

exports.up = async function (db) {
	const setting = await db.collection('core_setting').findOne({ opts_code: 'sys_site_code' });
	const siteCode = !!setting && !!setting.opts_value ? String(setting.opts_value).trim() : '';

	if (!siteCode) {
		console.log('⚠️  sys_site_code is not set — skip xsitex migration (set it in Setting Manager then run migrate again)');
		return;
	}

	const hospital = await db.collection('zdata_hospital').findOne({ hospcode: siteCode, xrstatx: 1 });
	const newSite = { code: siteCode, name: !!hospital && !!hospital.hospname ? hospital.hospname : siteCode };
	console.log(`🏥 Target site: ${newSite.code} - ${newSite.name}`);

	const collections = await db.listCollections().toArray();
	const zdataNames = collections.map((c) => c.name).filter((name) => name.startsWith('zdata_'));

	for (const name of zdataNames) {
		const col = db.collection(name);
		const siteResult = await col.updateMany({ 'xsitex.code': { $in: OLD_CODES } }, { $set: { xsitex: newSite } });
		// normalize xunitx code '00' → '00000' (เฉพาะตัว default เก่า — unit จริงไม่โดนแตะ)
		const unitResult = await col.updateMany({ 'xunitx.code': '00' }, { $set: { xunitx: { code: '00000', name: 'Center' } } });
		if (siteResult.modifiedCount > 0 || unitResult.modifiedCount > 0) {
			console.log(`✅ ${name}: xsitex ${siteResult.modifiedCount} rows, xunitx normalized ${unitResult.modifiedCount} rows`);
		}
	}

	// core_user: site ตาม instance / unit normalize เป็น 00000 (unit จริงของ user ไม่โดนแตะ)
	const userCol = db.collection('core_user');
	const userSite = await userCol.updateMany({ 'site.code': { $in: OLD_CODES } }, { $set: { site: newSite } });
	const userUnit = await userCol.updateMany({ 'unit.code': '00' }, { $set: { unit: { code: '00000', name: 'Center' } } });
	console.log(`✅ core_user: site ${userSite.modifiedCount} rows, unit normalized ${userUnit.modifiedCount} rows`);
};

exports.down = async function (db) {
	// revert: ย้อนทุก record ที่เป็นรหัสจาก sys_site_code กลับเป็น Center (00000)
	const setting = await db.collection('core_setting').findOne({ opts_code: 'sys_site_code' });
	const siteCode = !!setting && !!setting.opts_value ? String(setting.opts_value).trim() : '';
	if (!siteCode) {
		console.log('⚠️  sys_site_code is not set — nothing to revert');
		return;
	}

	const center = { code: '00000', name: 'Center' };
	const collections = await db.listCollections().toArray();
	const zdataNames = collections.map((c) => c.name).filter((name) => name.startsWith('zdata_'));

	for (const name of zdataNames) {
		await db.collection(name).updateMany({ 'xsitex.code': siteCode }, { $set: { xsitex: center } });
	}
	await db.collection('core_user').updateMany({ 'site.code': siteCode }, { $set: { site: center } });
	console.log(`↩️  Reverted xsitex/site ${siteCode} → 00000 (Center)`);
};
