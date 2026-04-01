const { MongoClient } = require('mongodb');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const url = process.env.MONGODB_URL || 'mongodb://localhost:27017';
const dbName = process.env.MONGODB_NAME || 'dbtest';

async function runMigrations() {
	let options = undefined;
	if (process.env.MONGODB_USERNAME && process.env.MONGODB_PASSWORD) {
		options = {
			auth: {
				username: process.env.MONGODB_USERNAME,
				password: process.env.MONGODB_PASSWORD,
			},
			authSource: 'admin',
		};
	}

	const client = new MongoClient(url, options);
	const db = client.db(dbName);
	const MIGRATION_COLLECTION = 'log_migrations';
	console.log('🔌 Connected...');
	const info = await db.command({ connectionStatus: 1 });
	const roles = info.authInfo.authenticatedUserRoles;
	console.log('🔐 Current roles:', roles);
	// ตรวจสอบว่ามี collection _migrations หรือไม่
	const collections = await db.listCollections().toArray();
	if (!collections.some((c) => c.name === MIGRATION_COLLECTION)) {
		console.log('🟢 Creating migration collection...');
		await db.createCollection(MIGRATION_COLLECTION);
	}

	const migrationCollection = db.collection(MIGRATION_COLLECTION);

	const migrationsPath = path.resolve('./migrations');
	const files = fs
		.readdirSync(migrationsPath)
		.filter((f) => f.endsWith('.js'))
		.sort();

	for (const file of files) {
		// ตรวจสอบว่าไฟล์นี้รันไปแล้วหรือยัง
		const alreadyRun = await migrationCollection.findOne({ name: file });
		if (alreadyRun) {
			console.log(`➡️ Skipping already applied migration: ${file}`);
			continue;
		}

		const migration = require(path.resolve(migrationsPath, file));
		if (migration.up) {
			console.log(`✅ Running migration: ${file}`);
			await migration.up(db);

			// บันทึกสถานะ migration ว่าเรียบร้อยแล้ว
			await migrationCollection.insertOne({
				name: file,
				appliedAt: new Date(),
			});
		}
	}

	await client.close();
	console.log('📦 All migrations end!');
}

runMigrations().catch((err) => {
	console.error('❌ ERROR: ' + err);
	process.exit(1);
});
