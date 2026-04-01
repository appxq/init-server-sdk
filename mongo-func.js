const path = require('path');
require('dotenv').config();

function mongoImport(from, fileName) {
	const mongodbUrl = process.env.MONGODB_URL || '';
	const isAtlas = mongodbUrl.includes('+srv://');

	let urldb = `${process.env.MONGODB_URL}`;
	urldb = urldb.replace('mongodb://', '');
	const fullPath = path.resolve('migrations/seeds/', fileName);

	if (isAtlas) {
		// ✅ สำหรับ MongoDB Atlas: ใช้ --uri ตัวเดียวจบ (ไม่ต้องระบุ user/pass แยก)
		// เราเติม /dbName เข้าไปใน URI เพื่อระบุ database เป้าหมาย
		const uriWithDb = mongodbUrl.includes('?') ? mongodbUrl.replace('?', `${process.env.MONGODB_NAME}?`) : `${mongodbUrl}/${process.env.MONGODB_NAME}`;

		cmd = `mongoimport --uri="${uriWithDb}" --collection=${from} --mode=upsert --type=json --file=${fullPath} --jsonArray`;
	} else {
		// ✅ สำหรับ Local: ใช้ --host แบบเดิมที่คุณคุ้นเคย
		let urldb = mongodbUrl.replace('mongodb://', '');
		cmd = `mongoimport --host=${urldb} --username=${process.env.MONGODB_USERNAME} --password=${process.env.MONGODB_PASSWORD} --authenticationDatabase admin --db=${process.env.MONGODB_NAME} --collection=${from} --mode=upsert --type=json --file=${fullPath} --jsonArray`;
	}
	// const cmd = `mongoimport --host=${urldb} --username=${process.env.MONGODB_USERNAME} --password=${process.env.MONGODB_PASSWORD} --authenticationDatabase admin --db=${process.env.MONGODB_NAME} --collection=${from} --mode=upsert --type=json --file=${fullPath} --jsonArray`;
	console.log('⏳ Executing:', urldb, fullPath);

	return cmd;
}

module.exports = {
	mongoImport,
};
