const path = require('path');
require('dotenv').config();

function mongoImport(from, fileName) {
	let urldb = `${process.env.MONGODB_URL}`;
	urldb = urldb.replace('mongodb://', '');
	const fullPath = path.resolve('migrations/seeds/', fileName);

	const cmd = `mongoimport --host=${urldb} --username=${process.env.MONGODB_USERNAME} --password=${process.env.MONGODB_PASSWORD} --authenticationDatabase admin --db=${process.env.MONGODB_NAME} --collection=${from} --mode=upsert --type=json --file=${fullPath} --jsonArray`;
	console.log('⏳ Executing:', urldb, fullPath);

	return cmd;
}

module.exports = {
	mongoImport,
};
