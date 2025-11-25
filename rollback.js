const { MongoClient } = require('mongodb');
const path = require('path');
require('dotenv').config();

const url = process.env.MONGODB_URL || 'mongodb://localhost:27017';
const dbName = process.env.MONGODB_NAME || 'dbtest';

async function rollback() {
	const client = new MongoClient(url, {
		auth: {
			username: process.env.MONGODB_USERNAME,
			password: process.env.MONGODB_PASSWORD,
		},
		authSource: 'admin',
	});
	await client.connect();
	const db = client.db(dbName);
	const MIGRATION_COLLECTION = 'log_migrations';
	console.log('🔌 Connected...');
	const migrationCollection = db.collection(MIGRATION_COLLECTION);
	const lastMigration = await migrationCollection.find().sort({ appliedAt: -1 }).limit(1).next();

	if (!lastMigration) {
		console.log('❌ No migrations to rollback.');
		await client.close();
		return;
	}

	const migrationsPath = path.resolve('./migrations');
	const file = lastMigration.name;
	const migration = require(path.resolve(migrationsPath, file));
	if (migration.down) {
		console.log(`✅ Rolling back migration: ${file}`);
		await migration.down(db);

		await migrationCollection.deleteOne({ name: file });
	}

	await client.close();
	console.log('📦 Rollback end!');
}

rollback().catch((err) => {
	console.error('❌ ERROR: ' + err);
	process.exit(1);
});
